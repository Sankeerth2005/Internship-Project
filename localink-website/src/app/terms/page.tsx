import type { Metadata } from 'next'
import LegalLayout from '@/components/LegalLayout'
import { site } from '@/constants/colors'

export const metadata: Metadata = {
  title: 'Terms of Service',
  description: 'Terms and conditions for using Vocal for Sanatan.',
  alternates: { canonical: 'https://vocalforsanatan.com/terms' },
}

export default function TermsPage() {
  return (
    <LegalLayout eyebrow="Legal" title="Terms of Service" updated="8 August 2026">
      <p>
        These Terms of Service (&quot;Terms&quot;) govern your access to and use of Vocal for
        Sanatan&apos;s website, mobile app (<code>{site.packageId}</code>), and related services
        (the &quot;Service&quot;). By creating an account or using the Service, you agree to these
        Terms and our <a href="/privacy">Privacy Policy</a>.
      </p>

      <h2>1. Eligibility</h2>
      <p>
        You must be at least 13 years old (or the age of digital consent in your region) and able to
        form a binding contract to use the Service. If you use the Service on behalf of a business,
        you represent that you have authority to bind that business.
      </p>

      <h2>2. Accounts</h2>
      <ul>
        <li>Provide accurate registration information and keep it updated</li>
        <li>Keep your credentials confidential and notify us of unauthorized use</li>
        <li>You are responsible for activity under your account</li>
        <li>We may suspend or terminate accounts that violate these Terms</li>
      </ul>

      <h2>3. Roles</h2>
      <p>
        The Service supports customers, business owners, and administrators. Business owners are
        responsible for the accuracy and legality of their listings, photos, hours, and contact
        details.
      </p>

      <h2>4. Acceptable use</h2>
      <p>You agree not to:</p>
      <ul>
        <li>Violate any law or third-party rights</li>
        <li>Harass, abuse, defraud, or impersonate others</li>
        <li>Post false, misleading, illegal, or infringing content</li>
        <li>Scrape, reverse engineer, or disrupt the Service or its security</li>
        <li>Spam users or misuse chat, reviews, or AI features</li>
        <li>Upload malware or attempt unauthorized access</li>
      </ul>

      <h2>5. User content</h2>
      <p>
        You retain ownership of content you submit (reviews, messages, photos, listing text). You
        grant us a worldwide, non-exclusive, royalty-free license to host, display, and distribute
        that content as needed to operate and promote the Service. You represent that you have the
        rights to grant this license.
      </p>

      <h2>6. Business listings</h2>
      <p>
        We may review, approve, reject, or remove listings that violate these Terms, appear
        fraudulent, or harm users. Listing on Vocal for Sanatan does not create a partnership or
        employment relationship.
      </p>

      <h2>7. AI features</h2>
      <p>
        AI search and related features may generate suggestions based on your input. Outputs can be
        inaccurate or incomplete. Always verify important information directly with the business.
      </p>

      <h2>8. Third-party services</h2>
      <p>
        The Service may integrate maps, sign-in providers, and other third parties. Their terms and
        privacy policies apply to your use of those features.
      </p>

      <h2>9. Intellectual property</h2>
      <p>
        The Vocal for Sanatan name, branding, software, and site content (excluding user content) are
        owned by us or our licensors and protected by applicable IP laws. You may not copy or
        exploit them without written permission.
      </p>

      <h2>10. Disclaimers</h2>
      <p>
        THE SERVICE IS PROVIDED &quot;AS IS&quot; AND &quot;AS AVAILABLE&quot; WITHOUT WARRANTIES OF
        ANY KIND, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
        AND NON-INFRINGEMENT. We do not guarantee uninterrupted availability or the accuracy of
        business listings provided by third parties.
      </p>

      <h2>11. Limitation of liability</h2>
      <p>
        TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR INDIRECT, INCIDENTAL,
        SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, OR GOODWILL,
        ARISING FROM YOUR USE OF THE SERVICE.
      </p>

      <h2>12. Indemnity</h2>
      <p>
        You agree to indemnify and hold us harmless from claims arising out of your content, your
        use of the Service, or your violation of these Terms.
      </p>

      <h2>13. Termination</h2>
      <p>
        You may stop using the Service and delete your account at any time (see{' '}
        <a href="/delete-account">Delete Account</a>). We may suspend or terminate access if you
        breach these Terms or if we discontinue the Service.
      </p>

      <h2>14. Governing law</h2>
      <p>
        These Terms are governed by the laws of {site.region}, without regard to conflict-of-law
        principles. Courts in {site.region} shall have exclusive jurisdiction, subject to mandatory
        consumer protections that may apply in your location.
      </p>

      <h2>15. Changes</h2>
      <p>
        We may update these Terms by posting a revised version on this page. Continued use after
        the effective date constitutes acceptance.
      </p>

      <h2>16. Contact</h2>
      <p>
        Legal: <a href={`mailto:${site.legalEmail}`}>{site.legalEmail}</a>
        <br />
        Support: <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a>
      </p>
    </LegalLayout>
  )
}
