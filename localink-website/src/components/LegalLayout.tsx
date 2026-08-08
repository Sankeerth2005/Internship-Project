import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'

interface LegalLayoutProps {
  title: string
  eyebrow: string
  updated: string
  children: React.ReactNode
}

export default function LegalLayout({ title, eyebrow, updated, children }: LegalLayoutProps) {
  return (
    <main className="min-h-screen">
      <Navbar />
      <section className="atmosphere grain pt-28 pb-8">
        <div className="container-custom max-w-3xl">
          <p className="mb-2 text-xs font-bold uppercase tracking-[0.2em] text-primary">{eyebrow}</p>
          <h1 className="heading-lg">{title}</h1>
          <p className="mt-2 text-sm text-text-soft">Last updated: {updated}</p>
        </div>
      </section>
      <section className="pb-16">
        <div className="container-custom max-w-3xl">
          <article className="legal-prose rounded-card border border-border bg-white p-5 sm:p-8 shadow-soft">
            {children}
          </article>
          <p className="mt-8 text-sm text-text-muted">
            Related:{' '}
            <Link href="/privacy" className="text-primary font-semibold">
              Privacy
            </Link>
            {' · '}
            <Link href="/terms" className="text-primary font-semibold">
              Terms
            </Link>
            {' · '}
            <Link href="/delete-account" className="text-primary font-semibold">
              Delete account
            </Link>
            {' · '}
            <Link href="/support" className="text-primary font-semibold">
              Support
            </Link>
          </p>
        </div>
      </section>
      <Footer />
    </main>
  )
}
