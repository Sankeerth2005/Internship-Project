import Link from 'next/link'
import Button from '@/components/Button'

export default function NotFound() {
  return (
    <main className="min-h-screen atmosphere grain flex items-center justify-center px-5">
      <div className="max-w-md text-center">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-primary">404</p>
        <h1 className="mt-3 font-display text-4xl font-bold text-text">Page not found</h1>
        <p className="mt-3 text-text-muted">
          That link may have moved. Head home or open support.
        </p>
        <div className="mt-8 flex flex-col sm:flex-row gap-3 justify-center">
          <Button href="/" size="lg">
            Go home
          </Button>
          <Button href="/support" variant="outline" size="lg">
            Support
          </Button>
        </div>
        <p className="mt-6 text-xs text-text-soft">
          <Link href="/privacy" className="hover:text-primary">
            Privacy
          </Link>
          {' · '}
          <Link href="/terms" className="hover:text-primary">
            Terms
          </Link>
        </p>
      </div>
    </main>
  )
}
