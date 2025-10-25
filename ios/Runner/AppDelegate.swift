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
    // Configure Firebase
    FirebaseApp.configure()

    // Configure Google Maps
    GMSServices.provideAPIKey("AIzaSyDwMeJhkBLaOqUfJYBX6ReGvaRaIYbSpFA")

    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    // Set FCM messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle APNs token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 APNs device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    Messaging.messaging().apnsToken = deviceToken
  }

  // Handle APNs token registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📩 Foreground notification received: \(userInfo)")

    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")

    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // Handle FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔄 Firebase registration token: \(String(describing: fcmToken))")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}