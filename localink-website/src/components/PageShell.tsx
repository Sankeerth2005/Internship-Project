import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import Button from '@/components/Button'

interface PageShellProps {
  eyebrow?: string
  title: string
  description?: string
  children: React.ReactNode
  ctaHref?: string
  ctaLabel?: string
}

export default function PageShell({
  eyebrow,
  title,
  description,
  children,
  ctaHref,
  ctaLabel,
}: PageShellProps) {
  return (
    <main className="min-h-screen">
      <Navbar />
      <section className="atmosphere grain pt-28 pb-10 relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0 mesh-grid opacity-60" aria-hidden />
        <div className="container-custom relative">
          <SectionHeader eyebrow={eyebrow} title={title} description={description} align="left" className="max-w-3xl" />
          {ctaHref && ctaLabel && (
            <div className="mt-6">
              <Button href={ctaHref} size="lg">
                {ctaLabel}
              </Button>
            </div>
          )}
        </div>
      </section>
      {children}
      <Footer />
    </main>
  )
}
