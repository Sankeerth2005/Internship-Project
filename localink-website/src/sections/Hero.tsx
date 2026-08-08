'use client'

import { motion } from 'framer-motion'
import {
  ArrowRight,
  MapPin,
  Mic,
  Sparkles,
  MessageCircle,
  ShieldCheck,
} from 'lucide-react'
import Image from 'next/image'
import Button from '@/components/Button'
import StoreBadges from '@/components/StoreBadges'
import { siteContent } from '@/constants/content'

const highlights = [
  { icon: Sparkles, label: 'AI search' },
  { icon: MessageCircle, label: 'Live chat' },
  { icon: MapPin, label: 'Near you' },
  { icon: Mic, label: 'Voice ready' },
]

export default function Hero() {
  return (
    <section className="relative overflow-hidden pt-20 lg:pt-0">
      <div className="grid lg:grid-cols-2 min-h-[calc(100svh-4.5rem)] lg:min-h-[720px]">
        {/* Left pane */}
        <div className="relative flex items-center atmosphere grain px-5 sm:px-8 lg:px-12 xl:px-16 py-10 lg:py-16">
          <div className="pointer-events-none absolute inset-0 mesh-grid opacity-70" aria-hidden />
          <div
            className="pointer-events-none absolute -left-20 top-24 h-72 w-72 rounded-full bg-primary/20 blur-3xl"
            aria-hidden
          />

          <motion.div
            className="relative z-10 w-full max-w-xl xl:max-w-2xl mx-auto lg:mx-0 text-center lg:text-left"
            initial={false}
          >
            <div className="mb-5 inline-flex items-center gap-2.5 rounded-full border border-primary/25 bg-white/90 px-3.5 py-1.5 shadow-soft backdrop-blur-sm">
              <Image
                src="/app-icon-192.png"
                alt=""
                width={22}
                height={22}
                className="rounded-md object-cover"
              />
              <span className="text-xs font-bold text-primary">Vocal for Sanatan</span>
              <span className="hidden sm:inline text-text-soft">·</span>
              <span className="hidden sm:inline text-xs font-semibold text-text-muted">
                Now on Google Play
              </span>
            </div>

            <h1 className="heading-xl">
              Your neighbourhood,{' '}
              <span className="gradient-text">discovered.</span>
            </h1>

            <p className="mt-4 text-body max-w-lg mx-auto lg:mx-0">
              {siteContent.hero.subheadline}
            </p>

            <div className="mt-6 flex flex-wrap justify-center lg:justify-start gap-2">
              {highlights.map(({ icon: Icon, label }) => (
                <span
                  key={label}
                  className="inline-flex items-center gap-1.5 rounded-full border border-border bg-white px-3.5 py-2 text-xs font-bold text-text-muted shadow-sm"
                >
                  <Icon className="h-3.5 w-3.5 text-primary" />
                  {label}
                </span>
              ))}
            </div>

            <div className="mt-7 flex flex-col sm:flex-row gap-3 justify-center lg:justify-start">
              <Button href="/download" size="lg">
                {siteContent.hero.ctaPrimary}
                <ArrowRight className="h-5 w-5" />
              </Button>
              <Button href="/business" variant="outline" size="lg">
                {siteContent.hero.ctaSecondary}
              </Button>
            </div>

            <div className="mt-6 flex justify-center lg:justify-start">
              <StoreBadges size="md" />
            </div>

            <div className="mt-5 flex flex-wrap items-center justify-center lg:justify-start gap-x-5 gap-y-2 text-xs font-semibold text-text-soft">
              <span className="inline-flex items-center gap-1.5">
                <ShieldCheck className="h-3.5 w-3.5 text-success" />
                Privacy-first
              </span>
              <span>Made for India</span>
              <span>Customers &amp; owners</span>
            </div>
          </motion.div>
        </div>

        {/* Right pane — real app screenshot in phone frame */}
        <div className="relative flex items-center justify-center bg-gradient-to-br from-[#FFF4EB] via-[#FFE8D4] to-[#FFD7B0] px-5 sm:px-8 lg:px-10 xl:px-14 py-12 lg:py-16 overflow-hidden">
          <div className="pointer-events-none absolute inset-0 mesh-grid opacity-40" aria-hidden />
          <div
            className="pointer-events-none absolute -right-16 top-10 h-80 w-80 rounded-full bg-primary/25 blur-3xl"
            aria-hidden
          />
          <div
            className="pointer-events-none absolute left-10 bottom-8 h-56 w-56 rounded-full bg-white/60 blur-3xl"
            aria-hidden
          />

          <div className="relative z-10 flex w-full max-w-xl items-center gap-4 xl:gap-6">
            <div className="hidden md:flex flex-1 flex-col gap-3">
              {[
                { title: 'AI discovery', sub: 'Ask naturally', icon: Sparkles },
                { title: 'Live chat', sub: 'Talk to owners', icon: MessageCircle },
                { title: 'Near you', sub: 'Maps & distance', icon: MapPin },
              ].map((card) => (
                <div
                  key={card.title}
                  className="rounded-2xl border border-white/70 bg-white/90 p-3.5 shadow-lift backdrop-blur"
                >
                  <div className="flex items-center gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                      <card.icon className="h-5 w-5" />
                    </span>
                    <div>
                      <p className="text-sm font-bold text-text">{card.title}</p>
                      <p className="text-xs text-text-muted">{card.sub}</p>
                    </div>
                  </div>
                </div>
              ))}
              <div className="grid grid-cols-3 gap-2">
                {[
                  { value: 'AI', label: 'Search' },
                  { value: 'Maps', label: 'Nearby' },
                  { value: 'Chat', label: 'Direct' },
                ].map((stat) => (
                  <div
                    key={stat.label}
                    className="rounded-xl border border-white/70 bg-white/90 px-2 py-3 text-center shadow-soft"
                  >
                    <p className="font-display text-base font-bold text-primary">{stat.value}</p>
                    <p className="text-[10px] font-semibold text-text-muted">{stat.label}</p>
                  </div>
                ))}
              </div>
            </div>

            <motion.div
              className="relative shrink-0 mx-auto"
              animate={{ y: [0, -10, 0] }}
              transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
            >
              <div className="absolute -inset-8 rounded-[2.5rem] bg-primary/20 blur-2xl" />

              {/* Android phone frame */}
              <div className="relative">
                {/* Volume / power buttons */}
                <span className="absolute -left-[3px] top-24 h-8 w-[3px] rounded-l-sm bg-[#3a3836]" aria-hidden />
                <span className="absolute -left-[3px] top-36 h-14 w-[3px] rounded-l-sm bg-[#3a3836]" aria-hidden />
                <span className="absolute -right-[3px] top-32 h-16 w-[3px] rounded-r-sm bg-[#3a3836]" aria-hidden />

                <div className="relative w-[260px] sm:w-[300px] lg:w-[320px] overflow-hidden rounded-[1.65rem] border-[3px] border-[#2C2A28] bg-[#0E0D0C] shadow-phone">
                  {/* Android top bezel with centered punch-hole */}
                  <div className="relative flex h-4 items-center justify-center bg-[#0E0D0C]">
                    <span className="h-2 w-2 rounded-full bg-[#1f1e1d] ring-1 ring-white/10" aria-hidden />
                  </div>

                  {/* Screen — natural Android aspect from screenshot */}
                  <div className="bg-white">
                    <Image
                      src="/images/app-home.png"
                      alt="Vocal for Sanatan Android app home screen"
                      width={472}
                      height={819}
                      className="block h-auto w-full"
                      priority
                    />
                  </div>

                  {/* Thin Android bottom chin */}
                  <div className="h-3 bg-[#0E0D0C]" aria-hidden />
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}
