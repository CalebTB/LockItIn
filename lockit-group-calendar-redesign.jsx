import React, { useState } from 'react';
import { ChevronLeft, ChevronRight, Users, Clock, X, Check, HelpCircle, Plus, Target, Calendar, Settings, Filter, UserPlus, AlertCircle, CheckCircle, Sun } from 'lucide-react';

// Sample group data
const group = {
  name: 'Friendsgiving Crew',
  emoji: '🦃',
  members: [
    { id: 1, name: 'You', avatar: 'Y', isYou: true },
    { id: 2, name: 'Sarah Chen', avatar: 'SC' },
    { id: 3, name: 'Mike Johnson', avatar: 'MJ' },
    { id: 4, name: 'Emma Wilson', avatar: 'EW' },
    { id: 5, name: 'Alex Rivera', avatar: 'AR' },
    { id: 6, name: 'Jordan Lee', avatar: 'JL' },
    { id: 7, name: 'Chris Park', avatar: 'CP' },
    { id: 8, name: 'Sam Taylor', avatar: 'ST' },
  ]
};

// Availability data for each day (0-8 members available)
const availabilityData = {
  1: 3, 2: 4, 3: 5, 4: 6, 5: 4, 6: 7, 7: 8,
  8: 5, 9: 4, 10: 3, 11: 2, 12: 4, 13: 6, 14: 7,
  15: 6, 16: 5, 17: 4, 18: 3, 19: 5, 20: 8, 21: 8,
  22: 7, 23: 6, 24: 5, 25: 8, 26: 7, 27: 6, 28: 8,
  29: 5, 30: 4, 31: 6
};

// Best days data with conflict info
const bestDays = [
  { day: 20, available: 8, total: 8, timeSlot: '9am-5pm', conflicts: [] },
  { day: 21, available: 8, total: 8, timeSlot: '9am-5pm', conflicts: [] },
  { day: 25, available: 8, total: 8, timeSlot: '5pm-10pm', conflicts: [] },
  { day: 28, available: 8, total: 8, timeSlot: '9am-5pm', conflicts: [] },
];

// Individual availability for selected day detail view
const dayDetailAvailability = {
  25: [
    { id: 1, name: 'You', avatar: 'Y', status: 'available', times: 'All day', isYou: true },
    { id: 2, name: 'Sarah Chen', avatar: 'SC', status: 'available', times: 'After 5pm' },
    { id: 3, name: 'Mike Johnson', avatar: 'MJ', status: 'available', times: 'All day' },
    { id: 4, name: 'Emma Wilson', avatar: 'EW', status: 'available', times: '2pm - 10pm' },
    { id: 5, name: 'Alex Rivera', avatar: 'AR', status: 'available', times: 'After 6pm' },
    { id: 6, name: 'Jordan Lee', avatar: 'JL', status: 'available', times: 'All day' },
    { id: 7, name: 'Chris Park', avatar: 'CP', status: 'available', times: 'After 4pm' },
    { id: 8, name: 'Sam Taylor', avatar: 'ST', status: 'available', times: 'All day' },
  ],
  20: [
    { id: 1, name: 'You', avatar: 'Y', status: 'available', times: 'All day', isYou: true },
    { id: 2, name: 'Sarah Chen', avatar: 'SC', status: 'available', times: 'All day' },
    { id: 3, name: 'Mike Johnson', avatar: 'MJ', status: 'available', times: 'All day' },
    { id: 4, name: 'Emma Wilson', avatar: 'EW', status: 'available', times: 'All day' },
    { id: 5, name: 'Alex Rivera', avatar: 'AR', status: 'available', times: 'All day' },
    { id: 6, name: 'Jordan Lee', avatar: 'JL', status: 'available', times: 'All day' },
    { id: 7, name: 'Chris Park', avatar: 'CP', status: 'available', times: 'All day' },
    { id: 8, name: 'Sam Taylor', avatar: 'ST', status: 'available', times: 'All day' },
  ],
  14: [
    { id: 1, name: 'You', avatar: 'Y', status: 'available', times: 'All day', isYou: true },
    { id: 2, name: 'Sarah Chen', avatar: 'SC', status: 'busy', times: '2-4pm conflict' },
    { id: 3, name: 'Mike Johnson', avatar: 'MJ', status: 'available', times: 'All day' },
    { id: 4, name: 'Emma Wilson', avatar: 'EW', status: 'available', times: 'After 12pm' },
    { id: 5, name: 'Alex Rivera', avatar: 'AR', status: 'available', times: 'All day' },
    { id: 6, name: 'Jordan Lee', avatar: 'JL', status: 'available', times: 'Evening only' },
    { id: 7, name: 'Chris Park', avatar: 'CP', status: 'available', times: 'All day' },
    { id: 8, name: 'Sam Taylor', avatar: 'ST', status: 'unknown', times: null },
  ],
  11: [
    { id: 1, name: 'You', avatar: 'Y', status: 'available', times: 'Morning only', isYou: true },
    { id: 2, name: 'Sarah Chen', avatar: 'SC', status: 'busy', times: null },
    { id: 3, name: 'Mike Johnson', avatar: 'MJ', status: 'busy', times: null },
    { id: 4, name: 'Emma Wilson', avatar: 'EW', status: 'busy', times: null },
    { id: 5, name: 'Alex Rivera', avatar: 'AR', status: 'busy', times: null },
    { id: 6, name: 'Jordan Lee', avatar: 'JL', status: 'available', times: 'Evening' },
    { id: 7, name: 'Chris Park', avatar: 'CP', status: 'busy', times: null },
    { id: 8, name: 'Sam Taylor', avatar: 'ST', status: 'unknown', times: null },
  ]
};

