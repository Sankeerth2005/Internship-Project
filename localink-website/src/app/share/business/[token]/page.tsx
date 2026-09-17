import ShareBusinessClient from '../../ShareBusinessClient'

type PageProps = {
  params: Promise<{ token: string }>
}

export default async function ShareBusinessPage({ params }: PageProps) {
  const { token } = await params
  return <ShareBusinessClient token={token ?? ''} kind="business" />
}
