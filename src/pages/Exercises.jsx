import React, { useState, useMemo } from 'react';
import { Plus, Trash2, Dumbbell, Search, ChevronDown, ChevronUp, Play } from 'lucide-react';
import { saveCustomExercise, deleteCustomExercise } from '../store/db';
import {
  useExerciseLibrary, EX_CATEGORIES, EX_MUSCLES, EX_EQUIPMENT,
} from '../data/exercises';
import { getExerciseVideoUrl } from '../data/exerciseVideos';
import { useToast } from '../components/Toast';
import styles from './Exercises.module.css';

const PAGE_SIZE = 40;

export default function Exercises() {
  const { exercises, customExercises, reload } = useExerciseLibrary();
  const { toast, confirm } = useToast();
  const [query, setQuery] = useState('');
  const [muscleFilter, setMuscleFilter] = useState('all');
  const [equipmentFilter, setEquipmentFilter] = useState('all');
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [expanded, setExpanded] = useState(null);
  const [form, setForm] = useState({ name: '', muscleGroup: 'chest', category: 'compound', equipment: 'barbell' });

  const handleAdd = async () => {
    const name = form.name.trim();
    if (!name) { toast('Enter an exercise name.', 'warning'); return; }
    if (exercises.some(e => e.name.toLowerCase() === name.toLowerCase())) {
      toast('That exercise already exists.', 'warning'); return;
    }
    await saveCustomExercise({ name, muscleGroup: form.muscleGroup, category: form.category, equipment: form.equipment });
    setForm({ ...form, name: '' });
    await reload();
    toast(`Added "${name}".`, 'success');
  };

  const handleDelete = async (name) => {
    const ok = await confirm({ title: 'Delete exercise?', message: `Remove "${name}" from your library?`, confirmLabel: 'Delete', danger: true });
    if (!ok) return;
    await deleteCustomExercise(name);
    await reload();
  };

  const filtered = useMemo(() => exercises.filter(e => {
    if (query && !e.name.toLowerCase().includes(query.toLowerCase())) return false;
    if (muscleFilter !== 'all' && e.muscleGroup !== muscleFilter) return false;
    if (equipmentFilter !== 'all' && e.equipment !== equipmentFilter) return false;
    return true;
  }), [exercises, query, muscleFilter, equipmentFilter]);

  const visible = filtered.slice(0, visibleCount);

  const toggleExpand = (name) => setExpanded(prev => (prev === name ? null : name));

  return (
    <div className="page stagger">
      <header>
        <h1 className="page-title">Exercise Library</h1>
        <p className="page-subtitle">{exercises.length} exercises · {customExercises.length} custom</p>
      </header>

      <section className="section card">
        <h2 className={styles.title}><Plus size={15} /> Add custom exercise</h2>
        <input className="input" placeholder="Exercise name" value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })} style={{ marginBottom: 'var(--sp-3)' }} />
        <div className={styles.selectRow}>
          <select className="select" value={form.muscleGroup} onChange={(e) => setForm({ ...form, muscleGroup: e.target.value })}>
            {EX_MUSCLES.map(m => <option key={m} value={m}>{m.replace('_', ' ')}</option>)}
          </select>
          <select className="select" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
            {EX_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
          <select className="select" value={form.equipment} onChange={(e) => setForm({ ...form, equipment: e.target.value })}>
            {EX_EQUIPMENT.map(eq => <option key={eq} value={eq}>{eq}</option>)}
          </select>
        </div>
        <button className="btn btn--primary btn--full" onClick={handleAdd}><Plus size={16} /> Add to Library</button>
      </section>

      <section className="section">
        <div className={styles.searchBox}>
          <Search size={16} className={styles.searchIcon} />
          <input className="input" style={{ paddingLeft: 36 }} placeholder="Search library…"
            value={query} onChange={(e) => { setQuery(e.target.value); setVisibleCount(PAGE_SIZE); }} />
        </div>

        <div className={styles.filterRow}>
          <select className="select" value={muscleFilter} onChange={(e) => { setMuscleFilter(e.target.value); setVisibleCount(PAGE_SIZE); }}>
            <option value="all">All muscles</option>
            {EX_MUSCLES.map(m => <option key={m} value={m}>{m.replace('_', ' ')}</option>)}
          </select>
          <select className="select" value={equipmentFilter} onChange={(e) => { setEquipmentFilter(e.target.value); setVisibleCount(PAGE_SIZE); }}>
            <option value="all">All equipment</option>
            {EX_EQUIPMENT.map(eq => <option key={eq} value={eq}>{eq}</option>)}
          </select>
        </div>

        <p className={styles.resultCount}>{filtered.length} exercise{filtered.length === 1 ? '' : 's'}</p>

        <div className={styles.list}>
          {visible.map(ex => {
            const isOpen = expanded === ex.name;
            const videoUrl = getExerciseVideoUrl(ex.name);
            return (
              <div key={ex.name} className={`${styles.item} card`}>
                <div className={styles.itemRow} onClick={() => toggleExpand(ex.name)}>
                  <Dumbbell size={16} className={styles.itemIcon} />
                  <div className={styles.itemInfo}>
                    <span className={styles.itemName}>{ex.name} {ex.custom && <span className="badge badge--accent">custom</span>}</span>
                    <span className={styles.itemSub}>
                      {ex.muscleGroup} · {ex.category} · {ex.equipment}
                      {ex.target && <> · targets {ex.target}</>}
                    </span>
                  </div>
                  {ex.custom && (
                    <button className="btn btn--ghost btn--icon text-danger" onClick={(e) => { e.stopPropagation(); handleDelete(ex.name); }}>
                      <Trash2 size={14} />
                    </button>
                  )}
                  {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                </div>

                {isOpen && (
                  <div className={styles.detail}>
                    {ex.secondaryMuscles?.length > 0 && (
                      <p className={styles.detailMeta}><strong>Also works:</strong> {ex.secondaryMuscles.join(', ')}</p>
                    )}
                    {ex.instructions?.length > 0 ? (
                      <ol className={styles.detailSteps}>
                        {ex.instructions.map((step, i) => <li key={i}>{step}</li>)}
                      </ol>
                    ) : (
                      <p className={styles.detailMeta}>No step-by-step instructions available for this exercise yet.</p>
                    )}
                    {videoUrl && (
                      <a href={videoUrl} target="_blank" rel="noopener noreferrer" className={`badge badge--amber ${styles.detailVideo}`}>
                        <Play size={10} fill="currentColor" /> Tutorial
                      </a>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {visibleCount < filtered.length && (
          <button className="btn btn--secondary btn--full section" onClick={() => setVisibleCount(c => c + PAGE_SIZE)}>
            Load more ({filtered.length - visibleCount} remaining)
          </button>
        )}
      </section>
    </div>
  );
}
