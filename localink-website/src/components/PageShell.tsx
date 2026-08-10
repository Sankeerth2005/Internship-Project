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
    <>
      <Navbar />
      <main id="main-content" className="min-h-screen">
        <section className="relative overflow-hidden bg-[#F7F2EC] pb-10 pt-28">
          <div className="container-custom relative">
            <SectionHeader
              eyebrow={eyebrow}
              title={title}
              description={description}
              align="left"
              className="max-w-3xl"
            />
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
      </main>
      <Footer />
    </>
  )
}
