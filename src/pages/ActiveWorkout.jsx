import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { X, Check, Plus, Clock, Trophy, Dumbbell, ChevronDown, ChevronUp, Play, Pause, TrendingUp } from 'lucide-react';
import { saveWorkoutLog, getPersonalRecord, savePersonalRecord, getAllWorkoutLogs } from '../store/db';
import RestTimer from '../components/RestTimer';
import { getExerciseVideoUrl } from '../data/exerciseVideos';
import { useExerciseLibrary } from '../data/exercises';
import { suggestProgression, convertWeight, localDateStr } from '../lib/fitness';
import { useSettings } from '../store/SettingsContext';
import { useToast } from '../components/Toast';
import styles from './ActiveWorkout.module.css';

const RESUME_KEY = 'ironlog_active_workout';

export default function ActiveWorkout() {
  const location = useLocation();
  const navigate = useNavigate();
  const { weightUnit, defaultRestTimer, vibrationEnabled } = useSettings();
  const { toast, confirm } = useToast();
  const { exercises: libraryExercises } = useExerciseLibrary();

  // Get workout from router state. A direct open (no state, no resume snapshot)
  // starts an empty freestyle session instead of a phantom pre-filled workout.
  const workoutData = location.state?.workout || {
    name: 'Freestyle Session',
    exercises: []
  };

  // Workout state
  const [exercises, setExercises] = useState([]);
  const [elapsedTime, setElapsedTime] = useState(0);
  
  // Rest timer state
  const [isRestTimerVisible, setIsRestTimerVisible] = useState(false);
  const [restDuration, setRestDuration] = useState(90);
  const [restSession, setRestSession] = useState(0); // bumps each set to remount the timer

  // Summary state
  const [showSummary, setShowSummary] = useState(false);
  const [newPRs, setNewPRs] = useState([]); // list of exercise names where a PR was hit
  const [totalVolume, setTotalVolume] = useState(0);
  const [totalSetsCount, setTotalSetsCount] = useState(0);
  const [summaryElapsed, setSummaryElapsed] = useState(0); // duration frozen at finish
  const [sessionNotes, setSessionNotes] = useState('');

  // Previous performance records state: exerciseName -> 'weight kg x reps'
  const [previousData, setPreviousData] = useState({});
  // Smart suggestions: exerciseName -> { weight, reps, note }
  const [suggestions, setSuggestions] = useState({});

  // Add Exercise Modal State
  const [showAddExModal, setShowAddExModal] = useState(false);
  const [exSearchQuery, setExSearchQuery] = useState('');

  const timerRef = useRef(null);
  const startTimeRef = useRef(Date.now());
  const initRef = useRef(false);
  const logsCacheRef = useRef(null); // avoids re-reading the whole log store per added exercise

  // Session metadata (kept in a ref so resume can override the incoming nav state)
  const [sessionMeta, setSessionMeta] = useState({
    name: workoutData.name,
    programId: workoutData.programId,
  });

  const clearResume = () => {
    try { localStorage.removeItem(RESUME_KEY); } catch (e) { /* ignore */ }
  };

  // Initialize exercises and load historical data (runs exactly once)
  useEffect(() => {
    if (initRef.current) return;
    initRef.current = true;

    const hasIncoming = !!location.state?.workout;
    let restored = null;
    if (!hasIncoming) {
      // No nav state means a reload / direct open — try to resume an
      // interrupted session so progress isn't silently lost.
      try {
        const raw = localStorage.getItem(RESUME_KEY);
        if (raw) restored = JSON.parse(raw);
      } catch (e) { /* ignore */ }
    } else {
      // Starting a fresh session — discard any stale resume snapshot.
      clearResume();
    }

    if (restored && Array.isArray(restored.exercises) && restored.exercises.length > 0) {
      setExercises(restored.exercises);
      setSessionMeta({ name: restored.name, programId: restored.programId });
      startTimeRef.current = restored.startTime || Date.now();
      setElapsedTime(Math.floor((Date.now() - startTimeRef.current) / 1000));
      loadPreviousPerformance(restored.exercises);
      toast('Resumed your in-progress workout.', 'info');
    } else {
      // Standardize sets format
      const formatted = (workoutData.exercises || []).map((ex) => {
        const setTotal = parseInt(ex.sets) || 3;
        const defaultReps = parseInt(ex.reps) || 10;
        const sets = [];
        for (let i = 0; i < setTotal; i++) {
          sets.push({ weight: 0, reps: defaultReps, completed: false });
        }
        return { ...ex, sets, isNotesExpanded: false };
      });
      setExercises(formatted);
      loadPreviousPerformance(workoutData.exercises || []);
      startTimeRef.current = Date.now();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Workout duration timer — kept separate so it stays alive under StrictMode's
  // mount/unmount/remount cycle (the init effect above runs only once).
  useEffect(() => {
    timerRef.current = setInterval(() => {
      setElapsedTime(Math.floor((Date.now() - startTimeRef.current) / 1000));
    }, 1000);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []);

  // Auto-save the in-progress session so a reload/close can resume it.
  useEffect(() => {
    if (!initRef.current || showSummary) return;
    if (exercises.length === 0) {
      // Removing the last exercise must also drop the snapshot, or the next
      // open would "resume" exercises the user explicitly discarded.
      clearResume();
      return;
    }
    try {
      localStorage.setItem(RESUME_KEY, JSON.stringify({
        name: sessionMeta.name,
        programId: sessionMeta.programId,
        exercises,
        startTime: startTimeRef.current,
        savedAt: Date.now(),
      }));
    } catch (e) { /* storage full / unavailable — non-fatal */ }
  }, [exercises, sessionMeta, showSummary]);

  // Fetch previous performance + compute a smart next-target suggestion per exercise
  const loadPreviousPerformance = async (exercisesList) => {
    try {
      if (!logsCacheRef.current) logsCacheRef.current = await getAllWorkoutLogs();
      const logs = logsCacheRef.current;
      const prevMap = {};
      const suggMap = {};

      for (const ex of exercisesList) {
        const repTarget = parseInt(ex.reps) || undefined;
        // Find most recent log where this exercise was performed
        let found = false;
        for (const log of logs) {
          const logEx = log.exercises?.find(le => le.name.toLowerCase() === ex.name.toLowerCase());
          if (logEx && logEx.sets?.length > 0) {
            // Convert the log's stored unit into the user's current unit so a
            // kg-era 100 doesn't get replayed as 100 lbs (or vice versa).
            const logUnit = log.weightUnit || weightUnit;
            const completedSets = logEx.sets
              .filter(s => s.completed)
              .map(s => ({ ...s, weight: convertWeight(s.weight, logUnit, weightUnit) }));
            if (completedSets.length > 0) {
              const bestSet = completedSets.reduce((best, curr) => (curr.weight > best.weight) ? curr : best, completedSets[0]);
              prevMap[ex.name] = { weight: bestSet.weight, reps: bestSet.reps };
              const sugg = suggestProgression(completedSets, { repTarget });
              if (sugg) suggMap[ex.name] = sugg;
              found = true;
              break;
            }
          }
        }

        // If no past log, check personalRecords store
        if (!found) {
          const pr = await getPersonalRecord(ex.name);
          prevMap[ex.name] = pr
            ? { weight: convertWeight(pr.weight, pr.weightUnit || weightUnit, weightUnit), reps: pr.reps }
            : null;
        }
      }

      // Merge so exercises added mid-session keep earlier entries intact.
      setPreviousData(prev => ({ ...prev, ...prevMap }));
      setSuggestions(prev => ({ ...prev, ...suggMap }));
    } catch (e) {
      console.error("Failed to load previous data:", e);
    }
  };

  // Apply a suggested target to every not-yet-completed set of an exercise.
  const applySuggestion = (exIdx) => {
    const sugg = suggestions[exercises[exIdx]?.name];
    if (!sugg) return;
    setExercises(prev => prev.map((ex, i) => {
      if (i !== exIdx) return ex;
      return {
        ...ex,
        sets: ex.sets.map(s => s.completed ? s : { ...s, weight: sugg.weight, reps: sugg.reps }),
      };
    }));
    toast('Applied suggested target.', 'success');
  };

  const formatTimer = (totalSeconds) => {
    const hrs = Math.floor(totalSeconds / 3600);
    const mins = Math.floor((totalSeconds % 3600) / 60);
    const secs = totalSeconds % 60;
    return [
      hrs > 0 ? hrs.toString().padStart(2, '0') : null,
      mins.toString().padStart(2, '0'),
      secs.toString().padStart(2, '0')
    ].filter(Boolean).join(':');
  };

  const handleToggleNote = (exIdx) => {
    setExercises(prev => prev.map((ex, idx) => {
      if (idx === exIdx) {
        return { ...ex, isNotesExpanded: !ex.isNotesExpanded };
      }
      return ex;
    }));
  };

  const handleUpdateSet = (exIdx, setIdx, field, value) => {
    setExercises(prev => prev.map((ex, i) => {
      if (i === exIdx) {
        const newSets = ex.sets.map((s, j) => {
          if (j === setIdx) {
            return { ...s, [field]: value };
          }
          return s;
        });
        return { ...ex, sets: newSets };
      }
      return ex;
    }));
  };

  const handleToggleCompleted = (exIdx, setIdx) => {
    const ex = exercises[exIdx];
    if (!ex) return;
    const currentSet = ex.sets[setIdx];
    if (!currentSet) return;

    // Decide everything from current state BEFORE updating. Doing this inside the
    // setExercises updater was unreliable: React only runs the updater
    // synchronously via an eager bail-out that's skipped whenever another update
    // (e.g. the per-second elapsed-time tick) is pending — which made the rest
    // timer open only intermittently.
    const willComplete = !currentSet.completed;

    // Parse rest string e.g. "90s" or "2 min"; fall back to the user's default.
    let duration = defaultRestTimer;
    if (ex.rest) {
      const seconds = parseInt(ex.rest);
      if (!isNaN(seconds)) {
        duration = ex.rest.includes('min') ? seconds * 60 : seconds;
      }
    }

    setExercises(prev => prev.map((e, i) => {
      if (i !== exIdx) return e;
      const newSets = e.sets.map((s, j) => {
        if (j !== setIdx) return s;
        let finalDuration = s.duration;
        let isRunning = s.isTimerRunning;
        if (willComplete && isRunning) {
          finalDuration = s.timerStartTime ? Math.floor((Date.now() - s.timerStartTime) / 1000) : 0;
          isRunning = false;
        }
        return { ...s, completed: willComplete, duration: finalDuration, isTimerRunning: isRunning };
      });
      return { ...e, sets: newSets };
    }));

    // Only open the rest timer when completing a set (not when un-checking).
    if (willComplete) {
      if (vibrationEnabled && navigator.vibrate) navigator.vibrate(30);
      setRestDuration(duration);
      setRestSession(n => n + 1); // remount RestTimer so it restarts cleanly each set
      setIsRestTimerVisible(true);
    }
  };

  // Tap a set's PREV cell to copy last session's best weight/reps into the inputs.
  const applyPrevToSet = (exIdx, setIdx) => {
    const prev = previousData[exercises[exIdx]?.name];
    if (!prev) return;
    setExercises(list => list.map((ex, i) => {
      if (i !== exIdx) return ex;
      return {
        ...ex,
        sets: ex.sets.map((s, j) => (j === setIdx && !s.completed)
          ? { ...s, weight: prev.weight, reps: prev.reps }
          : s),
      };
    }));
  };

  const handleRemoveExercise = async (exIdx) => {
    const ex = exercises[exIdx];
    if (!ex) return;
    const hasCompleted = ex.sets.some(s => s.completed);
    if (hasCompleted) {
      const ok = await confirm({
        title: `Remove ${ex.name}?`,
        message: 'This exercise has completed sets — they will be discarded.',
        confirmLabel: 'Remove',
        danger: true,
      });
      if (!ok) return;
    }
    setExercises(prev => prev.filter((_, i) => i !== exIdx));
  };

  const handleStartSetTimer = (exIdx, setIdx) => {
    setExercises(prev => prev.map((ex, i) => {
      if (i === exIdx) {
        const newSets = ex.sets.map((s, j) => {
          if (j === setIdx) {
            return {
              ...s,
              timerStartTime: Date.now(),
              isTimerRunning: true
            };
          }
          return s;
        });
        return { ...ex, sets: newSets };
      }
      return ex;
    }));
  };

  const handleStopSetTimer = (exIdx, setIdx) => {
    setExercises(prev => prev.map((ex, i) => {
      if (i === exIdx) {
        const newSets = ex.sets.map((s, j) => {
          if (j === setIdx) {
            const duration = s.timerStartTime ? Math.floor((Date.now() - s.timerStartTime) / 1000) : 0;
            return {
              ...s,
              isTimerRunning: false,
              duration
            };
          }
          return s;
        });
        return { ...ex, sets: newSets };
      }
      return ex;
    }));
  };

  const handleAddCustomExercise = (ex) => {
    const newEx = {
      name: ex.name,
      sets: [
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false }
      ],
      rest: '90s',
      muscleGroup: ex.muscleGroup,
      equipment: ex.equipment,
      notes: 'Custom exercise added during session',
      isNotesExpanded: false
    };
    setExercises(prev => [...prev, newEx]);
    setShowAddExModal(false);
    setExSearchQuery('');
    // Pull last-session numbers + progression suggestion for the new exercise.
    loadPreviousPerformance([newEx]);
  };

  const handleAddSet = (exIdx) => {
    setExercises(prev => prev.map((ex, i) => {
      if (i === exIdx) {
        const lastSet = ex.sets[ex.sets.length - 1] || { weight: 0, reps: 10 };
        return {
          ...ex,
          sets: [
            ...ex.sets,
            { weight: lastSet.weight, reps: lastSet.reps, completed: false }
          ]
        };
      }
      return ex;
    }));
  };

  // Rest Timer Callbacks
  const handleRestTimerComplete = () => {
    setIsRestTimerVisible(false);
  };

  const handleRestTimerSkip = () => {
    setIsRestTimerVisible(false);
  };

  // Check if at least one set is completed
  const isAnySetCompleted = () => {
    return exercises.some(ex => ex.sets.some(s => s.completed));
  };

  // Finish Workout: calculate summary metrics and determine if new PRs were made.
  // The session timer keeps running so "Back to Workout" resumes seamlessly;
  // the displayed/saved duration is frozen in summaryElapsed.
  const handleFinishWorkout = async () => {
    setSummaryElapsed(elapsedTime);

    let volume = 0;
    let setsCount = 0;
    const prsHit = [];

    // Calculate metrics & verify PRs
    for (const ex of exercises) {
      let exMaxWeight = 0;
      let exMaxRepsForWeight = 0;
      let exHasCompletedSet = false;

      ex.sets.forEach(s => {
        if (s.completed) {
          exHasCompletedSet = true;
          setsCount++;
          volume += (s.weight || 0) * (s.reps || 0);

          if (s.weight > exMaxWeight) {
            exMaxWeight = s.weight;
            exMaxRepsForWeight = s.reps;
          }
        }
      });

      if (exHasCompletedSet) {
        // Compare with current PR
        const currentPR = await getPersonalRecord(ex.name);
        if (!currentPR || exMaxWeight > currentPR.weight || (exMaxWeight === currentPR.weight && exMaxRepsForWeight > currentPR.reps)) {
          // If we actually lifted a non-zero weight, or if bodyweight is tracked
          if (exMaxWeight > 0 || ex.equipment === 'bodyweight') {
            prsHit.push(ex.name);
          }
        }
      }
    }

    setTotalVolume(volume);
    setTotalSetsCount(setsCount);
    setNewPRs(prsHit);
    setShowSummary(true);
  };

  const handleSaveAndExit = async () => {
    try {
      // 1. Save new PRs to Database
      for (const ex of exercises) {
        let maxWeight = 0;
        let maxReps = 0;
        let activePR = false;

        ex.sets.forEach(s => {
          if (s.completed) {
            activePR = true;
            if (s.weight > maxWeight) {
              maxWeight = s.weight;
              maxReps = s.reps;
            }
          }
        });

        if (activePR) {
          const current = await getPersonalRecord(ex.name);
          if (!current || maxWeight > current.weight || (maxWeight === current.weight && maxReps > current.reps)) {
            await savePersonalRecord({
              exerciseName: ex.name,
              weight: maxWeight,
              reps: maxReps,
              weightUnit,
              date: localDateStr()
            });
          }
        }
      }

      // 2. Save Workout Log
      const workoutLog = {
        id: `log-${Date.now()}`,
        name: sessionMeta.name,
        programName: sessionMeta.programId === 'beyond-the-rim' ? 'BTR' : (sessionMeta.programId === 'expert-powerbuilding' ? 'Expert' : 'Custom'),
        programId: sessionMeta.programId || 'custom',
        date: localDateStr(),
        duration: Math.round(summaryElapsed / 60) || 1, // in minutes
        notes: sessionNotes.trim(),
        exercises: exercises.map(ex => ({
          name: ex.name,
          isPR: newPRs.includes(ex.name),
          sets: ex.sets.map(s => ({
            weight: s.weight,
            reps: s.reps,
            completed: s.completed,
            ...(s.duration ? { duration: s.duration } : {})
          }))
        })),
        totalVolume,
        totalSets: totalSetsCount,
        weightUnit
      };

      await saveWorkoutLog(workoutLog);
      clearResume();

      toast(newPRs.length > 0 ? `Saved! ${newPRs.length} new PR${newPRs.length > 1 ? 's' : ''} 🏆` : 'Workout saved!', 'success');
      navigate('/');
    } catch (e) {
      console.error("Failed to save workout log:", e);
      toast('Error saving workout log.', 'error');
    }
  };

  const handleQuitWorkout = async () => {
    const ok = await confirm({
      title: 'Quit workout?',
      message: 'Your current progress will be discarded.',
      confirmLabel: 'Quit',
      danger: true,
    });
    if (ok) {
      clearResume();
      navigate('/');
    }
  };

  return (
    <div className={`${styles.activeWorkoutPage} page stagger`}>
      {/* Header */}
      <header className={styles.header}>
        <div className={styles.titleCol}>
          <h1 className={styles.workoutName}>{sessionMeta.name}</h1>
          <div className={styles.timerRow}>
            <Clock size={16} className={styles.timerIcon} />
            <span className={styles.timeValue}>{formatTimer(elapsedTime)}</span>
          </div>
        </div>

        <button className="btn btn--ghost btn--icon" onClick={handleQuitWorkout}>
          <X size={20} />
        </button>
      </header>

      {/* Exercises List */}
      <div className={styles.exercisesList}>
        {exercises.length === 0 && (
          <div className="empty-state card">
            <Dumbbell size={32} />
            <h3>Empty session</h3>
            <p>Add your first exercise below to start logging sets.</p>
          </div>
        )}
        {exercises.map((ex, exIdx) => {
          const allCompleted = ex.sets.length > 0 && ex.sets.every(s => s.completed);
          
          return (
            <div 
              key={exIdx} 
              className={`${styles.exerciseCard} card ${allCompleted ? styles.completedCard : ''}`}
            >
              {/* Card Header */}
              <div className={styles.cardHeader}>
                <div className={styles.exMeta}>
                  <h3 className={styles.exName}>{ex.name}</h3>
                  <div className={styles.badges}>
                    {ex.muscleGroup && <span className="badge badge--accent">{ex.muscleGroup}</span>}
                    {ex.equipment && <span className="badge badge--blue">{ex.equipment}</span>}
                    {(ex.youtubeUrl || getExerciseVideoUrl(ex.name)) && (
                      <a
                        href={ex.youtubeUrl || getExerciseVideoUrl(ex.name)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={`${styles.tutorialBadge} badge badge--amber`}
                      >
                        <Play size={10} fill="currentColor" style={{ marginRight: '4px' }} /> Tutorial
                      </a>
                    )}
                  </div>
                </div>

                <div className={styles.cardHeaderActions}>
                  <button className="btn btn--ghost btn--icon" onClick={() => handleToggleNote(exIdx)}>
                    {ex.isNotesExpanded ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                  </button>
                  <button
                    className="btn btn--ghost btn--icon"
                    title="Remove exercise"
                    aria-label={`Remove ${ex.name}`}
                    onClick={() => handleRemoveExercise(exIdx)}
                  >
                    <X size={16} />
                  </button>
                </div>
              </div>

              {/* Collapsible notes */}
              {ex.isNotesExpanded && ex.notes && (
                <p className={styles.notesBox}>
                  <strong>Notes:</strong> {ex.notes}
                </p>
              )}

              {/* Smart progressive-overload suggestion */}
              {suggestions[ex.name] && !ex.sets.every(s => s.completed) && (
                <button
                  type="button"
                  className={styles.suggestionBar}
                  onClick={() => applySuggestion(exIdx)}
                  title="Tap to apply to all sets"
                >
                  <TrendingUp size={14} />
                  <span className={styles.suggestionText}>
                    Suggested: <strong>{suggestions[ex.name].weight}{weightUnit} × {suggestions[ex.name].reps}</strong>
                  </span>
                  <span className={styles.suggestionApply}>Apply</span>
                </button>
              )}

              {/* Sets Table */}
              <table className={styles.setsTable}>
                <thead>
                  <tr>
                    <th>SET</th>
                    <th>PREV</th>
                    <th>{weightUnit.toUpperCase()}</th>
                    <th>REPS</th>
                    <th>TIME</th>
                    <th>✓</th>
                  </tr>
                </thead>
                <tbody>
                  {ex.sets.map((set, setIdx) => {
                    let displayTime = '—';
                    if (set.completed) {
                      displayTime = set.duration ? `${set.duration}s` : '—';
                    } else if (set.isTimerRunning) {
                      const elapsed = set.timerStartTime ? Math.floor((Date.now() - set.timerStartTime) / 1000) : 0;
                      displayTime = `${elapsed}s`;
                    } else if (set.duration) {
                      displayTime = `${set.duration}s`;
                    }

                    return (
                      <tr key={setIdx} className={set.completed ? styles.completedRow : ''}>
                        <td className={styles.setNum}>{setIdx + 1}</td>
                        <td className={styles.prevText}>
                          {previousData[ex.name] ? (
                            <button
                              type="button"
                              className={styles.prevFillBtn}
                              title="Tap to use last session's numbers"
                              disabled={set.completed}
                              onClick={() => applyPrevToSet(exIdx, setIdx)}
                            >
                              {previousData[ex.name].weight}{weightUnit} × {previousData[ex.name].reps}
                            </button>
                          ) : '—'}
                        </td>
                        <td>
                          <input
                            type="number"
                            step="0.5"
                            className={`${styles.setValInput} input`}
                            value={set.weight || ''}
                            placeholder="0"
                            disabled={set.completed}
                            onChange={(e) => handleUpdateSet(exIdx, setIdx, 'weight', parseFloat(e.target.value) || 0)}
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            className={`${styles.setValInput} input`}
                            value={set.reps || ''}
                            placeholder="0"
                            disabled={set.completed}
                            onChange={(e) => handleUpdateSet(exIdx, setIdx, 'reps', parseInt(e.target.value) || 0)}
                          />
                        </td>
                        <td>
                          <div className={styles.setTimerCell}>
                            <span className={set.isTimerRunning ? styles.runningTimer : ''}>{displayTime}</span>
                            {!set.completed && (
                              <button
                                className={styles.setTimerBtn}
                                onClick={() => set.isTimerRunning ? handleStopSetTimer(exIdx, setIdx) : handleStartSetTimer(exIdx, setIdx)}
                              >
                                {set.isTimerRunning ? <Pause size={12} /> : <Play size={12} />}
                              </button>
                            )}
                          </div>
                        </td>
                        <td>
                          <button
                            className={`checkbox ${set.completed ? 'checkbox--checked' : ''}`}
                            onClick={() => handleToggleCompleted(exIdx, setIdx)}
                          >
                            {set.completed && <Check size={14} />}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>

              <button 
                className={`${styles.addSetBtn} btn btn--ghost btn--sm btn--full`}
                onClick={() => handleAddSet(exIdx)}
              >
                <Plus size={14} /> Add Set
              </button>
            </div>
          );
        })}

        {/* Add Custom Exercise to Session */}
        <div style={{ marginTop: '1.5rem', paddingBottom: '2.5rem' }}>
          <button 
            className="btn btn--secondary btn--full"
            onClick={() => setShowAddExModal(true)}
          >
            <Plus size={16} /> Add Exercise to Session
          </button>
        </div>
      </div>

      {/* Bottom Finish Action Bar */}
      <div className={styles.actionBar}>
        <button 
          className="btn btn--primary btn--full" 
          disabled={!isAnySetCompleted()}
          onClick={handleFinishWorkout}
        >
          Finish Workout
        </button>
      </div>

      {/* Rest Timer Modal Overlay */}
      <RestTimer
        key={restSession}
        isVisible={isRestTimerVisible}
        initialDuration={restDuration}
        onComplete={handleRestTimerComplete}
        onSkip={handleRestTimerSkip}
      />

      {/* Workout Summary Overlay */}
      {showSummary && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-handle" />
            
            <div className={styles.summaryHeader}>
              <h2 className={styles.summaryTitle}>Workout Completed!</h2>
              <p className={styles.summarySubtitle}>Great session! Here is your breakdown:</p>
            </div>

            <div className={styles.summaryStats}>
              <div className={styles.summaryStatCard}>
                <span className={styles.summaryVal}>{formatTimer(summaryElapsed)}</span>
                <span className={styles.summaryLbl}>Duration</span>
              </div>
              <div className={styles.summaryStatCard}>
                <span className={styles.summaryVal}>{totalSetsCount}</span>
                <span className={styles.summaryLbl}>Total Sets</span>
              </div>
              <div className={styles.summaryStatCard}>
                <span className={styles.summaryVal}>{totalVolume.toLocaleString()} {weightUnit}</span>
                <span className={styles.summaryLbl}>Total Volume</span>
              </div>
            </div>

            {/* Personal Records Highlight */}
            {newPRs.length > 0 && (
              <div className={styles.prBox}>
                <div className={styles.prHeader}>
                  <Trophy className={styles.prIcon} size={20} />
                  <span>{newPRs.length} Personal Records Hit!</span>
                </div>
                <div className={styles.prList}>
                  {newPRs.map((name, idx) => (
                    <div key={idx} className={styles.prItem}>
                      <Trophy size={14} className={styles.prItemIcon} />
                      <span>{name}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Session notes */}
            <textarea
              className={`${styles.notesInput} input`}
              placeholder="Session notes (optional) — how did it feel?"
              rows={2}
              value={sessionNotes}
              onChange={(e) => setSessionNotes(e.target.value)}
            />

            <button className="btn btn--primary btn--full" onClick={handleSaveAndExit}>
              Save & Exit
            </button>
            <button
              className="btn btn--ghost btn--full"
              style={{ marginTop: 'var(--sp-2)' }}
              onClick={() => setShowSummary(false)}
            >
              Back to Workout
            </button>
          </div>
        </div>
      )}

      {/* Add Custom Exercise Modal */}
      {showAddExModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-handle" />
            <div className={styles.modalHeader}>
              <h3 className={styles.modalTitle}>Add Exercise to Session</h3>
              <button className="btn btn--ghost btn--icon" onClick={() => setShowAddExModal(false)}>
                <X size={20} />
              </button>
            </div>

            <div className={styles.modalBody}>
              <input
                type="text"
                className="input"
                placeholder="Search exercises..."
                value={exSearchQuery}
                onChange={(e) => setExSearchQuery(e.target.value)}
              />
              <div className={styles.searchSelectionList}>
                {libraryExercises.filter(ex => ex.name.toLowerCase().includes(exSearchQuery.toLowerCase())).slice(0, 10).map((ex) => (
                  <div 
                    key={ex.name} 
                    className={styles.selectionItem}
                    onClick={() => handleAddCustomExercise(ex)}
                  >
                    <div className={styles.selMeta}>
                      <span className={styles.selExName}>{ex.name}</span>
                      <span className={styles.selExSub}>{ex.muscleGroup} • {ex.equipment}</span>
                    </div>
                    <Plus size={16} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
