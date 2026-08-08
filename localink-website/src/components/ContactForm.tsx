'use client'

import { FormEvent, useState } from 'react'
import Button from '@/components/Button'
import { site } from '@/constants/colors'

export default function ContactForm() {
  const [sent, setSent] = useState(false)

  function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const data = new FormData(e.currentTarget)
    const name = String(data.get('name') || '')
    const email = String(data.get('email') || '')
    const topic = String(data.get('topic') || 'General')
    const message = String(data.get('message') || '')
    const body = encodeURIComponent(
      `Name: ${name}\nEmail: ${email}\nTopic: ${topic}\n\n${message}`
    )
    const subject = encodeURIComponent(`[Vocal for Sanatan] ${topic}`)
    window.location.href = `mailto:${site.supportEmail}?subject=${subject}&body=${body}`
    setSent(true)
  }

  return (
    <form
      onSubmit={onSubmit}
      className="rounded-card border border-border bg-white p-6 sm:p-8 shadow-soft space-y-5"
    >
      <div>
        <label htmlFor="name" className="mb-1.5 block text-sm font-semibold text-text">
          Name
        </label>
        <input
          id="name"
          name="name"
          required
          className="w-full rounded-input border border-border bg-background-surface px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/40"
        />
      </div>
      <div>
        <label htmlFor="email" className="mb-1.5 block text-sm font-semibold text-text">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          className="w-full rounded-input border border-border bg-background-surface px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/40"
        />
      </div>
      <div>
        <label htmlFor="topic" className="mb-1.5 block text-sm font-semibold text-text">
          Topic
        </label>
        <select
          id="topic"
          name="topic"
          className="w-full rounded-input border border-border bg-background-surface px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/40"
        >
          <option>General</option>
          <option>App support</option>
          <option>Business listing</option>
          <option>Privacy / data</option>
          <option>Account deletion</option>
          <option>Partnership</option>
        </select>
      </div>
      <div>
        <label htmlFor="message" className="mb-1.5 block text-sm font-semibold text-text">
          Message
        </label>
        <textarea
          id="message"
          name="message"
          required
          rows={5}
          className="w-full rounded-input border border-border bg-background-surface px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/40"
        />
      </div>
      <Button type="submit" size="lg" className="w-full">
        Open email draft
      </Button>
      {sent && (
        <p className="text-sm text-success">
          Your mail app should open with a pre-filled message. If it doesn&apos;t, email{' '}
          {site.supportEmail} directly.
        </p>
      )}
    </form>
  )
}
