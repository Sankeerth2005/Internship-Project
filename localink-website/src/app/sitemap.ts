import type { MetadataRoute } from 'next'

const base = 'https://vocalforsanatan.com'

export default function sitemap(): MetadataRoute.Sitemap {
  const routes: { path: string; priority: number; changeFrequency: MetadataRoute.Sitemap[0]['changeFrequency'] }[] = [
    { path: '', priority: 1, changeFrequency: 'weekly' },
    { path: '/features', priority: 0.9, changeFrequency: 'monthly' },
    { path: '/business', priority: 0.9, changeFrequency: 'monthly' },
    { path: '/download', priority: 0.95, changeFrequency: 'weekly' },
    { path: '/about', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/support', priority: 0.8, changeFrequency: 'monthly' },
    { path: '/contact', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/faq', priority: 0.75, changeFrequency: 'monthly' },
    { path: '/privacy', priority: 0.9, changeFrequency: 'yearly' },
    { path: '/terms', priority: 0.85, changeFrequency: 'yearly' },
    { path: '/delete-account', priority: 0.9, changeFrequency: 'yearly' },
  ]

  const now = new Date()

  return routes.map(({ path, priority, changeFrequency }) => ({
    url: `${base}${path}`,
    lastModified: now,
    changeFrequency,
    priority,
  }))
}
