import { Moon, Sun } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useTheme, useThemeActions } from '@/stores/theme.store'

export function ThemeToggle({ className }: { className?: string }) {
  const theme = useTheme()
  const { toggleTheme } = useThemeActions()
  const isDark = theme === 'dark'
  return (
    <Button
      variant='ghost'
      size='icon'
      className={className}
      onClick={toggleTheme}
      aria-label={isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
      title={isDark ? 'Modo claro' : 'Modo oscuro'}
    >
      {isDark ? <Sun className='size-5' /> : <Moon className='size-5' />}
    </Button>
  )
}
