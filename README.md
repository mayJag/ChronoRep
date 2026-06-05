# IronLog — Premium Athletic Workout Tracker

IronLog is a premium, dark-themed, offline-first workout tracking application engineered for athletic power, strength, and explosive performance. Designed for mobile and web screens, IronLog operates completely client-side to keep your training data private, secure, and accessible in environments with poor connectivity.

Built using **React**, **Vite**, **Capacitor**, and **IndexedDB**.

---

## 🚀 Key Features

* **Active Workout Interface & TUT Stopwatch:**
  * Log sets, reps, and weights with instant indicators showing your previous performance.
  * **Time Under Tension (TUT) Set Timer:** Start a stopwatch per set to track exact work duration. Completed set times are logged automatically.
  * **Dynamic Exercises:** Add additional master exercises to your workout on-the-fly during active sessions.

* **Advanced Plan & Split Customizer:**
  * **Follow Program:** Activate structured preloaded athletic training cycles.
  * **Hybrid Splits:** Mix and match different workouts across your weekly schedule.
  * **Custom Plans:** Create templates, rename workout days, and drag-and-drop exercises.
  * **Quick Workout Generator:** Instantly compile sessions based on target time limits (15, 30, 45, or 60 mins) and muscle focus.

* **Interactive Rest Timer:**
  * Configurable circular rest ring overlay with quick-adjust controls (+15s / -15s).
  * Plays high-frequency audio beeps (Web Audio API) and triggers native haptic device vibration upon completion.

* **Activity Log & Calendar:**
  * Visual monthly consistency calendar detailing days with logged sessions.
  * Historical breakdown including total volume lifted, elapsed time, and list of sets.
  * Personal Record (PR) trophies highlighted automatically when hitting new strength thresholds.

* **Settings & Offline Backups:**
  * Toggle weight units (kg/lbs) and vibration/sound alerts.
  * Complete export/import functionality to download your database to a JSON backup file and restore it anytime.

---

## 🛠️ Tech Stack

* **Frontend:** React, HashRouter (Capacitor webview friendly)
* **Build System:** Vite
* **Styling:** Vanilla CSS Modules (Glassmorphism card effects, dark theme variables, responsive grids)
* **Database:** IndexedDB (via `idb` wrapper)
* **Native Wrap:** Capacitor (Core, CLI, Android Bridge)
* **Icons:** Lucide React

---

## 💻 Local Development Setup

### Prerequisites
* Node.js (version 18+)
* Android SDK (if building the native mobile app)

### 1. Web Preview
Install dependencies and run the local development server:
```bash
npm install
npm run dev
```
Open [http://localhost:5173/](http://localhost:5173/) in your web browser.

### 2. Android App Compilation
Build the production assets and sync them to Capacitor:
```bash
# Build the production bundle
npm run build

# Sync assets to the native Android project
npx cap sync

# Compile the Android Debug APK (Windows PowerShell)
$env:ANDROID_HOME="C:\Users\jagga\AppData\Local\Android\Sdk"
cd android
.\gradlew.bat assembleDebug
```
The compiled package will be located at:
`android/app/build/outputs/apk/debug/app-debug.apk`
