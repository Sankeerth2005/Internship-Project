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
          glow: '#FFA047',
          dark: '#E55C00',
        },
        background: {
          DEFAULT: '#080707',
          surface: '#110F0F',
          light: '#FFFFFF',
        },
        text: {
          DEFAULT: '#F5F3F2',
          muted: '#A19E9A',
          dark: '#1A1918',
        },
        border: {
          DEFAULT: 'rgba(255, 255, 255, 0.08)',
        },
        error: '#FF3B30',
        success: '#34C759',
        warning: '#FF9500',
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
        display: ['var(--font-plus-jakarta-sans)', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'button': '30px',
        'card': '20px',
        'input': '14px',
      },
      boxShadow: {
        'card': '0px 10px 30px -10px rgba(0, 0, 0, 0.7)',
        'button': '0px 4px 15px rgba(255, 102, 0, 0.4)',
        'floating': '0px 20px 40px -15px rgba(0, 0, 0, 0.8)',
        'glow': '0px 0px 30px 2px rgba(255, 102, 0, 0.2)',
      },
      animation: {
        'gradient': 'gradient 8s ease infinite',
        'float': 'float 6s ease-in-out infinite',
        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        gradient: {
          '0%, 100%': {
            'background-size': '200% 200%',
            'background-position': 'left center'
          },
          '50%': {
            'background-size': '200% 200%',
            'background-position': 'right center'
          },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-15px)' },
        },
      },
    },
  },
  plugins: [],
}
export default config
