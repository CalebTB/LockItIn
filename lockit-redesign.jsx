import React, { useState } from 'react';
import { Calendar, Users, Bell, User, Plus, Clock, MapPin, ChevronRight, Lock, UserCheck, CalendarCheck, Sparkles, Sun } from 'lucide-react';

// Sample data
const events = [
  { 
    id: 1, 
    title: 'Team Standup', 
    time: '9:00 AM', 
    location: 'Conference Room A',
    type: 'group',
    privacy: 'shared',
    group: 'Work Squad',
    attendees: 4,
    date: 'today'
  },
  { 
    id: 2, 
    title: 'Doctor Appointment', 
    time: '2:00 PM', 
    location: 'City Medical Center',
    type: 'personal',
    privacy: 'private',
    date: 'today'
  },
  { 
    id: 3, 
    title: 'Secret Santa Exchange', 
    time: '7:00 PM', 
    location: "Sarah's Apartment",
    type: 'group',
    privacy: 'shared',
    group: 'Friendsgiving Crew',
    attendees: 8,
    confirmed: true,
    date: 'tomorrow'
  },
  { 
    id: 4, 
    title: 'NYE Game Night', 
    time: '8:00 PM', 
    location: "Mike's Place",
    type: 'group',
    privacy: 'shared',
    group: 'Game Night',
    attendees: 5,
    votesNeeded: 3,
    date: 'dec31'
  },
];

const groups = [
  { id: 1, name: 'Friendsgiving Crew', emoji: '🦃', members: 8, upcomingEvents: 2 },
  { id: 2, name: 'Game Night', emoji: '🎮', members: 5, upcomingEvents: 1 },
  { id: 3, name: 'Book Club', emoji: '📚', members: 6, upcomingEvents: 0 },
  { id: 4, name: 'Hiking Squad', emoji: '🥾', members: 4, upcomingEvents: 1 },
];

const notifications = [
  { id: 1, type: 'vote', title: 'NYE Game Night needs your vote', time: '2h ago', unread: true },
  { id: 2, type: 'confirmed', title: 'Secret Santa confirmed!', time: '1d ago', unread: true },
  { id: 3, type: 'friend', title: 'Alex Rivera wants to connect', time: '2d ago', unread: false },
];

// Privacy badge component
const PrivacyBadge = ({ privacy }) => {
  if (privacy === 'private') {
    return (
      <div className="flex items-center gap-1 px-2 py-0.5 bg-slate-100 text-slate-600 rounded-full text-xs font-medium">
        <Lock size={10} />
        <span>Private</span>
      </div>
    );
  }
  return null;
};

