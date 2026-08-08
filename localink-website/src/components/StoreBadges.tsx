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
  const icon = size === 'lg' ? 28 : 24
  const pad = size === 'lg' ? 'px-4 py-3' : 'px-3.5 py-2.5'
  const title = size === 'lg' ? 'text-base' : 'text-sm'
  const sub = size === 'lg' ? 'text-[10px]' : 'text-[9px]'

  return (
    <div className={cn('flex flex-col sm:flex-row gap-3', className)}>
      <Link
        href={playHref}
        className={cn(
          'inline-flex items-center gap-3 rounded-xl bg-[#111111] text-white shadow-soft transition hover:-translate-y-0.5 hover:bg-black',
          pad
        )}
      >
        <Image
          src="/google-play.png"
          alt="Google Play"
          width={icon}
          height={icon}
          className="shrink-0 rounded-md object-contain"
        />
        <span className="text-left leading-tight">
          <span className={cn('block uppercase tracking-wide text-white/70 font-semibold', sub)}>
            Get it on
          </span>
          <span className={cn('block font-bold', title)}>Google Play</span>
        </span>
      </Link>

      <Link
        href={appleHref}
        className={cn(
          'inline-flex items-center gap-3 rounded-xl bg-[#111111] text-white shadow-soft transition hover:-translate-y-0.5 hover:bg-black',
          pad
        )}
      >
        <Image
          src="/app-store.png"
          alt="App Store"
          width={icon}
          height={icon}
          className="shrink-0 rounded-[7px] object-contain"
        />
        <span className="text-left leading-tight">
          <span className={cn('block uppercase tracking-wide text-white/70 font-semibold', sub)}>
            Download on the
          </span>
          <span className={cn('block font-bold', title)}>App Store</span>
        </span>
      </Link>
    </div>
  )
}
