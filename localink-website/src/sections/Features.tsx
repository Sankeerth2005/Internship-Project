'use client'

import { siteContent } from '@/constants/content'
import SectionHeader from '@/components/SectionHeader'
import { Search, MessageCircle, Star, MapPin, BarChart3, Globe } from 'lucide-react'
import { motion } from 'framer-motion'

const iconMap = {
  Search,
  MessageCircle,
  Star,
  MapPin,
  BarChart3,
  Globe,
}

export default function Features() {
  return (
    <section className="py-24 lg:py-36 bg-[#0B0A0A] border-t border-b border-white/5 relative overflow-hidden">
      {/* Decorative background light */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-primary/5 rounded-full blur-[120px] pointer-events-none" />

      <div className="container-custom relative z-10">
        <SectionHeader
          title={siteContent.features.title}
          subtitle="Core Features"
          align="center"
        />

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {siteContent.features.items.map((feature, index) => {
            const Icon = iconMap[feature.icon as keyof typeof iconMap]
            return (
              <motion.div
                key={index}
                className="group p-8 rounded-card glass hover:glass-glow hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.08 }}
              >
                {/* Glow Spotlight Behind Icon */}
                <div className="absolute top-0 left-0 w-24 h-24 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors duration-300" />

                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-primary-glow flex items-center justify-center mb-6 shadow-[0_4px_15px_rgba(255,102,0,0.35)] group-hover:scale-105 group-hover:rotate-3 transition-all duration-300 relative z-10">
                  <Icon className="w-7 h-7 text-white" />
                </div>
                <h3 className="heading-sm mb-3.5 group-hover:text-primary transition-colors">{feature.title}</h3>
                <p className="text-text-muted text-sm leading-relaxed font-medium">{feature.description}</p>
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
