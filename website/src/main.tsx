import { StrictMode, useState, useCallback } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import './index.css'
import App from './App.tsx'
import LoadingScreen from './components/LoadingScreen.tsx'

function Root() {
  // Only show loading screen on first visit per session
  const alreadyLoaded = sessionStorage.getItem('paydome_loaded') === 'true'
  const [loading, setLoading] = useState(!alreadyLoaded)

  const handleComplete = useCallback(() => {
    sessionStorage.setItem('paydome_loaded', 'true')
    setLoading(false)
  }, [])

  return (
    <>
      {loading && <LoadingScreen onComplete={handleComplete} />}
      <div className={loading ? 'opacity-0' : 'opacity-100 transition-opacity duration-500'}>
        <App />
      </div>
    </>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <Root />
    </BrowserRouter>
  </StrictMode>,
)
