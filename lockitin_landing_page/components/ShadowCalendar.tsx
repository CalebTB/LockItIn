'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef, useState } from 'react'
import { Lock, Eye, Users } from 'lucide-react'

// Calendar event data with different privacy states
const calendarEvents = [
  {
    day: 'Mon',
    dayNumber: 9,
    events: [
      {
        title: 'Work Meeting',
        time: '9:00 AM - 5:00 PM',
        privacyState: 'busy' as const,
        actualTitle: 'Work Meeting'
      }
    ]
  },
  {
    day: 'Tue',
    dayNumber: 10,
    events: [
      {
        title: 'School Work',
        time: '6:00 PM - 9:00 PM',
        privacyState: 'private' as const,
        actualTitle: 'School Work'
      }
    ]
  },
  {
    day: 'Wed',
    dayNumber: 11,
    events: [
      {
        title: 'Doctor Appointment',
        time: '3:00 PM - 4:30 PM',
        privacyState: 'busy' as const,
        actualTitle: 'Doctor Appointment'
      }
    ]
  },
  {
    day: 'Thu',
    dayNumber: 12,
    events: []
  },
  {
    day: 'Fri',
    dayNumber: 13,
    events: []
  },
  {
    day: 'Sat',
    dayNumber: 14,
    events: [
      {
        title: 'Going to the Beach w Family',
        time: '2:00 PM - 6:00 PM',
        privacyState: 'shared' as const,
        actualTitle: 'Going to the Beach w Family'
      }
    ]
  },
  {
    day: 'Sun',
    dayNumber: 15,
    events: [
      {
        title: 'Weekend Brunch',
        time: '11:00 AM - 1:00 PM',
        privacyState: 'shared' as const,
        actualTitle: 'Weekend Brunch'
      }
    ]
  }
]

// CalendarMockup component showing privacy states
function CalendarMockup({ isInView }: { isInView: boolean }) {
  const [view, setView] = useState<'your' | 'groups'>('your')

  return (
    <div className="card overflow-hidden">
      {/* View Toggle */}
      <div className="flex items-center gap-2 mb-6 bg-gray-100 dark:bg-gray-800/50 rounded-lg p-1">
        <button
          onClick={() => setView('your')}
          className={`flex-1 px-4 py-2 rounded-md text-sm font-medium transition-all ${
            view === 'your'
              ? 'bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm'
              : 'text-gray-600 dark:text-gray-400'
          }`}
        >
          Your Calendar
        </button>
        <button
          onClick={() => setView('groups')}
          className={`flex-1 px-4 py-2 rounded-md text-sm font-medium transition-all ${
            view === 'groups'
              ? 'bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm'
              : 'text-gray-600 dark:text-gray-400'
          }`}
        >
          What Groups See
        </button>
      </div>

      {/* Calendar Grid */}
      <div className="grid grid-cols-7 gap-1 sm:gap-2 mb-6">
        {calendarEvents.map((day, index) => (
          <motion.div
            key={day.day}
            initial={{ opacity: 0, y: 20 }}
            animate={isInView ? { opacity: 1, y: 0 } : {}}
            transition={{ delay: 0.6 + index * 0.05 }}
            className="min-h-[120px] sm:min-h-[140px]"
          >
            {/* Day header */}
            <div className="text-center mb-2">
              <div className="text-xs sm:text-sm font-semibold text-gray-700 dark:text-gray-300">
                {day.day}
              </div>
              <div className="text-xs text-gray-500 dark:text-gray-400">
                {day.dayNumber}
              </div>
            </div>

            {/* Events */}
            <div className="space-y-1">
              {day.events.map((event, eventIndex) => (
                <CalendarEvent
                  key={eventIndex}
                  event={event}
                  view={view}
                  delay={0.8 + index * 0.05}
                  isInView={isInView}
                />
              ))}
            </div>
          </motion.div>
        ))}
      </div>

      {/* Privacy State Legend */}
      <div className="border-t border-gray-200 dark:border-gray-700 pt-4 space-y-2">
        <div className="flex items-center gap-2 text-xs sm:text-sm">
          <div className="w-3 h-3 rounded bg-gradient-to-br from-blue-500 to-blue-600 flex-shrink-0" />
          <span className="font-medium text-gray-700 dark:text-gray-300">Shared</span>
          <span className="text-gray-500 dark:text-gray-400">- Groups see full details</span>
        </div>
        <div className="flex items-center gap-2 text-xs sm:text-sm">
          <div className="w-3 h-3 rounded bg-gray-400 dark:bg-gray-600 flex-shrink-0" />
          <span className="font-medium text-gray-700 dark:text-gray-300">Busy</span>
          <span className="text-gray-500 dark:text-gray-400">- Groups see you're busy, not why</span>
        </div>
        <div className="flex items-center gap-2 text-xs sm:text-sm">
          <Lock className="w-3 h-3 text-gray-400 dark:text-gray-500 flex-shrink-0" />
          <span className="font-medium text-gray-700 dark:text-gray-300">Private</span>
          <span className="text-gray-500 dark:text-gray-400">- Completely hidden from groups</span>
        </div>
      </div>
    </div>
  )
}

