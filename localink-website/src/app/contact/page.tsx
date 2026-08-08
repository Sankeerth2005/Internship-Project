import type { Metadata } from 'next'
import ContactForm from '@/components/ContactForm'
import PageShell from '@/components/PageShell'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Contact',
  description: 'Contact Vocal for Sanatan support and partnerships.',
  alternates: { canonical: 'https://vocalforsanatan.com/contact' },
}

export default function ContactPage() {
  return (
    <PageShell
      eyebrow="Contact"
      title="Talk to us"
      description={`Prefer email? Reach ${site.supportEmail} anytime.`}
    >
      <section className="pb-24">
        <div className="container-custom max-w-xl">
          <ContactForm />
        </div>
      </section>
    </PageShell>
  )
}
