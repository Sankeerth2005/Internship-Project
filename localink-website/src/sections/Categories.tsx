'use client'

import { useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import {
  AirVent,
  Bike,
  BookOpen,
  Briefcase,
  Building2,
  Calculator,
  Cake,
  Car,
  CircleDot,
  Coffee,
  Droplets,
  Dumbbell,
  FileText,
  Flower2,
  Gem,
  Gift,
  GraduationCap,
  Hammer,
  Hand,
  Handshake,
  HeartPulse,
  Lamp,
  Languages,
  Microscope,
  Monitor,
  Music,
  Paintbrush,
  Pencil,
  Pill,
  Pizza,
  Sandwich,
  Scale,
  School,
  Scissors,
  Shield,
  Shirt,
  ShoppingBag,
  ShoppingCart,
  Smartphone,
  Smile,
  Soup,
  Sparkle,
  Sparkles,
  Gauge,
  Stethoscope,
  Truck,
  Utensils,
  UtensilsCrossed,
  Wrench,
  Zap,
  ChevronDown,
  X,
  type LucideIcon,
} from 'lucide-react'
import SectionHeader from '@/components/SectionHeader'
import Button from '@/components/Button'
import { catalogCategories } from '@/constants/catalog'
import { cn } from '@/lib/utils'

const iconMap: Record<string, LucideIcon> = {
  AirVent,
  Bike,
  BookOpen,
  Briefcase,
  Building2,
  Calculator,
  Cake,
  Car,
  CircleDot,
  Coffee,
  Droplets,
  Dumbbell,
  FileText,
  Flower2,
  Gem,
  Gift,
  GraduationCap,
  Hammer,
  Hand,
  Handshake,
  HeartPulse,
  Lamp,
  Languages,
  Microscope,
  Monitor,
  Music,
  Paintbrush,
  Pencil,
  Pill,
  Pizza,
  Sandwich,
  Scale,
  School,
  Scissors,
  Shield,
  Shirt,
  ShoppingBag,
  ShoppingCart,
  Smartphone,
  Smile,
  Soup,
  Sparkle,
  Sparkles,
  Gauge,
  Stethoscope,
  Truck,
  Utensils,
  UtensilsCrossed,
  Wrench,
  Zap,
}

function resolveIcon(name: string): LucideIcon {
  return iconMap[name] ?? Sparkles
}

export default function Categories() {
  const [activeId, setActiveId] = useState<string | null>(null)

  const active = useMemo(
    () => catalogCategories.find((c) => c.id === activeId) ?? null,
    [activeId]
  )

  function toggle(id: string) {
    setActiveId((prev) => (prev === id ? null : id))
  }

  return (
    <section id="categories" className="section-pad bg-white relative overflow-hidden">
      <div className="pointer-events-none absolute inset-y-0 right-0 w-1/3 bg-gradient-to-l from-primary/5 to-transparent" />
      <div className="container-custom relative">
        <div className="mb-10 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <SectionHeader
            eyebrow="Browse"
            title="Explore categories"
            description="Tap a category to see its subcategories — just like in the app."
            align="left"
            className="max-w-xl"
          />
        </div>

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {catalogCategories.map((item, i) => {
            const Icon = resolveIcon(item.icon)
            const isActive = activeId === item.id
            return (
              <motion.button
                key={item.id}
                type="button"
                initial={false}
                onClick={() => toggle(item.id)}
                aria-expanded={isActive}
                aria-controls="category-subcategories"
                className={cn(
                  'group flex items-center gap-3 rounded-2xl border px-4 py-4 text-left transition-all',
                  isActive
                    ? 'border-primary bg-primary/5 shadow-soft ring-2 ring-primary/20'
                    : 'border-border bg-background-surface hover:border-primary/40 hover:bg-white hover:shadow-soft'
                )}
                style={{ transitionDelay: `${i * 20}ms` }}
              >
                <span
                  className={cn(
                    'flex h-11 w-11 shrink-0 items-center justify-center rounded-xl transition-colors',
                    isActive
                      ? 'bg-primary text-white'
                      : 'bg-primary/10 text-primary group-hover:bg-primary group-hover:text-white'
                  )}
                >
                  <Icon className="h-5 w-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <h3 className="truncate font-display text-base font-bold text-text">{item.name}</h3>
                  <p className="truncate text-xs text-text-muted">{item.description}</p>
                </div>
                <ChevronDown
                  className={cn(
                    'h-4 w-4 shrink-0 text-text-soft transition-transform',
                    isActive && 'rotate-180 text-primary'
                  )}
                />
              </motion.button>
            )
          })}
        </div>

        <AnimatePresence mode="wait">
          {active && (
            <motion.div
              key={active.id}
              id="category-subcategories"
              initial={{ opacity: 0, height: 0, y: -8 }}
              animate={{ opacity: 1, height: 'auto', y: 0 }}
              exit={{ opacity: 0, height: 0, y: -8 }}
              transition={{ duration: 0.28 }}
              className="overflow-hidden"
            >
              <div className="mt-5 rounded-3xl border border-primary/20 bg-gradient-to-br from-primary/5 via-white to-background-surface p-5 sm:p-6 shadow-soft">
                <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    {(() => {
                      const ActiveIcon = resolveIcon(active.icon)
                      return (
                        <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-white">
                          <ActiveIcon className="h-5 w-5" />
                        </span>
                      )
                    })()}
                    <div>
                      <p className="text-xs font-bold uppercase tracking-[0.16em] text-primary">
                        Subcategories
                      </p>
                      <h4 className="font-display text-xl font-bold text-text">{active.name}</h4>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setActiveId(null)}
                    className="inline-flex items-center gap-1.5 rounded-full border border-border bg-white px-3 py-1.5 text-xs font-bold text-text-muted hover:text-primary"
                  >
                    <X className="h-3.5 w-3.5" />
                    Close
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3 lg:grid-cols-6">
                  {active.subcategories.map((sub, idx) => {
                    const SubIcon = resolveIcon(sub.icon)
                    return (
                      <motion.div
                        key={sub.name}
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: idx * 0.03 }}
                        className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-white px-3 py-4 text-center shadow-sm transition hover:border-primary/35 hover:shadow-soft"
                      >
                        <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary/10 text-primary">
                          <SubIcon className="h-5 w-5" />
                        </span>
                        <span className="text-xs font-bold text-text leading-snug">{sub.name}</span>
                      </motion.div>
                    )
                  })}
                </div>

                <div className="mt-5 flex flex-wrap items-center gap-3">
                  <Button href="/download" size="md">
                    Explore in the app
                  </Button>
                  <p className="text-xs text-text-soft">
                    {active.subcategories.length} subcategories in {active.name}
                  </p>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  )
}
