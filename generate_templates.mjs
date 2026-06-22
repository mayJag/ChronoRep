import fs from 'fs';
import { generatePlan } from './src/lib/planGenerator.js';

const BASE_EXERCISES = [
  { name: 'Back Squat', muscleGroup: 'legs', category: 'compound', equipment: 'barbell' },
  { name: 'Bench Press', muscleGroup: 'chest', category: 'compound', equipment: 'barbell' },
  { name: 'Deadlift', muscleGroup: 'legs', category: 'compound', equipment: 'barbell' },
  { name: 'Overhead Press', muscleGroup: 'shoulders', category: 'compound', equipment: 'barbell' },
  { name: 'Barbell Row', muscleGroup: 'back', category: 'compound', equipment: 'barbell' },
  { name: 'Pull-up', muscleGroup: 'back', category: 'compound', equipment: 'bodyweight' },
  { name: 'Dumbbell Lateral Raise', muscleGroup: 'shoulders', category: 'isolation', equipment: 'dumbbell' },
  { name: 'Cable Bicep Curl', muscleGroup: 'arms', category: 'isolation', equipment: 'cable' },
  { name: 'Triceps Pushdown', muscleGroup: 'arms', category: 'isolation', equipment: 'cable' },
  { name: 'Plank', muscleGroup: 'core', category: 'core', equipment: 'bodyweight' },
];

function createTemplate(id, name, author, desc, duration, daysPerWeek, objectives, split, experience, isPureBodybuilding = false) {
  // Generate a plan using the standard generator
  const generated = generatePlan({
    objectives, daysPerWeek, experience, equipment: 'full', split, armsDay: false
  }, BASE_EXERCISES);

  // Map to the Programs.jsx structure
  const weekDays = [];
  let dayNum = 1;
  
  const daysKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  daysKeys.forEach(key => {
    const d = generated.weeklySchedule[key];
    if (d.type === 'rest') {
      weekDays.push({
        dayNumber: dayNum++,
        name: 'Rest Day',
        type: 'rest',
        targetMuscles: [],
        estimatedDuration: 0,
        exercises: []
      });
    } else {
      weekDays.push({
        dayNumber: dayNum++,
        name: d.name,
        type: d.type,
        targetMuscles: [],
        estimatedDuration: 45,
        exercises: d.exercises.map(ex => {
          let notes = ex.notes || '';
          if (isPureBodybuilding && (ex.category === 'isolation' || ex.category === 'core')) {
            notes = (notes ? notes + ' ' : '') + 'Finish with lengthened partials! RPE 9-10.';
          }
          return {
            name: ex.name,
            warmupSets: ex.category === 'compound' ? 2 : 0,
            workingSets: ex.sets,
            reps: ex.reps,
            rest: ex.rest,
            notes,
            category: ex.category,
            muscleGroup: ex.muscleGroup,
            equipment: ex.equipment,
          };
        })
      });
    }
  });

  const program = {
    id,
    name,
    author,
    description: desc,
    duration,
    daysPerWeek,
    type: objectives[0],
    weeks: [
      {
        weekNumber: 1,
        label: "Week 1",
        days: weekDays
      }
    ]
  };

  return `export const ${id.replace(/-/g, '_')} = ${JSON.stringify(program, null, 2)};`;
}

const fundamentalsStr = createTemplate(
  'expert-fundamentals',
  'Ironlog Expert Fundamentals',
  'Ironlog Expert',
  'Beginner | 4x/Week. An evidence-based hypertrophy program designed to build a solid foundation of muscle and strength.',
  '8 weeks',
  4,
  ['hypertrophy'],
  'upperlower',
  'beginner'
);

const essentialsStr = createTemplate(
  'expert-essentials',
  'Ironlog Expert The Essentials',
  'Ironlog Expert',
  'Minimalist | 3x/Week. Designed for maximum efficiency in 45 mins or less. Low volume, high intensity.',
  '12 weeks',
  3,
  ['minimalist'],
  'fullbody',
  'intermediate'
);

const pureBodybuildingStr = createTemplate(
  'expert-pure-bodybuilding',
  'Ironlog Expert Pure Bodybuilding Phase 2',
  'Ironlog Expert',
  'Advanced | 5x/Week. Pure hypertrophy with high RPEs and lengthened partials for maximum growth.',
  '10 weeks',
  5,
  ['hypertrophy'],
  'upperlower',
  'advanced',
  true
);

fs.writeFileSync('./src/data/fundamentalsProgram.js', fundamentalsStr);
fs.writeFileSync('./src/data/essentialsProgram.js', essentialsStr);
fs.writeFileSync('./src/data/pureBodybuildingProgram.js', pureBodybuildingStr);
console.log('Successfully generated templates.');
