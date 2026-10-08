import { cn } from '@/lib/cn'

interface UserAvatarProps {
  initials: string
  imageUrl?: string | null
  className?: string
}

export function UserAvatar({ initials, imageUrl, className }: UserAvatarProps) {
  const base = 'flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-full'
  if (imageUrl) return <img src={imageUrl} alt='' className={cn(base, 'object-cover', className)} />
  return (
    <span
      aria-hidden
      className={cn(base, 'bg-primary-soft text-primary text-sm font-bold', className)}
    >
      {initials}
    </span>
  )
}
