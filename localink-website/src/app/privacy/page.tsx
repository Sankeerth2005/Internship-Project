import type { Metadata } from 'next'
import LegalLayout from '@/components/LegalLayout'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description:
    'How Vocal for Sanatan collects, uses, and protects personal data — required for Google Play and our users.',
  alternates: { canonical: 'https://vocalforsanatan.com/privacy' },
}

export default function PrivacyPage() {
  return (
    <LegalLayout eyebrow="Legal" title="Privacy Policy" updated="8 August 2026">
      <p>
        This Privacy Policy explains how <strong>Vocal for Sanatan</strong> (&quot;we&quot;,
        &quot;us&quot;, or &quot;our&quot;) collects, uses, shares, and protects information when
        you use our mobile application (package ID <code>{site.packageId}</code>), website at{' '}
        <a href={site.url}>{site.url}</a>, and related services (together, the &quot;Service&quot;).
      </p>
      <p>
        By using the Service you agree to this policy. If you do not agree, please do not use the
        Service.
      </p>

      <h2>1. Who we are</h2>
      <p>
        Vocal for Sanatan is a local business discovery platform that helps users find nearby
        businesses and helps business owners list and manage their presence. For privacy questions,
        contact <a href={`mailto:${site.privacyEmail}`}>{site.privacyEmail}</a>.
      </p>

      <h2>2. Information we collect</h2>
      <h3>2.1 Account &amp; profile</h3>
      <ul>
        <li>Name, email address, and password (if you register with email)</li>
        <li>Google account identifiers and basic profile details if you sign in with Google</li>
        <li>User role (customer, business owner, or admin) and profile preferences</li>
        <li>Business listing details you submit (name, description, hours, contact, address, photos)</li>
      </ul>

      <h3>2.2 Location</h3>
      <p>
        With your permission, we collect approximate or precise device location to show nearby
        businesses, sort by distance, and improve map-based discovery. You can deny or revoke
        location permission in your device settings; some nearby features will then be limited.
      </p>

      <h3>2.3 Voice &amp; audio</h3>
      <p>
        If you use voice search or voice messaging features, we process microphone audio on your
        device and/or our servers only as needed to convert speech to text or deliver voice messages.
        We do not sell voice recordings.
      </p>

      <h3>2.4 Photos &amp; media</h3>
      <p>
        If you upload business or profile photos, we store the images you choose to share so they
        can be displayed in the Service.
      </p>

      <h3>2.5 Communications</h3>
      <ul>
        <li>Chat messages (text and voice) between users and businesses</li>
        <li>Reviews and ratings you post</li>
        <li>Support emails and related correspondence</li>
      </ul>

      <h3>2.6 Usage &amp; device data</h3>
      <ul>
        <li>App interactions, search queries (including location context when provided), and favourites</li>
        <li>Device type, OS version, app version, and diagnostic logs needed to keep the Service reliable</li>
        <li>IP address and security-related signals for authentication and abuse prevention</li>
      </ul>

      <h2>3. How we use information</h2>
      <ul>
        <li>Provide, operate, and improve the Service</li>
        <li>Authenticate users and secure accounts</li>
        <li>Enable discovery, maps, chat, reviews, favourites, and business management</li>
        <li>Power AI-assisted search and recommendations based on your queries and preferences</li>
        <li>Send transactional emails (verification, password reset, important service notices)</li>
        <li>Detect, prevent, and respond to fraud, spam, or security incidents</li>
        <li>Comply with law and enforce our Terms of Service</li>
      </ul>

      <h2>4. Legal bases (where applicable)</h2>
      <p>
        Depending on your location, we process personal data under one or more of: your consent
        (e.g. location, microphone), performance of a contract (providing the Service you request),
        legitimate interests (security, product improvement), and legal obligation.
      </p>

      <h2>5. How we share information</h2>
      <p>We do not sell your personal information. We may share data only as follows:</p>
      <ul>
        <li>
          <strong>With other users / businesses</strong> — profile and listing details you choose to
          make public; chat content with your conversation counterpart
        </li>
        <li>
          <strong>Service providers</strong> — infrastructure, email delivery, maps/geocoding, AI
          processing, and analytics vendors who process data on our instructions
        </li>
        <li>
          <strong>Google Sign-In</strong> — authentication is handled under Google&apos;s terms and
          privacy policy when you choose that method
        </li>
        <li>
          <strong>Legal / safety</strong> — when required by law or to protect rights, safety, and
          integrity of users and the Service
        </li>
        <li>
          <strong>Business transfers</strong> — in connection with a merger, acquisition, or asset
          sale, with appropriate safeguards
        </li>
      </ul>

      <h2>6. Third-party services</h2>
      <p>
        The Service may rely on third parties such as Google (Sign-In), map/geocoding providers,
        email providers, and AI model providers to process requests. Those parties have their own
        privacy policies governing their processing.
      </p>

      <h2>7. Data retention</h2>
      <p>
        We retain account and listing data while your account is active and as needed to provide the
        Service. After account deletion, we remove or anonymize personal data within a reasonable
        period, except where we must retain limited records for legal, security, dispute, or
        accounting purposes.
      </p>

      <h2>8. Security</h2>
      <p>
        We use industry-standard measures including encrypted transport (HTTPS), access controls,
        and secure credential handling. No method of transmission or storage is 100% secure; please
        use a strong unique password and protect your device.
      </p>

      <h2>9. Your rights &amp; choices</h2>
      <ul>
        <li>Access or update profile information in the app</li>
        <li>
          Delete your account in-app or via our{' '}
          <a href="/delete-account">Delete Account</a> instructions
        </li>
        <li>Revoke device permissions (location, microphone, photos) in system settings</li>
        <li>
          Request access, correction, or deletion by emailing{' '}
          <a href={`mailto:${site.privacyEmail}`}>{site.privacyEmail}</a>
        </li>
      </ul>

      <h2>10. Children&apos;s privacy</h2>
      <p>
        The Service is not directed to children under 13 (or the minimum age required in your
        jurisdiction). We do not knowingly collect personal information from children. If you believe
        a child has provided us data, contact us and we will take appropriate steps to delete it.
      </p>

      <h2>11. International transfers</h2>
      <p>
        We primarily operate with users in {site.region}. If data is processed in other countries,
        we take steps designed to protect it in accordance with this policy and applicable law.
      </p>

      <h2>12. Changes</h2>
      <p>
        We may update this Privacy Policy from time to time. We will post the revised version on
        this page and update the &quot;Last updated&quot; date. Continued use after changes means
        you accept the updated policy.
      </p>

      <h2>13. Contact</h2>
      <p>
        Privacy requests: <a href={`mailto:${site.privacyEmail}`}>{site.privacyEmail}</a>
        <br />
        Support: <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>
        <br />
        Website: <a href={site.url}>{site.url}</a>
      </p>
    </LegalLayout>
  )
}
