export const siteContent = {
  hero: {
    brand: 'Vocal for Sanatan',
    headline: 'Your neighbourhood, discovered.',
    subheadline:
      'Find trusted local businesses with AI search, maps, reviews, and direct chat — no middlemen.',
    ctaPrimary: 'Get the app',
    ctaSecondary: 'List your business',
  },
  features: {
    title: 'Everything local, in one place',
    subtitle: 'Built for customers and business owners who want a direct connection.',
    items: [
      {
        icon: 'Search',
        title: 'AI-powered search',
        description:
          'Ask in natural language. Our assistant understands what you need and surfaces nearby matches.',
      },
      {
        icon: 'MessageCircle',
        title: 'Chat with owners',
        description:
          'Message businesses in real time — text or voice — and get answers without phone tag.',
      },
      {
        icon: 'Star',
        title: 'Authentic reviews',
        description:
          'Read experiences from real customers and share yours to help the community choose wisely.',
      },
      {
        icon: 'MapPin',
        title: 'Near you on the map',
        description:
          'Location-aware discovery with distance sorting so you find what is actually close.',
      },
      {
        icon: 'BarChart3',
        title: 'Owner insights',
        description:
          'Track profile views, leads, and engagement so you know what is working for your listing.',
      },
      {
        icon: 'Mic',
        title: 'Voice-first access',
        description:
          'Search and interact hands-free with voice input and spoken feedback when you need it.',
      },
    ],
  },
  howItWorks: {
    title: 'How it works',
    userSteps: [
      {
        step: 'Discover',
        description: 'Search by category, area, or ask the AI guide for what you need nearby.',
      },
      {
        step: 'Connect',
        description: 'Open a listing, check hours and reviews, then chat with the owner directly.',
      },
      {
        step: 'Engage',
        description: 'Save favourites, leave reviews, and keep your local circle growing.',
      },
    ],
    businessSteps: [
      {
        step: 'Register',
        description: 'Create your profile with photos, hours, location, and contact details.',
      },
      {
        step: 'Manage',
        description: 'Update listings, reply to customers, and keep your presence current.',
      },
      {
        step: 'Grow',
        description: 'Use analytics and reviews to attract more of the right customers.',
      },
    ],
  },
  categories: {
    title: 'Explore categories',
    items: [
      { name: 'Food & dining', description: 'Restaurants, cafés, sweets' },
      { name: 'Shopping', description: 'Retail & local markets' },
      { name: 'Health', description: 'Clinics, gyms, wellness' },
      { name: 'Home services', description: 'Repairs & maintenance' },
      { name: 'Automotive', description: 'Service & parts' },
      { name: 'Education', description: 'Tutors & centres' },
      { name: 'Professionals', description: 'Legal, finance, consulting' },
      { name: 'Beauty', description: 'Salons & fashion' },
    ],
  },
  download: {
    title: 'Get Vocal for Sanatan',
    subtitle: 'Available on Google Play. iOS coming soon.',
  },
  business: {
    title: 'Grow with Vocal for Sanatan',
    subtitle: 'Reach customers who are already looking for businesses like yours.',
    benefits: [
      'Show up when neighbours search for your category',
      'Chat directly with interested customers',
      'Build trust with photos, hours, and reviews',
      'Understand engagement with simple analytics',
    ],
  },
  footer: {
    copyright: '© 2026 Vocal for Sanatan. All rights reserved.',
  },
} as const
