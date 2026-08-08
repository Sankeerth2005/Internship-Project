'use client'

import { motion } from 'framer-motion'
import { Search, MessageCircle, Star, MapPin, BarChart3, Mic, type LucideIcon } from 'lucide-react'
import SectionHeader from '@/components/SectionHeader'
import { siteContent } from '@/constants/content'

const iconMap: Record<string, LucideIcon> = {
  Search,
  MessageCircle,
  Star,
  MapPin,
  BarChart3,
  Mic,
}

export default function Features() {
  const items = siteContent.features.items

  return (
    <section id="features" className="section-pad relative bg-white overflow-hidden">
      <div
        className="pointer-events-none absolute -left-20 top-20 h-64 w-64 rounded-full bg-primary/5 blur-3xl"
        aria-hidden
      />
      <div className="container-custom relative">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between mb-10">
          <SectionHeader
            eyebrow="Core features"
            title={siteContent.features.title}
            description={siteContent.features.subtitle}
            align="left"
            className="max-w-2xl"
          />
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {items.map((item, i) => {
            const Icon = iconMap[item.icon] ?? Search
            const featured = i === 0
            return (
              <motion.article
                key={item.title}
                initial={{ opacity: 0, y: 14 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-30px' }}
                transition={{ delay: i * 0.04, duration: 0.35 }}
                className={`group relative overflow-hidden rounded-3xl border border-border p-5 lg:p-6 transition-all duration-300 hover:-translate-y-1 hover:border-primary/35 hover:shadow-lift ${
                  featured
                    ? 'md:col-span-2 xl:col-span-1 bg-gradient-to-br from-primary/10 via-white to-primary-glow/10'
                    : 'bg-background-surface hover:bg-white'
                }`}
              >
                <span className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary transition-colors group-hover:bg-primary group-hover:text-white">
                  <Icon className="h-5 w-5" />
                </span>
                <h3 className="font-display text-xl font-bold text-text">{item.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-text-muted">{item.description}</p>
              </motion.article>
            )
          })}
        </div>
      </div>
    </section>
  )
}