// Individual calendar event component
function CalendarEvent({
  event,
  view,
  delay,
  isInView
}: {
  event: {
    title: string
    time: string
    privacyState: 'shared' | 'busy' | 'private'
    actualTitle: string
  }
  view: 'your' | 'groups'
  delay: number
  isInView: boolean
}) {
  // Determine what to show based on view and privacy state
  const getEventDisplay = () => {
    if (view === 'your') {
      // Show everything on "Your Calendar"
      return {
        title: event.actualTitle,
        time: event.time,
        show: true
      }
    } else {
      // "What Groups See" view
      if (event.privacyState === 'private') {
        return { title: '', time: '', show: false }
      } else if (event.privacyState === 'busy') {
        return { title: 'Busy', time: event.time, show: true }
      } else {
        return { title: event.actualTitle, time: event.time, show: true }
      }
    }
  }

  const display = getEventDisplay()

  if (!display.show) {
    // Private events are invisible in "What Groups See" view
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={isInView ? { opacity: view === 'your' ? 0.3 : 0 } : {}}
        transition={{ delay }}
        className={`${view === 'your' ? 'block' : 'hidden'}`}
      >
        <div className="bg-gray-200/30 dark:bg-gray-800/30 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded p-1 sm:p-2">
          <div className="flex items-center gap-1 justify-center">
            <Lock className="w-3 h-3 text-gray-400 dark:text-gray-500" />
            <span className="text-[10px] sm:text-xs text-gray-400 dark:text-gray-500 font-medium">
              Private
            </span>
          </div>
        </div>
      </motion.div>
    )
  }

  // Styling based on privacy state
  const getEventStyle = () => {
    if (event.privacyState === 'shared') {
      return 'bg-gradient-to-br from-blue-500 to-blue-600 text-white'
    } else if (event.privacyState === 'busy') {
      return 'bg-gray-400 dark:bg-gray-600 text-white'
    } else {
      return 'bg-gray-200/50 dark:bg-gray-800/50 border-2 border-dashed border-gray-300 dark:border-gray-600'
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.8 }}
      animate={isInView ? { opacity: 1, scale: 1 } : {}}
      transition={{ delay, type: "spring", stiffness: 200 }}
    >
      <div className={`rounded p-1 sm:p-2 ${getEventStyle()}`}>
        <div className="text-[10px] sm:text-xs font-medium leading-tight mb-0.5 sm:mb-1 line-clamp-2">
          {display.title}
        </div>
        <div className="text-[9px] sm:text-[10px] opacity-80 leading-tight">
          {display.time.split(' - ')[0]}
        </div>
        {event.privacyState === 'shared' && view === 'groups' && (
          <div className="flex items-center gap-1 mt-1 opacity-75">
            <Users className="w-2 h-2 sm:w-3 sm:h-3" />
            <span className="text-[8px] sm:text-[9px]">Shared</span>
          </div>
        )}
      </div>
    </motion.div>
  )
}

export default function ShadowCalendar() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  return (
    <section ref={ref} className="relative section-container bg-white dark:bg-gray-950">

      <div className="max-w-6xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-20"
        >
          <h2 className="text-4xl sm:text-5xl font-bold mb-6">
            The Shadow Calendar
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto text-balance">
            Share your availability without revealing private details. Our core innovation that makes privacy-first coordination possible.
          </p>
        </motion.div>

        {/* Main Solution Visual */}
        <div className="grid lg:grid-cols-2 gap-12 items-center mb-20">
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            animate={isInView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            <div className="card">
              <h3 className="text-2xl font-bold mb-4">The Shadow Calendar</h3>
              <p className="text-gray-600 dark:text-gray-400 mb-6">
                Our core innovation: Share when you're free without revealing private details.
              </p>

              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                    <span className="text-lg">🔒</span>
                  </div>
                  <div>
                    <div className="font-semibold mb-1">Private Events</div>
                    <div className="text-sm text-gray-600 dark:text-gray-400">
                      Doctor appointments, therapy, personal time—completely hidden
                    </div>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0">
                    <span className="text-lg">👁️</span>
                  </div>
                  <div>
                    <div className="font-semibold mb-1">Busy-Only Blocks</div>
                    <div className="text-sm text-gray-600 dark:text-gray-400">
                      Show you're busy without revealing event details
                    </div>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center flex-shrink-0">
                    <span className="text-lg">👥</span>
                  </div>
                  <div>
                    <div className="font-semibold mb-1">Shared with Details</div>
                    <div className="text-sm text-gray-600 dark:text-gray-400">
                      Group events where everyone sees the full details
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 30 }}
            animate={isInView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            {/* Visual Calendar Mockup */}
            <CalendarMockup isInView={isInView} />
          </motion.div>
        </div>

        {/* Why It Matters */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="bg-gradient-to-br from-primary/5 to-purple-500/5 rounded-3xl p-8 sm:p-12"
        >
          <div className="text-center mb-8">
            <h3 className="text-3xl font-bold mb-4">Privacy Without Friction</h3>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              You control exactly what each friend group sees. No compromises.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 gap-6 max-w-3xl mx-auto">
            <div className="text-center p-6">
              <div className="text-4xl mb-3">🔐</div>
              <div className="font-semibold text-lg mb-2">Keep Secrets Secret</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                Doctor appointments, job interviews, therapy—invisible to friends
              </div>
            </div>
            <div className="text-center p-6">
              <div className="text-4xl mb-3">⚡</div>
              <div className="font-semibold text-lg mb-2">Still Lightning Fast</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                See group availability instantly, no back-and-forth needed
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
