package com.example.lockitin_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register CalendarPlugin for CalendarContract integration
        flutterEngine.plugins.add(CalendarPlugin())
    }
}
