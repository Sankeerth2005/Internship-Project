'use client'

import { motion } from 'framer-motion'

const values = [
  { hi: 'धर्म', en: 'Dharma' },
  { hi: 'संस्कृति', en: 'Sanskriti' },
  { hi: 'सेवा', en: 'Seva' },
  { hi: 'स्वदेशी', en: 'Swadeshi' },
  { hi: 'समृद्धि', en: 'Samriddhi' },
]

export default function ValueStrip() {
  return (
    <section className="relative border-y border-border bg-[#1A1918] overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(255,102,0,0.18),transparent_60%)]" />
      <div className="container-custom relative z-10 py-6 lg:py-7">
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 lg:gap-4">
          {values.map((v, i) => (
            <motion.div
              key={v.en}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.04 }}
              className="rounded-2xl border border-white/10 bg-white/5 px-3 py-4 text-center backdrop-blur-sm"
            >
              <p className="font-display text-xl lg:text-2xl font-bold text-primary-glow">{v.hi}</p>
              <p className="mt-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/55">
                {v.en}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
