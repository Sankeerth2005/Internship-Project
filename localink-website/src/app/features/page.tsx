import type { Metadata } from 'next'
import PageShell from '@/components/PageShell'
import Features from '@/sections/Features'
import HowItWorks from '@/sections/HowItWorks'

export const metadata: Metadata = {
  title: 'Features',
  description: 'AI search, maps, chat, reviews, voice, and owner analytics in Vocal for Sanatan.',
  alternates: { canonical: 'https://vocalforsanatan.com/features' },
}

export default function FeaturesPage() {
  return (
    <PageShell
      eyebrow="Product"
      title="Built for discovery and connection"
      description="Everything customers and business owners need to find each other nearby."
      ctaHref="/download"
      ctaLabel="Get the app"
    >
      <Features />
      <HowItWorks />
    </PageShell>
  )
}
