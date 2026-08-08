'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Menu, X } from 'lucide-react'
import { AnimatePresence, motion } from 'framer-motion'
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

  return (
    <header
      className={cn(
        'fixed inset-x-0 top-0 z-50 transition-all duration-400',
        scrolled
          ? 'bg-white/90 backdrop-blur-xl border-b border-border shadow-soft py-2'
          : 'bg-transparent py-3'
      )}
    >
      <nav className="container-custom flex items-center justify-between" aria-label="Primary">
        <BrandLogo size="md" />

        <div className="hidden lg:flex items-center gap-7">
          {navigation.main.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="text-sm font-semibold text-text-muted hover:text-primary transition-colors"
            >
              {item.name}
            </Link>
          ))}
          <Link
            href="/download"
            className="rounded-button bg-primary px-5 py-2.5 text-sm font-bold text-white shadow-button hover:bg-primary-dark transition-colors"
          >
            Get the app
          </Link>
        </div>

        <button
          type="button"
          className="lg:hidden p-2 text-text-muted hover:text-text"
          aria-label={open ? 'Close menu' : 'Open menu'}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X size={24} /> : <Menu size={24} />}
        </button>
      </nav>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="lg:hidden overflow-hidden border-t border-border bg-white/95 backdrop-blur-xl"
          >
            <div className="container-custom flex flex-col gap-3 py-5">
              {navigation.main.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className="text-base font-semibold text-text-muted hover:text-primary py-1"
                  onClick={() => setOpen(false)}
                >
                  {item.name}
                </Link>
              ))}
              <Link
                href="/download"
                onClick={() => setOpen(false)}
                className="mt-1 rounded-button bg-primary px-5 py-3 text-center text-sm font-bold text-white"
              >
                Get the app
              </Link>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  )
}
