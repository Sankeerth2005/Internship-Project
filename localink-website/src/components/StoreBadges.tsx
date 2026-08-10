import Image from 'next/image'
import Link from 'next/link'
import { cn } from '@/lib/utils'

interface StoreBadgesProps {
  className?: string
  size?: 'md' | 'lg'
  playHref?: string
  appleHref?: string
}

export default function StoreBadges({
  className,
  size = 'md',
  playHref = '/download',
  appleHref = '/download',
}: StoreBadgesProps) {
  const height = size === 'lg' ? 56 : 48
  // Official badge aspect ratios (trimmed Play asset is ~564×168)
  const playWidth = Math.round(height * (564 / 168))
  const appleWidth = Math.round(height * (120 / 40))

  return (
    <div className={cn('flex flex-wrap items-center gap-3', className)}>
      <Link
        href={playHref}
        target={playHref.startsWith('http') ? '_blank' : undefined}
        rel={playHref.startsWith('http') ? 'noopener noreferrer' : undefined}
        className="inline-block transition hover:opacity-90 hover:-translate-y-0.5"
        aria-label="Get it on Google Play"
      >
        <Image
          src="/badges/google-play-badge.png"
          alt="Get it on Google Play"
          width={playWidth}
          height={height}
          className="h-auto w-auto"
          style={{ height, width: 'auto' }}
        />
      </Link>

      <Link
        href={appleHref}
        target={appleHref.startsWith('http') ? '_blank' : undefined}
        rel={appleHref.startsWith('http') ? 'noopener noreferrer' : undefined}
        className="inline-block transition hover:opacity-90 hover:-translate-y-0.5"
        aria-label="Download on the App Store"
      >
        {/* Official Apple badge SVG */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/badges/app-store-badge.svg"
          alt="Download on the App Store"
          width={appleWidth}
          height={height}
          className="block"
          style={{ height, width: 'auto' }}
        />
      </Link>
    </div>
  )
}
