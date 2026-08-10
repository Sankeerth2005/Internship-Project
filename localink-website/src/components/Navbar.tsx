'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Menu, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { navigation } from '@/constants/navigation'
import BrandLogo from '@/components/BrandLogo'

export default function Navbar() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [open])

  return (
    <header
      className={cn(
        'fixed inset-x-0 top-0 z-50 transition-[background-color,box-shadow,padding] duration-300',
        scrolled || open
          ? 'border-b border-border bg-white/95 py-2 shadow-soft backdrop-blur-md'
          : 'bg-transparent py-3'
      )}
    >
      <nav className="container-custom flex items-center justify-between" aria-label="Primary">
        <BrandLogo size="md" priority />

        <div className="hidden items-center gap-7 lg:flex">
          {navigation.main.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="text-sm font-semibold text-text-muted transition-colors hover:text-primary"
            >
              {item.name}
            </Link>
          ))}
          <Link
            href="/download"
            className="rounded-button bg-primary px-5 py-2.5 text-sm font-bold text-white shadow-button transition-colors hover:bg-primary-dark"
          >
            Get the app
          </Link>
        </div>

        <button
          type="button"
          className="rounded-lg p-2 text-text-muted transition-colors hover:bg-primary/5 hover:text-text lg:hidden"
          aria-label={open ? 'Close menu' : 'Open menu'}
          aria-expanded={open}
          aria-controls="mobile-nav"
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X size={24} aria-hidden /> : <Menu size={24} aria-hidden />}
        </button>
      </nav>

      <div
        id="mobile-nav"
        hidden={!open}
        className={cn(
          'border-t border-border bg-white lg:hidden',
          open ? 'block' : 'hidden'
        )}
      >
        <div className="container-custom flex flex-col gap-1 py-4">
          {navigation.main.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="rounded-xl px-3 py-3 text-base font-semibold text-text-muted transition-colors hover:bg-primary/5 hover:text-primary"
              onClick={() => setOpen(false)}
            >
              {item.name}
            </Link>
          ))}
          <Link
            href="/download"
            onClick={() => setOpen(false)}
            className="mt-2 rounded-button bg-primary px-5 py-3 text-center text-sm font-bold text-white"
          >
            Get the app
          </Link>
        </div>
      </div>
    </header>
  )
}
