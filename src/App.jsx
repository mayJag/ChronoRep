import React, { useEffect } from 'react';
import { Routes, Route, useLocation } from 'react-router-dom';
import { App as CapacitorApp } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';
import Navigation from './components/Navigation';
import Dashboard from './pages/Dashboard';
import Programs from './pages/Programs';
import PlanBuilder from './pages/PlanBuilder';
import History from './pages/History';
import Settings from './pages/Settings';
import ActiveWorkout from './pages/ActiveWorkout';
import ActivePlan from './pages/ActivePlan';
import RoutineEditor from './pages/RoutineEditor';
import More from './pages/More';
import Progress from './pages/Progress';
import Body from './pages/Body';
import Achievements from './pages/Achievements';
import Goals from './pages/Goals';
import Calculators from './pages/Calculators';
import Exercises from './pages/Exercises';

export default function App() {
  const location = useLocation();
  const isWorkoutActive = location.pathname === '/workout';

  // Hardware back button (Android): go back within the app's own navigation
  // history instead of falling through to the OS default, which exits straight
  // to the home screen when there's no listener registered at all.
  useEffect(() => {
    if (!Capacitor.isNativePlatform()) return;

    const listenerPromise = CapacitorApp.addListener('backButton', ({ canGoBack }) => {
      if (canGoBack) {
        window.history.back();
      } else {
        CapacitorApp.exitApp();
      }
    });

    return () => {
      listenerPromise.then((listener) => listener.remove());
    };
  }, []);

  return (
    <>
      <main style={{ flex: 1 }}>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/programs" element={<Programs />} />
          <Route path="/programs/:programId" element={<Programs />} />
          <Route path="/plan" element={<PlanBuilder />} />
          <Route path="/active-plan" element={<ActivePlan />} />
          <Route path="/routine/new" element={<RoutineEditor />} />
          <Route path="/routine/:routineId/edit" element={<RoutineEditor />} />
          <Route path="/history" element={<History />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/more" element={<More />} />
          <Route path="/progress" element={<Progress />} />
          <Route path="/body" element={<Body />} />
          <Route path="/achievements" element={<Achievements />} />
          <Route path="/goals" element={<Goals />} />
          <Route path="/tools" element={<Calculators />} />
          <Route path="/exercises" element={<Exercises />} />
          <Route path="/workout" element={<ActiveWorkout />} />
        </Routes>
      </main>
      
      {/* Hide bottom navigation when in active workout mode */}
      {!isWorkoutActive && <Navigation />}
    </>
  );
}
