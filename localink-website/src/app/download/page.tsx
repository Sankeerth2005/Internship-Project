import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { siteContent } from '@/constants/content'
import { Apple, Mail, CheckCircle, Smartphone, QrCode, Play } from 'lucide-react'

export default function Download() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      {/* Hero Section */}
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Download Vocal For Sanatan"
            subtitle="Get the App"
            description="Experience the future of local business discovery. Download Vocal For Sanatan on your favorite device."
            align="center"
          />
        </div>
      </section>

      {/* App Store Badges */}
      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="text-center mb-12">
            <h2 className="heading-lg mb-4">{siteContent.download.title}</h2>
            <p className="text-body">{siteContent.download.subtitle}</p>
          </div>

          <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-16">
            {/* iOS Badge */}
            <div className="glass rounded-card p-8 text-center w-full max-w-sm">
              <Apple className="w-16 h-16 text-primary mx-auto mb-4" />
              <h3 className="heading-md mb-2">iOS App Store</h3>
              <p className="text-text-muted mb-4">Coming Soon</p>
              <button className="w-full bg-black text-white px-6 py-4 rounded-xl opacity-50 cursor-not-allowed flex items-center justify-center gap-3">
                <Apple className="w-8 h-8" />
                <div className="text-left">
                  <div className="text-xs opacity-80">Download on the</div>
                  <div className="text-lg font-semibold">App Store</div>
                </div>
              </button>
            </div>

            {/* Android Badge */}
            <div className="glass rounded-card p-8 text-center w-full max-w-sm">
              <Play className="w-16 h-16 text-primary mx-auto mb-4" />
              <h3 className="heading-md mb-2">Google Play</h3>
              <p className="text-text-muted mb-4">Coming Soon</p>
              <button className="w-full bg-black text-white px-6 py-4 rounded-xl opacity-50 cursor-not-allowed flex items-center justify-center gap-3">
                <Play className="w-8 h-8" />
                <div className="text-left">
                  <div className="text-xs opacity-80">GET IT ON</div>
                  <div className="text-lg font-semibold">Google Play</div>
                </div>
              </button>
            </div>
          </div>

          {/* Features List */}
          <div className="max-w-2xl mx-auto">
            <GlassCard>
              <h3 className="heading-md mb-6 text-center">App Features</h3>
              <ul className="space-y-4">
                {[
                  'AI-powered business search',
                  'Real-time chat with businesses',
                  'Location-based discovery',
                  'Multi-language support',
                  'Business analytics dashboard',
                  'Verified reviews and ratings',
                ].map((feature, index) => (
                  <li key={index} className="flex items-center gap-3">
                    <CheckCircle className="w-5 h-5 text-success flex-shrink-0" />
                    <span className="text-text-muted">{feature}</span>
                  </li>
                ))}
              </ul>
            </GlassCard>
          </div>
        </div>
      </section>

      {/* Email Signup */}
      <section className="py-20">
        <div className="container-custom">
          <div className="max-w-md mx-auto">
            <GlassCard className="text-center">
              <Mail className="w-16 h-16 text-primary mx-auto mb-4" />
              <h3 className="heading-md mb-2">{siteContent.download.notifyTitle}</h3>
              <p className="text-text-muted mb-6">{siteContent.download.notifyDescription}</p>
              <form className="space-y-4">
                <input
                  type="email"
                  placeholder="Enter your email address"
                  className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                  aria-label="Email address"
                />
                <button type="submit" className="w-full bg-primary text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-lg transition-all">
                  Notify Me
                </button>
              </form>
            </GlassCard>
          </div>
        </div>
      </section>

      {/* Version Info */}
      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            <GlassCard className="text-center">
              <Smartphone className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Version</h3>
              <p className="text-text-muted">1.0.0 (Coming Soon)</p>
            </GlassCard>
            <GlassCard className="text-center">
              <QrCode className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">QR Code</h3>
              <p className="text-text-muted">Scan to download</p>
            </GlassCard>
            <GlassCard className="text-center">
              <CheckCircle className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Requirements</h3>
              <p className="text-text-muted">iOS 14+ / Android 8+</p>
            </GlassCard>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
