'use client'

import { useState } from 'react'
import { ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'
import { site } from '@/constants/colors'

const faqs = [
  {
    q: 'What is Vocal for Sanatan?',
    a: 'A mobile app to discover nearby businesses with AI search, maps, reviews, and direct chat between customers and owners.',
  },
  {
    q: 'Is it free?',
    a: 'Downloading and discovering businesses is free for customers. Business listing features are available in the app; any future paid plans will be clearly disclosed.',
  },
  {
    q: 'Why does the app ask for location?',
    a: 'Location helps show businesses near you and sort by distance. You can deny permission; some nearby features will be limited.',
  },
  {
    q: 'Why microphone permission?',
    a: 'Voice search and voice messages need the microphone. Audio is only used when you use those features.',
  },
  {
    q: 'How do I delete my account?',
    a: 'In the app: Profile → Delete account. Or email support with an account deletion request. Full steps are on the Delete Account page.',
  },
  {
    q: 'How do I list my business?',
    a: 'Download the app, register as a business owner, complete your listing with photos, hours, and location, then submit for approval if required.',
  },
  {
    q: 'Where can I get support?',
    a: `Email ${site.supportEmail} or visit the Support page for common fixes.`,
  },
]

export default function FaqList() {
  const [open, setOpen] = useState<number | null>(0)

  return (
    <div className="container-custom max-w-2xl space-y-3">
      {faqs.map((item, i) => {
        const isOpen = open === i
        return (
          <div
            key={item.q}
            className="rounded-card border border-border bg-white shadow-soft overflow-hidden"
          >
            <button
              type="button"
              className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
              onClick={() => setOpen(isOpen ? null : i)}
              aria-expanded={isOpen}
            >
              <span className="font-display text-base font-bold text-text">{item.q}</span>
              <ChevronDown
                className={cn(
                  'h-5 w-5 shrink-0 text-text-soft transition-transform',
                  isOpen && 'rotate-180'
                )}
              />
            </button>
            {isOpen && (
              <p className="px-5 pb-5 text-sm leading-relaxed text-text-muted">{item.a}</p>
            )}
          </div>
        )
      })}
    </div>
  )
}