// Semantic heatmap colors (Green/Amber/Red/Gray)
const getHeatmapColor = (available, total) => {
  if (total === 0) return 'bg-gray-100';
  const ratio = available / total;
  if (ratio > 0.75) return 'bg-emerald-100'; // High availability - Green
  if (ratio >= 0.5) return 'bg-amber-100';   // Medium - Amber
  if (ratio > 0) return 'bg-red-100';         // Low - Red
  return 'bg-gray-100';                       // No data - Gray
};

const getHeatmapDot = (available, total) => {
  if (total === 0) return 'bg-gray-300';
  const ratio = available / total;
  if (ratio > 0.75) return 'bg-emerald-500'; // High
  if (ratio >= 0.5) return 'bg-amber-500';   // Medium
  if (ratio > 0) return 'bg-red-500';         // Low
  return 'bg-gray-300';                       // No data
};

const getHeatmapText = (available, total) => {
  if (total === 0) return 'text-gray-400';
  const ratio = available / total;
  if (ratio > 0.75) return 'text-emerald-700';
  if (ratio >= 0.5) return 'text-amber-700';
  if (ratio > 0) return 'text-red-700';
  return 'text-gray-400';
};

// Best Day Card Component
const BestDayCard = ({ day, available, total, timeSlot, conflicts, onClick, isFirst }) => (
  <button
    onClick={onClick}
    className={`w-full p-4 rounded-2xl border transition-all text-left hover:shadow-lg active:scale-[0.98] ${
      isFirst 
        ? 'bg-gradient-to-r from-orange-50 to-amber-50 border-orange-200 hover:border-orange-300 shadow-sm' 
        : 'bg-white border-rose-100 hover:border-rose-200'
    }`}
  >
    <div className="flex items-start justify-between">
      <div>
        <div className="font-semibold text-rose-900">
          {new Date(2025, 11, day).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
        </div>
        <div className="text-sm text-rose-500 mt-0.5">
          {available}/{total} members available
        </div>
      </div>
      <div className={`px-2 py-1 rounded-full text-xs font-medium ${
        available === total 
          ? 'bg-emerald-100 text-emerald-700' 
          : 'bg-amber-100 text-amber-700'
      }`}>
        {available === total ? 'Everyone free' : `${available} free`}
      </div>
    </div>
    
    <div className="flex items-center gap-2 mt-2">
      {conflicts.length === 0 ? (
        <span className="flex items-center gap-1 text-xs text-emerald-600">
          <CheckCircle size={12} />
          Everyone free {timeSlot}
        </span>
      ) : (
        <span className="flex items-center gap-1 text-xs text-amber-600">
          <AlertCircle size={12} />
          {conflicts[0]} has conflict
        </span>
      )}
    </div>
  </button>
);

// Member Avatar Component
const MemberAvatar = ({ member, size = 'md' }) => {
  const sizeClasses = {
    sm: 'w-8 h-8 text-xs',
    md: 'w-10 h-10 text-sm',
    lg: 'w-12 h-12 text-base'
  };
  
  return (
    <div className={`${sizeClasses[size]} rounded-full flex items-center justify-center font-semibold ${
      member.isYou 
        ? 'bg-gradient-to-br from-rose-400 to-orange-400 text-white' 
        : 'bg-violet-100 text-violet-700'
    }`}>
      {member.avatar}
    </div>
  );
};

export default function GroupCalendarRedesign() {
  const [selectedDay, setSelectedDay] = useState(null);
  const [membersExpanded, setMembersExpanded] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [currentMonth] = useState('December 2025');
  
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const totalMembers = group.members.length;
  
  // Generate calendar grid
  const calendarDays = [];
  const startOffset = 1; // December 2025 starts on Monday
  
  for (let i = 0; i < startOffset; i++) {
    calendarDays.push(null);
  }
  
  for (let day = 1; day <= 31; day++) {
    calendarDays.push(day);
  }

  const handleDayClick = (day) => {
    if (day) {
      setSelectedDay(day);
    }
  };

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

        {/* Header - Clean with more actions */}
        <div className="relative bg-rose-50 px-4 py-3 border-b border-rose-100">
          <div className="flex items-center gap-3">
            <button className="p-2 -ml-2 hover:bg-rose-100 rounded-full transition-colors">
              <ChevronLeft size={24} className="text-rose-700" />
            </button>
            <div className="flex-1 flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-violet-100 flex items-center justify-center text-xl">
                {group.emoji}
              </div>
              <div>
                <h1 className="text-lg font-bold text-rose-900">{group.name}</h1>
                <p className="text-sm text-rose-500">{group.members.length} members</p>
              </div>
            </div>
            <button 
              onClick={() => setShowFilters(true)}
              className="p-2 hover:bg-rose-100 rounded-full transition-colors"
            >
              <Filter size={20} className="text-rose-600" />
            </button>
            <button className="p-2 hover:bg-rose-100 rounded-full transition-colors">
              <Users size={20} className="text-rose-600" />
            </button>
          </div>
        </div>

        {/* Main Content - Scrollable */}
        <div className="overflow-y-auto h-[calc(100%-140px)] pb-20">
          
          {/* BEST DAYS SECTION - Promoted to top */}
          <div className="px-4 py-4 bg-white border-b border-rose-100">
            <div className="flex items-center gap-2 mb-3">
              <Target size={18} className="text-orange-500" />
              <span className="text-sm font-semibold uppercase tracking-wide text-rose-900">
                Best Days to Meet
              </span>
            </div>
            
            <div className="space-y-2">
              {bestDays.slice(0, 3).map((day, idx) => (
                <BestDayCard
                  key={day.day}
                  {...day}
                  isFirst={idx === 0}
                  onClick={() => setSelectedDay(day.day)}
                />
              ))}
            </div>
            
            {bestDays.length > 3 && (
              <button className="w-full mt-3 text-sm font-medium text-rose-600 hover:text-rose-700">
                View all {bestDays.length} best days →
              </button>
            )}
          </div>

          {/* AVAILABILITY CALENDAR SECTION */}
          <div className="px-4 py-4">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-semibold uppercase tracking-wide text-rose-400">
                Availability Calendar
              </span>
              {/* Legend */}
              <div className="flex items-center gap-1 text-xs text-rose-400">
                <div className="w-3 h-3 rounded bg-emerald-500" />
                <div className="w-3 h-3 rounded bg-amber-500" />
                <div className="w-3 h-3 rounded bg-red-500" />
              </div>
            </div>
            
            {/* Month Navigation */}
            <div className="flex items-center justify-between mb-3 bg-white rounded-xl p-2 border border-rose-100">
              <button className="p-1 hover:bg-rose-100 rounded transition-colors">
                <ChevronLeft size={20} className="text-rose-400" />
              </button>
              <span className="text-rose-900 font-medium">{currentMonth}</span>
              <button className="p-1 hover:bg-rose-100 rounded transition-colors">
                <ChevronRight size={20} className="text-rose-400" />
              </button>
            </div>

            {/* Calendar Grid */}
            <div className="bg-white rounded-2xl p-3 border border-rose-100">
              {/* Day Headers */}
              <div className="grid grid-cols-7 gap-1 mb-2">
                {days.map((day, i) => (
                  <div key={i} className="text-center text-xs font-medium text-rose-400 py-1">
                    {day}
                  </div>
                ))}
              </div>
              
              {/* Calendar Days with Semantic Colors */}
              <div className="grid grid-cols-7 gap-1">
                {calendarDays.map((day, i) => {
                  const available = day ? availabilityData[day] || 0 : 0;
                  const isSelected = day === selectedDay;
                  const isToday = day === 27;
                  const isBestDay = bestDays.some(d => d.day === day);
                  
                  return (
                    <button
                      key={i}
                      onClick={() => handleDayClick(day)}
                      disabled={!day}
                      className={`
                        aspect-square rounded-xl flex flex-col items-center justify-center
                        transition-all duration-150 relative
                        ${day ? getHeatmapColor(available, totalMembers) : 'bg-transparent'}
                        ${day ? 'hover:scale-105 active:scale-95 cursor-pointer' : 'cursor-default'}
                        ${isSelected ? 'ring-2 ring-rose-500 ring-offset-1' : ''}
                        ${isToday ? 'ring-2 ring-rose-400 ring-offset-1' : ''}
                      `}
                    >
                      {day && (
                        <>
                          <span className={`text-sm font-medium ${getHeatmapText(available, totalMembers)}`}>
                            {day}
                          </span>
                          {/* Colored dot indicator */}
                          <div className={`w-1.5 h-1.5 rounded-full mt-0.5 ${getHeatmapDot(available, totalMembers)}`} />
                          {/* Best day marker */}
                          {isBestDay && (
                            <div className="absolute -top-1 -right-1 w-2 h-2 bg-orange-400 rounded-full" />
                          )}
                        </>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* GROUP MEMBERS SECTION - Collapsible */}
          <div className="px-4 py-3">
            <button 
              onClick={() => setMembersExpanded(!membersExpanded)}
              className="w-full flex items-center justify-between bg-white rounded-xl p-3 border border-rose-100 hover:border-rose-200 transition-colors"
            >
              <div className="flex items-center gap-3">
                <span className="text-sm font-semibold uppercase tracking-wide text-rose-400">
                  Group Members
                </span>
                <span className="text-xs text-rose-400 bg-rose-100 px-2 py-0.5 rounded-full">
                  {totalMembers}
                </span>
              </div>
              <div className="flex items-center gap-2">
                {!membersExpanded && (
                  <div className="flex -space-x-2">
                    {group.members.slice(0, 4).map((member) => (
                      <MemberAvatar key={member.id} member={member} size="sm" />
                    ))}
                    {totalMembers > 4 && (
                      <div className="w-8 h-8 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center text-xs font-medium border-2 border-white">
                        +{totalMembers - 4}
                      </div>
                    )}
                  </div>
                )}
                <ChevronRight 
                  size={18} 
                  className={`text-rose-400 transition-transform ${membersExpanded ? 'rotate-90' : ''}`} 
                />
              </div>
            </button>
            
            {/* Expanded Members List */}
            {membersExpanded && (
              <div className="mt-2 bg-white rounded-xl border border-rose-100 divide-y divide-rose-50">
                {group.members.map((member) => (
                  <div key={member.id} className="flex items-center gap-3 p-3">
                    <MemberAvatar member={member} />
                    <div className="flex-1">
                      <div className="font-medium text-rose-900">{member.name}</div>
                      {member.isYou && <div className="text-xs text-rose-400">You</div>}
                    </div>
                  </div>
                ))}
                <button className="w-full p-3 flex items-center justify-center gap-2 text-rose-500 hover:bg-rose-50 transition-colors">
                  <UserPlus size={16} />
                  <span className="text-sm font-medium">Invite Members</span>
                </button>
              </div>
            )}
          </div>
        </div>

        {/* FAB - Propose Event */}
        <button className="absolute bottom-8 right-6 px-5 py-3 bg-gradient-to-r from-rose-500 to-orange-500 rounded-full shadow-lg shadow-rose-300 flex items-center gap-2 text-white font-semibold hover:shadow-rose-400 hover:scale-105 transition-all active:scale-95 z-20">
          <Plus size={20} />
          <span>Propose Event</span>
        </button>

        {/* Day Detail Sheet */}
        {selectedDay && (
          <div 
            className="absolute inset-0 bg-black/20 backdrop-blur-sm z-30 transition-opacity"
            onClick={() => setSelectedDay(null)}
          />
        )}
        
        <div className={`absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl z-40 transition-transform duration-300 ease-out shadow-2xl ${
          selectedDay ? 'translate-y-0' : 'translate-y-full'
        }`}>
          <div className="w-12 h-1.5 bg-rose-200 rounded-full mx-auto my-3" />
          
          {selectedDay && (
            <>
              <div className="px-5 pb-3 flex items-center justify-between border-b border-rose-100">
                <div>
                  <h2 className="font-bold text-xl text-rose-900">
                    {new Date(2025, 11, selectedDay).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
                  </h2>
                  <p className="text-sm text-rose-500">
                    {availabilityData[selectedDay]}/{totalMembers} members available
                  </p>
                </div>
                <button 
                  onClick={() => setSelectedDay(null)}
                  className="p-2 hover:bg-rose-100 rounded-full transition-colors"
                >
                  <X size={20} className="text-rose-400" />
                </button>
              </div>
              
              {/* Best Time Slots */}
              {availabilityData[selectedDay] >= totalMembers * 0.75 && (
                <div className="px-5 py-3 border-b border-rose-100">
                  <div className="flex items-center gap-2 mb-2">
                    <Target size={14} className="text-orange-500" />
                    <span className="text-xs font-semibold uppercase tracking-wide text-rose-400">
                      Best Time Slots
                    </span>
                  </div>
                  <div className="flex gap-2">
                    <div className="flex-1 p-3 bg-emerald-50 rounded-xl border border-emerald-200">
                      <div className="flex items-center gap-2">
                        <Clock size={14} className="text-emerald-600" />
                        <span className="text-sm font-medium text-emerald-700">9:00 - 11:00 AM</span>
                      </div>
                      <span className="text-xs text-emerald-600">Everyone free</span>
                    </div>
                    <div className="flex-1 p-3 bg-amber-50 rounded-xl border border-amber-200">
                      <div className="flex items-center gap-2">
                        <Clock size={14} className="text-amber-600" />
                        <span className="text-sm font-medium text-amber-700">2:00 - 4:00 PM</span>
                      </div>
                      <span className="text-xs text-amber-600">7/8 free</span>
                    </div>
                  </div>
                </div>
              )}
              
              {/* Availability Breakdown */}
              <div className="px-5 py-3">
                <div className="flex items-center gap-2 mb-3">
                  <Users size={14} className="text-rose-400" />
                  <span className="text-xs font-semibold uppercase tracking-wide text-rose-400">
                    Availability Breakdown
                  </span>
                </div>
                <div className="space-y-2 max-h-[30vh] overflow-y-auto">
                  {(dayDetailAvailability[selectedDay] || group.members.map(m => ({
                    ...m,
                    status: Math.random() > 0.3 ? 'available' : 'busy',
                    times: 'Unknown'
                  }))).map((member) => (
                    <div 
                      key={member.id}
                      className={`p-3 rounded-xl flex items-center gap-3 ${
                        member.status === 'available' 
                          ? 'bg-emerald-50 border border-emerald-100' 
                          : member.status === 'busy'
                            ? 'bg-red-50 border border-red-100'
                            : 'bg-gray-50 border border-gray-100'
                      }`}
                    >
                      <MemberAvatar member={member} />
                      <div className="flex-1">
                        <div className={`font-medium ${
                          member.status === 'available' ? 'text-emerald-900' : 
                          member.status === 'busy' ? 'text-red-900' : 'text-gray-600'
                        }`}>
                          {member.name}
                        </div>
                        {member.status === 'available' && member.times && (
                          <div className="text-sm text-emerald-600 flex items-center gap-1">
                            <Clock size={12} />
                            {member.times}
                          </div>
                        )}
                        {member.status === 'busy' && member.times && (
                          <div className="text-sm text-red-600 flex items-center gap-1">
                            <AlertCircle size={12} />
                            {member.times}
                          </div>
                        )}
                      </div>
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                        member.status === 'available' 
                          ? 'bg-emerald-100 text-emerald-600' 
                          : member.status === 'busy'
                            ? 'bg-red-100 text-red-600'
                            : 'bg-gray-100 text-gray-400'
                      }`}>
                        {member.status === 'available' ? <Check size={16} /> : 
                         member.status === 'busy' ? <X size={16} /> : 
                         <HelpCircle size={16} />}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              {/* Propose Event Button */}
              {availabilityData[selectedDay] >= totalMembers * 0.5 && (
                <div className="px-5 pb-6 pt-2">
                  <button className="w-full py-4 bg-gradient-to-r from-rose-500 to-orange-500 hover:from-rose-400 hover:to-orange-400 text-white font-semibold rounded-2xl transition-all active:scale-[0.98] shadow-lg shadow-rose-200">
                    Propose Event for {new Date(2025, 11, selectedDay).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </button>
                </div>
              )}
            </>
          )}
        </div>

        {/* Home Indicator */}
        <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-32 h-1 bg-rose-900 rounded-full z-50" />
      </div>

      {/* Theme Label */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
        <div className="flex items-center gap-2 bg-white/80 border border-rose-200 backdrop-blur-sm px-4 py-2 rounded-full shadow-lg">
          <Sun size={16} className="text-orange-500" />
          <span className="text-sm font-medium text-rose-700">Group Calendar Redesign</span>
        </div>
      </div>
    </div>
  );
}
