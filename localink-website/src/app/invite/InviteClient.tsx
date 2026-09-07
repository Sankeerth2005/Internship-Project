'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { site } from '@/constants/colors'
import PageShell from '@/components/PageShell'
import StoreBadges from '@/components/StoreBadges'

const PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.vocalforsanatan.app'

type InviteClientProps = {
  code: string
}

export default function InviteClient({ code }: InviteClientProps) {
  const [copied, setCopied] = useState(false)
  const hasCode = code.length > 0

  const playHref = useMemo(() => {
    if (!hasCode) return PLAY_STORE
    const referrer = encodeURIComponent(`utm_source=referral&utm_content=${code}`)
    return `${PLAY_STORE}&referrer=${referrer}`
  }, [code, hasCode])

  const deepLink = useMemo(
    () => (hasCode ? `vocalforsanatan://invite?code=${encodeURIComponent(code)}` : null),
    [code, hasCode],
  )

  useEffect(() => {
    if (!hasCode || typeof window === 'undefined') return
    try {
      window.localStorage.setItem('vfs_pending_referral_code_v1', code)
    } catch {
      // ignore quota / private mode
    }
  }, [code, hasCode])

  useEffect(() => {
    if (!deepLink || typeof window === 'undefined') return
    // Best-effort: open installed app via custom scheme; browser ignores if missing.
    const t = window.setTimeout(() => {
      window.location.href = deepLink
    }, 400)
    return () => window.clearTimeout(t)
  }, [deepLink])

  async function copyCode() {
    if (!hasCode) return
    try {
      await navigator.clipboard.writeText(code)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopied(false)
    }
  }

  return (
    <PageShell
      eyebrow="Community invite"
      title="Support Sanatani businesses together"
      description={
        hasCode
          ? 'Your friend invited you to Vocal for Sanatan. Download the app and register — your invite is counted only after you successfully join.'
          : 'Download Vocal for Sanatan to discover and support Sanatani businesses in your community.'
      }
    >
      <section className="pb-20">
        <div className="container-custom max-w-xl">
          <div className="rounded-card border border-border bg-white p-6 shadow-soft sm:p-8">
            {hasCode ? (
              <div className="mb-6 rounded-2xl border border-primary/20 bg-[#FFF7F0] p-4">
                <p className="text-xs font-semibold uppercase tracking-wide text-text-muted">
                  Referral code
                </p>
                <p className="mt-1 font-mono text-2xl font-bold tracking-wider text-primary">
                  {code}
                </p>
                <p className="mt-2 text-xs text-text-soft">
                  Opening or installing alone does not count. Registration must succeed.
                </p>
                <button
                  type="button"
                  onClick={copyCode}
                  className="mt-3 rounded-xl border border-border bg-white px-3 py-2 text-sm font-semibold text-text transition hover:border-primary/40"
                >
                  {copied ? 'Copied' : 'Copy code'}
                </button>
              </div>
            ) : (
              <p className="mb-6 text-sm text-text-muted">
                No invite code was found in this link. You can still download the app and join
                normally.
              </p>
            )}

            <StoreBadges size="lg" playHref={playHref} appleHref="/contact" />

            <div className="mt-6 flex flex-col gap-3 sm:flex-row">
              <a
                href={playHref}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex flex-1 items-center justify-center rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-white transition hover:bg-primaryDark"
              >
                Get it on Google Play
              </a>
              {deepLink ? (
                <a
                  href={deepLink}
                  className="inline-flex flex-1 items-center justify-center rounded-2xl border border-border px-4 py-3 text-sm font-bold text-text transition hover:border-primary/40"
                >
                  Open app if installed
                </a>
              ) : null}
            </div>

            <p className="mt-4 text-xs text-text-soft">
              After install, open {site.name} and sign up. If the code is not applied
              automatically, enter it on the signup screen.
            </p>

            <p className="mt-4 text-center text-xs text-text-soft">
              <Link href="/download" className="underline underline-offset-2">
                More download options
              </Link>
            </p>
          </div>
        </div>
      </section>
    </PageShell>
  )
}
