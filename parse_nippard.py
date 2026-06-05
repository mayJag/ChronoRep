import re
import json
import os

def parse_nippard(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Preprocess text to fix concatenations like ROW1, PRESS3, etc.
    content = re.sub(r'(ROW|PRESS|DEADLIFT|SQUAT|THRUST|ABDUCTION|FLYE|CURL|UP|DIP|SHRUG|RAISE|WALK|PULLDOWN|AMRAP)(\d)', r'\1 \2', content, flags=re.IGNORECASE)

    # Split by pages
    pages = content.split('--- Page ')
    
    page_to_week = {
        1: (1, ""), 2: (1, ""), 3: (1, ""),
        4: (2, ""), 5: (2, ""), 6: (2, ""),
        7: (3, ""), 8: (3, ""), 9: (3, ""),
        10: (4, ""), 11: (4, ""), 12: (4, ""),
        13: (5, ""), 14: (5, ""), 15: (5, ""),
        16: (6, ""), 17: (6, ""), 18: (6, ""),
        19: (7, ""), 20: (7, ""), 21: (7, ""),
        22: (8, ""), 23: (8, ""), 24: (8, ""),
        25: (9, ""), 26: (9, ""), 27: (9, ""),
        28: (10, "A"), 29: (10, "A"), 30: (10, "A"),
        31: (10, "B"), 32: (10, "B"),
        33: (11, ""), 34: (11, ""), 35: (11, "")
    }
    
    weeks = []
    week_configs = [
        (1, "", "Week 1", ""),
        (2, "", "Week 2", ""),
        (3, "", "Week 3", ""),
        (4, "", "Week 4", ""),
        (5, "", "Week 5", ""),
        (6, "", "Week 6 (Semi-Deload)", "Semi-Deload Week"),
        (7, "", "Week 7", ""),
        (8, "", "Week 8", ""),
        (9, "", "Week 9", ""),
        (10, "A", "Week 10A (Max Testing - Bodybuilding)", "Max Testing (Option A)"),
        (10, "B", "Week 10B (Max Testing - Powerlifting)", "Max Testing (Option B)"),
        (11, "", "Week 11 (Deload)", "Deload Week")
    ]
    
    week_map = {}
    for w_num, w_opt, w_label, w_note in week_configs:
        w_obj = {
            "weekNumber": w_num,
            "label": w_label,
            "option": w_opt,
            "note": w_note,
            "days": []
        }
        weeks.append(w_obj)
        week_map[(w_num, w_opt)] = w_obj
        
    workout_headers = [
        ("FULL BODY 1: SQUAT, OHP", "Full Body 1: Squat, OHP", ["OHPBACK SQUAT", "OHP BACK SQUAT"]),
        ("FULL BODY 2: DEADLIFT, BENCH PRESS", "Full Body 2: Deadlift, Bench Press", ["PRESSDEADLIFT", "PRESS DEADLIFT"]),
        ("FULL BODY 3: SQUAT, DIP", "Full Body 3: Squat, Dip", ["DIPBACK SQUAT", "DIP BACK SQUAT"]),
        ("FULL BODY 4: DEADLIFT, BENCH PRESS", "Full Body 4: Deadlift, Bench Press", ["PRESSPAUSE DEADLIFT", "PRESS PAUSE DEADLIFT"]),
        ("FULL BODY 5: ARM & PUMP DAY", "Full Body 5: Arm & Pump Day", ["PUMP DAYA1."]),
        
        # Upper/Lower split days
        ("LOWER #1", "Lower 1", ["LOWER #1DEADLIFT"]),
        ("UPPER #1", "Upper 1", ["UPPER #1BARBELL BENCH PRESS"]),
        ("LOWER #2", "Lower 2", ["LOWER # 2BACK SQUAT", "LOWER #2 BACK SQUAT", "LOWER #2BACK SQUAT"]),
        ("UPPER #2", "Upper 2", ["UPPER #2OVERHEAD PRESS", "UPPER #2 OVERHEAD PRESS", "UPPER #2CLOSE-GRIP", "UPPER #2 CLOSE-GRIP"]),
        ("LOWER #3", "Lower 3", ["LOWER # 35\" BLOCK PULL", "LOWER #3 BLOCK PULL", "LOWER #3 5\" BLOCK PULL"]),
        ("UPPER #3", "Upper 3", ["UPPER #3FLAT-BACK", "UPPER #3 FLAT-BACK"]),
        
        # Week 10 max testing days
        ("SQUAT TEST", "Squat Test", ["TESTBACK SQUAT"]),
        ("BENCH TEST", "Bench Test", ["TESTBARBELL BENCH PRESS"]),
        ("DEADLIFT TEST", "Deadlift Test", ["TESTDEADLIFT"])
    ]

    known_exercises = [
        "BACK SQUAT", "OVERHEAD PRESS", "GLUTE HAM RAISE", "HELMS ROW", "HAMMER CURL",
        "DEADLIFT", "BARBELL BENCH PRESS", "HIP ABDUCTION", "WEIGHTED PULL-UP", "STANDING CALF RAISE",
        "WEIGHTED DIP", "HANGING LEG RAISE", "LAT PULL-OVER", "INCLINE DUMBBELL CURL", "FACE PULL",
        "PAUSE DEADLIFT", "PAUSE BARBELL BENCH PRESS", "CHEST-SUPPORTED T-BAR ROW OR PENDLAY ROW",
        "NORDIC HAM CURL", "DUMBBELL SHRUG", "BARBELL OR EZ BAR CURL", "FLOOR SKULL CRUSHER",
        "TRICEPS PRESSDOWN (REVERSE 21'S)", "DUMBBELL LATERAL RAISE", "BAND PULL-APART",
        "BICYCLE CRUNCH", "NECK FLEXION/EXTENSION (OPTIONAL)", "SUMO BOX SQUAT OR PAUSE HIGH-BAR SQUAT",
        "PULL-THROUGH", "LEG CURL", "CHIN-UP", "STANDING ARNOLD DUMBBELL PRESS", "CHEST-SUPPORTED DUMBBELL ROW",
        "CONCENTRATION BICEP CURL", "GOOD MORNING", "LEG EXTENSION", "BANDED LATERAL WALK OR HIP ABDUCTION",
        "V SIT-UP", "SINGLE-ARM LAT PULLDOWN", "CLOSE-GRIP BENCH PRESS", "PENDLAY ROW", "PEC FLYE",
        "INCLINE SHRUG", "UPRIGHT ROW", "BARBELL SKULL CRUSHER", "5\" BLOCK PULL",
        "BARBELL 45° HYPEREXTENSION OR HIP THRUST", "SEATED CALF RAISE", "FLAT-BACK BARBELL BENCH PRESS",
        "ECCENTRIC-ACCENTUATED PULL-UP", "SINGLE-ARM ROW", "LEAN-AWAY LATERAL RAISE",
        "NECK FLEXION/EXTENSION", "A1. BARBELL OR EZ BAR CURL", "A2. FLOOR SKULL CRUSHER",
        "B1. INCLINE DUMBBELL CURL (REVERSE 21'S)", "B2. TRICEPS PRESSDOWN (REVERSE 21'S)",
        "C1. DUMBBELL LATERAL RAISE", "C2. BAND PULL-APART", "C3. STANDING CALF RAISE", "C4. BICYCLE CRUNCH",
        "A1. INCLINE SHRUG", "A2. UPRIGHT ROW", "A1: FACE PULL", "A2: DUMBBELL LATERAL RAISE",
        "B1: CONCENTRATION BICEP CURL", "B2: TRICEPS PRESSDOWN", "B1: BARBELL OR EZ BAR CURL",
        "B2. SKULL CRUSHER", "SNATCH-GRIP ROMANIAN DEADLIFT", "ASSISTED CHIN-UP"
    ]

    current_day = None
    
    # Process pages 1 to 35
    for p_idx in range(1, 36):
        if p_idx >= len(pages):
            break
        page_str = pages[p_idx]
        if not page_str.strip():
            continue
            
        week_num, week_opt = page_to_week[p_idx]
        current_week = week_map[(week_num, week_opt)]
        
        lines = page_str.split('\n')
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if not line:
                i += 1
                continue
            
            if "SUGGESTED REST DAY" in line.upper() or "SUGGESTED 1-2 REST DAYS" in line.upper():
                current_week["days"].append({
                    "dayNumber": len(current_week["days"]) + 1,
                    "name": "Rest Day",
                    "type": "rest",
                    "targetMuscles": [],
                    "estimatedDuration": 0,
                    "exercises": []
                })
                current_day = None
                i += 1
                continue
            
            matched_header = None
            matched_type = None
            matched_muscles = None
            strip_pattern = None
            
            line_clean = line.upper().replace(" ", "").replace("#", "").replace(":", "").replace("-", "")
            
            for check_str, d_name, d_type, d_muscles, s_pat in day_rules:
                if check_str in line_clean:
                    matched_header = d_name
                    matched_type = d_type
                    matched_muscles = d_muscles
                    strip_pattern = s_pat
                    break
            
            if matched_header:
                day_num = len(current_week["days"]) + 1
                current_day = {
                    "dayNumber": day_num,
                    "name": matched_header,
                    "type": matched_type,
                    "targetMuscles": matched_muscles,
                    "estimatedDuration": 75 if matched_type == "full_body" else 60,
                    "exercises": []
                }
                current_week["days"].append(current_day)
                
                line_cleaned = re.sub(strip_pattern, '', line, flags=re.IGNORECASE).strip()
                
                ex_obj = parse_exercise_line(line_cleaned)
                if ex_obj:
                    current_day["exercises"].append(ex_obj)
                i += 1
                continue
            
            if current_day:
                ex_obj = parse_exercise_line(line)
                if ex_obj:
                    current_day["exercises"].append(ex_obj)
            
            i += 1

    # Now parse substitutions (pages 69-72)
    substitutions = {}
    for p_idx in range(69, 73):
        if p_idx >= len(pages):
            break
        page_str = pages[p_idx]
        lines = page_str.split('\n')
        for line in lines:
            line = line.strip()
            if ':' in line and not line.startswith('---'):
                parts = line.split(':', 1)
                key = parts[0].strip()
                val = parts[1].strip()
                # Check if key is uppercase (mostly letters)
                if key.isupper() and len(key) > 3:
                    subs_list = [v.strip() for v in val.split(',')]
                    # Clean up keys and values
                    key_clean = re.sub(r'^[A-Z\d\s\W]+[\.:\s]+', '', key).title()
                    substitutions[key_clean] = subs_list

    return weeks, substitutions

def parse_exercise_line(line):
    pattern = r'^(.+?)\s+(\d+)\s+([\d\-]+)\s+([\d\-\/AMRAP]+)\s+([\d\.\-%%]+|N/A)\s+([\d\.\-]+|N/A)\s+(\d+(?:-\d+)?\s*(?:MIN|SEC|MINUTES|SECONDS|MIN\s+REST|SEC\s+REST))\s*(.*)$'
    match = re.match(pattern, line, re.IGNORECASE)
    if match:
        name = match.group(1).strip()
        warmup = int(match.group(2))
        working = match.group(3)
        reps = match.group(4)
        pct_1rm = match.group(5)
        rpe = match.group(6)
        rest = match.group(7)
        notes = match.group(8).strip()
        
        name_clean = re.sub(r'^[A-Z\d]+[\.:\s]+', '', name)
        
        return {
            "name": name_clean,
            "warmupSets": warmup,
            "workingSets": int(working) if working.isdigit() else working,
            "reps": reps,
            "percentRM": pct_1rm,
            "rpe": rpe,
            "rest": rest,
            "notes": notes,
            "category": "compound" if warmup > 0 else "isolation",
            "muscleGroup": "legs" if any(x in name.lower() for x in ["squat", "deadlift", "calf", "glute", "lunge"]) else "upper_body",
            "equipment": "barbell" if any(x in name.lower() for x in ["barbell", "squat", "deadlift", "bench press"]) else "dumbbell"
        }
    else:
        pattern_lazy = r'^(.+?)\s+(\d+)\s+([\d\-]+)\s+([\w\-\/]+)\s+([\w\.\-%%\/]+)\s+([\w\.\-]+)\s+(\d+(?:-\d+)?\s*\w+)\s*(.*)$'
        match_lazy = re.match(pattern_lazy, line, re.IGNORECASE)
        if match_lazy:
            name = match_lazy.group(1).strip()
            warmup = int(match_lazy.group(2))
            working = match_lazy.group(3)
            reps = match_lazy.group(4)
            pct_1rm = match_lazy.group(5)
            rpe = match_lazy.group(6)
            rest = match_lazy.group(7)
            notes = match_lazy.group(8).strip()
            
            name_clean = re.sub(r'^[A-Z\d]+[\.:\s]+', '', name)
            
            return {
                "name": name_clean,
                "warmupSets": warmup,
                "workingSets": int(working) if working.isdigit() else working,
                "reps": reps,
                "percentRM": pct_1rm,
                "rpe": rpe,
                "rest": rest,
                "notes": notes,
                "category": "compound" if warmup > 0 else "isolation",
                "muscleGroup": "legs" if any(x in name.lower() for x in ["squat", "deadlift", "calf", "glute", "lunge"]) else "upper_body",
                "equipment": "barbell" if any(x in name.lower() for x in ["barbell", "squat", "deadlift", "bench press"]) else "dumbbell"
            }
    return None

if __name__ == '__main__':
    day_rules = [
        ("OHPBACKSQUAT", "Full Body 1: Squat, OHP", "full_body", ["legs", "shoulders", "back", "arms", "chest"], r'^OHP\s*'),
        ("PRESSDEADLIFT", "Full Body 2: Deadlift, Bench Press", "full_body", ["legs", "shoulders", "back", "arms", "chest"], r'^PRESS\s*'),
        ("DIPBACKSQUAT", "Full Body 3: Squat, Dip", "full_body", ["legs", "shoulders", "back", "arms", "chest"], r'^DIP\s*'),
        ("PRESSPAUSEDEADLIFT", "Full Body 4: Deadlift, Bench Press", "full_body", ["legs", "shoulders", "back", "arms", "chest"], r'^PRESS\s*'),
        ("PUMPDAYA1", "Full Body 5: Arm & Pump Day", "full_body", ["legs", "shoulders", "back", "arms", "chest"], r'^PUMP\s*DAY\s*'),
        ("LOWER1", "Lower 1", "lower", ["legs", "glutes", "hamstrings", "calves"], r'^LOWER\s*#?\s*1\s*'),
        ("UPPER1", "Upper 1", "upper", ["chest", "back", "shoulders", "arms"], r'^UPPER\s*#?\s*1\s*'),
        ("LOWER2", "Lower 2", "lower", ["legs", "glutes", "hamstrings", "calves"], r'^LOWER\s*#?\s*2\s*|^LOWER\s*#\s*2\s*'),
        ("UPPER2", "Upper 2", "upper", ["chest", "back", "shoulders", "arms"], r'^UPPER\s*#?\s*2\s*'),
        ("LOWER3", "Lower 3", "lower", ["legs", "glutes", "hamstrings", "calves"], r'^LOWER\s*#?\s*3\s*|^LOWER\s*#\s*3\s*'),
        ("UPPER3", "Upper 3", "upper", ["chest", "back", "shoulders", "arms"], r'^UPPER\s*#?\s*3\s*'),
        ("TESTBACKSQUAT", "Squat Test", "lower", ["legs", "glutes", "hamstrings", "calves"], r'^TEST\s*'),
        ("TESTBARBELLBENCH", "Bench Test", "upper", ["chest", "back", "shoulders", "arms"], r'^TEST\s*'),
        ("TESTDEADLIFT", "Deadlift Test", "lower", ["legs", "glutes", "hamstrings", "calves"], r'^TEST\s*')
    ]
    
    weeks, substitutions = parse_nippard("routine_only_output.txt")
    
    nippardProgram = {
        "id": "nippard-powerbuilding",
        "name": "Jeff Nippard Powerbuilding System",
        "author": "Jeff Nippard",
        "description": "Intermediate-Advanced | 5-6x/Week",
        "duration": "10 weeks (11 with Deload)",
        "daysPerWeek": 5,
        "type": "powerbuilding",
        "weeks": weeks
    }
    
    os.makedirs("src/data", exist_ok=True)
    with open("src/data/nippardProgram.js", "w", encoding='utf-8') as out_f:
        out_f.write("export const nippardProgram = " + json.dumps(nippardProgram, indent=2) + ";\n\n")
        out_f.write("export const exerciseSubstitutions = " + json.dumps(substitutions, indent=2) + ";\n")
        
    print("Successfully generated src/data/nippardProgram.js!")
