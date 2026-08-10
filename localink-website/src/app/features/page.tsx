import type { Metadata } from 'next'
import Image from 'next/image'
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
      title="Smart. Simple. Personal."
      description="Everything you need, made for you — discover, chat, and manage your local world in one app."
      ctaHref="/download"
      ctaLabel="Get the app"
    >
      <section className="pb-10">
        <div className="mx-auto w-full max-w-[1100px] px-3 sm:px-5 lg:px-6">
          <div className="overflow-hidden rounded-2xl border border-border bg-[#F7F2EC] shadow-soft sm:rounded-3xl">
            <Image
              src="/images/marketing/features-showcase.webp"
              alt="Vocal for Sanatan app screens — home, business details, AI chat, and profile"
              width={1600}
              height={1065}
              className="block h-auto w-full select-none"
              quality={85}
              sizes="(max-width: 1100px) 100vw, 1100px"
              priority
            />
          </div>
        </div>
      </section>
      <Features />
      <HowItWorks />
    </PageShell>
  )
}
