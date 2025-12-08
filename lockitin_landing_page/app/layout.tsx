import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'LockItIn - Stop the 30-Message Planning Hell',
  description: 'The iOS calendar app that makes group event planning effortless. Share availability without revealing private details. Vote once. Event created. Launch April 2026.',
  keywords: ['calendar app', 'group planning', 'event coordination', 'iOS', 'privacy', 'scheduling', 'friend groups'],
  authors: [{ name: 'LockItIn' }],
  creator: 'LockItIn',
  publisher: 'LockItIn',
  metadataBase: new URL('https://lockitin.app'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://lockitin.app',
    siteName: 'LockItIn',
    title: 'LockItIn - Lock in plans, not details',
    description: 'Stop the 30-message group chat. See real availability. Vote once. Event created.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'LockItIn - Group Event Planning Made Effortless',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'LockItIn - Lock in plans, not details',
    description: 'Stop the 30-message group chat. See real availability. Vote once. Event created.',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
  },
  icons: {
    icon: '/favicon.ico',
    apple: '/apple-touch-icon.png',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <meta name="theme-color" content="#007AFF" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      </head>
      <body className="antialiased bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100">
        {children}
      </body>
    </html>
  )
}
