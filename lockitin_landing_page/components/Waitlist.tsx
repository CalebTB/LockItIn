'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const waitlistSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  name: z.string().min(2, 'Name must be at least 2 characters'),
})

type WaitlistFormData = z.infer<typeof waitlistSchema>

export default function Waitlist() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<WaitlistFormData>({
    resolver: zodResolver(waitlistSchema),
  })

  const onSubmit = async (data: WaitlistFormData) => {
    setIsSubmitting(true)

    // Simulate API call - replace with actual API endpoint
    await new Promise(resolve => setTimeout(resolve, 1000))

    console.log('Waitlist signup:', data)

    setIsSubmitted(true)
    setIsSubmitting(false)
    reset()

    // Reset success message after 5 seconds
    setTimeout(() => setIsSubmitted(false), 5000)
  }

  return (
    <section id="waitlist" ref={ref} className="section-container relative overflow-hidden bg-white dark:bg-gray-950">

      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-purple-500/5 to-pink-500/5 -z-10" />

      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            Join the Waitlist
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Be the first to know when LockItIn launches in April 2026. Early access for waitlist members.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="card max-w-2xl mx-auto"
        >
          {!isSubmitted ? (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              <div>
                <label htmlFor="name" className="block text-sm font-medium mb-2">
                  Your Name
                </label>
                <input
                  {...register('name')}
                  type="text"
                  id="name"
                  placeholder="Sarah Mitchell"
                  className={`w-full px-4 py-3 rounded-xl border-2 ${
                    errors.name
                      ? 'border-error focus:border-error'
                      : 'border-gray-200 dark:border-gray-700 focus:border-primary'
                  } bg-white dark:bg-gray-800 transition-colors focus:outline-none`}
                />
                {errors.name && (
                  <p className="mt-2 text-sm text-error">{errors.name.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium mb-2">
                  Email Address
                </label>
                <input
                  {...register('email')}
                  type="email"
                  id="email"
                  placeholder="sarah@example.com"
                  className={`w-full px-4 py-3 rounded-xl border-2 ${
                    errors.email
                      ? 'border-error focus:border-error'
                      : 'border-gray-200 dark:border-gray-700 focus:border-primary'
                  } bg-white dark:bg-gray-800 transition-colors focus:outline-none`}
                />
                {errors.email && (
                  <p className="mt-2 text-sm text-error">{errors.email.message}</p>
                )}
              </div>

              <motion.button
                type="submit"
                disabled={isSubmitting}
                className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
                whileHover={!isSubmitting ? { scale: 1.02 } : {}}
                whileTap={!isSubmitting ? { scale: 0.98 } : {}}
              >
                {isSubmitting ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                        fill="none"
                      />
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      />
                    </svg>
                    Joining...
                  </span>
                ) : (
                  'Join the Waitlist'
                )}
              </motion.button>

              <p className="text-xs text-center text-gray-500 dark:text-gray-400">
                We respect your privacy. No spam, just updates about launch.
              </p>
            </form>
          ) : (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="text-center py-8"
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 200, delay: 0.1 }}
                className="w-20 h-20 mx-auto mb-6 rounded-full bg-success flex items-center justify-center"
              >
                <svg
                  className="w-10 h-10 text-white"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path d="M5 13l4 4L19 7"></path>
                </svg>
              </motion.div>
              <h3 className="text-2xl font-bold mb-2">You're on the list!</h3>
              <p className="text-gray-600 dark:text-gray-400">
                We'll send you an email when LockItIn launches in April 2026.
              </p>
            </motion.div>
          )}
        </motion.div>

        {/* Benefits of joining */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-12 grid sm:grid-cols-3 gap-6 text-center"
        >
          <div>
            <div className="text-3xl mb-2">🎁</div>
            <div className="font-semibold mb-1">Early Access</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Get the app before public launch
            </div>
          </div>
          <div>
            <div className="text-3xl mb-2">💰</div>
            <div className="font-semibold mb-1">Exclusive Pricing</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Special launch pricing for early adopters
            </div>
          </div>
          <div>
            <div className="text-3xl mb-2">💬</div>
            <div className="font-semibold mb-1">Shape the Product</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Your feedback helps us build better
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
