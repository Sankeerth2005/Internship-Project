import type { Metadata } from 'next'
import InviteClient from './InviteClient'

export const metadata: Metadata = {
  title: 'Join with Invite',
  description:
    'Join Vocal for Sanatan with a community referral invite and support Sanatani businesses.',
  alternates: { canonical: 'https://vocalforsanatan.com/invite' },
  robots: { index: false, follow: true },
}

type InvitePageProps = {
  searchParams: Promise<{ code?: string }>
}

export default async function InvitePage({ searchParams }: InvitePageProps) {
  const params = await searchParams
  const code = (params.code ?? '').trim().toUpperCase()

  return <InviteClient code={code} />
}
