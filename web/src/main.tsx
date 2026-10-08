import '@fontsource-variable/outfit'
import '@fontsource-variable/plus-jakarta-sans'
import './index.css'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppProviders } from '@/app/providers/providers'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppProviders />
  </StrictMode>,
)
