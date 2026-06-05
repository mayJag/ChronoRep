import { openDB } from 'idb';

const DB_NAME = 'ironlog';
const DB_VERSION = 1;

export async function getDB() {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      // Active program & user settings
      if (!db.objectStoreNames.contains('settings')) {
        db.createObjectStore('settings', { keyPath: 'key' });
      }

      // Custom routines created by user
      if (!db.objectStoreNames.contains('routines')) {
        const store = db.createObjectStore('routines', { keyPath: 'id' });
        store.createIndex('createdAt', 'createdAt');
      }

      // Workout logs (completed sessions)
      if (!db.objectStoreNames.contains('workoutLogs')) {
        const store = db.createObjectStore('workoutLogs', { keyPath: 'id' });
        store.createIndex('date', 'date');
        store.createIndex('programId', 'programId');
      }

      // Per-exercise personal records
      if (!db.objectStoreNames.contains('personalRecords')) {
        const store = db.createObjectStore('personalRecords', { keyPath: 'exerciseName' });
      }

      // Custom user plans (hybrid / single program assignments)
      if (!db.objectStoreNames.contains('plans')) {
        const store = db.createObjectStore('plans', { keyPath: 'id' });
        store.createIndex('createdAt', 'createdAt');
      }
    },
  });
}

// --- Settings helpers ---
export async function getSetting(key) {
  const db = await getDB();
  const result = await db.get('settings', key);
  return result?.value;
}

export async function setSetting(key, value) {
  const db = await getDB();
  await db.put('settings', { key, value });
}

// --- Routines CRUD ---
export async function getAllRoutines() {
  const db = await getDB();
  return db.getAllFromIndex('routines', 'createdAt');
}

export async function getRoutine(id) {
  const db = await getDB();
  return db.get('routines', id);
}

export async function saveRoutine(routine) {
  const db = await getDB();
  await db.put('routines', routine);
}

export async function deleteRoutine(id) {
  const db = await getDB();
  await db.delete('routines', id);
}

// --- Workout Logs ---
export async function getAllWorkoutLogs() {
  const db = await getDB();
  const logs = await db.getAllFromIndex('workoutLogs', 'date');
  return logs.reverse(); // newest first
}

export async function getWorkoutLog(id) {
  const db = await getDB();
  return db.get('workoutLogs', id);
}

export async function saveWorkoutLog(log) {
  const db = await getDB();
  await db.put('workoutLogs', log);
}

export async function deleteWorkoutLog(id) {
  const db = await getDB();
  await db.delete('workoutLogs', id);
}

export async function getWorkoutLogsByDate(dateStr) {
  const db = await getDB();
  return db.getAllFromIndex('workoutLogs', 'date', dateStr);
}

// --- Personal Records ---
export async function getPersonalRecord(exerciseName) {
  const db = await getDB();
  return db.get('personalRecords', exerciseName);
}

export async function savePersonalRecord(record) {
  const db = await getDB();
  await db.put('personalRecords', record);
}

export async function getAllPersonalRecords() {
  const db = await getDB();
  return db.getAll('personalRecords');
}

// --- Plans CRUD ---
export async function getAllPlans() {
  const db = await getDB();
  return db.getAllFromIndex('plans', 'createdAt');
}

export async function getPlan(id) {
  const db = await getDB();
  return db.get('plans', id);
}

export async function savePlan(plan) {
  const db = await getDB();
  await db.put('plans', plan);
}

export async function deletePlan(id) {
  const db = await getDB();
  await db.delete('plans', id);
}

// --- Utility: Generate unique ID ---
export function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
}
