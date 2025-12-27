import Flutter
import EventKit
import UIKit

/// iOS EventKit integration for LockItIn calendar access
/// Handles permission requests and event CRUD operations via platform channels
class CalendarPlugin: NSObject, FlutterPlugin {
    private let eventStore = EKEventStore()

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.lockitin.calendar",
            binaryMessenger: registrar.messenger()
        )
        let instance = CalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestPermission(result: result)
        case "checkPermission":
            checkPermission(result: result)
        case "fetchEvents":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for fetchEvents",
                    details: nil
                ))
                return
            }
            fetchEvents(args: args, result: result)
        case "createEvent":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for createEvent",
                    details: nil
                ))
                return
            }
            createEvent(args: args, result: result)
        case "updateEvent":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for updateEvent",
                    details: nil
                ))
                return
            }
            updateEvent(args: args, result: result)
        case "deleteEvent":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for deleteEvent",
                    details: nil
                ))
                return
            }
            deleteEvent(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Permission Management

    private func requestPermission(result: @escaping FlutterResult) {
        if #available(iOS 17.0, *) {
            // iOS 17+ uses async/await API
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    await MainActor.run {
                        result(granted ? "granted" : "denied")
                    }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "PERMISSION_ERROR",
                            message: "Failed to request calendar permission: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }
            }
        } else {
            // iOS 16 and below use callback-based API
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(
                            code: "PERMISSION_ERROR",
                            message: "Failed to request calendar permission: \(error.localizedDescription)",
                            details: nil
                        ))
                    } else {
                        result(granted ? "granted" : "denied")
                    }
                }
            }
        }
    }

    private func checkPermission(result: @escaping FlutterResult) {
        let status: EKAuthorizationStatus

        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        if #available(iOS 17.0, *) {
            switch status {
            case .authorized, .fullAccess:
                result("granted")
            case .denied:
                result("denied")
            case .restricted:
                result("restricted")
            case .notDetermined:
                result("notDetermined")
            case .writeOnly:
                // Write-only is not sufficient for our needs
                result("denied")
            @unknown default:
                result("notDetermined")
            }
        } else {
            switch status {
            case .authorized:
                result("granted")
            case .denied:
                result("denied")
            case .restricted:
                result("restricted")
            case .notDetermined:
                result("notDetermined")
            @unknown default:
                result("notDetermined")
            }
        }
    }

    // MARK: - Fetch Events

    private func fetchEvents(args: [String: Any], result: @escaping FlutterResult) {
        // Check permission first
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        if #available(iOS 17.0, *) {
            guard status == .authorized || status == .fullAccess else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        } else {
            guard status == .authorized else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        }

        // Parse date range
        guard let startMillis = args["startDate"] as? Int64,
              let endMillis = args["endDate"] as? Int64 else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid startDate/endDate",
                details: nil
            ))
            return
        }

        let startDate = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000)
        let endDate = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000)

        // Create predicate to fetch events in date range
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil // Fetch from all calendars
        )

        let events = eventStore.events(matching: predicate)

        // Convert events to Flutter-compatible format
        let eventData = events.map { event -> [String: Any?] in
            return [
                "nativeEventId": event.eventIdentifier,
                "title": event.title,
                "description": event.notes,
                "startTime": Int64(event.startDate.timeIntervalSince1970 * 1000),
                "endTime": Int64(event.endDate.timeIntervalSince1970 * 1000),
                "location": event.location,
                "isAllDay": event.isAllDay
            ]
        }

        result(eventData)
    }

    // MARK: - Create Event

    private func createEvent(args: [String: Any], result: @escaping FlutterResult) {
        // Check permission
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        if #available(iOS 17.0, *) {
            guard status == .authorized || status == .fullAccess else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        } else {
            guard status == .authorized else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        }

        // Parse event data
        guard let title = args["title"] as? String,
              let startMillis = args["startTime"] as? Int64,
              let endMillis = args["endTime"] as? Int64 else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing required event fields",
                details: nil
            ))
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = args["description"] as? String
        event.startDate = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000)
        event.endDate = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000)
        event.location = args["location"] as? String
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            result(event.eventIdentifier)
        } catch {
            result(FlutterError(
                code: "CREATE_FAILED",
                message: "Failed to create event: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    // MARK: - Update Event

    private func updateEvent(args: [String: Any], result: @escaping FlutterResult) {
        // Check permission
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        if #available(iOS 17.0, *) {
            guard status == .authorized || status == .fullAccess else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        } else {
            guard status == .authorized else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        }

        // Get event ID
        guard let eventId = args["nativeEventId"] as? String,
              let event = eventStore.event(withIdentifier: eventId) else {
            result(FlutterError(
                code: "EVENT_NOT_FOUND",
                message: "Event not found",
                details: nil
            ))
            return
        }

        // Update event fields
        if let title = args["title"] as? String {
            event.title = title
        }
        if let description = args["description"] as? String {
            event.notes = description
        }
        if let startMillis = args["startTime"] as? Int64 {
            event.startDate = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000)
        }
        if let endMillis = args["endTime"] as? Int64 {
            event.endDate = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000)
        }
        if let location = args["location"] as? String {
            event.location = location
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            result(nil)
        } catch {
            result(FlutterError(
                code: "UPDATE_FAILED",
                message: "Failed to update event: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    // MARK: - Delete Event

    private func deleteEvent(args: [String: Any], result: @escaping FlutterResult) {
        // Check permission
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        if #available(iOS 17.0, *) {
            guard status == .authorized || status == .fullAccess else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        } else {
            guard status == .authorized else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Calendar access not authorized",
                    details: nil
                ))
                return
            }
        }

        // Get event ID
        guard let eventId = args["nativeEventId"] as? String,
              let event = eventStore.event(withIdentifier: eventId) else {
            result(FlutterError(
                code: "EVENT_NOT_FOUND",
                message: "Event not found",
                details: nil
            ))
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            result(nil)
        } catch {
            result(FlutterError(
                code: "DELETE_FAILED",
                message: "Failed to delete event: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
}
