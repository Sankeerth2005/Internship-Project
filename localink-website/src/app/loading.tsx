export default function Loading() {
  return (
    <div className="flex min-h-[50vh] items-center justify-center bg-[#F9F8F6]" role="status">
      <div className="flex flex-col items-center gap-3">
        <div className="h-10 w-10 animate-pulse rounded-xl bg-primary/30" />
        <p className="text-sm font-semibold text-text-muted">Loading…</p>
      </div>
    </div>
  )
}
