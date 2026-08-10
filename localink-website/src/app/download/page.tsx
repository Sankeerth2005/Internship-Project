import type { Metadata } from 'next'
import Image from 'next/image'
import { ShieldCheck } from 'lucide-react'
import PageShell from '@/components/PageShell'
import StoreBadges from '@/components/StoreBadges'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Download',
  description: 'Download Vocal for Sanatan on Google Play. iOS coming soon.',
  alternates: { canonical: 'https://vocalforsanatan.com/download' },
}

export default function DownloadPage() {
  return (
    <PageShell
      eyebrow="Download"
      title="One platform. Every screen."
      description="Find local businesses, chat with owners, and grow your neighbourhood network — seamlessly across devices."
    >
      <section className="pb-10">
        <div className="mx-auto w-full max-w-[1100px] px-3 sm:px-5 lg:px-6">
          <div className="overflow-hidden rounded-2xl border border-border bg-[#F7F2EC] shadow-soft sm:rounded-3xl">
            <Image
              src="/images/marketing/every-screen.webp"
              alt="Vocal for Sanatan across desktop, laptop, tablet, and phones"
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

      <section className="pb-20">
        <div className="container-custom max-w-3xl">
          <div className="rounded-card border border-border bg-white p-6 shadow-soft sm:p-8">
            <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
              <Image
                src="/app-icon.png"
                alt="Vocal for Sanatan"
                width={88}
                height={88}
                className="rounded-2xl border border-border object-cover shadow-soft"
              />
              <div className="flex-1">
                <h2 className="font-display text-2xl font-bold text-text">Vocal for Sanatan</h2>
                <p className="mt-1 text-sm text-text-muted">
                  Android on Google Play · iOS coming soon
                </p>
                <p className="mt-1 text-xs text-text-soft">
                  Package ID: <code>{site.packageId}</code>
                </p>
              </div>
            </div>

            <div className="mt-6">
              <StoreBadges
                size="lg"
                playHref="https://play.google.com/store/apps/details?id=com.vocalforsanatan.app"
                appleHref="/contact"
              />
            </div>

            <p className="mt-4 text-xs text-text-soft">
              Google Play badge links to the listing. App Store opens contact for the iOS waitlist
              until launch.
            </p>
          </div>

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
            <a
              href="https://play.google.com/store/apps/details?id=com.vocalforsanatan.app"
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-2xl border border-border bg-background-surface p-5 transition hover:border-primary/30 hover:shadow-soft"
            >
              <Image
                src="/badges/google-play-badge.png"
                alt="Get it on Google Play"
                width={180}
                height={70}
                className="h-12 w-auto object-contain object-left"
              />
              <p className="mt-3 text-sm text-text-muted">
                Available for Android customers and business owners.
              </p>
            </a>
            <a
              href="/contact"
              className="rounded-2xl border border-border bg-background-surface p-5 transition hover:border-primary/30 hover:shadow-soft"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/badges/app-store-badge.svg"
                alt="Download on the App Store"
                width={150}
                height={50}
                className="h-12 w-auto object-contain object-left"
              />
              <p className="mt-3 text-sm text-text-muted">iOS version is on the roadmap. Stay tuned.</p>
            </a>
          </div>

          <div className="mt-6 flex items-start gap-3 rounded-card border border-border bg-white p-5 text-sm text-text-muted">
            <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-success" />
            <p>
              Before installing, review our{' '}
              <a href="/privacy" className="font-semibold text-primary">
                Privacy Policy
              </a>{' '}
              and{' '}
              <a href="/terms" className="font-semibold text-primary">
                Terms of Service
              </a>
              . Need to leave later?{' '}
              <a href="/delete-account" className="font-semibold text-primary">
                Delete your account
              </a>{' '}
              anytime.
            </p>
          </div>
        </div>
      </section>
    </PageShell>
  )
}
