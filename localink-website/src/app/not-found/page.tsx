'use client'

import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import { Home, ArrowLeft } from 'lucide-react'

export default function NotFound() {
  return (
    <main className="min-h-screen flex flex-col">
      <Navbar />
      
      <div className="flex-1 flex items-center justify-center py-20">
        <div className="container-custom text-center">
          <div className="max-w-md mx-auto">
            <h1 className="text-9xl font-bold gradient-text mb-4">404</h1>
            <h2 className="heading-lg mb-4">Page Not Found</h2>
            <p className="text-body mb-8">
              Sorry, we can&apos;t find the page you&apos;re looking for. The page might have been removed, renamed, or is temporarily unavailable.
            </p>
            <div className="flex gap-4 justify-center">
              <Link href="/">
                <button className="bg-primary text-white px-6 py-3 rounded-button font-bold shadow-button hover:shadow-lg transition-all flex items-center gap-2">
                  <Home className="w-5 h-5" />
                  Go Home
                </button>
              </Link>
              <button
                onClick={() => window.history.back()}
                className="border-2 border-primary text-primary px-6 py-3 rounded-button font-bold hover:bg-primary hover:text-white transition-all flex items-center gap-2"
              >
                <ArrowLeft className="w-5 h-5" />
                Go Back
              </button>
            </div>
          </div>
        </div>
      </div>

      <Footer />
    </main>
  )
}
