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
      title="Get Vocal for Sanatan"
      description="Find local businesses, chat with owners, and grow your neighbourhood network."
    >
      <section className="pb-20">
        <div className="container-custom max-w-3xl">
          <div className="rounded-card border border-border bg-white p-6 sm:p-8 shadow-soft">
            <div className="flex flex-col sm:flex-row sm:items-center gap-5">
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
              Google Play link activates once the listing is live. App Store opens contact for iOS
              waitlist until launch.
            </p>
          </div>

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
            <div className="rounded-2xl border border-border bg-background-surface p-5">
              <div className="mb-3 flex items-center gap-3">
                <Image
                  src="/google-play.png"
                  alt=""
                  width={36}
                  height={36}
                  className="rounded-lg object-contain bg-black"
                />
                <h3 className="font-display text-lg font-bold text-text">Google Play</h3>
              </div>
              <p className="text-sm text-text-muted">
                Available for Android customers and business owners.
              </p>
            </div>
            <div className="rounded-2xl border border-border bg-background-surface p-5">
              <div className="mb-3 flex items-center gap-3">
                <Image
                  src="/app-store.png"
                  alt=""
                  width={36}
                  height={36}
                  className="rounded-[8px] object-contain"
                />
                <h3 className="font-display text-lg font-bold text-text">App Store</h3>
              </div>
              <p className="text-sm text-text-muted">iOS version is on the roadmap. Stay tuned.</p>
            </div>
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