// Event card component
const EventCard = ({ event }) => {
  const accentColors = {
    group: 'from-rose-500 to-orange-500',
    personal: 'from-slate-400 to-slate-500',
  };

  return (
    <div className="bg-white rounded-2xl p-4 border border-rose-100 hover:border-rose-200 hover:shadow-lg hover:shadow-rose-100/50 transition-all cursor-pointer group">
      <div className="flex gap-3">
        {/* Colored accent bar */}
        <div className={`w-1 self-stretch rounded-full bg-gradient-to-b ${accentColors[event.type]}`} />
        
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="font-semibold text-rose-900 truncate">{event.title}</span>
                {event.privacy === 'private' && <PrivacyBadge privacy={event.privacy} />}
              </div>
              
              <div className="flex items-center gap-1 text-sm text-rose-500">
                <Clock size={14} />
                <span>{event.time}</span>
              </div>
              
              {event.location && (
                <div className="flex items-center gap-1 text-sm text-rose-400 mt-0.5">
                  <MapPin size={14} />
                  <span className="truncate">{event.location}</span>
                </div>
              )}
            </div>
            
            <ChevronRight size={18} className="text-rose-300 group-hover:text-rose-500 transition-colors mt-1 flex-shrink-0" />
          </div>
          
          {/* Group info / Attendees */}
          {event.type === 'group' && (
            <div className="flex items-center gap-3 mt-3">
              {event.confirmed && (
                <span className="flex items-center gap-1 text-xs px-2 py-1 bg-emerald-50 text-emerald-700 rounded-full border border-emerald-200">
                  <CalendarCheck size={12} />
                  Confirmed
                </span>
              )}
              {event.votesNeeded && (
                <span className="flex items-center gap-1 text-xs px-2 py-1 bg-amber-50 text-amber-700 rounded-full border border-amber-200">
                  <Users size={12} />
                  {event.votesNeeded} votes needed
                </span>
              )}
              {!event.confirmed && !event.votesNeeded && (
                <div className="flex items-center gap-2">
                  <div className="flex -space-x-2">
                    {[...Array(Math.min(3, event.attendees))].map((_, i) => (
                      <div key={i} className="w-6 h-6 rounded-full bg-gradient-to-br from-rose-400 to-orange-400 border-2 border-white" />
                    ))}
                  </div>
                  <span className="text-xs text-rose-400">{event.attendees} attending</span>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Day section header
const DayHeader = ({ label, isToday }) => (
  <div className="sticky top-0 bg-gradient-to-b from-rose-50 via-rose-50 to-rose-50/80 backdrop-blur-sm py-3 px-4 -mx-4 z-10">
    <span className={`text-xs font-semibold uppercase tracking-wider ${isToday ? 'text-rose-600' : 'text-rose-400'}`}>
      {label}
    </span>
  </div>
);

// Week View Component
const WeekView = () => {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const dates = [23, 24, 25, 26, 27, 28, 29];
  const hours = ['8am', '9am', '10am', '11am', '12pm', '1pm', '2pm', '3pm', '4pm', '5pm', '6pm', '7pm', '8pm'];
  
  // Sample events positioned in the grid
  const weekEvents = [
    { day: 2, hour: 1, title: 'Team Standup', type: 'group', duration: 1 },
    { day: 2, hour: 6, title: 'Doctor Appt', type: 'private', duration: 1 },
    { day: 3, hour: 11, title: 'Secret Santa', type: 'group', duration: 2 },
    { day: 6, hour: 12, title: 'NYE Party', type: 'group', duration: 3 },
  ];

  const getEventAt = (dayIdx, hourIdx) => {
    return weekEvents.find(e => e.day === dayIdx && e.hour === hourIdx);
  };

  const isEventContinuation = (dayIdx, hourIdx) => {
    return weekEvents.some(e => 
      e.day === dayIdx && 
      hourIdx > e.hour && 
      hourIdx < e.hour + e.duration
    );
  };

  return (
    <div className="px-2 pb-24">
      {/* Day headers */}
      <div className="grid grid-cols-8 gap-0.5 mb-1 sticky top-0 bg-rose-50 z-10 pt-2 pb-1">
        <div className="w-10" /> {/* Spacer for time column */}
        {days.map((day, idx) => (
          <div key={day} className="text-center">
            <div className="text-xs text-rose-400 font-medium">{day}</div>
            <div className={`text-sm font-semibold mt-0.5 w-8 h-8 flex items-center justify-center mx-auto rounded-full ${
              dates[idx] === 27 
                ? 'bg-gradient-to-br from-rose-500 to-orange-500 text-white' 
                : 'text-rose-900'
            }`}>
              {dates[idx]}
            </div>
          </div>
        ))}
      </div>

      {/* Current time indicator */}
      <div className="relative">
        <div className="absolute left-10 right-0 top-[88px] h-0.5 bg-rose-500 z-20">
          <div className="absolute -left-1.5 -top-1 w-3 h-3 rounded-full bg-rose-500" />
        </div>
      </div>

      {/* Time grid */}
      <div className="relative">
        {hours.map((hour, hourIdx) => (
          <div key={hour} className="grid grid-cols-8 gap-0.5 border-t border-rose-100">
            {/* Time label */}
            <div className="w-10 pr-2 py-3 text-right">
              <span className="text-xs text-rose-400">{hour}</span>
            </div>
            
            {/* Day cells */}
            {days.map((_, dayIdx) => {
              const event = getEventAt(dayIdx, hourIdx);
              const isContinuation = isEventContinuation(dayIdx, hourIdx);
              
              return (
                <div 
                  key={dayIdx} 
                  className={`min-h-[44px] border-l border-rose-100 relative ${
                    dayIdx === 4 ? 'bg-rose-100/30' : '' // Today column highlight
                  }`}
                >
                  {event && !isContinuation && (
                    <div 
                      className={`absolute inset-x-0.5 top-0.5 rounded-lg p-1 z-10 ${
                        event.type === 'private' 
                          ? 'bg-slate-200 border border-slate-300' 
                          : 'bg-gradient-to-br from-rose-200 to-orange-200 border border-rose-300'
                      }`}
                      style={{ height: `${event.duration * 44 - 4}px` }}
                    >
                      <div className="flex items-center gap-0.5">
                        {event.type === 'private' && <Lock size={8} className="text-slate-600" />}
                        {event.type === 'group' && <Users size={8} className="text-rose-600" />}
                      </div>
                      <span className="text-[10px] font-medium text-rose-900 leading-tight line-clamp-2">
                        {event.title}
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
};

// Month View Component
const MonthView = ({ onDaySelect }) => {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // December 2025 calendar data
  const calendarWeeks = [
    [null, 1, 2, 3, 4, 5, 6],
    [7, 8, 9, 10, 11, 12, 13],
    [14, 15, 16, 17, 18, 19, 20],
    [21, 22, 23, 24, 25, 26, 27],
    [28, 29, 30, 31, null, null, null],
  ];

  // Event indicators per day (dots)
  const eventDots = {
    1: [{ color: 'rose' }],
    5: [{ color: 'rose' }],
    8: [{ color: 'rose' }],
    11: [{ color: 'rose' }, { color: 'amber' }],
    12: [{ color: 'violet' }],
    14: [{ color: 'rose' }],
    15: [{ color: 'rose' }, { color: 'violet' }],
    16: [{ color: 'amber' }],
    17: [{ color: 'rose' }],
    23: [{ color: 'rose' }],
    25: [{ color: 'amber' }, { color: 'rose' }],
    27: [{ color: 'rose' }, { color: 'violet' }],
    28: [{ color: 'rose' }],
    31: [{ color: 'violet' }, { color: 'rose' }, { color: 'amber' }],
  };

  const dotColors = {
    rose: 'bg-rose-500',
    amber: 'bg-amber-500',
    violet: 'bg-violet-500',
    emerald: 'bg-emerald-500',
  };

  return (
    <div className="px-4 pb-24">
      {/* Day headers */}
      <div className="grid grid-cols-7 gap-1 mb-2 pt-2">
        {days.map(day => (
          <div key={day} className="text-center text-xs font-medium text-rose-400 py-2">
            {day}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div className="space-y-1">
        {calendarWeeks.map((week, weekIdx) => (
          <div key={weekIdx} className="grid grid-cols-7 gap-1">
            {week.map((date, dayIdx) => {
              const isToday = date === 27;
              const dots = eventDots[date] || [];
              
              return (
                <button
                  key={dayIdx}
                  onClick={() => date && onDaySelect && onDaySelect(date)}
                  disabled={!date}
                  className={`aspect-square min-h-[44px] rounded-xl flex flex-col items-center justify-center transition-all ${
                    date ? 'hover:bg-rose-100 active:scale-95' : ''
                  } ${
                    isToday 
                      ? 'bg-gradient-to-br from-rose-500 to-orange-500 text-white shadow-lg shadow-rose-200' 
                      : 'text-rose-900'
                  }`}
                >
                  {date && (
                    <>
                      <span className={`text-sm font-medium ${isToday ? 'font-bold' : ''}`}>
                        {date}
                      </span>
                      {/* Event dots */}
                      {dots.length > 0 && (
                        <div className="flex gap-0.5 mt-1">
                          {dots.slice(0, 3).map((dot, i) => (
                            <div 
                              key={i} 
                              className={`w-1.5 h-1.5 rounded-full ${
                                isToday ? 'bg-white/80' : dotColors[dot.color]
                              }`} 
                            />
                          ))}
                          {dots.length > 3 && (
                            <span className={`text-[8px] font-medium ${isToday ? 'text-white/80' : 'text-rose-400'}`}>
                              +{dots.length - 3}
                            </span>
                          )}
                        </div>
                      )}
                    </>
                  )}
                </button>
              );
            })}
          </div>
        ))}
      </div>

      {/* Selected day preview (optional enhancement) */}
      <div className="mt-6 p-4 bg-white rounded-2xl border border-rose-100">
        <div className="text-xs font-semibold uppercase tracking-wider text-rose-400 mb-3">
          December 27 • Today
        </div>
        <div className="space-y-2">
          <div className="flex items-center gap-3 p-2 rounded-xl bg-rose-50">
            <div className="w-1 h-8 rounded-full bg-gradient-to-b from-rose-500 to-orange-500" />
            <div>
              <div className="text-sm font-medium text-rose-900">Team Standup</div>
              <div className="text-xs text-rose-500">9:00 AM</div>
            </div>
          </div>
          <div className="flex items-center gap-3 p-2 rounded-xl bg-slate-50">
            <div className="w-1 h-8 rounded-full bg-slate-400" />
            <div>
              <div className="text-sm font-medium text-rose-900">Doctor Appointment</div>
              <div className="text-xs text-rose-500">2:00 PM</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// Empty state component
const EmptyState = ({ variant = 'today' }) => {
  const content = {
    today: {
      icon: CalendarCheck,
      title: 'Nothing scheduled today',
      description: 'Your calendar is clear. Time to plan something fun?',
      primaryAction: 'Create Event',
      secondaryAction: 'View Groups',
    },
    week: {
      icon: Calendar,
      title: 'No events this week',
      description: 'Time to plan something with your groups?',
      primaryAction: 'Create Event',
      secondaryAction: 'View Groups',
    },
    new: {
      icon: Sparkles,
      title: 'Welcome to LockItIn',
      description: 'Create your first event to get started with group planning',
      primaryAction: 'Create Event',
      secondaryAction: 'Import Calendar',
    },
  };

  const { icon: Icon, title, description, primaryAction, secondaryAction } = content[variant];

  return (
    <div className="flex flex-col items-center justify-center py-12 px-8 text-center">
      <div className="w-20 h-20 rounded-full bg-gradient-to-br from-rose-100 to-orange-100 flex items-center justify-center mb-6">
        <Icon size={36} className="text-rose-400" />
      </div>
      <h3 className="text-lg font-semibold text-rose-900 mb-2">{title}</h3>
      <p className="text-sm text-rose-500 mb-6 max-w-xs">{description}</p>
      <button className="w-full max-w-xs py-3 bg-gradient-to-r from-rose-500 to-orange-500 text-white font-semibold rounded-xl shadow-lg shadow-rose-200 hover:shadow-rose-300 transition-all active:scale-[0.98]">
        + {primaryAction}
      </button>
      <button className="mt-3 text-sm font-medium text-rose-500 hover:text-rose-600">
        {secondaryAction}
      </button>
    </div>
  );
};

// Agenda View (Calendar Tab Content)
const AgendaView = () => {
  const todayEvents = events.filter(e => e.date === 'today');
  const tomorrowEvents = events.filter(e => e.date === 'tomorrow');
  const laterEvents = events.filter(e => !['today', 'tomorrow'].includes(e.date));

  return (
    <div className="px-4 pb-24">
      {/* Today */}
      <DayHeader label="Today • Wed Dec 27" isToday />
      {todayEvents.length > 0 ? (
        <div className="space-y-3 mb-6">
          {todayEvents.map(event => <EventCard key={event.id} event={event} />)}
        </div>
      ) : (
        <div className="py-4 text-center text-rose-400 text-sm mb-6">No events today</div>
      )}

      {/* Tomorrow */}
      <DayHeader label="Tomorrow • Thu Dec 28" />
      {tomorrowEvents.length > 0 ? (
        <div className="space-y-3 mb-6">
          {tomorrowEvents.map(event => <EventCard key={event.id} event={event} />)}
        </div>
      ) : (
        <div className="py-4 text-center text-rose-400 text-sm mb-6">No events</div>
      )}

      {/* Later */}
      <DayHeader label="Tue Dec 31" />
      <div className="space-y-3">
        {laterEvents.map(event => <EventCard key={event.id} event={event} />)}
      </div>
    </div>
  );
};

// Groups Tab Content
const GroupsTab = () => (
  <div className="px-4 pb-24">
    <div className="space-y-3 pt-4">
      {groups.map((group, idx) => (
        <button 
          key={group.id}
          className="w-full p-4 flex items-center gap-4 bg-white border border-rose-100 hover:border-rose-200 hover:shadow-lg hover:shadow-rose-100/50 rounded-2xl transition-all group"
        >
          <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-2xl shadow-lg ${
            idx % 4 === 0 ? 'bg-gradient-to-br from-amber-400 to-orange-500 shadow-orange-200' :
            idx % 4 === 1 ? 'bg-gradient-to-br from-violet-400 to-purple-500 shadow-purple-200' :
            idx % 4 === 2 ? 'bg-gradient-to-br from-rose-400 to-pink-500 shadow-pink-200' :
            'bg-gradient-to-br from-emerald-400 to-teal-500 shadow-teal-200'
          } group-hover:scale-105 transition-transform`}>
            {group.emoji}
          </div>
          <div className="flex-1 text-left">
            <div className="font-semibold text-rose-900">{group.name}</div>
            <div className="text-sm text-rose-400">{group.members} members</div>
          </div>
          <div className="flex items-center gap-2">
            {group.upcomingEvents > 0 && (
              <span className="text-xs px-2 py-1 bg-rose-100 text-rose-600 rounded-full font-medium">
                {group.upcomingEvents} upcoming
              </span>
            )}
            <ChevronRight size={20} className="text-rose-300 group-hover:text-rose-500 transition-colors" />
          </div>
        </button>
      ))}
      
      <button className="w-full p-4 flex items-center justify-center gap-2 border-2 border-dashed border-rose-200 text-rose-400 hover:border-rose-400 hover:text-rose-600 rounded-2xl transition-colors group">
        <Plus size={20} className="group-hover:rotate-90 transition-transform" />
        <span className="font-semibold">Create New Group</span>
      </button>
    </div>
  </div>
);

// Inbox Tab Content
const InboxTab = () => (
  <div className="px-4 pb-24">
    <div className="space-y-3 pt-4">
      {notifications.map(notif => (
        <div 
          key={notif.id}
          className={`p-4 rounded-2xl border transition-all cursor-pointer ${
            notif.unread 
              ? 'bg-white border-rose-200 shadow-sm' 
              : 'bg-rose-50/50 border-rose-100'
          }`}
        >
          <div className="flex items-start gap-3">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
              notif.type === 'vote' ? 'bg-amber-100 text-amber-600' :
              notif.type === 'confirmed' ? 'bg-emerald-100 text-emerald-600' :
              'bg-rose-100 text-rose-600'
            }`}>
              {notif.type === 'vote' && <Users size={18} />}
              {notif.type === 'confirmed' && <CalendarCheck size={18} />}
              {notif.type === 'friend' && <UserCheck size={18} />}
            </div>
            <div className="flex-1">
              <div className="flex items-start justify-between gap-2">
                <span className={`font-medium ${notif.unread ? 'text-rose-900' : 'text-rose-700'}`}>
                  {notif.title}
                </span>
                {notif.unread && (
                  <span className="w-2 h-2 rounded-full bg-rose-500 mt-2 flex-shrink-0" />
                )}
              </div>
              <span className="text-sm text-rose-400">{notif.time}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  </div>
);

// Profile Tab Content
const ProfileTab = () => (
  <div className="px-4 pb-24 pt-4">
    {/* User Info */}
    <div className="flex flex-col items-center mb-8">
      <div className="w-24 h-24 rounded-full bg-gradient-to-br from-rose-400 to-orange-400 flex items-center justify-center text-white text-3xl font-bold shadow-lg shadow-rose-200 mb-4">
        CB
      </div>
      <h2 className="text-xl font-bold text-rose-900">Caleb Brown</h2>
      <p className="text-sm text-rose-500">4 groups • 12 friends</p>
    </div>

    {/* Quick Actions */}
    <div className="space-y-2">
      {[
        { icon: Users, label: 'Friends', badge: '12' },
        { icon: Calendar, label: 'Calendar Sync', badge: null },
        { icon: Lock, label: 'Privacy Settings', badge: null },
        { icon: Bell, label: 'Notifications', badge: '3' },
      ].map((item, idx) => (
        <button 
          key={idx}
          className="w-full p-4 flex items-center gap-4 bg-white border border-rose-100 hover:border-rose-200 rounded-2xl transition-all"
        >
          <div className="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center text-rose-500">
            <item.icon size={20} />
          </div>
          <span className="flex-1 text-left font-medium text-rose-900">{item.label}</span>
          {item.badge && (
            <span className="px-2 py-0.5 bg-rose-100 text-rose-600 rounded-full text-sm font-medium">
              {item.badge}
            </span>
          )}
          <ChevronRight size={18} className="text-rose-300" />
        </button>
      ))}
    </div>
  </div>
);

// Main component
export default function LockItInRedesign() {
  const [activeTab, setActiveTab] = useState(0);
  const [calendarView, setCalendarView] = useState('day');

  const tabs = [
    { icon: Calendar, label: 'Calendar' },
    { icon: Users, label: 'Groups' },
    { icon: Bell, label: 'Inbox', badge: 2 },
    { icon: User, label: 'Profile' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-rose-50 to-amber-50 flex items-center justify-center p-4">
      
      {/* Ambient glow effects */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 -left-1/4 w-96 h-96 bg-rose-200/30 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 -right-1/4 w-96 h-96 bg-orange-200/30 rounded-full blur-3xl" />
      </div>

      {/* Phone Frame */}
      <div className="relative w-full max-w-sm bg-rose-50 rounded-[3rem] shadow-2xl shadow-rose-200/50 overflow-hidden h-[750px] border-[8px] border-rose-100">
        
        {/* Status Bar */}
        <div className="relative bg-rose-50 px-6 py-2 flex items-center justify-between text-xs">
          <span className="font-semibold text-rose-900">9:41</span>
          <div className="flex items-center gap-1">
            <div className="flex gap-0.5">
              {[1,2,3,4].map(i => (
                <div key={i} className={`w-1 h-1 rounded-full ${i < 4 ? 'bg-rose-900' : 'bg-rose-300'}`} />
              ))}
            </div>
            <span className="ml-1 text-rose-900">5G</span>
            <div className="w-6 h-3 border border-rose-900 rounded-sm ml-1 relative">
              <div className="absolute inset-0.5 bg-rose-900 rounded-sm" style={{width: '70%'}} />
            </div>
          </div>
        </div>

        {/* Header - Simplified (44pt height) */}
        <div className="relative bg-rose-50 px-4 py-3 flex items-center justify-between">
          <h1 className="text-xl font-bold text-rose-900">
            {activeTab === 0 && calendarView === 'week' && 'Dec 23-29, 2025'}
            {activeTab === 0 && calendarView !== 'week' && 'December 2025'}
            {activeTab === 1 && 'Groups'}
            {activeTab === 2 && 'Inbox'}
            {activeTab === 3 && 'Profile'}
          </h1>
          {activeTab === 0 && (
            <button className="px-3 py-1.5 text-sm font-semibold text-rose-600 hover:bg-rose-100 rounded-lg transition-colors">
              Today
            </button>
          )}
        </div>

        {/* View Switcher (Calendar tab only) */}
        {activeTab === 0 && (
          <div className="px-4 pb-3 bg-rose-50">
            <div className="flex p-1 bg-rose-100 rounded-xl">
              {['Day', 'Week', 'Month'].map((view) => (
                <button
                  key={view}
                  onClick={() => setCalendarView(view.toLowerCase())}
                  className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all ${
                    calendarView === view.toLowerCase()
                      ? 'bg-white text-rose-900 shadow-sm'
                      : 'text-rose-500 hover:text-rose-700'
                  }`}
                >
                  {view}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Main Content */}
        <div className="relative overflow-y-auto h-[calc(100%-180px)] bg-rose-50">
          {activeTab === 0 && calendarView === 'day' && <AgendaView />}
          {activeTab === 0 && calendarView === 'week' && <WeekView />}
          {activeTab === 0 && calendarView === 'month' && <MonthView onDaySelect={(day) => {
            console.log('Selected day:', day);
            setCalendarView('day');
          }} />}
          {activeTab === 1 && <GroupsTab />}
          {activeTab === 2 && <InboxTab />}
          {activeTab === 3 && <ProfileTab />}
        </div>

        {/* FAB - Single action, Calendar tab only */}
        {activeTab === 0 && (
          <button className="absolute bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-rose-500 to-orange-500 rounded-full shadow-lg shadow-rose-300 flex items-center justify-center text-white hover:shadow-rose-400 hover:scale-105 transition-all active:scale-95 z-20">
            <Plus size={28} strokeWidth={2.5} />
          </button>
        )}

        {/* Groups tab FAB */}
        {activeTab === 1 && (
          <button className="absolute bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-violet-500 to-purple-500 rounded-full shadow-lg shadow-purple-200 flex items-center justify-center text-white hover:shadow-purple-300 hover:scale-105 transition-all active:scale-95 z-20">
            <Plus size={28} strokeWidth={2.5} />
          </button>
        )}

        {/* Bottom Tab Bar */}
        <div className="absolute bottom-0 left-0 right-0 bg-white/90 backdrop-blur-xl border-t border-rose-100 px-2 pb-6 pt-2 z-30">
          <div className="flex items-center justify-around">
            {tabs.map((tab, idx) => (
              <button
                key={idx}
                onClick={() => setActiveTab(idx)}
                className={`flex flex-col items-center gap-1 px-4 py-1 rounded-xl transition-all ${
                  activeTab === idx ? 'text-rose-600' : 'text-rose-400 hover:text-rose-500'
                }`}
              >
                <div className="relative">
                  <tab.icon size={24} strokeWidth={activeTab === idx ? 2.5 : 2} />
                  {tab.badge && (
                    <span className="absolute -top-1 -right-1 w-4 h-4 bg-rose-500 text-white text-xs font-bold rounded-full flex items-center justify-center">
                      {tab.badge}
                    </span>
                  )}
                </div>
                <span className={`text-xs font-medium ${activeTab === idx ? 'font-semibold' : ''}`}>
                  {tab.label}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Home Indicator */}
        <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-32 h-1 bg-rose-900 rounded-full z-50" />
      </div>

      {/* Theme Label */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
        <div className="flex items-center gap-2 bg-white/80 border border-rose-200 backdrop-blur-sm px-4 py-2 rounded-full shadow-lg">
          <Sun size={16} className="text-orange-500" />
          <span className="text-sm font-medium text-rose-700">LockItIn Redesign</span>
        </div>
      </div>
    </div>
  );
}
