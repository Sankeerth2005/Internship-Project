'use client'

import { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { motion } from 'framer-motion'

interface SectionHeaderProps {
  title: string
  subtitle?: string
  description?: string
  className?: string
  align?: 'left' | 'center' | 'right'
}

export default function SectionHeader({ title, subtitle, description, className, align = 'center' }: SectionHeaderProps) {
  const alignClasses = {
    left: 'text-left',
    center: 'text-center',
    right: 'text-right',
  }

  return (
    <motion.div
      className={cn('mb-12', alignClasses[align], className)}
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.5 }}
    >
      {subtitle && (
        <motion.span
          className="inline-block text-primary font-semibold text-sm uppercase tracking-wider mb-3"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.1 }}
        >
          {subtitle}
        </motion.span>
      )}
      <h2 className="heading-lg mb-4">{title}</h2>
      {description && (
        <motion.p
          className="text-body max-w-2xl mx-auto"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2 }}
        >
          {description}
        </motion.p>
      )}
    </motion.div>
  )
}
