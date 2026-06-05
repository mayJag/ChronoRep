import re
import json
import os

def parse_btr(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    pages = content.split('--- Page ')
    
    phases = []
    phase_names = {
        0: "Phase Zero - Knee Health (Optional)",
        1: "Phase One - Foundational Strength",
        2: "Phase Two - Strength & Power",
        3: "Phase Three - Reactive Strength",
        4: "Phase Four - Speed & Elasticity",
        5: "Phase Five - Peaking & Max Velocity"
    }
    
    # Initialize phase structures
    for p_num in range(6):
        phases.append({
            "phaseNumber": p_num,
            "name": phase_names[p_num],
            "optional": p_num == 0,
            "description": "Only start if you have knee pain" if p_num == 0 else "Progressive jump training phase",
            "weeks": []
        })
        # Add 4 weeks to each phase
        for w_num in range(1, 5):
            phases[p_num]["weeks"].append({
                "weekNumber": w_num,
                "days": []
            })
            
    # Process pages 47 to 214
    for idx in range(47, 215):
        if idx >= len(pages):
            break
        page_str = pages[idx]
        if not page_str.strip():
            continue
            
        # Day index from 0 to 167
        day_idx = idx - 47
        p_num = day_idx // 28
        w_idx = (day_idx % 28) // 7
        d_num = (day_idx % 7) + 1
        
        current_phase = phases[p_num]
        current_week = current_phase["weeks"][w_idx]
        
        lines = page_str.split('\n')
        
        # Parse day info
        is_rest = False
        day_title = ""
        
        # Look at the first 10 lines for title / rest day indicators
        for line in lines[:10]:
            line_upper = line.upper()
            if "REST DAY" in line_upper:
                is_rest = True
                day_title = "Rest Day"
                break
            elif "MOVEMENT WORKOUT" in line_upper:
                day_title = line.strip()
                break
            elif "MAIN WORKOUT" in line_upper:
                day_title = line.strip()
                break
            elif "ACCESSORY WORKOUT" in line_upper:
                day_title = line.strip()
                break
            elif "PLYOMETRIC" in line_upper and "STRENGTH" in line_upper:
                day_title = "Plyometric & Strength Workout"
                break
            elif "AGILITY" in line_upper and "QUICKNESS" in line_upper:
                day_title = "Agility & Quickness Workout"
                break
            elif "MOBILITY" in line_upper and "UPPER BODY" in line_upper:
                day_title = "Mobility & Upper Body"
                break
            elif "FEET" in line_upper and "ANKLES" in line_upper:
                day_title = "Feet, Ankles, Shoulders & Spine"
                break
                
        if not day_title:
            # Default day title based on type
            if d_num in [1, 3, 5]:
                day_title = "Vertical Jump & Core"
            elif d_num in [2, 4, 6]:
                day_title = "Mobility & Upper Body"
            else:
                day_title = "Rest Day"
                is_rest = True
                
        day_type = "rest" if is_rest else ("mobility" if "mobility" in day_title.lower() or "feet" in day_title.lower() else "main")
        
        day_obj = {
            "dayNumber": d_num,
            "name": day_title,
            "type": day_type,
            "exercises": []
        }
        current_week["days"].append(day_obj)
        
        # Parse exercises from the lines
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # An exercise line contains parenthesized details
            if '(' in line and ')' in line:
                ex_obj = parse_btr_exercise(line)
                if ex_obj:
                    day_obj["exercises"].append(ex_obj)
                    
    return phases

def parse_btr_exercise(line):
    # Match the name before the first parenthesis
    name_match = re.match(r'^([^\(]+)', line)
    if not name_match:
        return None
    name = name_match.group(1).strip()
    
    # Skip headers or notes that happen to contain parentheses
    if name.upper() in ["WARM UP", "WARM-UP", "TIP", "NOTE", "PHASE", "WEEK", "DAY", "CLICK HERE"]:
        return None
        
    # Extract all text inside parentheses
    parens = re.findall(r'\(([^\)]+)\)', line)
    if not parens:
        return None
        
    sets = 1
    reps = parens[0].strip()
    rest = "N/A"
    
    # Parse sets and reps from the first parenthesized block
    # E.g. "3 sets of 2 minutes" or "4 sets of 25 reps" or "2 sets of 45 seconds"
    first_block = parens[0].lower()
    set_match = re.search(r'(\d+)\s*sets?(?:\s*of\s*(.+))?', first_block)
    if set_match:
        sets = int(set_match.group(1))
        if set_match.group(2):
            reps = set_match.group(2).strip()
        else:
            reps = first_block.replace(f"{sets} sets", "").strip()
            if not reps:
                reps = "1 completion"
                
    # E.g. "3 times through" or "2 times through"
    times_match = re.search(r'(\d+)\s*times\s*through', first_block)
    if times_match:
        sets = int(times_match.group(1))
        reps = "1 completion"
        
    # Check if there is a second parenthesized block for rest
    # E.g. "1 min rest in between"
    for block in parens[1:]:
        block_lower = block.lower()
        if "rest" in block_lower:
            rest = block.strip()
            # Clean up text
            rest = re.sub(r'\s+in\s+between\s*.*', '', rest, flags=re.IGNORECASE)
            rest = re.sub(r'\s+rest.*', '', rest, flags=re.IGNORECASE)
            break
            
    # Clean up name (remove leading bullet points/hyphens)
    name_clean = re.sub(r'^[\-\*\•\d\.\s]+', '', name).strip()
    # Capitalize the exercise name properly
    name_clean = name_clean.title()
    
    # Categorize and equipment guess
    category = "plyometric"
    muscle = "legs"
    equipment = "bodyweight"
    
    name_lower = name_clean.lower()
    if "warm up" in name_lower or "warm-up" in name_lower or "deadmill" in name_lower or "mobility" in name_lower:
        category = "warmup"
        muscle = "full_body"
    elif "push up" in name_lower or "swimmer" in name_lower or "arm circle" in name_lower or "pike hold" in name_lower or "pull up" in name_lower or "lat pull" in name_lower:
        category = "isolation"
        muscle = "upper_body"
    elif "hold" in name_lower or "sit" in name_lower or "bridge" in name_lower or "plank" in name_lower or "crunch" in name_lower or "core" in name_lower or "sit-up" in name_lower:
        category = "core"
        muscle = "core"
    elif "stretch" in name_lower or "breathing" in name_lower or "foam roll" in name_lower:
        category = "mobility"
        muscle = "full_body"
        
    if "dumbbell" in name_lower:
        equipment = "dumbbell"
    elif "band" in name_lower:
        equipment = "resistance band"
    elif "box" in name_lower:
        equipment = "box"
    elif "treadmill" in name_lower:
        equipment = "treadmill"
        
    return {
        "name": name_clean,
        "sets": sets,
        "reps": reps,
        "rest": rest,
        "notes": "",
        "category": category,
        "muscleGroup": muscle,
        "equipment": equipment
    }

if __name__ == '__main__':
    phases = parse_btr("btr_output.txt")
    
    btrProgram = {
        "id": "beyond-the-rim",
        "name": "Beyond The Rim - Vertical Jump Training",
        "author": "Nathanael Morton",
        "description": "20-Week Vertical Jump Training Program - Bodyweight Edition",
        "duration": "20 weeks (24 with Phase 0)",
        "daysPerWeek": 7,
        "type": "vertical_jump",
        "phases": phases
    }
    
    os.makedirs("src/data", exist_ok=True)
    with open("src/data/btrProgram.js", "w", encoding='utf-8') as out_f:
        out_f.write("export const btrProgram = " + json.dumps(btrProgram, indent=2) + ";\n")
        
    print("Successfully generated src/data/btrProgram.js!")
