import type { Metadata } from 'next'
import PageShell from '@/components/PageShell'
import Button from '@/components/Button'

export const metadata: Metadata = {
  title: 'About',
  description: 'About Vocal for Sanatan — local discovery rooted in community.',
  alternates: { canonical: 'https://vocalforsanatan.com/about' },
}

export default function AboutPage() {
  return (
    <PageShell
      eyebrow="Our story"
      title="Local discovery, rooted in community"
      description="Vocal for Sanatan helps people find trusted neighbourhood businesses and helps owners be found — with AI search, maps, chat, and reviews."
    >
      <section className="pb-24">
        <div className="container-custom max-w-3xl space-y-8 text-body">
          <p>
            Too many great local shops stay invisible online. Too many customers waste time calling
            around. We built Vocal for Sanatan so discovery feels natural — search by voice or text,
            see what&apos;s nearby, and talk to the owner directly.
          </p>
          <p>
            The name reflects a simple idea: give voice to the businesses and traditions that shape
            everyday life. Technology should strengthen the street corner, not replace it.
          </p>
          <div className="rounded-card border border-border bg-white p-6 sm:p-8 shadow-soft">
            <h2 className="font-display text-2xl font-bold text-text">What we stand for</h2>
            <ul className="mt-4 space-y-3 text-sm text-text-muted">
              <li>
                <strong className="text-text">Direct connection</strong> — chat with businesses, not
                endless intermediaries.
              </li>
              <li>
                <strong className="text-text">Trust</strong> — real reviews, clear listings, and
                transparent policies.
              </li>
              <li>
                <strong className="text-text">Accessibility</strong> — voice, maps, and interfaces
                designed for real-world use.
              </li>
              <li>
                <strong className="text-text">Respect for data</strong> — permissions only when
                needed; account deletion when you ask.
              </li>
            </ul>
          </div>
          <div className="flex flex-wrap gap-3">
            <Button href="/download" size="lg">
              Get the app
            </Button>
            <Button href="/contact" variant="outline" size="lg">
              Contact us
            </Button>
          </div>
        </div>
      </section>
    </PageShell>
  )
}
