import type { Metadata } from 'next'
import Link from 'next/link'
import { HelpCircle, Mail, Shield, Trash2 } from 'lucide-react'
import PageShell from '@/components/PageShell'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Support',
  description: 'Get help with Vocal for Sanatan — support contact, FAQs, and account assistance.',
  alternates: { canonical: 'https://vocalforsanatan.com/support' },
}

const cards = [
  {
    icon: Mail,
    title: 'Email support',
    body: `Write to ${site.supportEmail}. We typically respond within 1–2 business days.`,
    href: `mailto:${site.supportEmail}`,
    cta: 'Email us',
  },
  {
    icon: HelpCircle,
    title: 'FAQ',
    body: 'Quick answers about accounts, listings, chat, and permissions.',
    href: '/faq',
    cta: 'Browse FAQ',
  },
  {
    icon: Shield,
    title: 'Privacy & data',
    body: 'Read how we handle location, voice, photos, and account data.',
    href: '/privacy',
    cta: 'Privacy Policy',
  },
  {
    icon: Trash2,
    title: 'Delete account',
    body: 'Step-by-step instructions to permanently delete your account.',
    href: '/delete-account',
    cta: 'Delete account',
  },
]

export default function SupportPage() {
  return (
    <PageShell
      eyebrow="Help center"
      title="We're here to help"
      description="App issues, business listing questions, or privacy requests — start here."
    >
      <section className="pb-24">
        <div className="container-custom grid gap-5 sm:grid-cols-2">
          {cards.map((card) => (
            <Link
              key={card.title}
              href={card.href}
              className="group rounded-card border border-border bg-white p-6 shadow-soft transition-all hover:-translate-y-1 hover:border-primary/30"
            >
              <span className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-primary/10 text-primary group-hover:bg-primary group-hover:text-white transition-colors">
                <card.icon className="h-5 w-5" />
              </span>
              <h2 className="font-display text-xl font-bold text-text">{card.title}</h2>
              <p className="mt-2 text-sm text-text-muted leading-relaxed">{card.body}</p>
              <span className="mt-4 inline-block text-sm font-bold text-primary">{card.cta} →</span>
            </Link>
          ))}
        </div>

        <div className="container-custom mt-12 max-w-2xl rounded-card border border-border bg-background-surface p-6 sm:p-8">
          <h2 className="font-display text-2xl font-bold text-text">Common topics</h2>
          <ul className="mt-4 space-y-3 text-sm text-text-muted">
            <li>
              <strong className="text-text">Can&apos;t sign in?</strong> Try password reset in the
              app, or Google Sign-In with the same email.
            </li>
            <li>
              <strong className="text-text">Location not working?</strong> Enable location permission
              for Vocal for Sanatan in Android settings.
            </li>
            <li>
              <strong className="text-text">Business pending approval?</strong> New listings may need
              admin review before they appear publicly.
            </li>
            <li>
              <strong className="text-text">Report abuse?</strong> Email{' '}
              <a className="font-semibold text-primary" href={`mailto:${site.supportEmail}`}>
                {site.supportEmail}
              </a>{' '}
              with screenshots and the listing or user involved.
            </li>
          </ul>
        </div>
      </section>
    </PageShell>
  )
}
