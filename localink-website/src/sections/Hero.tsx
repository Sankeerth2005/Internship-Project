'use client'

import { motion } from 'framer-motion'
import {
  ArrowRight,
  MapPin,
  Mic,
  Search,
  Sparkles,
  Star,
  Wifi,
  Battery,
  Signal,
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
        {/* Left pane — fills half the viewport */}
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

        {/* Right pane — full-bleed visual */}
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
              <div className="absolute -inset-10 rounded-[3rem] bg-primary/20 blur-2xl" />
              <div className="relative w-[240px] sm:w-[260px] h-[480px] sm:h-[510px] rounded-[2.4rem] border border-[#1A1918]/20 bg-[#1A1918] p-2 shadow-phone">
                <div className="absolute left-1/2 top-2.5 z-20 h-4 w-20 -translate-x-1/2 rounded-full bg-black/80" />
                <div className="flex h-full flex-col overflow-hidden rounded-[2rem] bg-white">
                  <div className="flex items-center justify-between px-4 pt-3.5 text-[10px] font-bold text-text-muted">
                    <span>9:41</span>
                    <div className="flex items-center gap-1">
                      <Signal className="h-3 w-3" />
                      <Wifi className="h-3 w-3" />
                      <Battery className="h-3.5 w-3.5" />
                    </div>
                  </div>

                  <div className="border-b border-border px-3.5 pb-2.5 pt-1.5">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <Image
                          src="/app-icon-192.png"
                          alt=""
                          width={18}
                          height={18}
                          className="rounded-[4px] object-cover"
                        />
                        <span className="text-xs font-extrabold text-primary">Vocal for Sanatan</span>
                      </div>
                      <span className="flex items-center gap-1 text-[10px] text-text-muted">
                        <MapPin className="h-3 w-3 text-primary" />
                        Bengaluru
                      </span>
                    </div>
                    <div className="flex items-center gap-2 rounded-xl border border-border bg-background-surface px-2.5 py-1.5 text-[10px] text-text-soft">
                      <Search className="h-3.5 w-3.5 text-primary" />
                      <span className="flex-1">Search business, category...</span>
                      <Mic className="h-3.5 w-3.5" />
                    </div>
                  </div>

                  <div className="flex-1 space-y-2.5 overflow-hidden bg-background-surface p-2.5">
                    <div className="flex gap-1.5">
                      {['Food', 'Retail', 'Services', 'Health'].map((c, i) => (
                        <span
                          key={c}
                          className={`rounded-full px-2 py-1 text-[9px] font-bold ${
                            i === 0
                              ? 'bg-primary/15 text-primary'
                              : 'border border-border bg-white text-text-muted'
                          }`}
                        >
                          {c}
                        </span>
                      ))}
                    </div>

                    <div className="rounded-2xl border border-border bg-white p-2 shadow-soft">
                      <div className="mb-1.5 flex aspect-[16/9] items-center justify-center rounded-xl bg-gradient-to-br from-primary/20 via-primary-glow/25 to-success/15">
                        <Image
                          src="/app-icon-192.png"
                          alt=""
                          width={40}
                          height={40}
                          className="rounded-lg object-cover shadow-soft"
                        />
                      </div>
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="text-[11px] font-bold text-text">Shree Balaji Sweets</p>
                          <p className="text-[9px] text-text-muted">Sweet Shop · 1.2 km</p>
                        </div>
                        <span className="inline-flex items-center gap-0.5 rounded-md bg-primary/10 px-1.5 py-0.5 text-[9px] font-black text-primary">
                          4.9 <Star className="h-2.5 w-2.5 fill-primary" />
                        </span>
                      </div>
                    </div>

                    <div className="rounded-2xl border border-primary/20 bg-white p-2.5 shadow-soft">
                      <div className="mb-1.5 flex items-center gap-2">
                        <span className="flex h-5 w-5 items-center justify-center rounded-md bg-primary/15 text-[8px] font-black text-primary">
                          AI
                        </span>
                        <span className="text-[10px] font-bold text-text">Sanatan AI</span>
                      </div>
                      <p className="rounded-xl bg-primary/5 px-2 py-1.5 text-[9px] leading-relaxed text-text">
                        Namaste! Looking for authentic sweets near you?
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-4 border-t border-border bg-white py-2 text-center text-[9px] font-bold text-text-soft">
                    <span className="text-primary">Explore</span>
                    <span>AI</span>
                    <span>Saved</span>
                    <span>Profile</span>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}
