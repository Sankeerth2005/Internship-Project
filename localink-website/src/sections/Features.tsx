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
    <section id="features" className="section-pad relative overflow-hidden bg-white">
      <div className="container-custom relative">
        <div className="mb-10">
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
              <article
                key={item.title}
                className={`group relative overflow-hidden rounded-3xl border border-border p-5 transition-all duration-200 hover:-translate-y-0.5 hover:border-primary/35 hover:shadow-lift lg:p-6 ${
                  featured
                    ? 'bg-gradient-to-br from-primary/10 via-white to-primary-glow/10 md:col-span-2 xl:col-span-1'
                    : 'bg-background-surface hover:bg-white'
                }`}
              >
                <span className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary transition-colors group-hover:bg-primary group-hover:text-white">
                  <Icon className="h-5 w-5" aria-hidden />
                </span>
                <h3 className="font-display text-xl font-bold text-text">{item.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-text-muted">{item.description}</p>
              </article>
            )
          })}
        </div>
      </div>
    </section>
  )
}
