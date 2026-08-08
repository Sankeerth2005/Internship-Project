'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import SectionHeader from '@/components/SectionHeader'
import { siteContent } from '@/constants/content'
import { cn } from '@/lib/utils'

export default function HowItWorks() {
  const [tab, setTab] = useState<'customers' | 'owners'>('customers')
  const steps =
    tab === 'customers' ? siteContent.howItWorks.userSteps : siteContent.howItWorks.businessSteps

  return (
    <section id="how-it-works" className="section-pad bg-background-surface">
      <div className="container-custom">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <SectionHeader
            eyebrow="Simple flow"
            title={siteContent.howItWorks.title}
            align="left"
            className="max-w-lg"
          />
          <div className="inline-flex rounded-button border border-border bg-white p-1 self-start shadow-soft">
            {(
              [
                ['customers', 'Customers'],
                ['owners', 'Owners'],
              ] as const
            ).map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() => setTab(key)}
                className={cn(
                  'rounded-[10px] px-5 py-2.5 text-sm font-bold transition-all',
                  tab === key ? 'bg-primary text-white shadow-button' : 'text-text-muted hover:text-text'
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={tab}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.25 }}
            className="mt-10 grid gap-4 md:grid-cols-3"
          >
            {steps.map((step, i) => (
              <div
                key={step.step}
                className="relative overflow-hidden rounded-3xl border border-border bg-white p-6 lg:p-7 shadow-soft"
              >
                <span className="absolute -right-1 -top-3 font-display text-7xl font-bold text-primary/10">
                  {i + 1}
                </span>
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-primary">
                  Step {i + 1}
                </p>
                <h3 className="relative mt-2 font-display text-2xl font-bold text-text">{step.step}</h3>
                <p className="relative mt-3 text-sm leading-relaxed text-text-muted">{step.description}</p>
              </div>
            ))}
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
