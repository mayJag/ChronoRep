import fs from 'fs';
import path from 'path';

const filesToUpdate = [
  'README.md',
  'src/data/essentialsProgram.js',
  'src/data/expertPowerbuilding.js',
  'src/data/fundamentalsProgram.js',
  'src/data/hybridProgram.js',
  'src/data/pureBodybuildingProgram.js',
  'src/pages/PlanBuilder.jsx',
  'src/pages/Programs.jsx',
  'src/pages/Settings.jsx',
];

for (const file of filesToUpdate) {
  const filePath = path.join(process.cwd(), file);
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Replace visual occurrences
    content = content.replace(/IronLog/g, 'ChronoRep');
    content = content.replace(/Ironlog/g, 'ChronoRep');
    content = content.replace(/IRONLOG/g, 'CHRONOREP');
    content = content.replace(/ironlog_backup/g, 'chronorep_backup');
    
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated ${file}`);
  }
}
