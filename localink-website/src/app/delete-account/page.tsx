import type { Metadata } from 'next'
import LegalLayout from '@/components/LegalLayout'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Delete Account',
  description:
    'How to delete your Vocal for Sanatan account and associated data — Google Play account deletion requirement.',
  alternates: { canonical: 'https://vocalforsanatan.com/delete-account' },
}

export default function DeleteAccountPage() {
  return (
    <LegalLayout eyebrow="Account" title="Delete your account" updated="8 August 2026">
      <p>
        Google Play requires apps that support account creation to also offer a way to request
        account deletion. Vocal for Sanatan lets you delete your account from the app, or by
        contacting support.
      </p>

      <h2>Delete from the mobile app (recommended)</h2>
      <ol className="list-decimal pl-5 space-y-2 my-4 text-text-muted">
        <li>Open the Vocal for Sanatan app and sign in.</li>
        <li>Go to <strong>Profile</strong> (or Settings).</li>
        <li>Choose <strong>Delete account</strong>.</li>
        <li>Confirm the deletion when prompted.</li>
      </ol>
      <p>
        Your account is deactivated immediately. Associated personal data is removed or anonymized
        according to our <a href="/privacy">Privacy Policy</a>.
      </p>

      <h2>Delete by email</h2>
      <p>
        If you cannot access the app, email{' '}
        <a href={`mailto:${site.supportEmail}?subject=Account%20deletion%20request`}>
          {site.supportEmail}
        </a>{' '}
        from the email address linked to your account with the subject line{' '}
        <strong>Account deletion request</strong>. Include:
      </p>
      <ul>
        <li>Full name on the account</li>
        <li>Registered email address</li>
        <li>Whether you are a customer or business owner</li>
      </ul>
      <p>We will verify ownership and process the request within a reasonable period (typically within 30 days).</p>

      <h2>What gets deleted</h2>
      <ul>
        <li>Account credentials and profile information</li>
        <li>Favourites and personal preferences</li>
        <li>Access to chat history from your account</li>
        <li>Business listings you solely own (for business owner accounts), subject to review</li>
      </ul>

      <h2>What may be retained</h2>
      <ul>
        <li>Anonymized analytics that no longer identify you</li>
        <li>Records we must keep for legal, security, fraud prevention, or accounting reasons</li>
        <li>
          Content you shared publicly (e.g. reviews) may remain in anonymized or attributed form
          where removal would break other users&apos; legitimate expectations — contact us if you
          need specific review removal
        </li>
      </ul>

      <h2>Google Sign-In</h2>
      <p>
        Deleting your Vocal for Sanatan account does not delete your Google account. It only removes
        our app&apos;s access to the data we stored for your Vocal for Sanatan profile.
      </p>

      <h2>Questions</h2>
      <p>
        Privacy: <a href={`mailto:${site.privacyEmail}`}>{site.privacyEmail}</a>
        <br />
        Support: <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>
      </p>
    </LegalLayout>
  )
}
