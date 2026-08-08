import Link from 'next/link'
import BrandLogo from '@/components/BrandLogo'
import { navigation } from '@/constants/navigation'
import { siteContent } from '@/constants/content'
import { site } from '@/constants/colors'

export default function Footer() {
  return (
    <footer className="relative border-t border-border bg-[#1A1918] text-white overflow-hidden">
      <div
        className="pointer-events-none absolute -top-20 left-1/2 h-40 w-[24rem] -translate-x-1/2 rounded-full bg-primary/25 blur-3xl"
        aria-hidden
      />

      <div className="container-custom relative z-10 py-12 lg:py-14">
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-5">
          <div className="lg:col-span-2">
            <BrandLogo tone="light" />
            <p className="mt-4 max-w-sm text-sm leading-relaxed text-white/65">
              Discover nearby businesses, chat with owners, and grow your community — powered by AI
              search and real maps.
            </p>
            <p className="mt-3 text-xs text-white/45">
              Support:{' '}
              <a className="font-semibold text-primary-glow hover:underline" href={`mailto:${site.supportEmail}`}>
                {site.supportEmail}
              </a>
            </p>
          </div>

          {(
            [
              ['Company', navigation.footer.company],
              ['Product', navigation.footer.product],
              ['Legal', navigation.footer.legal],
            ] as const
          ).map(([title, links]) => (
            <div key={title}>
              <h3 className="mb-3 font-display text-sm font-bold uppercase tracking-wider text-white">
                {title}
              </h3>
              <ul className="space-y-2.5">
                {links.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-sm font-medium text-white/55 transition-colors hover:text-primary-glow"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-10 flex flex-col gap-2 border-t border-white/10 pt-6 text-xs text-white/40 sm:flex-row sm:items-center sm:justify-between">
          <p>{siteContent.footer.copyright}</p>
          <p>
            Package ID: <span className="text-white/60">{site.packageId}</span>
          </p>
        </div>
      </div>
    </footer>
  )
}
