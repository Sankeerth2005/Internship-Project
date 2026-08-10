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
    <>
      <Navbar />
      <main id="main-content" className="min-h-screen">
        <Hero />
        <ValueStrip />
        <Features />
        <HowItWorks />
        <Categories />
        <BusinessCTA />
        <DownloadCTA />
      </main>
      <Footer />
    </>
  )
}
