import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Home, Dumbbell, Calendar, BarChart3, Settings } from 'lucide-react';
import styles from './Navigation.module.css';

export default function Navigation() {
  const location = useLocation();
  const navigate = useNavigate();

  const navItems = [
    { label: 'Home', icon: Home, path: '/' },
    { label: 'Programs', icon: Dumbbell, path: '/programs' },
    { label: 'Plan', icon: Calendar, path: '/plan' },
    { label: 'History', icon: BarChart3, path: '/history' },
    { label: 'Settings', icon: Settings, path: '/settings' },
  ];

  return (
    <nav className={styles.navBar}>
      <div className={styles.navContainer}>
        {navItems.map((item) => {
          const isActive = location.pathname === item.path;
          const Icon = item.icon;

          return (
            <button
              key={item.path}
              className={`${styles.navItem} ${isActive ? styles.navItemActive : ''}`}
              onClick={() => navigate(item.path)}
            >
              {isActive && <div className={styles.glowDot} />}
              <Icon size={20} className={styles.icon} />
              <span className={styles.label}>{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
