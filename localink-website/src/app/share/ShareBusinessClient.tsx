'use client'

import { useEffect, useMemo } from 'react'
import Link from 'next/link'
import PageShell from '@/components/PageShell'
import StoreBadges from '@/components/StoreBadges'

const PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.vocalforsanatan.app'

type ShareBusinessClientProps = {
  token: string
  kind: 'business' | 'collection'
}

export default function ShareBusinessClient({
  token,
  kind,
}: ShareBusinessClientProps) {
  const normalized = (token ?? '').trim().toUpperCase()
  const hasToken = normalized.length >= 8

  const playHref = useMemo(() => {
    if (!hasToken) return PLAY_STORE
    const referrer = encodeURIComponent(
      `utm_source=share&utm_content=${kind}_${normalized}`,
    )
    return `${PLAY_STORE}&referrer=${referrer}`
  }, [hasToken, kind, normalized])

  const deepLink = useMemo(
    () =>
      hasToken
        ? `vocalforsanatan://share/${kind}/${encodeURIComponent(normalized)}`
        : null,
    [hasToken, kind, normalized],
  )

  useEffect(() => {
    if (!hasToken || typeof window === 'undefined') return
    try {
      window.localStorage.setItem(
        'vfs_pending_share_route_v1',
        `${kind}:${normalized}`,
      )
    } catch {
      // ignore
    }
  }, [hasToken, kind, normalized])

  useEffect(() => {
    if (!deepLink || typeof window === 'undefined') return
    const t = window.setTimeout(() => {
      window.location.href = deepLink
    }, 400)
    return () => window.clearTimeout(t)
  }, [deepLink])

  const title =
    kind === 'business'
      ? 'A Sanatani business was shared with you'
      : 'Businesses were shared with you'

  return (
    <PageShell
      eyebrow="Community recommendation"
      title={title}
      description={
        hasToken
          ? 'If Vocal for Sanatan is installed, we will try to open your shared list. If not, install from Play Store, then open the same share link again (or reopen the app after install — we attempt to restore the share when Play provides install context).'
          : 'Download Vocal for Sanatan to discover and support Sanatani businesses.'
      }
    >
      <section className="pb-20">
        <div className="container-custom max-w-xl">
          <div className="rounded-card border border-border bg-white p-6 shadow-soft sm:p-8">
            {hasToken ? (
              <p className="mb-6 text-sm text-text-muted">
                This is a business recommendation link — not a referral invite.
                After installing, open Vocal for Sanatan; if the shared list does
                not appear automatically, tap this link again.
              </p>
            ) : null}
            <StoreBadges playHref={playHref} />
            <p className="mt-6 text-center text-sm text-text-muted">
              <Link href="/download" className="text-primary underline">
                Learn more about Vocal for Sanatan
              </Link>
            </p>
          </div>
        </div>
      </section>
    </PageShell>
  )
}
