'use client'

import { useState } from 'react'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import SectionHeader from '@/components/SectionHeader'
import GlassCard from '@/components/GlassCard'
import { Mail, MapPin, Phone, Building2 } from 'lucide-react'

export default function Contact() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: '',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // Handle form submission (frontend only)
    console.log('Form submitted:', formData)
    alert('Thank you for your message! We will get back to you soon.')
    setFormData({ name: '', email: '', subject: '', message: '' })
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    })
  }

  return (
    <main className="min-h-screen">
      <Navbar />
      
      <section className="pt-32 pb-20 mesh-gradient">
        <div className="container-custom">
          <SectionHeader
            title="Contact Us"
            subtitle="Get in Touch"
            description="Have questions or feedback? We'd love to hear from you."
            align="center"
          />
        </div>
      </section>

      <section className="py-20 bg-surface">
        <div className="container-custom">
          <div className="grid lg:grid-cols-2 gap-12">
            {/* Contact Form */}
            <div>
              <GlassCard>
                <h3 className="heading-md mb-6">Send us a Message</h3>
                <form onSubmit={handleSubmit} className="space-y-6">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium mb-2">
                      Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                      className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                      placeholder="Your name"
                    />
                  </div>
                  
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium mb-2">
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                      placeholder="your@email.com"
                    />
                  </div>
                  
                  <div>
                    <label htmlFor="subject" className="block text-sm font-medium mb-2">
                      Subject
                    </label>
                    <input
                      type="text"
                      id="subject"
                      name="subject"
                      value={formData.subject}
                      onChange={handleChange}
                      required
                      className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                      placeholder="How can we help?"
                    />
                  </div>
                  
                  <div>
                    <label htmlFor="message" className="block text-sm font-medium mb-2">
                      Message
                    </label>
                    <textarea
                      id="message"
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      required
                      rows={5}
                      className="w-full px-4 py-3 rounded-input border border-border bg-white focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                      placeholder="Your message..."
                    />
                  </div>
                  
                  <button
                    type="submit"
                    className="w-full bg-primary text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-lg transition-all"
                  >
                    Send Message
                  </button>
                </form>
              </GlassCard>
            </div>

            {/* Contact Information */}
            <div className="space-y-6">
              <GlassCard>
                <h3 className="heading-md mb-6">Contact Information</h3>
                
                <div className="space-y-6">
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <Mail className="w-6 h-6 text-primary" />
                    </div>
                    <div>
                      <h4 className="font-semibold mb-1">Email</h4>
                      <p className="text-text-muted">contact@vocalforsanatan.com</p>
                      <p className="text-text-muted">support@vocalforsanatan.com</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <Phone className="w-6 h-6 text-primary" />
                    </div>
                    <div>
                      <h4 className="font-semibold mb-1">Phone</h4>
                      <p className="text-text-muted">+91 123 456 7890</p>
                      <p className="text-sm text-text-muted">Mon-Fri, 9am-6pm IST</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <MapPin className="w-6 h-6 text-primary" />
                    </div>
                    <div>
                      <h4 className="font-semibold mb-1">Location</h4>
                      <p className="text-text-muted">Bangalore, India</p>
                      <p className="text-sm text-text-muted">Remote team worldwide</p>
                    </div>
                  </div>
                </div>
              </GlassCard>

              <GlassCard>
                <h3 className="heading-md mb-4">Business Inquiries</h3>
                <p className="text-text-muted mb-4">
                  For partnership opportunities, business listings, or enterprise solutions, reach out to our business team.
                </p>
                <div className="flex items-center gap-3">
                  <Building2 className="w-6 h-6 text-primary" />
                  <span className="text-text-muted">business@vocalforsanatan.com</span>
                </div>
              </GlassCard>

            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
