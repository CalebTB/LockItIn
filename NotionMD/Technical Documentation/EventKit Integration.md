# EventKit Integration

```swift
// CalendarManager.swift
import EventKit
import Combine

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    // MARK: - Authorization
    
    func requestAccess() async throws -> Bool {
        let granted = try await eventStore.requestAccess(to: .event)
        await MainActor.run {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
        return granted
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard authorizationStatus == .authorized else { return [] }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        return eventStore.events(matching: predicate)
    }
    
    // MARK: - Create Event
    
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil
    ) throws -> String {
        guard authorizationStatus == .authorized else {
            throw CalendarError.notAuthorized
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }
    
    // MARK: - Update Event
    
    func updateEvent(
        identifier: String,
        title: String?,
        startDate: Date?,
        endDate: Date?
    ) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }
        
        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }
        
        try eventStore.save(event, span: .thisEvent)
    }
    
    // MARK: - Delete Event
    
    func deleteEvent(identifier: String) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }
        
        try eventStore.remove(event, span: .thisEvent)
    }
    
    // MARK: - Get Availability
    
    func getAvailability(
        for date: Date,
        duration: TimeInterval = 3600 // 1 hour default
    ) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let events = fetchEvents(from: startOfDay, to: endOfDay)
        
        // Generate 30-minute slots for the day
        var slots: [AvailabilitySlot] = []
        var currentTime = startOfDay
        
        while currentTime < endOfDay {
            let slotEnd = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
            
            let isBusy = events.contains { event in
                event.startDate < slotEnd && event.endDate > currentTime
            }
            
            slots.append(AvailabilitySlot(
                start: currentTime,
                end: slotEnd,
                status: isBusy ? .busy : .available
            ))
            
            currentTime = slotEnd
        }
        
        return slots
    }
}

// MARK: - Models

struct AvailabilitySlot {
    let start: Date
    let end: Date
    let status: AvailabilityStatus
}

enum AvailabilityStatus {
    case available
    case busy
    case unknown
}

enum CalendarError: Error {
    case notAuthorized
    case eventNotFound
    case saveFailed
}
```