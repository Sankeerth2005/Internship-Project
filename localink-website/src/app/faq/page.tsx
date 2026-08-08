import type { Metadata } from 'next'
import PageShell from '@/components/PageShell'
import FaqList from '@/components/FaqList'

export const metadata: Metadata = {
  title: 'FAQ',
  description: 'Frequently asked questions about Vocal for Sanatan.',
  alternates: { canonical: 'https://vocalforsanatan.com/faq' },
}

export default function FaqPage() {
  return (
    <PageShell
      eyebrow="FAQ"
      title="Frequently asked questions"
      description="Short answers to common questions."
    >
      <section className="pb-24">
        <FaqList />
      </section>
    </PageShell>
  )
}
