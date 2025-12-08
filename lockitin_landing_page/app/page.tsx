'use client'

import Hero from '@/components/Hero'
import Problem from '@/components/Problem'
import ShadowCalendar from '@/components/ShadowCalendar'
import Features from '@/components/Features'
import HowItWorks from '@/components/HowItWorks'
import SocialProof from '@/components/SocialProof'
import Waitlist from '@/components/Waitlist'
import Footer from '@/components/Footer'

export default function Home() {
  return (
    <main className="overflow-hidden">
      <Hero />
      <Problem />
      <ShadowCalendar />
      <Features />
      <HowItWorks />
      <SocialProof />
      <Waitlist />
      <Footer />
    </main>
  )
}
