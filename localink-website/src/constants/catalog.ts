export type CatalogCategory = {
  id: string
  name: string
  description: string
  icon: string
  subcategories: { name: string; icon: string }[]
}

/** Marketing catalog aligned with Vocal for Sanatan category naming. */
export const catalogCategories: CatalogCategory[] = [
  {
    id: 'food',
    name: 'Food & dining',
    description: 'Restaurants, cafés, sweets',
    icon: 'Utensils',
    subcategories: [
      { name: 'Restaurants', icon: 'UtensilsCrossed' },
      { name: 'Cafés & tea', icon: 'Coffee' },
      { name: 'Sweets & bakery', icon: 'Cake' },
      { name: 'Fast food', icon: 'Pizza' },
      { name: 'Catering', icon: 'Soup' },
      { name: 'Street food', icon: 'Sandwich' },
    ],
  },
  {
    id: 'shopping',
    name: 'Shopping & retail',
    description: 'Retail & local markets',
    icon: 'ShoppingBag',
    subcategories: [
      { name: 'Grocery', icon: 'ShoppingCart' },
      { name: 'Fashion', icon: 'Shirt' },
      { name: 'Electronics', icon: 'Smartphone' },
      { name: 'Handloom', icon: 'Sparkles' },
      { name: 'Home & kitchen', icon: 'Lamp' },
      { name: 'Gifts & crafts', icon: 'Gift' },
    ],
  },
  {
    id: 'health',
    name: 'Health & wellness',
    description: 'Clinics, gyms, wellness',
    icon: 'HeartPulse',
    subcategories: [
      { name: 'Clinics & doctors', icon: 'Stethoscope' },
      { name: 'Pharmacy', icon: 'Pill' },
      { name: 'Gym & fitness', icon: 'Dumbbell' },
      { name: 'Yoga & spa', icon: 'Flower2' },
      { name: 'Dental', icon: 'Smile' },
      { name: 'Labs & diagnostics', icon: 'Microscope' },
    ],
  },
  {
    id: 'home',
    name: 'Home services',
    description: 'Repairs & maintenance',
    icon: 'Wrench',
    subcategories: [
      { name: 'Plumbing', icon: 'Droplets' },
      { name: 'Electrical', icon: 'Zap' },
      { name: 'Cleaning', icon: 'Sparkle' },
      { name: 'AC & appliance', icon: 'AirVent' },
      { name: 'Painting', icon: 'Paintbrush' },
      { name: 'Carpentry', icon: 'Hammer' },
    ],
  },
  {
    id: 'auto',
    name: 'Automotive',
    description: 'Service & parts',
    icon: 'Car',
    subcategories: [
      { name: 'Car service', icon: 'Car' },
      { name: 'Bike service', icon: 'Bike' },
      { name: 'Tyres & parts', icon: 'CircleDot' },
      { name: 'Car wash', icon: 'Droplets' },
      { name: 'Towing', icon: 'Truck' },
      { name: 'Driving school', icon: 'Gauge' },
    ],
  },
  {
    id: 'education',
    name: 'Education',
    description: 'Tutors & centres',
    icon: 'GraduationCap',
    subcategories: [
      { name: 'Schools', icon: 'School' },
      { name: 'Coaching', icon: 'BookOpen' },
      { name: 'Tutors', icon: 'Pencil' },
      { name: 'Music & arts', icon: 'Music' },
      { name: 'Language', icon: 'Languages' },
      { name: 'Computer courses', icon: 'Monitor' },
    ],
  },
  {
    id: 'professionals',
    name: 'Professionals',
    description: 'Legal, finance, consulting',
    icon: 'Briefcase',
    subcategories: [
      { name: 'Lawyers', icon: 'Scale' },
      { name: 'CA & tax', icon: 'Calculator' },
      { name: 'Insurance', icon: 'Shield' },
      { name: 'Real estate', icon: 'Building2' },
      { name: 'Consultants', icon: 'Handshake' },
      { name: 'Notary', icon: 'FileText' },
    ],
  },
  {
    id: 'beauty',
    name: 'Beauty & fashion',
    description: 'Salons & personal care',
    icon: 'Scissors',
    subcategories: [
      { name: 'Salons', icon: 'Scissors' },
      { name: 'Spa', icon: 'Flower2' },
      { name: 'Makeup', icon: 'Sparkles' },
      { name: 'Mehendi', icon: 'Hand' },
      { name: 'Boutique', icon: 'Shirt' },
      { name: 'Jewellery', icon: 'Gem' },
    ],
  },
]
