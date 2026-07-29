/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: [],
  },
  reactStrictMode: true,
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
}

module.exports = nextConfig
