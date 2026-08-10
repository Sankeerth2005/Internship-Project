import type { Metadata, Viewport } from 'next'
import { Fraunces, Manrope } from 'next/font/google'
import JsonLd from '@/components/JsonLd'
import './globals.css'

const display = Fraunces({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
  weight: ['600', '700'],
  preload: true,
  adjustFontFallback: true,
})

const body = Manrope({
  subsets: ['latin'],
  variable: '--font-body',
  display: 'swap',
  weight: ['400', '500', '600', '700'],
  preload: true,
  adjustFontFallback: true,
})

export const metadata: Metadata = {
  metadataBase: new URL('https://vocalforsanatan.com'),
  title: {
    default: 'Vocal for Sanatan — Discover Local Businesses Near You',
    template: '%s | Vocal for Sanatan',
  },
  description:
    'Find trusted local businesses with AI search, live maps, reviews, and direct chat. Vocal for Sanatan connects customers and owners across India — free on Google Play.',
  keywords: [
    'Vocal for Sanatan',
    'local business directory India',
    'AI business search',
    'find shops near me',
    'business chat app',
    'verified local businesses',
    'neighbourhood discovery app',
  ],
  authors: [{ name: 'Vocal for Sanatan' }],
  creator: 'Vocal for Sanatan',
  publisher: 'Vocal for Sanatan',
  category: 'business',
  applicationName: 'Vocal for Sanatan',
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.png', type: 'image/png', sizes: '32x32' },
      { url: '/app-icon-192.png', type: 'image/png', sizes: '192x192' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
    shortcut: '/favicon.ico',
  },
  openGraph: {
    title: 'Vocal for Sanatan — Discover Local Businesses',
    description:
      'AI-powered local discovery, real-time chat with businesses, reviews, and maps — built for communities across India.',
    url: 'https://vocalforsanatan.com',
    siteName: 'Vocal for Sanatan',
    type: 'website',
    locale: 'en_IN',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'Vocal for Sanatan — Your neighbourhood, discovered',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Vocal for Sanatan — Discover Local Businesses',
    description: 'AI search, maps, reviews, and chat with local businesses near you.',
    images: ['/og-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  alternates: { canonical: 'https://vocalforsanatan.com' },
  verification: {},
}

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#FF6600' },
    { media: '(prefers-color-scheme: dark)', color: '#E55C00' },
  ],
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en-IN" className="scroll-smooth">
      <body className={`${display.variable} ${body.variable} font-sans`}>
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[100] focus:rounded-lg focus:bg-primary focus:px-4 focus:py-2 focus:text-sm focus:font-bold focus:text-white"
        >
          Skip to content
        </a>
        <JsonLd />
        {children}
      </body>
    </html>
  )
}
