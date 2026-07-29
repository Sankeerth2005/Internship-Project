'use client'

import { motion } from 'framer-motion'
import { siteContent } from '@/constants/content'
import Button from '@/components/Button'
import { ArrowRight, Search, MapPin, Sparkles, Send, Mic, Battery, Wifi, Signal } from 'lucide-react'

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden mesh-gradient pt-36 pb-16 lg:pt-44 lg:pb-20">
      {/* Decorative Blur Spotlights */}
      <div className="absolute top-[20%] left-[-10%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-[100px] animate-pulse-slow pointer-events-none" />
      <div className="absolute bottom-[10%] right-[-10%] w-[600px] h-[600px] bg-primary-glow/10 rounded-full blur-[120px] animate-pulse-slow pointer-events-none" />

      <div className="container-custom relative z-10 w-full">
        <div className="grid lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          {/* Left Content */}
          <motion.div
            className="lg:col-span-7 text-center lg:text-left flex flex-col items-center lg:items-start"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <motion.div
              className="inline-flex items-center gap-2 px-4.5 py-2 rounded-full bg-primary/10 border border-primary/20 text-primary font-bold text-xs sm:text-sm mb-6 tracking-wide uppercase"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <Sparkles className="w-4 h-4 animate-bounce" />
              Coming Soon to iOS & Android
            </motion.div>
            
            <motion.h1
              className="heading-xl mb-6 leading-[1.1] tracking-tight max-w-2xl text-text font-black"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              Discover Local <span className="gradient-text">Businesses</span>, Connect with Your Community
            </motion.h1>
            
            <motion.p
              className="text-body text-text-muted mb-8 max-w-xl text-base sm:text-lg leading-relaxed font-medium"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              {siteContent.hero.subheadline}
            </motion.p>
            
            <motion.div
              className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              <Button variant="primary" size="lg" className="w-full sm:w-auto font-bold tracking-wide shadow-button hover:shadow-[0_0_30px_rgba(255,102,0,0.5)]">
                {siteContent.hero.ctaPrimary}
                <ArrowRight className="ml-2 w-5 h-5" />
              </Button>
              <Button variant="outline" size="lg" className="w-full sm:w-auto font-bold tracking-wide border-white/10 hover:border-primary/40 hover:bg-white/5">
                {siteContent.hero.ctaSecondary}
              </Button>
            </motion.div>
          </motion.div>

          <motion.div
            className="lg:col-span-5 flex justify-center w-full lg:pt-20"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <motion.div
              className="relative"
              animate={{ y: [0, -15, 0] }}
              transition={{
                duration: 6,
                repeat: Infinity,
                repeatType: 'reverse',
                ease: 'easeInOut'
              }}
            >
              {/* Phone Frame */}
              <div className="relative w-[300px] h-[610px] bg-[#161515] rounded-[3.2rem] p-3 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.9)] border border-white/10">
                {/* Dynamic Island Notch */}
                <div className="absolute top-4 left-1/2 -translate-x-1/2 w-28 h-6 bg-[#080707] rounded-full z-20 flex items-center justify-between px-3.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-blue-900/40 flex items-center justify-center">
                    <div className="w-1.5 h-1.5 rounded-full bg-blue-500/80" />
                  </div>
                  <div className="w-3.5 h-1 bg-white/20 rounded-full" />
                </div>
                
                {/* Phone screen container */}
                <div className="w-full h-full bg-[#0E0D0D] rounded-[2.8rem] overflow-hidden relative border border-white/5 flex flex-col text-white font-sans text-xs">
                  {/* Status Bar */}
                  <div className="h-10 pt-5 px-6 flex justify-between items-center text-[10px] text-text-muted font-bold z-10">
                    <div>9:41</div>
                    <div className="flex items-center gap-1">
                      <Signal className="w-3 h-3" />
                      <Wifi className="w-3 h-3" />
                      <Battery className="w-4 h-4" />
                    </div>
                  </div>

                  {/* App Header */}
                  <div className="px-4 py-3 border-b border-white/5 bg-[#121110]">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-extrabold text-sm tracking-tight text-primary">Vocal For Sanatan</span>
                      <div className="flex items-center gap-1 text-[10px] text-text-muted">
                        <MapPin className="w-3 h-3 text-primary" />
                        <span>Bengaluru, India</span>
                      </div>
                    </div>
                    {/* Search Bar */}
                    <div className="flex items-center gap-2 bg-[#1C1A1A] rounded-xl px-3 py-2 text-text-muted border border-white/5">
                      <Search className="w-3.5 h-3.5 text-text-muted" />
                      <span className="flex-1 text-[10px]">Search local services...</span>
                      <Mic className="w-3.5 h-3.5 text-text-muted cursor-pointer" />
                    </div>
                  </div>

                  {/* Scrollable Screen Content */}
                  <div className="flex-1 overflow-hidden p-3 space-y-3.5 bg-[#0A0909]">
                    {/* Category Chips */}
                    <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
                      <span className="bg-primary/20 border border-primary/40 text-primary font-bold px-3 py-1 rounded-full text-[9px] flex-shrink-0">🍽️ Food & Dining</span>
                      <span className="bg-[#151413] border border-white/5 text-text-muted font-medium px-3 py-1 rounded-full text-[9px] flex-shrink-0">🛍️ Retail Stores</span>
                      <span className="bg-[#151413] border border-white/5 text-text-muted font-medium px-3 py-1 rounded-full text-[9px] flex-shrink-0">🔧 Services</span>
                    </div>

                    {/* Featured Business Item */}
                    <div className="bg-[#121110] border border-white/5 rounded-2xl p-2.5 space-y-2">
                      <div className="aspect-video w-full rounded-xl bg-gradient-to-br from-primary/10 to-primary-glow/20 relative overflow-hidden flex items-center justify-center border border-white/5">
                        <span className="text-[10px] text-text-muted font-semibold">Store Preview Image</span>
                      </div>
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="font-bold text-[11px] text-text">Shree Balaji Sweets & Caterers</h4>
                          <p className="text-[9px] text-text-muted">Sweet Shop • 1.2 km away</p>
                        </div>
                        <span className="bg-primary/10 text-primary px-1.5 py-0.5 rounded font-black text-[9px]">4.9 ★</span>
                      </div>
                    </div>

                    {/* AI Chat Assistant Assistant widget */}
                    <div className="bg-[#121110] border border-primary/20 rounded-2xl p-3 space-y-2.5 relative">
                      <div className="absolute top-2 right-2 w-2 h-2 rounded-full bg-primary animate-ping" />
                      <div className="flex items-center gap-1.5">
                        <div className="w-5 h-5 rounded-lg bg-primary/20 flex items-center justify-center">
                          <span className="text-primary text-[8px] font-black">AI</span>
                        </div>
                        <span className="font-bold text-[10px] text-text">Sanatan AI Assistant</span>
                      </div>
                      <div className="space-y-1.5 text-[9px]">
                        <div className="bg-primary/5 border border-primary/10 rounded-xl p-2 text-text">
                          Namaste! Looking for authentic sweets or traditional handloom shops in your neighborhood?
                        </div>
                        <div className="bg-[#1C1A1A] border border-white/5 rounded-xl p-2 text-text-muted text-right ml-6">
                          Show me sweet shops.
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Navigation Bar */}
                  <div className="h-12 border-t border-white/5 bg-[#121110] flex items-center justify-around text-text-muted text-[9px] font-bold">
                    <span className="text-primary cursor-pointer">Explore</span>
                    <span className="cursor-pointer">AI Guide</span>
                    <span className="cursor-pointer">Saved</span>
                    <span className="cursor-pointer">Profile</span>
                  </div>
                </div>
              </div>

              {/* Decorative side cards floating */}
              <motion.div
                className="absolute -left-12 top-20 glass rounded-2xl p-3.5 shadow-floating border border-white/10"
                animate={{ y: [0, -8, 0] }}
                transition={{
                  duration: 4,
                  repeat: Infinity,
                  repeatType: 'reverse',
                  delay: 0.5,
                }}
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center shadow-inner">
                    <Sparkles className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <div className="font-bold text-xs text-text">AI Powered</div>
                    <div className="text-[10px] text-text-muted">Smart Discovery</div>
                  </div>
                </div>
              </motion.div>

              <motion.div
                className="absolute -right-12 bottom-20 glass rounded-2xl p-3.5 shadow-floating border border-white/10"
                animate={{ y: [0, 8, 0] }}
                transition={{
                  duration: 5,
                  repeat: Infinity,
                  repeatType: 'reverse',
                  delay: 0.7,
                }}
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-success/10 flex items-center justify-center">
                    <MapPin className="w-5 h-5 text-success" />
                  </div>
                  <div>
                    <div className="font-bold text-xs text-text">Direct Connect</div>
                    <div className="text-[10px] text-text-muted">Zero Middlemen</div>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
