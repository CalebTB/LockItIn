package com.example.lockitin_app

import android.Manifest
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/**
 * Android CalendarContract integration for LockItIn calendar access
 * Handles permission requests and event CRUD operations via platform channels
 */
class CalendarPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var binding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null

    companion object {
        private const val CHANNEL_NAME = "com.lockitin.calendar"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    // FlutterPlugin implementation
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    // MethodCallHandler implementation
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "checkPermission" -> checkPermission(result)
            "fetchEvents" -> {
                val startDate = call.argument<Long>("startDate")
                val endDate = call.argument<Long>("endDate")
                if (startDate == null || endDate == null) {
                    result.error("INVALID_ARGUMENTS", "Missing startDate or endDate", null)
                } else {
                    fetchEvents(startDate, endDate, result)
                }
            }
            "createEvent" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments for createEvent", null)
                } else {
                    createEvent(args, result)
                }
            }
            "updateEvent" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments for updateEvent", null)
                } else {
                    updateEvent(args, result)
                }
            }
            "deleteEvent" -> {
                val nativeEventId = call.argument<String>("nativeEventId")
                if (nativeEventId == null) {
                    result.error("INVALID_ARGUMENTS", "Missing nativeEventId", null)
                } else {
                    deleteEvent(nativeEventId, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - Permission Management

    private fun requestPermission(result: Result) {
        val activity = binding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        if (hasCalendarPermission()) {
            result.success("granted")
        } else {
            pendingResult = result
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(
                    Manifest.permission.READ_CALENDAR,
                    Manifest.permission.WRITE_CALENDAR
                ),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun checkPermission(result: Result) {
        result.success(if (hasCalendarPermission()) "granted" else "denied")
    }

    private fun hasCalendarPermission(): Boolean {
        val activity = binding?.activity ?: return false
        val readPermission = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_CALENDAR
        )
        val writePermission = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.WRITE_CALENDAR
        )
        return readPermission == PackageManager.PERMISSION_GRANTED &&
                writePermission == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(if (granted) "granted" else "denied")
            pendingResult = null
            return true
        }
        return false
    }

    // MARK: - Fetch Events

    private fun fetchEvents(startMillis: Long, endMillis: Long, result: Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar access not authorized", null)
            return
        }

        val activity = binding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val contentResolver: ContentResolver = activity.contentResolver
            val events = mutableListOf<Map<String, Any?>>()

            // Query events in date range
            val projection = arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.DTEND,
                CalendarContract.Events.EVENT_LOCATION,
                CalendarContract.Events.ALL_DAY
            )

            val selection = "(${CalendarContract.Events.DTSTART} >= ? AND " +
                    "${CalendarContract.Events.DTSTART} <= ?) OR " +
                    "(${CalendarContract.Events.DTEND} >= ? AND " +
                    "${CalendarContract.Events.DTEND} <= ?)"

            val selectionArgs = arrayOf(
                startMillis.toString(),
                endMillis.toString(),
                startMillis.toString(),
                endMillis.toString()
            )

            val cursor: Cursor? = contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${CalendarContract.Events.DTSTART} ASC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val eventId = it.getLong(0)
                    val title = it.getString(1) ?: "Untitled Event"
                    val description = it.getString(2)
                    val dtStart = it.getLong(3)
                    val dtEnd = it.getLong(4)
                    val location = it.getString(5)
                    val allDay = it.getInt(6) == 1

                    events.add(
                        mapOf(
                            "nativeEventId" to eventId.toString(),
                            "title" to title,
                            "description" to description,
                            "startTime" to dtStart,
                            "endTime" to dtEnd,
                            "location" to location,
                            "isAllDay" to allDay
                        )
                    )
                }
            }

            result.success(events)
        } catch (e: Exception) {
            result.error("FETCH_FAILED", "Failed to fetch events: ${e.message}", null)
        }
    }

    // MARK: - Create Event

    private fun createEvent(args: Map<*, *>, result: Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar access not authorized", null)
            return
        }

        val activity = binding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val title = args["title"] as? String
                ?: throw IllegalArgumentException("Missing title")
            val startTime = args["startTime"] as? Long
                ?: throw IllegalArgumentException("Missing startTime")
            val endTime = args["endTime"] as? Long
                ?: throw IllegalArgumentException("Missing endTime")

            val contentResolver: ContentResolver = activity.contentResolver

            // Get primary calendar ID
            val calendarId = getPrimaryCalendarId(contentResolver)
                ?: throw IllegalStateException("No calendar found")

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, args["description"] as? String)
                put(CalendarContract.Events.DTSTART, startTime)
                put(CalendarContract.Events.DTEND, endTime)
                put(CalendarContract.Events.EVENT_LOCATION, args["location"] as? String)
                put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            }

            val uri: Uri? = contentResolver.insert(
                CalendarContract.Events.CONTENT_URI,
                values
            )

            if (uri != null) {
                val eventId = uri.lastPathSegment
                result.success(eventId)
            } else {
                result.error("CREATE_FAILED", "Failed to create event", null)
            }
        } catch (e: Exception) {
            result.error("CREATE_FAILED", "Failed to create event: ${e.message}", null)
        }
    }

    // MARK: - Update Event

    private fun updateEvent(args: Map<*, *>, result: Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar access not authorized", null)
            return
        }

        val activity = binding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val nativeEventId = args["nativeEventId"] as? String
                ?: throw IllegalArgumentException("Missing nativeEventId")

            val contentResolver: ContentResolver = activity.contentResolver
            val values = ContentValues()

            args["title"]?.let { values.put(CalendarContract.Events.TITLE, it as String) }
            args["description"]?.let { values.put(CalendarContract.Events.DESCRIPTION, it as String) }
            args["startTime"]?.let { values.put(CalendarContract.Events.DTSTART, it as Long) }
            args["endTime"]?.let { values.put(CalendarContract.Events.DTEND, it as Long) }
            args["location"]?.let { values.put(CalendarContract.Events.EVENT_LOCATION, it as String) }

            val uri = ContentUris.withAppendedId(
                CalendarContract.Events.CONTENT_URI,
                nativeEventId.toLong()
            )

            val updated = contentResolver.update(uri, values, null, null)
            if (updated > 0) {
                result.success(null)
            } else {
                result.error("UPDATE_FAILED", "Event not found", null)
            }
        } catch (e: Exception) {
            result.error("UPDATE_FAILED", "Failed to update event: ${e.message}", null)
        }
    }

    // MARK: - Delete Event

    private fun deleteEvent(nativeEventId: String, result: Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar access not authorized", null)
            return
        }

        val activity = binding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val contentResolver: ContentResolver = activity.contentResolver
            val uri = ContentUris.withAppendedId(
                CalendarContract.Events.CONTENT_URI,
                nativeEventId.toLong()
            )

            val deleted = contentResolver.delete(uri, null, null)
            if (deleted > 0) {
                result.success(null)
            } else {
                result.error("DELETE_FAILED", "Event not found", null)
            }
        } catch (e: Exception) {
            result.error("DELETE_FAILED", "Failed to delete event: ${e.message}", null)
        }
    }

    // MARK: - Helper Methods

    private fun getPrimaryCalendarId(contentResolver: ContentResolver): Long? {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.IS_PRIMARY} = 1"

        val cursor: Cursor? = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            null,
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                return it.getLong(0)
            }
        }

        // If no primary calendar, use first available calendar
        val allCalendarsCursor: Cursor? = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )

        allCalendarsCursor?.use {
            if (it.moveToFirst()) {
                return it.getLong(0)
            }
        }

        return null
    }
}
