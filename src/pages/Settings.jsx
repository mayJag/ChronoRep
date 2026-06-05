import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Timer, Scale, Volume2, Vibrate, Trash2, Info, Download, Upload, RotateCcw, ShieldAlert, Check, HelpCircle } from 'lucide-react';
import { getSetting, setSetting, getDB } from '../store/db';
import styles from './Settings.module.css';

export default function Settings() {
  const navigate = useNavigate();

  // Settings state
  const [restTimer, setRestTimer] = useState(90);
  const [weightUnit, setWeightUnit] = useState('kg');
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [vibrationEnabled, setVibrationEnabled] = useState(true);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const rest = await getSetting('defaultRestTimer') || 90;
      const unit = await getSetting('weightUnit') || 'kg';
      const sound = await getSetting('soundEnabled') !== false; // default true
      const vibration = await getSetting('vibrationEnabled') !== false; // default true

      setRestTimer(rest);
      setWeightUnit(unit);
      setSoundEnabled(sound);
      setVibrationEnabled(vibration);
    } catch (e) {
      console.error("Failed to load settings:", e);
    }
  };

  const handleUpdateRestTimer = async (val) => {
    const intVal = parseInt(val) || 90;
    setRestTimer(intVal);
    await setSetting('defaultRestTimer', intVal);
  };

  const handleToggleWeightUnit = async () => {
    const nextUnit = weightUnit === 'kg' ? 'lbs' : 'kg';
    setWeightUnit(nextUnit);
    await setSetting('weightUnit', nextUnit);
  };

  const handleToggleSound = async () => {
    const nextSound = !soundEnabled;
    setSoundEnabled(nextSound);
    await setSetting('soundEnabled', nextSound);
  };

  const handleToggleVibration = async () => {
    const nextVib = !vibrationEnabled;
    setVibrationEnabled(nextVib);
    await setSetting('vibrationEnabled', nextVib);
  };

  // --- Database Maintenance Functions ---
  const handleClearHistory = async () => {
    if (window.confirm("WARNING: Are you sure you want to clear your workout history? All your logs will be deleted permanently.")) {
      try {
        const db = await getDB();
        await db.clear('workoutLogs');
        alert("Workout history cleared successfully.");
      } catch (err) {
        console.error(err);
        alert("Failed to clear history.");
      }
    }
  };

  const handleResetAllData = async () => {
    const firstConfirm = window.confirm("CRITICAL WARNING: Are you sure you want to reset all data? This will delete all your settings, routines, plans, history, and personal records.");
    if (firstConfirm) {
      const secondConfirm = window.confirm("DOUBLE CONFIRMATION: Are you absolutely sure? This action is irreversible.");
      if (secondConfirm) {
        try {
          const db = await getDB();
          await db.clear('settings');
          await db.clear('routines');
          await db.clear('workoutLogs');
          await db.clear('personalRecords');
          await db.clear('plans');

          alert("All data reset successfully. The application will reload.");
          window.location.reload();
        } catch (err) {
          console.error(err);
          alert("Failed to reset database.");
        }
      }
    }
  };

  // --- Backup & Restore Functions ---
  const handleExportData = async () => {
    try {
      const db = await getDB();
      const backupData = {
        settings: await db.getAll('settings'),
        routines: await db.getAll('routines'),
        workoutLogs: await db.getAll('workoutLogs'),
        personalRecords: await db.getAll('personalRecords'),
        plans: await db.getAll('plans'),
        exportedAt: new Date().toISOString()
      };

      const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(backupData, null, 2));
      const downloadAnchor = document.createElement('a');
      downloadAnchor.setAttribute("href", dataStr);
      downloadAnchor.setAttribute("download", `ironlog_backup_${new Date().toISOString().split('T')[0]}.json`);
      document.body.appendChild(downloadAnchor);
      downloadAnchor.click();
      downloadAnchor.remove();
    } catch (e) {
      console.error(e);
      alert("Failed to export data backup.");
    }
  };

  const handleImportData = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const data = JSON.parse(e.target.result);
        if (!data.workoutLogs && !data.personalRecords && !data.routines) {
          alert("Invalid backup file format.");
          return;
        }

        if (window.confirm("WARNING: Importing data will overwrite your current settings, routines, history, and records. Proceed?")) {
          const db = await getDB();
          
          // Clear current tables
          await db.clear('settings');
          await db.clear('routines');
          await db.clear('workoutLogs');
          await db.clear('personalRecords');
          await db.clear('plans');

          // Populate tables
          if (data.settings) {
            for (const item of data.settings) await db.put('settings', item);
          }
          if (data.routines) {
            for (const item of data.routines) await db.put('routines', item);
          }
          if (data.workoutLogs) {
            for (const item of data.workoutLogs) await db.put('workoutLogs', item);
          }
          if (data.personalRecords) {
            for (const item of data.personalRecords) await db.put('personalRecords', item);
          }
          if (data.plans) {
            for (const item of data.plans) await db.put('plans', item);
          }

          alert("Backup data restored successfully! App will reload.");
          window.location.reload();
        }
      } catch (err) {
        console.error(err);
        alert("Error parsing backup file.");
      }
    };
    reader.readAsText(file);
  };

  return (
    <div className={`${styles.settingsPage} page stagger`}>
      <header className={styles.header}>
        <h1 className="page-title">Settings</h1>
        <p className="page-subtitle">Configure your workout behavior and data backup preferences</p>
      </header>

      {/* Preferences Section */}
      <section className="section">
        <h2 className={styles.sectionHeader}>Preferences</h2>
        <div className={styles.settingsGroup}>
          {/* Rest Timer */}
          <div className={styles.settingRow}>
            <div className={styles.settingLabelCol}>
              <Timer size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Default Rest Timer</span>
                <span className={styles.settingDesc}>Auto-triggered rest length between sets</span>
              </div>
            </div>
            <select
              className={`${styles.restSelect} select`}
              value={restTimer}
              onChange={(e) => handleUpdateRestTimer(e.target.value)}
            >
              <option value={30}>30s</option>
              <option value={60}>60s</option>
              <option value={90}>90s</option>
              <option value={120}>2m</option>
              <option value={180}>3m</option>
            </select>
          </div>

          {/* Weight Unit */}
          <div className={styles.settingRow}>
            <div className={styles.settingLabelCol}>
              <Scale size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Weight Unit</span>
                <span className={styles.settingDesc}>Display weights in kilograms or pounds</span>
              </div>
            </div>
            <button className={`${styles.toggleBtn} btn btn--secondary btn--sm`} onClick={handleToggleWeightUnit}>
              {weightUnit.toUpperCase()}
            </button>
          </div>

          {/* Sound */}
          <div className={styles.settingRow}>
            <div className={styles.settingLabelCol}>
              <Volume2 size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Sound Effects</span>
                <span className={styles.settingDesc}>Play audio beeps when rest timer finishes</span>
              </div>
            </div>
            <button
              className={`checkbox ${soundEnabled ? 'checkbox--checked' : ''}`}
              onClick={handleToggleSound}
            >
              {soundEnabled && <Check size={14} />}
            </button>
          </div>

          {/* Vibration */}
          <div className={styles.settingRow}>
            <div className={styles.settingLabelCol}>
              <Vibrate size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Haptic Vibration</span>
                <span className={styles.settingDesc}>Vibrate device when rest timer reaches zero</span>
              </div>
            </div>
            <button
              className={`checkbox ${vibrationEnabled ? 'checkbox--checked' : ''}`}
              onClick={handleToggleVibration}
            >
              {vibrationEnabled && <Check size={14} />}
            </button>
          </div>
        </div>
      </section>

      {/* Data Backup & Restore */}
      <section className="section">
        <h2 className={styles.sectionHeader}>Data Backup</h2>
        <div className={styles.settingsGroup}>
          {/* Export */}
          <div className={styles.settingRow} onClick={handleExportData} style={{ cursor: 'pointer' }}>
            <div className={styles.settingLabelCol}>
              <Download size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Export Data Backup</span>
                <span className={styles.settingDesc}>Download workout logs and settings as JSON file</span>
              </div>
            </div>
          </div>

          {/* Import */}
          <div className={styles.settingRow} style={{ position: 'relative' }}>
            <div className={styles.settingLabelCol}>
              <Upload size={18} className={styles.settingIcon} />
              <div className={styles.settingText}>
                <span className={styles.settingName}>Restore Data Backup</span>
                <span className={styles.settingDesc}>Upload and restore a previous JSON data backup</span>
              </div>
            </div>
            <input
              type="file"
              accept=".json"
              className={styles.fileInput}
              onChange={handleImportData}
            />
          </div>
        </div>
      </section>

      {/* Database Maintenance */}
      <section className="section">
        <h2 className={styles.sectionHeader}>Maintenance</h2>
        <div className={styles.settingsGroup}>
          {/* Clear history */}
          <div className={`${styles.settingRow} ${styles.dangerRow}`} onClick={handleClearHistory}>
            <div className={styles.settingLabelCol}>
              <Trash2 size={18} className={styles.dangerIcon} />
              <div className={styles.settingText}>
                <span className={styles.dangerName}>Clear Workout History</span>
                <span className={styles.settingDesc}>Delete all logged sessions. Preserves templates/PRs.</span>
              </div>
            </div>
          </div>

          {/* Reset all data */}
          <div className={`${styles.settingRow} ${styles.dangerRow}`} onClick={handleResetAllData}>
            <div className={styles.settingLabelCol}>
              <RotateCcw size={18} className={styles.dangerIcon} />
              <div className={styles.settingText}>
                <span className={styles.dangerName}>Reset All Application Data</span>
                <span className={styles.settingDesc}>Wipe the database clean. Resets app to factory settings.</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* App Info */}
      <section className="section card" style={{ marginTop: 'var(--sp-6)', textAlign: 'center' }}>
        <Info size={24} className={styles.infoIcon} />
        <h3 className={styles.appName}>IronLog Workout Tracker</h3>
        <p className={styles.appVersion}>Version 1.0.0 (Release Build)</p>
        <p className={styles.appCredits}>
          Engineered for vertical jump performance & powerbuilding. Preloaded with "Beyond The Rim" & Jeff Nippard's Systems.
        </p>
      </section>
    </div>
  );
}
