'use client'

import { siteContent } from '@/constants/content'
import Button from '@/components/Button'
import { motion } from 'framer-motion'
import { Apple, Play, Mail } from "lucide-react"

export default function DownloadCTA() {
  return (
    <section className="py-24 lg:py-36 bg-[#0B0A0A] border-t border-white/5 relative overflow-hidden">
      {/* Ambient glowing spotlight */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-primary/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="container-custom relative z-10">
        <div className="text-center mb-16">
          <span className="text-primary font-bold text-sm uppercase tracking-wider mb-3.5 inline-block">Get the App</span>
          <h2 className="heading-lg mb-4 text-text">{siteContent.download.title}</h2>
          <p className="text-body max-w-xl mx-auto">{siteContent.download.subtitle}</p>
        </div>

        {/* App Store Badges */}
        <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-20">
          <motion.button
            className="flex items-center gap-3.5 bg-black/40 border border-white/10 hover:border-primary/20 text-white px-8 py-4.5 rounded-2xl hover:bg-black/60 transition-all opacity-70 cursor-not-allowed shadow-[0_4px_20px_rgba(0,0,0,0.4)]"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            disabled
          >
            <Apple className="w-8 h-8 text-primary" />
            <div className="text-left">
              <div className="text-xs opacity-70">Download on the</div>
              <div className="text-lg font-bold tracking-tight leading-tight">App Store</div>
              <div className="text-[10px] text-primary font-bold uppercase tracking-wider mt-0.5">Coming Soon</div>
            </div>
          </motion.button>

          <motion.button
            className="flex items-center gap-3.5 bg-black/40 border border-white/10 hover:border-primary/20 text-white px-8 py-4.5 rounded-2xl hover:bg-black/60 transition-all opacity-70 cursor-not-allowed shadow-[0_4px_20px_rgba(0,0,0,0.4)]"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            disabled
          >
            <Play className="w-8 h-8 text-primary" />
            <div className="text-left">
              <div className="text-xs opacity-70">GET IT ON</div>
              <div className="text-lg font-bold tracking-tight leading-tight">Google Play</div>
              <div className="text-[10px] text-primary font-bold uppercase tracking-wider mt-0.5">Coming Soon</div>
            </div>
          </motion.button>
        </div>

        {/* Email Signup Notification Card */}
        <motion.div
          className="max-w-xl mx-auto"
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
        >
          <div className="glass rounded-card p-10 border border-white/5 text-center shadow-floating relative overflow-hidden">
            {/* Background card accent glow */}
            <div className="absolute -top-12 -right-12 w-32 h-32 bg-primary/5 rounded-full blur-2xl pointer-events-none" />

            <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-6 border border-primary/20 shadow-inner">
              <Mail className="w-6 h-6 text-primary" />
            </div>
            <h3 className="heading-sm mb-3.5 text-text">{siteContent.download.notifyTitle}</h3>
            <p className="text-text-muted text-sm leading-relaxed mb-8 max-w-sm mx-auto font-medium">{siteContent.download.notifyDescription}</p>
            <form className="flex flex-col sm:flex-row gap-3">
              <input
                type="email"
                placeholder="Enter your email address"
                className="flex-1 px-4.5 py-3.5 rounded-input border border-white/10 bg-white/5 text-text focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent text-sm font-medium"
                aria-label="Email address"
                required
              />
              <Button type="submit" size="md" className="font-bold tracking-wide shadow-button hover:shadow-[0_0_20px_rgba(255,102,0,0.5)] py-3.5">
                Notify Me
              </Button>
            </form>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
