import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    './src/sections/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#FF6600',
          glow: '#FF9E4F',
          dark: '#E55C00',
        },
        background: {
          DEFAULT: '#FFFFFF',
          surface: '#F9F8F6',
        },
        text: {
          DEFAULT: '#1A1918',
          muted: '#5F5C58',
          soft: '#9F9B96',
        },
        border: {
          DEFAULT: '#EAE8E3',
        },
        error: '#E1251B',
        success: '#1E824C',
        warning: '#FFA500',
      },
      fontFamily: {
        sans: ['var(--font-body)', 'system-ui', 'sans-serif'],
        display: ['var(--font-display)', 'Georgia', 'serif'],
      },
      borderRadius: {
        button: '14px',
        card: '20px',
        input: '12px',
      },
      boxShadow: {
        soft: '0 12px 40px -16px rgba(26, 25, 24, 0.18)',
        button: '0 8px 24px -6px rgba(255, 102, 0, 0.45)',
        phone: '0 40px 80px -24px rgba(26, 25, 24, 0.35)',
        lift: '0 20px 50px -20px rgba(255, 102, 0, 0.28)',
      },
      animation: {
        float: 'float 7s ease-in-out infinite',
        'fade-up': 'fadeUp 0.8s ease-out both',
        shimmer: 'shimmer 8s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-14px)' },
        },
        fadeUp: {
          '0%': { opacity: '0', transform: 'translateY(24px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        shimmer: {
          '0%, 100%': { backgroundPosition: '0% 50%' },
          '50%': { backgroundPosition: '100% 50%' },
        },
      },
    },
  },
  plugins: [],
}
export default config
