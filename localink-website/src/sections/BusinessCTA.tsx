'use client'

import { Check } from 'lucide-react'
import Image from 'next/image'
import Button from '@/components/Button'
import { siteContent } from '@/constants/content'

export default function BusinessCTA() {
  return (
    <section className="section-pad bg-background-surface">
      <div className="container-custom">
        <div className="overflow-hidden rounded-[28px] border border-border bg-white shadow-soft">
          <div className="grid lg:grid-cols-2">
            <div className="p-7 sm:p-10 lg:p-12">
              <p className="mb-2 text-xs font-bold uppercase tracking-[0.2em] text-primary">
                For business owners
              </p>
              <h2 className="heading-md max-w-md">{siteContent.business.title}</h2>
              <p className="mt-3 max-w-lg text-body">{siteContent.business.subtitle}</p>
              <ul className="mt-6 grid gap-3 sm:grid-cols-2">
                {siteContent.business.benefits.map((b) => (
                  <li key={b} className="flex items-start gap-2.5 text-sm text-text-muted">
                    <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-success/15 text-success">
                      <Check className="h-3 w-3" />
                    </span>
                    {b}
                  </li>
                ))}
              </ul>
              <div className="mt-8">
                <Button href="/business" size="lg">
                  Learn more
                </Button>
              </div>
            </div>
            <div className="relative min-h-[280px] bg-gradient-to-br from-primary via-primary-glow to-primary-dark p-7 sm:p-10 lg:p-12 flex flex-col justify-between text-white">
              <div className="absolute inset-0 opacity-25 bg-[radial-gradient(circle_at_30%_20%,white,transparent_45%)]" />
              <div className="absolute inset-0 opacity-20 mesh-grid" />
              <div className="relative flex items-center gap-3">
                <Image
                  src="/app-icon-192.png"
                  alt=""
                  width={52}
                  height={52}
                  className="rounded-xl border border-white/30 object-cover shadow-soft"
                />
                <div>
                  <p className="text-sm font-bold">Vocal for Sanatan</p>
                  <p className="text-xs text-white/80">Owner dashboard ready</p>
                </div>
              </div>
              <div className="relative mt-10">
                <p className="font-display text-3xl sm:text-4xl font-bold leading-tight">
                  List once.
                  <br />
                  Get discovered daily.
                </p>
                <p className="mt-3 max-w-md text-sm sm:text-base text-white/85">
                  Photos, hours, maps, chat, and reviews — your storefront in your customers&apos;
                  pocket.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
