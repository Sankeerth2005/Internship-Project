import type { Metadata } from 'next'
import Image from 'next/image'
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
      title="Manage. Grow. Succeed."
      description={siteContent.business.subtitle}
      ctaHref="/download"
      ctaLabel="Get started in the app"
    >
      <section className="pb-10">
        <div className="mx-auto w-full max-w-[1100px] px-3 sm:px-5 lg:px-6">
          <div className="overflow-hidden rounded-2xl sm:rounded-3xl border border-border bg-[#F7F2EC] shadow-soft">
            <Image
              src="/images/marketing/business-suite.webp"
              alt="Business Suite screens — analytics, controls, details, and catalog"
              width={1600}
              height={1065}
              className="block h-auto w-full select-none"
              quality={85}
              sizes="(max-width: 1100px) 100vw, 1100px"
              priority
            />
          </div>
        </div>
      </section>
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
