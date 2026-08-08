import type { MetadataRoute } from 'next'

const base = 'https://vocalforsanatan.com'

export default function sitemap(): MetadataRoute.Sitemap {
  const routes = [
    '',
    '/about',
    '/features',
    '/business',
    '/download',
    '/support',
    '/contact',
    '/faq',
    '/privacy',
    '/terms',
    '/delete-account',
  ]

  return routes.map((path) => ({
    url: `${base}${path}`,
    lastModified: new Date('2026-08-08'),
    changeFrequency: path === '' ? 'weekly' : 'monthly',
    priority: path === '' ? 1 : path === '/privacy' || path === '/delete-account' ? 0.9 : 0.7,
  }))
}
