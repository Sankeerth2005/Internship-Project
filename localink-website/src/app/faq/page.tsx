'use client'

import { useState } from 'react'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { ChevronDown, ChevronUp } from 'lucide-react'

const faqs = [
  {
    question: 'What is Vocal For Sanatan?',
    answer: 'Vocal For Sanatan is AI-powered platform that connects users with local businesses through intelligent search, real-time communication, and authentic reviews. It helps users discover quality local services while enabling businesses to reach their community effectively.',
  },
  {
    question: 'How do I download the Vocal For Sanatan app?',
    answer: 'The Vocal For Sanatan app is coming soon to iOS and Android. Sign up for our newsletter on the Download page to be notified when the app launches in your region.',
  },
  {
    question: 'Is Vocal For Sanatan free to use?',
    answer: 'Yes, Vocal For Sanatan is completely free for users to discover and connect with businesses. Business owners can also create basic listings for free. Premium features for businesses will be available in the future.',
  },
  {
    question: 'How does the AI search work?',
    answer: 'Our AI-powered search understands natural language queries and provides personalized recommendations based on your preferences, location, and search history. It learns from your interactions to deliver increasingly relevant results.',
  },
  {
    question: 'Can I chat with business owners directly?',
    answer: 'Yes! Vocal For Sanatan features real-time messaging that allows you to chat directly with business owners. You can send text messages, voice notes, and get quick responses to your queries.',
  },
  {
    question: 'How are reviews verified?',
    answer: 'We use AI-powered verification to ensure reviews are from genuine users who have actually interacted with the business. Our system detects and filters out fake or spam reviews to maintain trust and authenticity.',
  },
  {
    question: 'How do I create a business listing?',
    answer: 'Download the Vocal For Sanatan app and navigate to the "For Business Owners" section. Follow the simple registration process to add your business details, photos, and services. Your listing will be live after verification.',
  },
  {
    question: 'Can I edit my business listing?',
    answer: 'Absolutely! Business owners have full control over their listings. You can update your business information, add photos, change services, and manage your profile at any time through the business dashboard.',
  },
  {
    question: 'What languages does Vocal For Sanatan support?',
    answer: 'Vocal For Sanatan supports multiple languages with real-time translation. Currently, we support English, Hindi, and several regional Indian languages. We are continuously adding more languages based on user demand.',
  },
  {
    question: 'How does location-based discovery work?',
    answer: 'Vocal For Sanatan uses your device location to show businesses near you. You can also search by pincode or city. The app displays distance from your location and allows you to filter results by proximity.',
  },
  {
    question: 'Is my data secure on Vocal For Sanatan?',
    answer: 'Yes, we take data security seriously. We use enterprise-grade encryption to protect your personal information. We do not sell your data to third parties and follow strict privacy protocols to ensure your information remains secure.',
  },
  {
    question: 'How do I report inappropriate content?',
    answer: 'If you encounter inappropriate content, use the report feature within the app or email us at support@vocalforsanatan.com. Our team reviews all reports and takes appropriate action to maintain a safe and respectful community.',
  },
]

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null)

  const toggleFAQ = (index: number) => {
    setOpenIndex(openIndex === index ? null : index)
  }

  return (
    <main className="min-h-screen">
      <Navbar />
      
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Frequently Asked Questions"
            subtitle="Got Questions?"
            description="Find answers to common questions about Vocal For Sanatan. Can't find what you're looking for? Contact our support team."
            align="center"
          />
        </div>
      </section>

      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="max-w-3xl mx-auto space-y-4">
            {faqs.map((faq, index) => (
              <GlassCard key={index} className="overflow-hidden">
                <button
                  onClick={() => toggleFAQ(index)}
                  className="w-full flex items-center justify-between p-6 text-left focus:outline-none"
                  aria-expanded={openIndex === index}
                >
                  <span className="font-semibold text-lg">{faq.question}</span>
                  {openIndex === index ? (
                    <ChevronUp className="w-5 h-5 text-primary flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-primary flex-shrink-0" />
                  )}
                </button>
                {openIndex === index && (
                  <div className="px-6 pb-6">
                    <p className="text-text-muted">{faq.answer}</p>
                  </div>
                )}
              </GlassCard>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20">
        <div className="container-custom">
          <div className="max-w-2xl mx-auto text-center">
            <GlassCard>
              <h3 className="heading-md mb-4">Still Have Questions?</h3>
              <p className="text-body mb-8">
                Our support team is here to help you with any questions or concerns.
              </p>
              <div className="flex gap-4 justify-center">
                <button className="bg-primary text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-lg transition-all">
                  Contact Support
                </button>
                <button className="border-2 border-primary text-primary px-6 py-3 rounded-button font-bold hover:bg-primary hover:text-white transition-all">
                  Visit Help Center
                </button>
              </div>
            </GlassCard>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
