import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'

export default function Privacy() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Privacy Policy"
            subtitle="Your Privacy Matters"
            description="Last updated: January 2025"
            align="center"
          />
        </div>
      </section>

      <section className="py-20">
        <div className="container-custom max-w-4xl">
          <div className="prose prose-lg max-w-none">
            <h2>1. Information We Collect</h2>
            <p>Vocal For Sanatan collects information you provide directly to us, such as when you create an account, use our services, or communicate with us. This may include your name, email address, phone number, and any other information you choose to provide.</p>

            <h2>2. How We Use Your Information</h2>
            <p>We use the information we collect to provide, maintain, and improve our services, to process transactions and send you related information, to send you technical notices and support messages, and to respond to your comments and questions.</p>

            <h2>3. Information Sharing</h2>
            <p>We do not sell your personal information. We may share your information with third parties only in the circumstances described in this policy, such as with your consent, to comply with legal obligations, or to protect our rights.</p>

            <h2>4. Data Security</h2>
            <p>We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.</p>

            <h2>5. Your Rights</h2>
            <p>You have the right to access, correct, or delete your personal information. You may also opt out of certain communications from us. To exercise these rights, please contact us at privacy@vocalforsanatan.com.</p>

            <h2>6. Children&apos;s Privacy</h2>
            <p>Our services are not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.</p>

            <h2>7. Changes to This Policy</h2>
            <p>We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the &quot;Last updated&quot; date.</p>

            <h2>8. Contact Us</h2>
            <p>If you have any questions about this privacy policy, please contact us at privacy@vocalforsanatan.com.</p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
