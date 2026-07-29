'use client'

import { siteContent } from '@/constants/content'
import SectionHeader from '@/components/SectionHeader'
import { Utensils, ShoppingBag, Heart, Wrench, Car, GraduationCap, Briefcase, Music, Plane, Scissors } from 'lucide-react'
import { motion } from 'framer-motion'

const iconMap = {
  'Restaurants & Cafes': Utensils,
  'Shopping & Retail': ShoppingBag,
  'Health & Wellness': Heart,
  'Home Services': Wrench,
  'Automotive': Car,
  'Education': GraduationCap,
  'Professional Services': Briefcase,
  'Entertainment': Music,
  'Travel & Tourism': Plane,
  'Beauty & Fashion': Scissors,
}

export default function Categories() {
  return (
    <section className="py-24 lg:py-36 bg-[#0B0A0A]/50 border-t border-b border-white/5 relative overflow-hidden">
      {/* Background ambient glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-primary/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="container-custom relative z-10">
        <SectionHeader
          title={siteContent.categories.title}
          subtitle="Explore Options"
          align="center"
        />

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
          {siteContent.categories.items.map((category, index) => {
            const Icon = iconMap[category.name as keyof typeof iconMap] || ShoppingBag
            return (
              <motion.div
                key={index}
                className="group p-6.5 rounded-card glass hover:glass-glow hover:-translate-y-1.5 transition-all duration-300 relative text-center cursor-pointer flex flex-col justify-between"
                initial={{ opacity: 0, scale: 0.95 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.05 }}
              >
                <div>
                  <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-5 border border-primary/20 shadow-[inset_0_0_10px_rgba(255,102,0,0.05)] group-hover:bg-primary group-hover:scale-105 group-hover:rotate-3 transition-all duration-300">
                    <Icon className="w-7 h-7 text-primary group-hover:text-white transition-colors" />
                  </div>
                  <h4 className="font-display font-bold text-text mb-2 text-sm sm:text-base group-hover:text-primary transition-colors">{category.name}</h4>
                  <p className="text-xs text-text-muted leading-relaxed font-medium">{category.description}</p>
                </div>
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
