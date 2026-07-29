import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'

export default function Terms() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Terms & Conditions"
            subtitle="Terms of Service"
            description="Last updated: January 2025"
            align="center"
          />
        </div>
      </section>

      <section className="py-20">
        <div className="container-custom max-w-4xl">
          <div className="prose prose-lg max-w-none">
            <h2>1. Acceptance of Terms</h2>
            <p>By accessing or using Vocal For Sanatan, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our service.</p>

            <h2>2. Changes to Terms</h2>
            <p>We reserve the right to modify these terms at any time. We will notify users of any material changes by posting the new terms on this page.</p>

            <h2>3. User Accounts</h2>
            <p>You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account or password.</p>

            <h2>4. Acceptable Use</h2>
            <p>You agree to use Vocal For Sanatan only for lawful purposes. You may not use the service to harass, abuse, or harm others, or to post or transmit any content that is illegal, harmful, or violates the rights of others.</p>

            <h2>5. Business Listings</h2>
            <p>Business owners are responsible for the accuracy of their listings. Vocal For Sanatan reserves the right to remove any listing that violates our policies or is deemed inappropriate.</p>

            <h2>7. Intellectual Property</h2>
            <p>All content on Vocal For Sanatan, including text, graphics, logos, and software, is the property of Vocal For Sanatan or its content suppliers and is protected by intellectual property laws.</p>

            <h2>8. Disclaimer of Warranties</h2>
            <p>Vocal For Sanatan is provided on an &quot;as is&quot; and &quot;as available&quot; basis. We make no warranties, expressed or implied, and hereby disclaim all warranties.</p>

            <h2>9. Limitation of Liability</h2>
            <p>In no event shall Vocal For Sanatan be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your access to or use of the service.</p>

            <h2>10. Governing Law</h2>
            <p>These terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.</p>

            <h2>11. Contact Information</h2>
            <p>For any questions regarding these terms, please contact us at legal@vocalforsanatan.com.</p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
