export interface Feature {
  icon: string
  title: string
  description: string
}

export interface Step {
  step: string
  description: string
}

export interface Statistic {
  value: string
  label: string
}

export interface Testimonial {
  quote: string
  name: string
  role: string
  location: string
  rating: number
}

export interface Category {
  name: string
  description: string
}

export interface NavigationItem {
  name: string
  href: string
  icon?: string
}

export interface Screenshot {
  id: string
  title: string
  description: string
  dimensions: string
  altText: string
}
