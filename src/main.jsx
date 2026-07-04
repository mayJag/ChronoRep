import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { HashRouter } from 'react-router-dom'
import './index.css'
import App from './App.jsx'
import { ToastProvider } from './components/Toast.jsx'
import { SettingsProvider } from './store/SettingsContext.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <HashRouter>
      <SettingsProvider>
        <ToastProvider>
          <App />
        </ToastProvider>
      </SettingsProvider>
    </HashRouter>
  </StrictMode>,
)

// PWA: offline app shell + installability (web builds only — Capacitor ships its own bundle)
if ('serviceWorker' in navigator && import.meta.env.PROD && !window.location.protocol.startsWith('capacitor')) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register(`${import.meta.env.BASE_URL}sw.js`).catch((e) => {
      console.warn('Service worker registration failed:', e);
    });
  });
}
