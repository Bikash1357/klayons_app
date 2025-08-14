// // background_service.dart
// import 'package:workmanager/workmanager.dart';
// import 'notification_service.dart';
//
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print('Background task running: $task');
//
//     switch (task) {
//       case 'checkAnnouncements':
//         await NotificationService.checkForNewAnnouncements();
//         break;
//     }
//
//     return Future.value(true);
//   });
// }
//
// class BackgroundService {
//   static Future<void> initialize() async {
//     await Workmanager().initialize(
//       callbackDispatcher,
//       isInDebugMode: false, // Set to false in production
//     );
//
//     // Register periodic task to check for announcements every 15 minutes
//     await Workmanager().registerPeriodicTask(
//       'checkAnnouncementsTask',
//       'checkAnnouncements',
//       frequency: Duration(minutes: 15),
//       constraints: Constraints(
//         networkType: NetworkType.connected,
//       ),
//     );
//   }
//
//   static Future<void> checkNow() async {
//     await NotificationService.checkForNewAnnouncements();
//   }
// }
