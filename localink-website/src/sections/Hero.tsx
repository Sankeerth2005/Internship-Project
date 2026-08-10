import Image from 'next/image'
import { ArrowRight } from 'lucide-react'
import Button from '@/components/Button'
import StoreBadges from '@/components/StoreBadges'
import { siteContent } from '@/constants/content'

export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-[#F7F2EC] pt-20" aria-labelledby="hero-heading">
      <div className="mx-auto w-full max-w-[1100px] px-3 sm:px-5 lg:px-6">
        <div className="relative overflow-hidden rounded-2xl shadow-soft sm:rounded-3xl">
          <Image
            src="/images/marketing/hero-banner.webp"
            alt="Vocal for Sanatan — your neighbourhood, discovered with AI search, live maps, verified businesses, and smart support"
            width={1600}
            height={1065}
            className="block h-auto w-full select-none"
            priority
            fetchPriority="high"
            quality={85}
            sizes="(max-width: 1100px) 100vw, 1100px"
          />
        </div>
      </div>

      <div className="mt-4 border-t border-border/60 bg-white sm:mt-6">
        <div className="container-custom flex flex-col items-center justify-between gap-4 py-5 sm:flex-row sm:py-6">
          <div className="min-w-0 flex-1 text-center sm:text-left">
            <h1 id="hero-heading" className="heading-md text-balance sm:text-3xl lg:text-4xl">
              Your neighbourhood,{' '}
              <span className="text-primary">discovered.</span>
            </h1>
            <p className="mt-2 max-w-xl text-sm text-text-muted sm:text-base">
              {siteContent.hero.subheadline}
            </p>
          </div>
          <div className="flex flex-col items-center gap-3 sm:items-end">
            <div className="flex flex-col gap-3 sm:flex-row">
              <Button href="/download" size="lg">
                {siteContent.hero.ctaPrimary}
                <ArrowRight className="h-5 w-5" aria-hidden />
              </Button>
              <Button href="/business" variant="outline" size="lg">
                {siteContent.hero.ctaSecondary}
              </Button>
            </div>
            <StoreBadges
              size="md"
              playHref="https://play.google.com/store/apps/details?id=com.vocalforsanatan.app"
            />
          </div>
        </div>
      </div>
    </section>
  )
}
