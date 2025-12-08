'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'

export default function Features() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  const features = [
    {
      icon: "📅",
      title: "Apple Calendar Sync",
      description: "Seamlessly syncs with your iPhone calendar. Events flow both ways automatically.",
      color: "from-blue-500 to-blue-600"
    },
    {
      icon: "🎯",
      title: "Smart Time Suggestions",
      description: "AI analyzes group availability and suggests the best 3 times instantly.",
      color: "from-orange-500 to-orange-600"
    },
    {
      icon: "✨",
      title: "Auto-Event Creation",
      description: "When voting closes, the event automatically adds to everyone's calendar. Zero friction.",
      color: "from-pink-500 to-pink-600"
    },
    {
      icon: "🚗",
      title: "Travel Time Alerts",
      description: "Know exactly when to leave with real-time traffic updates and departure notifications.",
      color: "from-cyan-500 to-cyan-600"
    },
    {
      icon: "📸",
      title: "Event Photo Albums",
      description: "After every event, share photos with your group. No time limits, no pressure. Year in Review included.",
      color: "from-purple-500 to-purple-600"
    }
  ]

  return (
    <section ref={ref} className="relative section-container bg-gray-50 dark:bg-gray-950">

      <div className="max-w-6xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            Everything You Need
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            Powerful features built for real-world event planning
          </p>
        </motion.div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8 mb-20">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="card group cursor-default transition-all duration-300 hover:shadow-lg hover:border-primary/30"
            >
              <div className={`feature-icon bg-gradient-to-br ${feature.color} mb-6 group-hover:scale-110 transition-transform duration-200`}>
                <span>{feature.icon}</span>
              </div>
              <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
              <p className="text-gray-600 dark:text-gray-400">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Special Event Templates */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.6 }}
        >
          <div className="text-center mb-12">
            <h3 className="text-3xl sm:text-4xl font-bold mb-4">
              Special Event Templates
            </h3>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
              Complex events made simple with purpose-built templates
            </p>
          </div>

          {/* Surprise Birthday Party - Split Screen */}
          <div className="bg-gradient-to-br from-primary/5 via-purple-500/5 to-pink-500/5 dark:from-primary/10 dark:via-purple-500/10 dark:to-pink-500/10 rounded-3xl p-8 sm:p-12 border border-primary/10 dark:border-primary/20">
            <div className="text-center mb-10">
              <div className="inline-flex items-center gap-3 bg-gradient-to-r from-primary to-purple-600 text-white px-6 py-3 rounded-full font-semibold text-lg mb-4">
                <span className="text-2xl">🎂</span>
                Surprise Birthday Party Mode
              </div>
              <p className="text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
                Plan the perfect surprise with hidden events, decoy calendars, and task coordination
              </p>
            </div>

            {/* Unified Split Screen - Single Container */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: 1.0 }}
              className="max-w-5xl mx-auto bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm rounded-3xl shadow-2xl overflow-hidden border border-gray-200 dark:border-gray-700"
            >
              {/* Unified Header */}
              <div className="bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 p-6 text-white">
                <div className="flex items-center justify-center gap-4 text-sm font-medium opacity-90 mb-2">
                  <div className="flex items-center gap-2">
                    <span>👤</span> Sarah's View
                  </div>
                  <div className="text-xl">↔</div>
                  <div className="flex items-center gap-2">
                    <span>👥</span> Friends' View
                  </div>
                </div>
                <div className="text-center text-lg font-semibold">
                  Two Different Realities, One Perfect Surprise
                </div>
              </div>

              {/* Side-by-Side Comparison */}
              <div className="grid md:grid-cols-2 divide-y md:divide-y-0 md:divide-x divide-gray-200 dark:divide-gray-700">
                {/* Left Side: What Sarah Sees */}
                <div className="p-6 sm:p-8 space-y-4">
                  <div className="flex items-center gap-2 text-blue-600 dark:text-blue-400 font-semibold mb-4">
                    <span className="text-xl">👤</span>
                    <span>What Sarah sees</span>
                  </div>

                  {/* Decoy Event Card */}
                  <div className="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/20 rounded-xl overflow-hidden border border-blue-200 dark:border-blue-700/50">
                    <div className="bg-gradient-to-r from-blue-500 to-blue-600 p-4 text-white">
                      <div className="text-xs opacity-90 mb-1">Saturday, March 15</div>
                      <div className="text-lg font-bold">Dinner with Mom</div>
                    </div>
                    <div className="p-4 space-y-2.5">
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">🕐</span>
                        <span>6:00 PM - 9:00 PM</span>
                      </div>
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">📍</span>
                        <span>Mom's House</span>
                      </div>
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">👥</span>
                        <span>Just you and Mom</span>
                      </div>
                    </div>
                  </div>

                  <div className="text-center text-xs text-gray-500 dark:text-gray-400 italic pt-2">
                    "Just a regular dinner, nothing suspicious..."
                  </div>
                </div>

                {/* Right Side: What Friends See */}
                <div className="p-6 sm:p-8 space-y-4 bg-gradient-to-br from-purple-50/30 to-pink-50/30 dark:from-purple-900/10 dark:to-pink-900/10">
                  <div className="flex items-center gap-2 text-purple-600 dark:text-purple-400 font-semibold mb-4">
                    <span className="text-xl">👥</span>
                    <span>What everyone else sees</span>
                  </div>

                  {/* Real Event Card */}
                  <div className="bg-gradient-to-br from-purple-50 to-pink-100 dark:from-purple-900/30 dark:to-pink-800/20 rounded-xl overflow-hidden border-2 border-purple-300 dark:border-purple-600/50">
                    <div className="bg-gradient-to-r from-purple-500 to-pink-600 p-4 text-white">
                      <div className="flex items-center gap-2 mb-1">
                        <div className="text-xs opacity-90">Saturday, March 15</div>
                        <div className="ml-auto bg-white/20 backdrop-blur-sm px-2 py-0.5 rounded-full text-xs font-semibold">
                          🤫 SURPRISE
                        </div>
                      </div>
                      <div className="text-lg font-bold">Sarah's Surprise Party!</div>
                    </div>
                    <div className="p-4 space-y-2.5">
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">🕐</span>
                        <span className="font-semibold">Arrive by 5:45 PM</span>
                        <span className="text-xs bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 px-1.5 py-0.5 rounded-full ml-auto">Before Sarah!</span>
                      </div>
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">📍</span>
                        <span>Dave's House (back entrance)</span>
                      </div>
                      <div className="flex items-center gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                        <span className="text-base">👥</span>
                        <span>15 friends attending</span>
                      </div>
                      <div className="mt-3 pt-3 border-t border-purple-200 dark:border-purple-700/50">
                        <div className="text-xs font-semibold text-gray-900 dark:text-white mb-2">Task Assignments:</div>
                        <div className="space-y-1.5 text-xs text-gray-600 dark:text-gray-400">
                          <div className="flex items-center gap-2">
                            <span className="text-sm">🎂</span>
                            <span>Mike: Pick up cake by 5pm</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-sm">🎈</span>
                            <span>Lisa: Decorations setup</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-sm">🚗</span>
                            <span>Tom: Get Sarah there at 6pm</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="text-center text-xs text-gray-500 dark:text-gray-400 italic pt-2">
                    "Everything coordinated, nothing forgotten"
                  </div>
                </div>
              </div>

              {/* Bottom Caption */}
              <div className="bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800/50 dark:to-gray-700/50 px-6 py-4 text-center border-t border-gray-200 dark:border-gray-700">
                <div className="text-sm text-gray-600 dark:text-gray-300 font-medium">
                  She sees a casual dinner → They coordinate the perfect surprise
                </div>
              </div>
            </motion.div>

            {/* Feature Highlights */}
            <div className="grid sm:grid-cols-3 gap-6 mt-12">
              <div className="text-center">
                <div className="text-3xl mb-2">🎭</div>
                <div className="font-semibold text-gray-900 dark:text-white mb-1">Hidden Events</div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Birthday person never sees the real plan</div>
              </div>
              <div className="text-center">
                <div className="text-3xl mb-2">📝</div>
                <div className="font-semibold text-gray-900 dark:text-white mb-1">Task Coordination</div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Assign cake, decorations, getting them there</div>
              </div>
              <div className="text-center">
                <div className="text-3xl mb-2">⏰</div>
                <div className="font-semibold text-gray-900 dark:text-white mb-1">Timeline Sync</div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Everyone arrives before the guest of honor</div>
              </div>
            </div>
          </div>

          {/* Potluck Template - Secondary */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={isInView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.6, delay: 1.2 }}
            className="mt-8 bg-gradient-to-br from-orange-50 to-amber-50 dark:from-orange-900/20 dark:to-amber-900/20 rounded-2xl p-8 border border-orange-100 dark:border-orange-800"
          >
            <div className="grid sm:grid-cols-2 gap-8 items-center">
              <div>
                <div className="inline-flex items-center gap-3 bg-gradient-to-r from-orange-500 to-amber-600 text-white px-5 py-2.5 rounded-full font-semibold mb-4">
                  <span className="text-xl">🍗</span>
                  Potluck & Friendsgiving
                </div>
                <h4 className="text-2xl font-bold mb-3 text-gray-900 dark:text-white">
                  Never bring the same dish twice
                </h4>
                <p className="text-gray-600 dark:text-gray-400 mb-4">
                  Coordinate dishes, track servings, avoid duplicates. Everyone knows what's needed and what's covered.
                </p>
                <div className="space-y-2 text-sm text-gray-700 dark:text-gray-300">
                  <div className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span>Dish signup by category (mains, sides, desserts)</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span>Serving size tracking for headcount</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span>Dietary restrictions visible to all</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span>Duplicate prevention warnings</span>
                  </div>
                </div>
              </div>
              <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg p-6 border border-gray-200 dark:border-gray-700">
                <div className="font-semibold text-gray-900 dark:text-white mb-4">Who's bringing what:</div>
                <div className="space-y-3 text-sm">
                  <div className="flex items-center justify-between pb-2 border-b border-gray-200 dark:border-gray-700">
                    <span className="text-gray-700 dark:text-gray-300">🦃 Turkey (serves 12)</span>
                    <span className="text-gray-500 dark:text-gray-400">Mike</span>
                  </div>
                  <div className="flex items-center justify-between pb-2 border-b border-gray-200 dark:border-gray-700">
                    <span className="text-gray-700 dark:text-gray-300">🥔 Mashed potatoes</span>
                    <span className="text-gray-500 dark:text-gray-400">Sarah</span>
                  </div>
                  <div className="flex items-center justify-between pb-2 border-b border-gray-200 dark:border-gray-700">
                    <span className="text-gray-700 dark:text-gray-300">🥧 Pumpkin pie (GF)</span>
                    <span className="text-gray-500 dark:text-gray-400">Lisa</span>
                  </div>
                  <div className="flex items-center justify-between pb-2 border-b border-dashed border-gray-300 dark:border-gray-600">
                    <span className="text-gray-400 dark:text-gray-500 italic">Stuffing - still needed</span>
                    <span className="text-xs bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300 px-2 py-1 rounded-full">Open</span>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>

      {/* Section divider */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gray-200/10 dark:bg-gray-800/30" />
    </section>
  )
}
