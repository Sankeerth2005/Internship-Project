import type { Metadata } from 'next'
import { Check } from 'lucide-react'
import PageShell from '@/components/PageShell'
import Button from '@/components/Button'
import { siteContent } from '@/constants/content'

export const metadata: Metadata = {
  title: 'For Business',
  description: 'List your business on Vocal for Sanatan and connect with nearby customers.',
  alternates: { canonical: 'https://vocalforsanatan.com/business' },
}

export default function BusinessPage() {
  return (
    <PageShell
      eyebrow="Owners"
      title={siteContent.business.title}
      description={siteContent.business.subtitle}
      ctaHref="/download"
      ctaLabel="Get started in the app"
    >
      <section className="pb-24">
        <div className="container-custom grid gap-6 lg:grid-cols-2">
          <div className="rounded-card border border-border bg-white p-8 shadow-soft">
            <h2 className="font-display text-2xl font-bold text-text">Why list with us</h2>
            <ul className="mt-6 space-y-4">
              {siteContent.business.benefits.map((b) => (
                <li key={b} className="flex gap-3 text-sm text-text-muted">
                  <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-success/15 text-success">
                    <Check className="h-3.5 w-3.5" />
                  </span>
                  {b}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-card border border-border bg-gradient-to-br from-primary to-primary-dark p-8 text-white shadow-lift">
            <h2 className="font-display text-2xl font-bold">Three steps</h2>
            <ol className="mt-6 space-y-5">
              {siteContent.howItWorks.businessSteps.map((s, i) => (
                <li key={s.step}>
                  <p className="text-sm font-bold text-white/70">Step {i + 1}</p>
                  <p className="font-display text-xl font-bold">{s.step}</p>
                  <p className="mt-1 text-sm text-white/85">{s.description}</p>
                </li>
              ))}
            </ol>
            <div className="mt-8">
              <Button href="/download" variant="secondary" size="lg">
                Download the app
              </Button>
            </div>
          </div>
        </div>
      </section>
    </PageShell>
  )
}
