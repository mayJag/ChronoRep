/// Built-in master exercise library, ported from the web app's `exercises.js`.
/// Muscle groups: chest, back, shoulders, arms, legs, core, full_body.
/// Categories: compound, isolation, plyometric, core, mobility.
library;

class Exercise {
  final String name;
  final String muscleGroup;
  final String category;
  final String equipment;
  const Exercise(this.name, this.muscleGroup, this.category, this.equipment);
}

const List<Exercise> kExercises = [
  // Compounds
  Exercise('Back Squat', 'legs', 'compound', 'barbell'),
  Exercise('Bench Press', 'chest', 'compound', 'barbell'),
  Exercise('Deadlift', 'legs', 'compound', 'barbell'),
  Exercise('Overhead Press', 'shoulders', 'compound', 'barbell'),
  Exercise('Barbell Row', 'back', 'compound', 'barbell'),
  Exercise('Lat Pulldown', 'back', 'compound', 'cable'),
  Exercise('Incline Dumbbell Press', 'chest', 'compound', 'dumbbell'),
  Exercise('Leg Press', 'legs', 'compound', 'machine'),
  Exercise('Romanian Deadlift', 'legs', 'compound', 'barbell'),
  Exercise('Pull Up', 'back', 'compound', 'bodyweight'),
  Exercise('Push Up', 'chest', 'compound', 'bodyweight'),
  Exercise('Bulgarian Split Squat', 'legs', 'compound', 'dumbbell'),
  Exercise('Front Squat', 'legs', 'compound', 'barbell'),
  Exercise('Sumo Deadlift', 'legs', 'compound', 'barbell'),
  Exercise('Dumbbell Row', 'back', 'compound', 'dumbbell'),
  Exercise('Close-Grip Bench Press', 'arms', 'compound', 'barbell'),
  Exercise('Hip Thrust', 'legs', 'compound', 'barbell'),
  Exercise('Walking Lunges', 'legs', 'compound', 'dumbbell'),
  Exercise('Seated Cable Row', 'back', 'compound', 'cable'),
  Exercise('Dumbbell Shoulder Press', 'shoulders', 'compound', 'dumbbell'),
  Exercise('Chest Dip', 'chest', 'compound', 'bodyweight'),

  // Isolation
  Exercise('Dumbbell Lateral Raise', 'shoulders', 'isolation', 'dumbbell'),
  Exercise('Cable Bicep Curl', 'arms', 'isolation', 'cable'),
  Exercise('Triceps Pushdown', 'arms', 'isolation', 'cable'),
  Exercise('Lying Leg Curl', 'legs', 'isolation', 'machine'),
  Exercise('Leg Extension', 'legs', 'isolation', 'machine'),
  Exercise('Calf Raise', 'legs', 'isolation', 'bodyweight'),
  Exercise('Face Pull', 'shoulders', 'isolation', 'cable'),
  Exercise('Hammer Curl', 'arms', 'isolation', 'dumbbell'),
  Exercise('Dumbbell Tricep Extension', 'arms', 'isolation', 'dumbbell'),
  Exercise('Rear Delt Fly', 'shoulders', 'isolation', 'dumbbell'),
  Exercise('Preacher Curl', 'arms', 'isolation', 'machine'),
  Exercise('Cable Lateral Raise', 'shoulders', 'isolation', 'cable'),
  Exercise('Incline Dumbbell Curl', 'arms', 'isolation', 'dumbbell'),
  Exercise('Overhead Cable Extension', 'arms', 'isolation', 'cable'),
  Exercise('Pec Deck Fly', 'chest', 'isolation', 'machine'),
  Exercise('Cable Fly', 'chest', 'isolation', 'cable'),
  Exercise('Seated Leg Curl', 'legs', 'isolation', 'machine'),

  // Core
  Exercise('Plank', 'core', 'core', 'bodyweight'),
  Exercise('Hanging Leg Raise', 'core', 'core', 'bodyweight'),
  Exercise('Russian Twist', 'core', 'core', 'bodyweight'),
  Exercise('Dead Bug', 'core', 'core', 'bodyweight'),
  Exercise('Bicycle Crunch', 'core', 'core', 'bodyweight'),
  Exercise('Cable Crunch', 'core', 'core', 'cable'),
  Exercise('Ab Wheel Rollout', 'core', 'core', 'bodyweight'),
  Exercise('Pallof Press', 'core', 'core', 'cable'),
];

/// Exercises available for a given equipment level.
bool equipmentAllowed(String equip, Exercise ex) {
  if (equip == 'bodyweight') return ex.equipment == 'bodyweight';
  if (equip == 'dumbbell') {
    return ex.equipment == 'dumbbell' || ex.equipment == 'bodyweight';
  }
  return true; // full gym
}
