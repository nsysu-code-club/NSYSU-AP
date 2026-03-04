import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    if(!UserDefaults.standard.bool(forKey: "Notification")) {
        UIApplication.shared.cancelAllLocalNotifications()
        UserDefaults.standard.set(true, forKey: "Notification")
    }
    //Course app widget must be iOS 14 above
    if #available(iOS 14.0, *) {
        //Course data export to app group
        let standrtUserDefaults = UserDefaults.standard
        let groupUserDefaults = UserDefaults(suiteName: "group.com.nsysu.ap")
        if let semester = standrtUserDefaults.string(forKey: "flutter.ap_common.current_semester_code"){
            if let text = standrtUserDefaults.string(forKey: "flutter.ap_common.course_data_\(semester)"){
                groupUserDefaults?.set(text, forKey: "course_notify")
            }
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
