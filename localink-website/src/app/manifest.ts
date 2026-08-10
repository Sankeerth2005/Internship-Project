import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Vocal for Sanatan',
    short_name: 'Vocal',
    description: 'Discover and connect with local businesses near you.',
    start_url: '/',
    display: 'standalone',
    background_color: '#F9F8F6',
    theme_color: '#FF6600',
    lang: 'en-IN',
    icons: [
      {
        src: '/app-icon-192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'any',
      },
      {
        src: '/apple-touch-icon.png',
        sizes: '180x180',
        type: 'image/png',
      },
    ],
  }
}
