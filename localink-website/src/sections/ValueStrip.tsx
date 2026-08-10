const values = [
  { hi: 'धर्म', en: 'Dharma' },
  { hi: 'संस्कृति', en: 'Sanskriti' },
  { hi: 'सेवा', en: 'Seva' },
  { hi: 'स्वदेशी', en: 'Swadeshi' },
  { hi: 'समृद्धि', en: 'Samriddhi' },
]

export default function ValueStrip() {
  return (
    <section
      className="relative overflow-hidden border-y border-border bg-[#1A1918]"
      aria-label="Brand values"
    >
      <div
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(255,102,0,0.18),transparent_60%)]"
        aria-hidden
      />
      <div className="container-custom relative z-10 py-6 lg:py-7">
        <ul className="grid grid-cols-2 gap-3 sm:grid-cols-5 lg:gap-4">
          {values.map((v) => (
            <li
              key={v.en}
              className="rounded-2xl border border-white/10 bg-white/5 px-3 py-4 text-center"
            >
              <p className="font-display text-xl font-bold text-primary-glow lg:text-2xl">{v.hi}</p>
              <p className="mt-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/55">
                {v.en}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
