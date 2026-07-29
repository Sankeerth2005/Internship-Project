'use client'

import Link from 'next/link'
import { navigation } from '@/constants/navigation'
import { siteContent } from '@/constants/content'
import { cn } from '@/lib/utils'
import { motion } from 'framer-motion'

export default function Footer() {
  return (
    <footer className="bg-[#0B0A0A] border-t border-white/5 relative overflow-hidden">
      {/* Footer Ambient Light */}
      <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[500px] h-[150px] bg-primary/10 rounded-full blur-[80px] pointer-events-none" />

      <div className="container-custom py-16 lg:py-24 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-12">
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link href="/" className="flex items-center gap-2.5 mb-6 group">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-primary-glow flex items-center justify-center shadow-[0_0_20px_rgba(255,102,0,0.35)] group-hover:scale-105 transition-all">
                <span className="text-white font-black text-xl">V</span>
              </div>
              <span className="text-xl font-display font-extrabold text-text tracking-tight group-hover:text-primary transition-colors">
                Vocal For Sanatan
              </span>
            </Link>
            <p className="text-text-muted mb-6 max-w-sm leading-relaxed text-sm">
              The all-in-one platform that connects users with local businesses through intelligent search and real-time communication.
            </p>
          </div>

          {/* Company Links */}
          <div>
            <h3 className="font-display font-bold text-text mb-5 text-sm uppercase tracking-wider">{siteContent.footer.company.title}</h3>
            <ul className="space-y-3.5">
              {navigation.footer.company.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-text-muted hover:text-text text-sm transition-colors font-medium"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Product Links */}
          <div>
            <h3 className="font-display font-bold text-text mb-5 text-sm uppercase tracking-wider">{siteContent.footer.product.title}</h3>
            <ul className="space-y-3.5">
              {navigation.footer.product.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-text-muted hover:text-text text-sm transition-colors font-medium"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h3 className="font-display font-bold text-text mb-5 text-sm uppercase tracking-wider">{siteContent.footer.legal.title}</h3>
            <ul className="space-y-3.5">
              {navigation.footer.legal.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-text-muted hover:text-text text-sm transition-colors font-medium"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Newsletter */}
        <div className="mt-16 pt-12 border-t border-white/5">
          <div className="grid lg:grid-cols-2 gap-8 items-center">
            <div>
              <h3 className="font-display font-bold text-text mb-2 text-lg">{siteContent.footer.newsletter.title}</h3>
              <p className="text-text-muted text-sm leading-relaxed max-w-md">{siteContent.footer.newsletter.description}</p>
            </div>
            <form className="flex flex-col sm:flex-row gap-3 w-full max-w-md lg:ml-auto">
              <input
                type="email"
                placeholder="Enter your email"
                className="flex-1 px-4 py-3 rounded-input border border-white/10 bg-white/5 text-text focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent text-sm"
                aria-label="Email address"
                required
              />
              <motion.button
                type="submit"
                className="bg-primary hover:bg-primary-glow text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-[0_0_20px_rgba(255,102,0,0.5)] transition-all text-sm"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Subscribe
              </motion.button>
            </form>
          </div>
        </div>

        {/* Copyright */}
        <div className="mt-16 pt-8 border-t border-white/5 text-center text-text-muted text-xs font-medium">
          <p>{siteContent.footer.copyright}</p>
        </div>
      </div>
    </footer>
  )
}
