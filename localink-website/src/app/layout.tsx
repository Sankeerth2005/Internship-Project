import type { Metadata, Viewport } from 'next'
import { Fraunces, Manrope } from 'next/font/google'
import './globals.css'

const display = Fraunces({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
})

const body = Manrope({
  subsets: ['latin'],
  variable: '--font-body',
  display: 'swap',
})

export const metadata: Metadata = {
  metadataBase: new URL('https://vocalforsanatan.com'),
  title: {
    default: 'Vocal for Sanatan — Discover Local Businesses',
    template: '%s | Vocal for Sanatan',
  },
  description:
    'Vocal for Sanatan connects you with nearby businesses through AI search, maps, reviews, and direct chat. Download the Android app and grow your local community.',
  keywords: [
    'Vocal for Sanatan',
    'local business directory',
    'AI business search',
    'find shops near me',
    'business chat app',
    'India local commerce',
  ],
  authors: [{ name: 'Vocal for Sanatan' }],
  icons: {
    icon: [{ url: '/app-icon-192.png', type: 'image/png' }],
    apple: [{ url: '/app-icon.png' }],
    shortcut: '/favicon.png',
  },
  openGraph: {
    title: 'Vocal for Sanatan — Discover Local Businesses',
    description:
      'AI-powered local discovery, real-time chat with businesses, reviews, and maps — built for communities across India.',
    url: 'https://vocalforsanatan.com',
    siteName: 'Vocal for Sanatan',
    type: 'website',
    locale: 'en_IN',
    images: [{ url: '/app-icon.png', width: 1024, height: 1024, alt: 'Vocal for Sanatan' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Vocal for Sanatan',
    description: 'Discover and connect with local businesses near you.',
    images: ['/app-icon.png'],
  },
  robots: { index: true, follow: true },
  alternates: { canonical: 'https://vocalforsanatan.com' },
}

export const viewport: Viewport = {
  themeColor: '#FF6600',
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={`${display.variable} ${body.variable} font-sans`}>
        {children}
      </body>
    </html>
  )
}
