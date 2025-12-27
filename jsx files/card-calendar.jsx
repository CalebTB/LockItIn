import React, { useState } from 'react';

const CardCalendar = () => {
  const [currentMonth, setCurrentMonth] = useState(new Date(2025, 0, 1));
  const [selectedDay, setSelectedDay] = useState(26);

  // Event categories with colors
  const categories = {
    social: { color: '#8B5CF6', bg: '#8B5CF620', label: 'Social', icon: '👥' },
    work: { color: '#3B82F6', bg: '#3B82F620', label: 'Work', icon: '💼' },
    fitness: { color: '#10B981', bg: '#10B98120', label: 'Fitness', icon: '🏃' },
    family: { color: '#F59E0B', bg: '#F59E0B20', label: 'Family', icon: '🏠' }
  };

  // Sample events with details
  const events = {
    '2025-01-03': [
      { type: 'social', title: 'Coffee with Mike' },
      { type: 'social', title: 'Game night' }
    ],
    '2025-01-05': [
      { type: 'fitness', title: 'Morning run' }
    ],
    '2025-01-08': [
      { type: 'work', title: 'Team sync' },
      { type: 'social', title: 'Happy hour' },
      { type: 'family', title: 'Dinner at Mom\'s' }
    ],
    '2025-01-10': [
      { type: 'family', title: 'Kids soccer game' },
      { type: 'family', title: 'Movie night' }
    ],
    '2025-01-12': [
      { type: 'social', title: 'Brunch' },
      { type: 'fitness', title: 'Gym session' },
      { type: 'fitness', title: 'Yoga class' }
    ],
    '2025-01-15': [
      { type: 'work', title: 'Client meeting' }
    ],
    '2025-01-17': [
      { type: 'social', title: 'Birthday party' },
      { type: 'work', title: 'Workshop' },
      { type: 'family', title: 'Family call' },
      { type: 'fitness', title: 'Tennis' }
    ],
    '2025-01-20': [
      { type: 'fitness', title: 'Cycling' },
      { type: 'fitness', title: 'Stretching' }
    ],
    '2025-01-22': [
      { type: 'social', title: 'Lunch with Sarah' }
    ],
    '2025-01-25': [
      { type: 'family', title: 'Anniversary dinner' },
      { type: 'social', title: 'Drinks after' },
      { type: 'work', title: 'Project review' }
    ],
    '2025-01-26': [
      { type: 'social', title: 'Board game afternoon' },
      { type: 'fitness', title: 'Evening walk' },
      { type: 'family', title: 'Video call with cousins' }
    ],
    '2025-01-28': [
      { type: 'work', title: 'Quarterly planning' },
      { type: 'work', title: 'Budget review' }
    ],
    '2025-01-30': [
      { type: 'social', title: 'Trivia night' },
      { type: 'fitness', title: 'Basketball' }
    ],
  };

  const getDaysInMonth = (date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const lastDay = new Date(year, month + 1, 0);
    return lastDay.getDate();
  };

  const formatDateKey = (day) => {
    const year = currentMonth.getFullYear();
    const month = String(currentMonth.getMonth() + 1).padStart(2, '0');
    const dayStr = String(day).padStart(2, '0');
    return `${year}-${month}-${dayStr}`;
  };

  const getEventCounts = (day) => {
    const dateKey = formatDateKey(day);
    const dayEvents = events[dateKey] || [];
    const counts = {};
    dayEvents.forEach(event => {
      counts[event.type] = (counts[event.type] || 0) + 1;
    });
    return counts;
  };

  const getDayEvents = (day) => {
    const dateKey = formatDateKey(day);
    return events[dateKey] || [];
  };

  const daysInMonth = getDaysInMonth(currentMonth);
  const monthName = currentMonth.toLocaleString('default', { month: 'long', year: 'numeric' });

  const prevMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1));
    setSelectedDay(1);
  };

  const nextMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1));
    setSelectedDay(1);
  };

  const getDayName = (day) => {
    const date = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day);
    return date.toLocaleString('default', { weekday: 'short' });
  };

  // Calculate month totals
  const monthTotals = {};
  Object.keys(events).forEach(dateKey => {
    if (dateKey.startsWith(`${currentMonth.getFullYear()}-${String(currentMonth.getMonth() + 1).padStart(2, '0')}`)) {
      events[dateKey].forEach(event => {
        monthTotals[event.type] = (monthTotals[event.type] || 0) + 1;
      });
    }
  });

  const selectedEvents = getDayEvents(selectedDay);

  return (
    <div className="min-h-screen bg-slate-50 font-sans">
      {/* Header */}
      <div className="bg-gradient-to-br from-violet-600 to-indigo-700 px-4 pt-6 pb-8 rounded-b-3xl shadow-lg">
        <div className="flex items-center justify-between mb-6">
          <button 
            onClick={prevMonth}
            className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center hover:bg-white/30 transition-colors"
          >
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="text-center">
            <h1 className="text-2xl font-bold text-white">{monthName}</h1>
            <p className="text-violet-200 text-sm">Friends Calendar</p>
          </div>
          <button 
            onClick={nextMonth}
            className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center hover:bg-white/30 transition-colors"
          >
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        {/* Month Summary Badges */}
        <div className="flex justify-center gap-3 flex-wrap">
          {Object.entries(categories).map(([key, { color, label, icon }]) => (
            <div 
              key={key}
              className="flex items-center gap-1.5 bg-white/20 backdrop-blur-sm rounded-full px-3 py-1.5"
            >
              <span className="text-sm">{icon}</span>
              <span 
                className="text-sm font-bold"
                style={{ color: 'white' }}
              >
                {monthTotals[key] || 0}
              </span>
            </div>
          ))}
        </div>
      </div>
      
      {/* Horizontal Day Selector */}
      <div className="px-4 -mt-4">
        <div className="bg-white rounded-2xl shadow-lg p-3 overflow-x-auto">
          <div className="flex gap-2" style={{ minWidth: 'max-content' }}>
            {Array.from({ length: daysInMonth }, (_, i) => i + 1).map(day => {
              const eventCounts = getEventCounts(day);
              const hasEvents = Object.keys(eventCounts).length > 0;
              const isSelected = selectedDay === day;
              const isToday = day === 26;
              
              return (
                <button
                  key={day}
                  onClick={() => setSelectedDay(day)}
                  className={`flex flex-col items-center min-w-[48px] py-2 px-1 rounded-xl transition-all
                    ${isSelected 
                      ? 'bg-gradient-to-br from-violet-500 to-indigo-600 shadow-lg shadow-violet-500/30' 
                      : isToday
                        ? 'bg-violet-100'
                        : 'hover:bg-slate-100'
                    }`}
                >
                  <span className={`text-xs font-medium ${isSelected ? 'text-violet-200' : 'text-slate-400'}`}>
                    {getDayName(day)}
                  </span>
                  <span className={`text-lg font-bold ${isSelected ? 'text-white' : 'text-slate-700'}`}>
                    {day}
                  </span>
                  {hasEvents && (
                    <div className="flex gap-0.5 mt-1">
                      {Object.entries(eventCounts).slice(0, 4).map(([type]) => (
                        <div
                          key={type}
                          className="w-1.5 h-1.5 rounded-full"
                          style={{ backgroundColor: isSelected ? 'white' : categories[type]?.color }}
                        />
                      ))}
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </div>
      
      {/* Selected Day Card */}
      <div className="px-4 mt-4">
        <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
          <div className="bg-gradient-to-r from-slate-50 to-slate-100 px-4 py-3 border-b border-slate-200">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold text-slate-800">
                  {new Date(currentMonth.getFullYear(), currentMonth.getMonth(), selectedDay)
                    .toLocaleString('default', { weekday: 'long', month: 'short', day: 'numeric' })}
                </h2>
                <p className="text-sm text-slate-500">
                  {selectedEvents.length} event{selectedEvents.length !== 1 ? 's' : ''} scheduled
                </p>
              </div>
              {selectedEvents.length > 0 && (
                <div className="flex gap-1">
                  {Object.entries(getEventCounts(selectedDay)).map(([type, count]) => (
                    <div
                      key={type}
                      className="w-7 h-7 rounded-lg flex items-center justify-center text-white text-xs font-bold"
                      style={{ backgroundColor: categories[type]?.color }}
                    >
                      {count}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
          
          {/* Events List */}
          <div className="p-4">
            {selectedEvents.length === 0 ? (
              <div className="text-center py-8">
                <div className="text-4xl mb-2">📅</div>
                <p className="text-slate-400">No events this day</p>
                <p className="text-sm text-slate-300">Tap + to add one</p>
              </div>
            ) : (
              <div className="space-y-3">
                {selectedEvents.map((event, idx) => (
                  <div
                    key={idx}
                    className="flex items-center gap-3 p-3 rounded-xl transition-all hover:scale-[1.02]"
                    style={{ backgroundColor: categories[event.type]?.bg }}
                  >
                    <div
                      className="w-12 h-12 rounded-xl flex items-center justify-center text-xl shadow-sm"
                      style={{ backgroundColor: categories[event.type]?.color }}
                    >
                      {categories[event.type]?.icon}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-slate-800">{event.title}</h3>
                      <p 
                        className="text-sm font-medium"
                        style={{ color: categories[event.type]?.color }}
                      >
                        {categories[event.type]?.label}
                      </p>
                    </div>
                    <svg className="w-5 h-5 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
      
      {/* Upcoming Events Card */}
      <div className="px-4 mt-4 pb-24">
        <div className="bg-white rounded-2xl shadow-lg p-4">
          <h3 className="font-bold text-slate-800 mb-3 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-violet-500"></span>
            Upcoming This Week
          </h3>
          <div className="space-y-2">
            {[26, 28, 30].map(day => {
              const dayEvents = getDayEvents(day);
              if (dayEvents.length === 0) return null;
              const eventCounts = getEventCounts(day);
              
              return (
                <button
                  key={day}
                  onClick={() => setSelectedDay(day)}
                  className="w-full flex items-center gap-3 p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-all text-left"
                >
                  <div className="text-center min-w-[40px]">
                    <div className="text-xs text-slate-400 font-medium">{getDayName(day)}</div>
                    <div className="text-xl font-bold text-slate-700">{day}</div>
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-slate-700 truncate">
                      {dayEvents[0].title}{dayEvents.length > 1 ? ` +${dayEvents.length - 1} more` : ''}
                    </p>
                  </div>
                  <div className="flex gap-1">
                    {Object.entries(eventCounts).map(([type, count]) => (
                      <div
                        key={type}
                        className="w-6 h-6 rounded-md flex items-center justify-center text-white text-xs font-bold"
                        style={{ backgroundColor: categories[type]?.color }}
                      >
                        {count}
                      </div>
                    ))}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
      
      {/* Floating Action Button */}
      <div className="fixed bottom-6 right-6">
        <button className="w-14 h-14 bg-gradient-to-br from-violet-500 to-indigo-600 rounded-full shadow-lg shadow-violet-500/40 flex items-center justify-center hover:scale-110 transition-transform">
          <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>
    </div>
  );
};

export default CardCalendar;
