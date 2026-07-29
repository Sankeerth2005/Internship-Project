'use client'

import { siteContent } from '@/constants/content'
import SectionHeader from '@/components/SectionHeader'
import Button from '@/components/Button'
import { Building2, ArrowRight, BarChart3, TrendingUp, Star, Users } from 'lucide-react'
import { motion } from 'framer-motion'

export default function BusinessCTA() {
  return (
    <section className="py-24 lg:py-36 bg-[#080707] relative overflow-hidden">
      {/* Decorative spotlights */}
      <div className="absolute top-[20%] right-[-5%] w-[500px] h-[500px] bg-primary/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="container-custom relative z-10">
        <div className="grid lg:grid-cols-12 gap-16 items-center">
          {/* Left Content */}
          <motion.div
            className="lg:col-span-7"
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
          >
            <SectionHeader
              title={siteContent.business.title}
              subtitle={siteContent.business.subtitle}
              align="left"
            />

            <ul className="space-y-4.5 mb-10">
              {siteContent.business.benefits.map((benefit, index) => (
                <li key={index} className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-success/10 flex items-center justify-center flex-shrink-0 mt-1 border border-success/30 shadow-[inset_0_0_6px_rgba(52,199,89,0.1)]">
                    <div className="w-2.5 h-2.5 rounded-full bg-success" />
                  </div>
                  <span className="text-text-muted text-sm sm:text-base leading-relaxed font-medium">{benefit}</span>
                </li>
              ))}
            </ul>

            <div className="flex flex-col sm:flex-row gap-4">
              <Button variant="primary" size="lg" className="w-full sm:w-auto font-bold tracking-wide shadow-button hover:shadow-[0_0_25px_rgba(255,102,0,0.5)]">
                {siteContent.business.ctaTitle}
                <ArrowRight className="ml-2 w-5 h-5" />
              </Button>
              <Button variant="outline" size="lg" className="w-full sm:w-auto font-bold tracking-wide border-white/10 hover:border-primary/40 hover:bg-white/5">
                Learn More
              </Button>
            </div>
          </motion.div>

          {/* Right Content - Simulated Admin Dashboard Mockup */}
          <motion.div
            className="lg:col-span-5 w-full"
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
          >
            <div className="glass rounded-card p-6 shadow-floating border border-white/10 relative overflow-hidden">
              {/* Dashboard Ambient Light */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 rounded-full blur-2xl pointer-events-none" />

              <div className="flex items-center gap-3 mb-6 pb-4 border-b border-white/5">
                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20">
                  <Building2 className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <h3 className="font-display font-bold text-sm text-text">Vocal For Sanatan Dashboard</h3>
                  <p className="text-[10px] text-text-muted font-medium">Partner Portal</p>
                </div>
              </div>

              {/* Statistics Row */}
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="bg-[#121110] border border-white/5 rounded-xl p-3.5 space-y-1">
                  <div className="flex items-center justify-between text-[10px] text-text-muted">
                    <span>Profile Views</span>
                    <TrendingUp className="w-3.5 h-3.5 text-success" />
                  </div>
                  <div className="font-display font-bold text-lg text-text">1,248</div>
                  <div className="text-[9px] text-success font-semibold">+18.4% this week</div>
                </div>

                <div className="bg-[#121110] border border-white/5 rounded-xl p-3.5 space-y-1">
                  <div className="flex items-center justify-between text-[10px] text-text-muted">
                    <span>Direct Leads</span>
                    <Users className="w-3.5 h-3.5 text-primary" />
                  </div>
                  <div className="font-display font-bold text-lg text-text">84</div>
                  <div className="text-[9px] text-primary font-semibold">+12.6% this week</div>
                </div>
              </div>

              {/* Simulated Customer Reviews Box */}
              <div className="bg-[#121110] border border-white/5 rounded-xl p-3.5 space-y-3">
                <div className="flex justify-between items-center text-[10px]">
                  <span className="font-bold text-text-muted">Recent Customer Reviews</span>
                  <span className="text-primary font-bold">View All</span>
                </div>

                <div className="space-y-2">
                  <div className="bg-[#1C1A1A] border border-white/5 rounded-lg p-2.5 space-y-1 text-[9px]">
                    <div className="flex justify-between items-center">
                      <span className="font-bold text-text">Aman Sharma</span>
                      <div className="flex text-primary gap-0.5 font-bold">★★★★★</div>
                    </div>
                    <p className="text-text-muted leading-relaxed font-medium">
                      &quot;Excellent sweets and highly professional service. Direct delivery options made it very easy!&quot;
                    </p>
                  </div>
                </div>
              </div>

              {/* Action Buttons Mockup */}
              <div className="mt-6 flex gap-3 text-[10px] font-bold">
                <span className="flex-1 bg-primary text-white py-2 rounded-lg text-center cursor-pointer hover:bg-primary-glow transition-all">Edit Listing</span>
                <span className="flex-1 border border-white/10 text-text-muted py-2 rounded-lg text-center cursor-pointer hover:bg-white/5 transition-all">Analytics</span>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
