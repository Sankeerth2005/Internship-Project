import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { siteContent } from '@/constants/content'
import { Search, MessageCircle, Star, MapPin, BarChart3, Globe, Shield, Zap, Smartphone } from 'lucide-react'

const iconMap = {
  Search,
  MessageCircle,
  Star,
  MapPin,
  BarChart3,
  Globe,
  Shield,
  Zap,
  Smartphone,
}

const extendedFeatures = [
  ...siteContent.features.items,
  {
    icon: 'Shield',
    title: 'Secure & Private',
    description: 'Your data security is our priority. We use enterprise-grade encryption and follow strict privacy protocols to protect your information.',
  },
  {
    icon: 'Zap',
    title: 'Lightning Fast',
    description: 'Experience blazing-fast performance with our optimized infrastructure. Search, chat, and discover without any delays.',
  },
  {
    icon: 'Smartphone',
    title: 'Mobile First',
    description: 'Designed for mobile from the ground up. Enjoy a seamless experience whether you are on a phone, tablet, or desktop.',
  },
]

export default function Features() {
  return (
    <main className="min-h-screen">
      <Navbar />
      
      {/* Hero Section */}
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Features"
            subtitle="Powerful Capabilities"
            description="Everything you need to discover and connect with local businesses, all in one platform."
            align="center"
          />
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {extendedFeatures.map((feature, index) => {
              const Icon = iconMap[feature.icon as keyof typeof iconMap]
              return (
                <GlassCard key={index}>
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-primary-glow flex items-center justify-center mb-4">
                    <Icon className="w-7 h-7 text-white" />
                  </div>
                  <h3 className="heading-sm mb-3">{feature.title}</h3>
                  <p className="text-text-muted">{feature.description}</p>
                </GlassCard>
              )
            })}
          </div>
        </div>
      </section>

      {/* Feature Highlight */}
      <section className="py-20">
        <div className="container-custom">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <SectionHeader
                title="AI-Powered Intelligence"
                subtitle="Smart Search"
                align="left"
              />
              <p className="text-body mb-6">
                Our AI engine understands natural language queries, context, and preferences to deliver highly relevant results. Whether you&apos;re searching for a specific service or exploring options, Vocal For Sanatan&apos;s intelligent search helps you find exactly what you need.
              </p>
              <ul className="space-y-3">
                {[
                  'Natural language understanding',
                  'Personalized recommendations',
                  'Context-aware results',
                  'Continuous learning',
                ].map((item, index) => (
                  <li key={index} className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded-full bg-success/20 flex items-center justify-center">
                      <div className="w-3 h-3 rounded-full bg-success" />
                    </div>
                    <span className="text-text-muted">{item}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="glass rounded-card p-8 shadow-floating">
              <div className="aspect-video bg-gradient-to-br from-primary/10 to-primary-glow/10 rounded-lg flex items-center justify-center">
                <p className="text-text-muted">AI Search Interface Screenshot</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
