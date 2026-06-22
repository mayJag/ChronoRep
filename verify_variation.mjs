import { generatePlan } from './src/lib/planGenerator.js';

// Standalone verification — no React/DB imports needed.
const BASE_EXERCISES = [
  { name: 'Back Squat', muscleGroup: 'legs', category: 'compound', equipment: 'barbell' },
  { name: 'Bench Press', muscleGroup: 'chest', category: 'compound', equipment: 'barbell' },
  { name: 'Deadlift', muscleGroup: 'legs', category: 'compound', equipment: 'barbell' },
  { name: 'Overhead Press', muscleGroup: 'shoulders', category: 'compound', equipment: 'barbell' },
  { name: 'Barbell Row', muscleGroup: 'back', category: 'compound', equipment: 'barbell' },
  { name: 'Dumbbell Lateral Raise', muscleGroup: 'shoulders', category: 'isolation', equipment: 'dumbbell' },
  { name: 'Cable Bicep Curl', muscleGroup: 'arms', category: 'isolation', equipment: 'cable' },
  { name: 'Triceps Pushdown', muscleGroup: 'arms', category: 'isolation', equipment: 'cable' },
  { name: 'Plank', muscleGroup: 'core', category: 'core', equipment: 'bodyweight' },
];

function printPlan(label, goals) {
  const plan = generatePlan(goals, BASE_EXERCISES);
  console.log(`\n=== ${label} ===`);
  const activeDays = Object.values(plan.weeklySchedule).filter(d => d.type !== 'rest');
  activeDays.forEach(day => {
    console.log(`Day: ${day.name} (${day.exercises.length} exercises)`);
    day.exercises.forEach(ex => {
      console.log(`  - ${ex.name} (${ex.category}): ${ex.sets} sets x ${ex.reps}`);
    });
  });
}

printPlan('Minimalist 3-Day Plan', {
  objectives: ['minimalist'], daysPerWeek: 3, experience: 'intermediate', equipment: 'full', split: 'fullbody'
});

printPlan('Hypertrophy 4-Day Plan', {
  objectives: ['hypertrophy'], daysPerWeek: 4, experience: 'intermediate', equipment: 'full', split: 'upperlower'
});
