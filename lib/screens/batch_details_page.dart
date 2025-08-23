// import 'package:flutter/material.dart';
// import '../services/activity/ActivitiedsServices.dart';
// import '../services/activity/activities_batchServices/batchWithActivity.dart';
// import '../services/activity/activities_batchServices/batch_detail_models.dart';
//
// class BatchDetailPage extends StatefulWidget {
//   final Activity? activity;
//   final BatchWithActivity? batch;
//   final int? activityId;
//   final int? batchId;
//
//   const BatchDetailPage({
//     Key? key,
//     this.activity,
//     this.batch,
//     this.activityId,
//     this.batchId,
//   }) : super(key: key);
//
//   @override
//   _BatchDetailPageState createState() => _BatchDetailPageState();
// }
//
// class _BatchDetailPageState extends State<BatchDetailPage> {
//   Activity? currentActivity;
//   BatchWithActivity? currentBatch;
//   BatchDetail? batchDetail;
//   bool isLoading = false;
//   String? errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   void _initializeData() {
//     if (widget.activity != null) {
//       currentActivity = widget.activity;
//     } else if (widget.activityId != null) {
//       _fetchActivityById(widget.activityId!);
//     }
//
//     if (widget.batch != null) {
//       currentBatch = widget.batch;
//     } else if (widget.batchId != null) {
//       _fetchBatchDetailById(widget.batchId!);
//     }
//   }
//
//   Future<void> _fetchActivityById(int id) async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       final activity = await ActivitiesService.getActivityById(id);
//       setState(() {
//         currentActivity = activity;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Failed to load activity details';
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _fetchBatchDetailById(int id) async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       final detail = await BatchService.getBatchDetailById(id);
//       setState(() {
//         batchDetail = detail;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Failed to load batch details: ${e.toString()}';
//         isLoading = false;
//       });
//     }
//   }
//
//   String _getDisplayName() {
//     if (batchDetail != null) {
//       return batchDetail!.name;
//     }
//     if (currentBatch != null) {
//       return currentBatch!.displayName;
//     }
//     if (currentActivity != null) {
//       return currentActivity!.name;
//     }
//     return 'Loading...';
//   }
//
//   String _getDisplayId() {
//     if (batchDetail != null) {
//       return 'Batch ID: ${batchDetail!.id}';
//     }
//     if (currentBatch != null) {
//       return 'Batch ID: ${currentBatch!.id}';
//     }
//     if (currentActivity != null) {
//       return 'Activity ID: ${currentActivity!.id}';
//     }
//     return '';
//   }
//
//   String _formatAgeGroup() {
//     if (batchDetail != null && batchDetail!.ageRange.isNotEmpty) {
//       return 'Age Range: ${batchDetail!.ageRange}';
//     }
//     if (currentBatch != null && currentBatch!.ageRange.isNotEmpty) {
//       return 'Age Range: ${currentBatch!.ageRange}';
//     }
//     if (currentActivity != null) {
//       if (currentActivity!.ageGroupStart == currentActivity!.ageGroupEnd) {
//         return 'Recommended for ${currentActivity!.ageGroupStart} year olds';
//       } else {
//         return 'Recommended for ${currentActivity!.ageGroupStart}-${currentActivity!.ageGroupEnd} year olds';
//       }
//     }
//     return 'Age information not available';
//   }
//
//   String _getPriceInfo() {
//     if (batchDetail != null) {
//       return batchDetail!.priceDisplay;
//     }
//     if (currentBatch != null) {
//       return currentBatch!.priceDisplay;
//     }
//     if (currentActivity?.pricing.isNotEmpty == true) {
//       try {
//         final price = double.parse(currentActivity!.pricing);
//         return '₹${price.toStringAsFixed(0)}';
//       } catch (e) {
//         return '₹${currentActivity!.pricing}';
//       }
//     }
//     return 'Price not available';
//   }
//
//   String _getSessionInfo() {
//     if (batchDetail != null) {
//       if (batchDetail!.schedules.isNotEmpty) {
//         return '${batchDetail!.totalSessions} sessions total';
//       }
//       return 'Duration: ${batchDetail!.startDate} to ${batchDetail!.endDate}';
//     }
//     if (currentBatch != null) {
//       return 'Duration: ${currentBatch!.startDate} to ${currentBatch!.endDate}';
//     }
//     if (currentActivity?.batchesCount.isNotEmpty == true) {
//       return 'for ${currentActivity!.batchesCount} sessions';
//     }
//     return 'for multiple sessions';
//   }
//
//   String _getCapacityInfo() {
//     if (batchDetail != null) {
//       return 'Capacity: ${batchDetail!.capacity}';
//     }
//     if (currentBatch != null) {
//       return 'Capacity: ${currentBatch!.capacity}';
//     }
//     return '7 spots left';
//   }
//
//   bool _isBookable() {
//     if (batchDetail != null) {
//       return batchDetail!.isActive;
//     }
//     if (currentBatch != null) {
//       return currentBatch!.isBookable;
//     }
//     if (currentActivity != null) {
//       return currentActivity!.isActive;
//     }
//     return false;
//   }
//
//   String _getBannerImage() {
//     if (currentBatch?.activity.bannerImageUrl.isNotEmpty == true) {
//       return currentBatch!.activity.bannerImageUrl;
//     }
//     if (currentActivity?.bannerImageUrl.isNotEmpty == true) {
//       return currentActivity!.bannerImageUrl;
//     }
//     return 'assets/images/klayons_auth_cover.png';
//   }
//
//   String _getDescription() {
//     if (currentBatch?.activity.description.isNotEmpty == true) {
//       return currentBatch!.activity.description;
//     }
//     if (currentActivity?.description.isNotEmpty == true) {
//       return currentActivity!.description;
//     }
//     return 'Lorem ipsum dolor sit amet consectetur. Feugiat sollicitudin ut pellentesque in ultrices. Viverra odio id pellentesque felis sagittis arcu volutpat non vestibulum. At placerat elementum et eleifentum ut...';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: const Center(
//           child: CircularProgressIndicator(color: Colors.orange),
//         ),
//       );
//     }
//
//     if (errorMessage != null) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red, size: 48),
//               const SizedBox(height: 16),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Text(
//                   errorMessage!,
//                   style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => _initializeData(),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       extendBodyBehindAppBar: true,
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Image
//             Stack(
//               children: [
//                 Container(
//                   width: double.infinity,
//                   height: 250,
//                   decoration: BoxDecoration(
//                     image: _getBannerImage().startsWith('http')
//                         ? DecorationImage(
//                             image: NetworkImage(_getBannerImage()),
//                             fit: BoxFit.cover,
//                             onError: (error, stackTrace) {},
//                           )
//                         : DecorationImage(
//                             image: AssetImage(_getBannerImage()),
//                             fit: BoxFit.cover,
//                           ),
//                   ),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.black.withOpacity(0.3),
//                           Colors.transparent,
//                           Colors.black.withOpacity(0.1),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 30,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(30),
//                         topRight: Radius.circular(30),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // Content Section
//             Container(
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ID Badge
//                     if (_getDisplayId().isNotEmpty) ...[
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(15),
//                           border: Border.all(
//                             color: Colors.orange.withOpacity(0.3),
//                             width: 1,
//                           ),
//                         ),
//                         child: Text(
//                           _getDisplayId(),
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Activity/Batch Name
//                     Text(
//                       _getDisplayName(),
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//
//                     // Age Group
//                     Text(
//                       _formatAgeGroup(),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Price and Session Info
//                     Row(
//                       children: [
//                         Text(
//                           _getPriceInfo(),
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFFFF5722),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _getSessionInfo(),
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//
//                     // Batch Details
//                     if (batchDetail != null) ...[
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey!),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'BATCH DETAILS',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1.0,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.people,
//                                   size: 16,
//                                   color: Colors.grey,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(_getCapacityInfo()),
//                                 const Spacer(),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: batchDetail!.isActive
//                                         ? Colors.green.withOpacity(0.1)
//                                         : Colors.red.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     batchDetail!.isActive
//                                         ? 'Active'
//                                         : 'Inactive',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: batchDetail!.isActive
//                                           ? Colors.green
//                                           : Colors.red,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (batchDetail!.schedules.isNotEmpty) ...[
//                               const SizedBox(height: 12),
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   _buildSessionStat(
//                                     'Total',
//                                     batchDetail!.totalSessions.toString(),
//                                     Colors.blue,
//                                   ),
//                                   _buildSessionStat(
//                                     'Scheduled',
//                                     batchDetail!.scheduledSessions.toString(),
//                                     Colors.green,
//                                   ),
//                                   _buildSessionStat(
//                                     'Cancelled',
//                                     batchDetail!.cancelledSessions.toString(),
//                                     Colors.red,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                     ],
//
//                     // Schedules Section
//                     if (batchDetail != null &&
//                         batchDetail!.schedules.isNotEmpty) ...[
//                       const Text(
//                         'CLASS SCHEDULES',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 1.0,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       ...batchDetail!.schedules.map(
//                         (schedule) => _buildScheduleCard(schedule),
//                       ),
//                       const SizedBox(height: 24),
//                     ],
//
//                     // Book for section
//                     const Text(
//                       'Book for:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//
//                     // Child selection buttons
//                     Row(
//                       children: [
//                         _buildChildButton('Aarya', true),
//                         const SizedBox(width: 12),
//                         _buildChildButton('Khushi', false),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//
//                     // Spots left indicator
//                     Center(
//                       child: Text(
//                         _getCapacityInfo(),
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Enroll Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isBookable()
//                             ? () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(
//                                       'Enrolling in ${_getDisplayName()}...',
//                                     ),
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 );
//                               }
//                             : null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFFF5722),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: Text(
//                           _isBookable() ? 'Enroll' : 'Not Available',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Description Section
//                     const Text(
//                       'DESCRIPTION',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 1.0,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       _getDescription(),
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.black87,
//                         height: 1.5,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     GestureDetector(
//                       onTap: () {},
//                       child: const Text(
//                         'read more',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFFFF5722),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSessionStat(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//       ],
//     );
//   }
//
//   Widget _buildScheduleCard(BatchSchedule schedule) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             spreadRadius: 0,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   schedule.timeRange,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: schedule.isActive
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   schedule.isActive ? 'Active' : 'Inactive',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: schedule.isActive ? Colors.green : Colors.red,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (schedule.nextOccurrences.isNotEmpty) ...[
//             const SizedBox(height: 16),
//             const Text(
//               'Upcoming Sessions:',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 8),
//             ...schedule.nextOccurrences
//                 .take(5)
//                 .map((occurrence) => _buildOccurrenceItem(occurrence)),
//             if (schedule.nextOccurrences.length > 5) ...[
//               const SizedBox(height: 8),
//               Center(
//                 child: Text(
//                   '+ ${schedule.nextOccurrences.length - 5} more sessions',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOccurrenceItem(ScheduleOccurrence occurrence) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: occurrence.isCancelled
//                   ? Colors.red.withOpacity(0.1)
//                   : Colors.green.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Center(
//               child: Text(
//                 occurrence.day,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: occurrence.isCancelled ? Colors.red : Colors.green,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${occurrence.fullDay}, ${occurrence.date}',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   occurrence.time,
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               color: occurrence.isCancelled
//                   ? Colors.red.withOpacity(0.1)
//                   : Colors.green.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text(
//               occurrence.status,
//               style: TextStyle(
//                 fontSize: 10,
//                 color: occurrence.isCancelled ? Colors.red : Colors.green,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChildButton(String name, bool isSelected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xFFFF5722), width: 1),
//       ),
//       child: Text(
//         name,
//         style: TextStyle(
//           color: isSelected ? Colors.white : const Color(0xFFFF5722),
//           fontWeight: FontWeight.w500,
//           fontSize: 14,
//         ),
//       ),
//     );
//   }
// }
