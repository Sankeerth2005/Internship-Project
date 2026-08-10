import Image from 'next/image'
import Link from 'next/link'
import { cn } from '@/lib/utils'

interface BrandLogoProps {
  className?: string
  showWordmark?: boolean
  size?: 'sm' | 'md' | 'lg'
  href?: string
  tone?: 'dark' | 'light'
  priority?: boolean
}

const sizes = {
  sm: { box: 'h-9 w-9', img: 36, text: 'text-base' },
  md: { box: 'h-11 w-11', img: 44, text: 'text-lg sm:text-xl' },
  lg: { box: 'h-14 w-14', img: 56, text: 'text-xl sm:text-2xl' },
}

export default function BrandLogo({
  className,
  showWordmark = true,
  size = 'md',
  href = '/',
  tone = 'dark',
  priority = false,
}: BrandLogoProps) {
  const s = sizes[size]

  const inner = (
    <span className={cn('group inline-flex items-center gap-2.5', className)}>
      <span
        className={cn(
          'relative shrink-0 overflow-hidden rounded-xl border border-border bg-white shadow-soft',
          s.box
        )}
      >
        <Image
          src="/app-icon-192.png"
          alt=""
          width={s.img}
          height={s.img}
          className="h-full w-full object-cover"
          priority={priority}
          sizes={`${s.img}px`}
        />
      </span>
      {showWordmark && (
        <span
          className={cn(
            'font-display font-bold tracking-tight transition-colors',
            s.text,
            tone === 'light'
              ? 'text-white group-hover:text-primary-glow'
              : 'text-text group-hover:text-primary'
          )}
        >
          Vocal for Sanatan
        </span>
      )}
    </span>
  )

  if (!href) return inner
  return (
    <Link href={href} className="inline-flex" aria-label="Vocal for Sanatan home">
      {inner}
    </Link>
  )
}
