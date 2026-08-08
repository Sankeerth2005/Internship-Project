'use client'

import Link from 'next/link'
import { ButtonHTMLAttributes, ReactNode } from 'react'
import { cn } from '@/lib/utils'

type Variant = 'primary' | 'secondary' | 'outline' | 'ghost'
type Size = 'sm' | 'md' | 'lg'

const variants: Record<Variant, string> = {
  primary:
    'bg-primary text-white shadow-button hover:bg-primary-dark hover:-translate-y-0.5',
  secondary:
    'bg-background-surface text-text border border-border hover:border-primary/40 hover:bg-white',
  outline:
    'border-2 border-primary/30 text-primary bg-white/70 hover:border-primary hover:bg-primary/5',
  ghost: 'text-text-muted hover:text-primary hover:bg-primary/5',
}

const sizes: Record<Size, string> = {
  sm: 'px-4 py-2 text-sm',
  md: 'px-6 py-3 text-sm sm:text-base',
  lg: 'px-8 py-3.5 text-base',
}

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
  href?: string
  children: ReactNode
}

export default function Button({
  className,
  variant = 'primary',
  size = 'md',
  href,
  children,
  ...props
}: ButtonProps) {
  const classes = cn(
    'inline-flex items-center justify-center gap-2 font-bold rounded-button transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-50',
    variants[variant],
    sizes[size],
    className
  )

  if (href) {
    return (
      <Link href={href} className={classes}>
        {children}
      </Link>
    )
  }

  return (
    <button className={classes} {...props}>
      {children}
    </button>
  )
}
