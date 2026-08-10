'use client'

import { useState } from 'react'
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
          <div
            className="inline-flex self-start rounded-button border border-border bg-white p-1 shadow-soft"
            role="tablist"
            aria-label="Audience"
          >
            {(
              [
                ['customers', 'Customers'],
                ['owners', 'Owners'],
              ] as const
            ).map(([key, label]) => (
              <button
                key={key}
                type="button"
                role="tab"
                aria-selected={tab === key}
                onClick={() => setTab(key)}
                className={cn(
                  'rounded-[10px] px-5 py-2.5 text-sm font-bold transition-colors',
                  tab === key
                    ? 'bg-primary text-white shadow-button'
                    : 'text-text-muted hover:text-text'
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="mt-10 grid gap-4 md:grid-cols-3" role="tabpanel">
          {steps.map((step, i) => (
            <div
              key={`${tab}-${step.step}`}
              className="relative overflow-hidden rounded-3xl border border-border bg-white p-6 shadow-soft lg:p-7"
            >
              <span
                className="absolute -right-1 -top-3 font-display text-7xl font-bold text-primary/10"
                aria-hidden
              >
                {i + 1}
              </span>
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-primary">
                Step {i + 1}
              </p>
              <h3 className="relative mt-2 font-display text-2xl font-bold text-text">{step.step}</h3>
              <p className="relative mt-3 text-sm leading-relaxed text-text-muted">
                {step.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
