'use client'

import { siteContent } from '@/constants/content'
import SectionHeader from '@/components/SectionHeader'
import { ArrowRight, Building2, Users } from 'lucide-react'
import { motion } from 'framer-motion'

export default function HowItWorks() {
  return (
    <section className="py-24 lg:py-36 bg-[#080707] relative overflow-hidden" id="how-it-works">
      {/* Decorative spotlights */}
      <div className="absolute top-[10%] left-[-5%] w-[450px] h-[450px] bg-primary/5 rounded-full blur-[90px] pointer-events-none" />
      <div className="absolute bottom-[10%] right-[-5%] w-[450px] h-[450px] bg-primary-glow/5 rounded-full blur-[90px] pointer-events-none" />

      <div className="container-custom relative z-10">
        <SectionHeader
          title={siteContent.howItWorks.title}
          subtitle="Process Walkthrough"
          align="center"
        />

        {/* For Users */}
        <div className="mb-24">
          <div className="flex items-center justify-center gap-3 mb-14">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <Users className="w-5 h-5 text-primary" />
            </div>
            <h3 className="heading-md">For Customers</h3>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {siteContent.howItWorks.userSteps.map((step, index) => (
              <motion.div
                key={index}
                className="relative"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
              >
                <div className="h-full p-8 rounded-card glass hover:glass-glow hover:-translate-y-1 transition-all duration-300 relative flex flex-col justify-between">
                  <div className="flex items-start gap-4">
                    {/* Number box */}
                    <div className="w-11 h-11 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0 border border-primary/20 text-primary font-black text-sm shadow-[inset_0_0_10px_rgba(255,102,0,0.1)]">
                      {index + 1}
                    </div>
                    <div>
                      <h4 className="heading-sm mb-2.5 text-text group-hover:text-primary transition-colors">{step.step}</h4>
                      <p className="text-text-muted text-sm leading-relaxed font-medium">{step.description}</p>
                    </div>
                  </div>
                </div>
                
                {index < siteContent.howItWorks.userSteps.length - 1 && (
                  <div className="hidden md:flex absolute top-1/2 -right-6 -translate-y-1/2 z-10">
                    <ArrowRight className="w-7 h-7 text-primary/30 animate-pulse" />
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>

        {/* For Business Owners */}
        <div>
          <div className="flex items-center justify-center gap-3 mb-14">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <Building2 className="w-5 h-5 text-primary" />
            </div>
            <h3 className="heading-md">For Business Owners</h3>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {siteContent.howItWorks.businessSteps.map((step, index) => (
              <motion.div
                key={index}
                className="relative"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
              >
                <div className="h-full p-8 rounded-card glass hover:glass-glow hover:-translate-y-1 transition-all duration-300 relative flex flex-col justify-between">
                  <div className="flex items-start gap-4">
                    {/* Number box */}
                    <div className="w-11 h-11 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0 border border-primary/20 text-primary font-black text-sm shadow-[inset_0_0_10px_rgba(255,102,0,0.1)]">
                      {index + 1}
                    </div>
                    <div>
                      <h4 className="heading-sm mb-2.5 text-text group-hover:text-primary transition-colors">{step.step}</h4>
                      <p className="text-text-muted text-sm leading-relaxed font-medium">{step.description}</p>
                    </div>
                  </div>
                </div>
                
                {index < siteContent.howItWorks.businessSteps.length - 1 && (
                  <div className="hidden md:flex absolute top-1/2 -right-6 -translate-y-1/2 z-10">
                    <ArrowRight className="w-7 h-7 text-primary/30 animate-pulse" />
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
