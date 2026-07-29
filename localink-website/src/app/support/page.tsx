import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { Mail, HelpCircle, Bug, MessageSquare } from 'lucide-react'

export default function Support() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Support Center"
            subtitle="We're Here to Help"
            description="Get the help you need with our comprehensive support resources."
            align="center"
          />
        </div>
      </section>

      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
            <GlassCard className="text-center cursor-pointer hover:border-primary transition-colors">
              <Mail className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Email Support</h3>
              <p className="text-sm text-text-muted">support@vocalforsanatan.com</p>
            </GlassCard>
            <GlassCard className="text-center cursor-pointer hover:border-primary transition-colors">
              <HelpCircle className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Help Center</h3>
              <p className="text-sm text-text-muted">Browse articles</p>
            </GlassCard>
            <GlassCard className="text-center cursor-pointer hover:border-primary transition-colors">
              <Bug className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Report a Bug</h3>
              <p className="text-sm text-text-muted">Submit issue</p>
            </GlassCard>
            <GlassCard className="text-center cursor-pointer hover:border-primary transition-colors">
              <MessageSquare className="w-12 h-12 text-primary mx-auto mb-4" />
              <h3 className="font-semibold mb-2">Live Chat</h3>
              <p className="text-sm text-text-muted">Coming Soon</p>
            </GlassCard>
          </div>

          <div className="max-w-3xl mx-auto">
            <GlassCard>
              <h3 className="heading-md mb-6">Frequently Asked Questions</h3>
              
              <div className="space-y-6">
                <div>
                  <h4 className="font-semibold mb-2">How do I create a business listing?</h4>
                  <p className="text-text-muted">To create a business listing, download the Vocal For Sanatan app and navigate to the &quot;For Business Owners&quot; section. Follow the registration process to add your business details.</p>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2">Is Vocal For Sanatan free to use?</h4>
                  <p className="text-text-muted">Yes, Vocal For Sanatan is free for users to discover and connect with businesses. Business owners can also create basic listings for free.</p>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2">How are reviews verified?</h4>
                  <p className="text-text-muted">We use AI-powered verification to ensure reviews are from genuine users. Our system detects and filters out fake or spam reviews.</p>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2">Can I edit my business listing?</h4>
                  <p className="text-text-muted">Yes, business owners can edit their listings at any time through the business dashboard in the app.</p>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2">How do I report inappropriate content?</h4>
                  <p className="text-text-muted">Use the report feature within the app or email us at support@vocalforsanatan.com with details about the inappropriate content.</p>
                </div>
              </div>
            </GlassCard>
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="container-custom">
          <div className="max-w-2xl mx-auto text-center">
            <h3 className="heading-md mb-4">Still Need Help?</h3>
            <p className="text-body mb-8">
              Our support team is available to assist you with any questions or issues you may have.
            </p>
            <form className="space-y-4">
              <input
                type="email"
                placeholder="Your email address"
                className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                aria-label="Email address"
              />
              <textarea
                placeholder="Describe your issue"
                rows={4}
                className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                aria-label="Issue description"
              />
              <button type="submit" className="w-full bg-primary text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-lg transition-all">
                Submit Request
              </button>
            </form>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
