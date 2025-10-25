import Flutter
import UIKit
import GoogleMaps
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 AppDelegate: didFinishLaunchingWithOptions called")

    // Configure Firebase FIRST
    FirebaseApp.configure()
    print("✅ Firebase configured")

    // Set FCM messaging delegate IMMEDIATELY
    Messaging.messaging().delegate = self
    print("✅ FCM delegate set")

    // Configure Google Maps
    GMSServices.provideAPIKey("AIzaSyDwMeJhkBLaOqUfJYBX6ReGvaRaIYbSpFA")

    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("📱 Notification permission - Granted: \(granted), Error: \(String(describing: error))")
          if granted {
            DispatchQueue.main.async {
              print("📱 Calling registerForRemoteNotifications...")
              UIApplication.shared.registerForRemoteNotifications()
            }
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    // Also register immediately (redundant but ensures it's called)
    DispatchQueue.main.async {
      print("📱 [Immediate] Calling registerForRemoteNotifications...")
      application.registerForRemoteNotifications()
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // APNS TOKEN REGISTRATION SUCCESS
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅✅✅ didRegisterForRemoteNotificationsWithDeviceToken CALLED ✅✅✅")
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("✅ APNs device token: \(token)")

    // Set APNs token for Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNs token SET for Firebase Messaging")

    // Verify it was set
    if let apnsToken = Messaging.messaging().apnsToken {
      print("✅ VERIFIED: APNs token is now set in Firebase")
    } else {
      print("❌ WARNING: APNs token NOT set in Firebase after assignment")
    }
  }

  // APNS TOKEN REGISTRATION FAILURE
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌❌❌ didFailToRegisterForRemoteNotificationsWithError CALLED ❌❌❌")
    print("❌ Error: \(error.localizedDescription)")
    print("❌ Full error: \(error)")
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📩 Foreground notification: \(userInfo)")

    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")
    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔄🔄🔄 FCM Token received in AppDelegate: \(String(describing: fcmToken))")

    // Check if APNs token is set
    if let apnsToken = Messaging.messaging().apnsToken {
      print("✅ APNs token IS SET when FCM token received")
    } else {
      print("⚠️ APNs token NOT SET when FCM token received")
    }

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
