import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import Hero from '@/sections/Hero'
import ValueStrip from '@/sections/ValueStrip'
import Features from '@/sections/Features'
import HowItWorks from '@/sections/HowItWorks'
import Categories from '@/sections/Categories'
import BusinessCTA from '@/sections/BusinessCTA'
import DownloadCTA from '@/sections/DownloadCTA'

export default function Home() {
  return (
    <main className="min-h-screen">
      <Navbar />
      <Hero />
      <ValueStrip />
      <Features />
      <HowItWorks />
      <Categories />
      <BusinessCTA />
      <DownloadCTA />
      <Footer />
    </main>
  )
}
