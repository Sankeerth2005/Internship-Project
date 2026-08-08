'use client'

import Image from 'next/image'
import StoreBadges from '@/components/StoreBadges'
import { siteContent } from '@/constants/content'

export default function DownloadCTA() {
  return (
    <section className="section-pad bg-white">
      <div className="container-custom">
        <div className="relative overflow-hidden rounded-[28px] border border-border bg-gradient-to-br from-background-surface via-white to-primary/5 p-7 sm:p-10 lg:p-12 shadow-soft">
          <div className="absolute -right-16 -top-16 h-56 w-56 rounded-full bg-primary/15 blur-3xl" />
          <div className="absolute -left-10 bottom-0 h-40 w-40 rounded-full bg-primary-glow/20 blur-3xl" />
          <div className="relative grid items-center gap-8 lg:grid-cols-[1.2fr_auto]">
            <div className="flex flex-col sm:flex-row sm:items-center gap-5">
              <Image
                src="/app-icon.png"
                alt="Vocal for Sanatan"
                width={84}
                height={84}
                className="rounded-2xl border border-border object-cover shadow-soft"
              />
              <div>
                <p className="mb-1 text-xs font-bold uppercase tracking-[0.2em] text-primary">
                  Get the app
                </p>
                <h2 className="heading-md">{siteContent.download.title}</h2>
                <p className="mt-2 max-w-xl text-body">{siteContent.download.subtitle}</p>
              </div>
            </div>
            <StoreBadges size="lg" />
          </div>
        </div>
      </div>
    </section>
  )
}
