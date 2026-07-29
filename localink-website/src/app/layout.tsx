import type { Metadata } from 'next'
import { Inter, Plus_Jakarta_Sans } from 'next/font/google'
import './globals.css'

const inter = Inter({ 
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

const plusJakartaSans = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-plus-jakarta-sans',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'Vocal For Sanatan - Discover Local Businesses | AI-Powered Business Directory',
  description: 'Find and connect with local businesses using Vocal For Sanatan\'s AI-powered platform. Search, chat, and review businesses in your area. Download the app coming soon to iOS and Android.',
  keywords: 'local business directory, find local businesses, business search app, AI business recommendations, local services, business reviews, chat with businesses, mobile business app',
  openGraph: {
    title: 'Vocal For Sanatan - Discover Local Businesses',
    description: 'The all-in-one platform connecting users with local businesses through intelligent search and real-time communication.',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Vocal For Sanatan - Discover Local Businesses',
    description: 'The all-in-one platform connecting users with local businesses through intelligent search and real-time communication.',
  },
  robots: {
    index: true,
    follow: true,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark scroll-smooth">
      <body className={`${inter.variable} ${plusJakartaSans.variable} font-sans bg-background text-text antialiased`}>
        {children}
      </body>
    </html>
  )
}
