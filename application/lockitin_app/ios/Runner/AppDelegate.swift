import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Register custom CalendarPlugin for EventKit integration
    let controller = window?.rootViewController as! FlutterViewController
    CalendarPlugin.register(with: registrar(forPlugin: "CalendarPlugin")!)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
