import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { motion } from 'framer-motion'
import { Target, Heart, Users, Zap } from 'lucide-react'

export default function About() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      {/* Hero Section */}
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="About Vocal For Sanatan"
            subtitle="Our Mission"
            description="Connecting communities through technology, one local business at a time."
            align="center"
          />
        </div>
      </section>

      {/* Mission Section */}
      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="heading-lg mb-6">Our Mission</h2>
              <p className="text-body mb-6">
                Vocal For Sanatan was founded with a simple yet powerful vision: to bridge the gap between local businesses and their communities. We believe that every local business deserves to be discovered, and every community member deserves easy access to quality local services.
              </p>
              <p className="text-body mb-6">
                By leveraging cutting-edge AI technology and intuitive design, we&apos;re creating a platform that makes local discovery effortless, authentic, and meaningful for everyone involved.
              </p>
            </div>
            <div className="grid grid-cols-2 gap-6">
              <GlassCard className="text-center">
                <Target className="w-12 h-12 text-primary mx-auto mb-4" />
                <h3 className="font-semibold mb-2">Mission</h3>
                <p className="text-sm text-text-muted">Empower local businesses</p>
              </GlassCard>
              <GlassCard className="text-center">
                <Heart className="w-12 h-12 text-primary mx-auto mb-4" />
                <h3 className="font-semibold mb-2">Values</h3>
                <p className="text-sm text-text-muted">Community first</p>
              </GlassCard>
              <GlassCard className="text-center">
                <Users className="w-12 h-12 text-primary mx-auto mb-4" />
                <h3 className="font-semibold mb-2">Community</h3>
                <p className="text-sm text-text-muted">500+ cities</p>
              </GlassCard>
              <GlassCard className="text-center">
                <Zap className="w-12 h-12 text-primary mx-auto mb-4" />
                <h3 className="font-semibold mb-2">Innovation</h3>
                <p className="text-sm text-text-muted">AI-powered</p>
              </GlassCard>
            </div>
          </div>
        </div>
      </section>

      {/* Story Section */}
      <section className="py-20">
        <div className="container-custom">
          <SectionHeader
            title="Our Story"
            align="center"
          />
          <div className="max-w-3xl mx-auto">
            <p className="text-body mb-6">
              Vocal For Sanatan started as a simple observation: while global platforms have made it easy to discover products from anywhere, finding quality local services remained surprisingly difficult. Business owners struggled to get discovered, and community members wasted time searching through outdated directories.
            </p>
            <p className="text-body mb-6">
              We asked ourselves: What if there was a platform that understood both sides of this equation? A platform that used intelligent search to help users find exactly what they needed, while giving businesses the tools they needed to connect with their community effectively.
            </p>
            <p className="text-body">
              Today, Vocal For Sanatan is that platform. We&apos;ve grown from a small idea to a growing community of thousands of businesses and tens of thousands of users, but our core mission remains the same: to strengthen local communities through better connections.
            </p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
