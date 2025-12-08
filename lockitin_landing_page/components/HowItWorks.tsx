'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'

export default function HowItWorks() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  const steps = [
    {
      number: "01",
      title: "Connect & See Availability",
      description: "Sync your calendar. Instantly see when your whole group is free—without revealing private events.",
      visual: "🗓️"
    },
    {
      number: "02",
      title: "Propose & Vote",
      description: "Suggest 2-5 time options. Everyone votes with one tap. Results update in real-time.",
      visual: "🗳️"
    },
    {
      number: "03",
      title: "Event Auto-Created",
      description: "When voting closes, the event automatically adds to everyone's calendar. You're done!",
      visual: "✅"
    }
  ]

  return (
    <section id="how-it-works" ref={ref} className="relative section-container bg-white dark:bg-gray-950">

      <div className="max-w-6xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-20"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            How It Works
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            From idea to confirmed event in 3 simple steps
          </p>
        </motion.div>

        <div className="relative">
          {/* Connection Line */}
          <div className="absolute left-8 top-20 bottom-20 w-0.5 bg-gradient-to-b from-primary via-purple-500 to-green-500 hidden lg:block" />

          <div className="space-y-12">
            {steps.map((step, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -30 }}
                animate={isInView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.6, delay: index * 0.2 }}
                className="relative"
              >
                <div className="flex flex-col lg:flex-row gap-8 items-start lg:items-center">
                  {/* Step Number Circle */}
                  <div className="relative z-10">
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={isInView ? { scale: 1 } : {}}
                      transition={{ delay: index * 0.2 + 0.3, type: "spring", stiffness: 200 }}
                      className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white font-bold text-xl shadow-lg"
                    >
                      {step.number}
                    </motion.div>
                  </div>

                  {/* Content Card */}
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={isInView ? { opacity: 1, y: 0 } : {}}
                    transition={{ delay: index * 0.2 + 0.4 }}
                    className="flex-1 card transition-all duration-300 hover:shadow-lg hover:border-primary/30"
                  >
                    <div className="flex items-start gap-6">
                      <div className="flex-1">
                        <h3 className="text-2xl font-bold mb-3">{step.title}</h3>
                        <p className="text-gray-600 dark:text-gray-400 text-lg">
                          {step.description}
                        </p>
                      </div>
                      <div className="text-6xl opacity-20 hidden sm:block">
                        {step.visual}
                      </div>
                    </div>
                  </motion.div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Time Comparison */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 1 }}
          className="mt-20 grid md:grid-cols-2 gap-8"
        >
          <div className="bg-red-50 dark:bg-red-900/20 rounded-3xl p-8 border-2 border-red-200 dark:border-red-800">
            <div className="text-center">
              <div className="text-5xl mb-4">😫</div>
              <div className="text-2xl font-bold text-red-600 dark:text-red-400 mb-2">
                The Old Way
              </div>
              <div className="text-gray-600 dark:text-gray-400 mb-4">
                Group chat coordination
              </div>
              <div className="space-y-2 text-left max-w-xs mx-auto">
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-red-500">✗</span>
                  <span>30+ messages back and forth</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-red-500">✗</span>
                  <span>45 minutes wasted planning</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-red-500">✗</span>
                  <span>Half your friends forget to respond</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-red-500">✗</span>
                  <span>Event falls through 40% of the time</span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-green-50 dark:bg-green-900/20 rounded-3xl p-8 border-2 border-green-200 dark:border-green-800">
            <div className="text-center">
              <div className="text-5xl mb-4">✨</div>
              <div className="text-2xl font-bold text-green-600 dark:text-green-400 mb-2">
                The LockItIn Way
              </div>
              <div className="text-gray-600 dark:text-gray-400 mb-4">
                Effortless coordination
              </div>
              <div className="space-y-2 text-left max-w-xs mx-auto">
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-green-500">✓</span>
                  <span>Zero messages needed</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-green-500">✓</span>
                  <span>2 minutes from idea to locked-in event</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-green-500">✓</span>
                  <span>Everyone votes with one tap</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-green-500">✓</span>
                  <span>95% success rate for confirmed events</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Section divider */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gray-200/10 dark:bg-gray-800/30" />
    </section>
  )
}
