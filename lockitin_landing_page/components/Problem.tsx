'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'

export default function Problem() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  const messages = [
    { sender: "Sarah", text: "When should we do game night?" },
    { sender: "Mike", text: "I'm free Thursday or Saturday" },
    { sender: "Alex", text: "Can't do Thursday" },
    { sender: "Jordan", text: "What time Saturday?" },
    { sender: "Sarah", text: "Maybe 7pm?" },
    { sender: "Chris", text: "I work until 8" },
    { sender: "Mike", text: "Actually I forgot I have dinner Thursday" },
    { sender: "Alex", text: "Wait what did we decide?" },
  ]

  return (
    <section ref={ref} className="relative section-container bg-gray-50 dark:bg-gray-950">

      <div className="max-w-4xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            Sound Familiar?
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Why does planning one hangout take 30+ messages?
          </p>
        </motion.div>

        {/* Message Thread Mockup */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={isInView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="card max-w-md mx-auto mb-12"
        >
          <div className="flex items-center gap-3 mb-4 pb-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex -space-x-2">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 border-2 border-white dark:border-gray-900"></div>
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 border-2 border-white dark:border-gray-900"></div>
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-green-400 to-green-600 border-2 border-white dark:border-gray-900"></div>
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 border-2 border-white dark:border-gray-900"></div>
            </div>
            <div>
              <div className="font-semibold text-sm">Game Night Crew</div>
              <div className="text-xs text-gray-500">8 members</div>
            </div>
          </div>

          <div className="space-y-3 max-h-96 overflow-y-auto">
            {messages.map((msg, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -10 }}
                animate={isInView ? { opacity: 1, x: 0 } : {}}
                transition={{ delay: 0.3 + index * 0.1 }}
                className="flex gap-2"
              >
                <div className="flex-1">
                  <div className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1">
                    {msg.sender}
                  </div>
                  <div className="bg-gray-100 dark:bg-gray-800 rounded-2xl rounded-tl-sm px-4 py-2 text-sm">
                    {msg.text}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={isInView ? { opacity: 1 } : {}}
            transition={{ delay: 1.2 }}
            className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700 text-center"
          >
            <div className="text-3xl font-bold text-error mb-2">30+ Messages</div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              ...and still no confirmed event
            </div>
          </motion.div>
        </motion.div>

        {/* The Real Problem */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 1.3 }}
          className="mt-12 max-w-3xl mx-auto"
        >
          <div className="card bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 border-2 border-primary/20">
            <div className="text-center">
              <div className="text-4xl mb-4">💡</div>
              <h3 className="text-2xl font-bold mb-3">The Real Problem</h3>
              <p className="text-lg text-gray-700 dark:text-gray-300 mb-4">
                You can't see each other's calendars, so everyone plays the availability guessing game.
              </p>
              <p className="text-base text-gray-600 dark:text-gray-400">
                But sharing your full calendar feels invasive. Who wants friends seeing their therapy appointments or job interviews?
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Section divider */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gray-200/10 dark:bg-gray-800/30" />
    </section>
  )
}
