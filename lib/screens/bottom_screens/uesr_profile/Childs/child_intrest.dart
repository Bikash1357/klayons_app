import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:klayons/utils/colour.dart';
import 'package:klayons/utils/styles/fonts.dart';
import '../../../../services/user_child/post_addchildservice.dart';
import '../../../../services/user_child/get_ChildServices.dart';
import '../../../../utils/styles/button.dart';
import 'add_child.dart';

class Interest {
  final int id;
  final String name;

  const Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) =>
      Interest(id: json['id'] as int, name: json['name'] as String);
}

class InterestService {
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';

  static Future<List<Interest>> getInterests() async {
    final uri = Uri.parse('$baseUrl/profiles/interests/');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((j) => Interest.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load interests (code: ${response.statusCode})');
  }
}

class AddChildInterestsPage extends StatefulWidget {
  final ChildData childData;
  final bool isEditMode;

  const AddChildInterestsPage({
    Key? key,
    required this.childData,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<AddChildInterestsPage> createState() => _AddChildInterestsPageState();
}

class _AddChildInterestsPageState extends State<AddChildInterestsPage> {
  final Set<int> selectedInterestIds = {};
  bool isSubmitting = false;
  bool isLoadingInterests = true;
  List<Interest> interests = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.childData.existingInterestIds != null) {
      selectedInterestIds.addAll(widget.childData.existingInterestIds!);
    }
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() {
      isLoadingInterests = true;
      errorMessage = null;
    });
    try {
      final loaded = await InterestService.getInterests();
      if (mounted) {
        setState(() {
          interests = loaded;
          isLoadingInterests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoadingInterests = false;
        });
      }
    }
  }

  Color _chipColor(int index) {
    return Colors.orange;
  }

  IconData _iconForInterest(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('robot')) return Icons.precision_manufacturing;
    if (lower.contains('speech')) return Icons.record_voice_over;
    if (lower.contains('drama')) return Icons.theater_comedy;
    if (lower.contains('chess')) return Icons.casino;
    if (lower.contains('taekwondo') || lower.contains('karate'))
      return Icons.sports_martial_arts;
    if (lower.contains('draw')) return Icons.brush;
    if (lower.contains('science')) return Icons.science;
    if (lower.contains('paint')) return Icons.palette;
    if (lower.contains('read')) return Icons.menu_book;
    if (lower.contains('dance')) return Icons.music_note;
    if (lower.contains('sing')) return Icons.mic;
    if (lower.contains('music')) return Icons.piano;
    if (lower.contains('sport')) return Icons.sports_soccer;
    if (lower.contains('cod')) return Icons.code;
    if (lower.contains('craft')) return Icons.handyman;
    if (lower.contains('language')) return Icons.language;
    if (lower.contains('swim')) return Icons.pool;
    if (lower.contains('cook') || lower.contains('chef'))
      return Icons.restaurant;
    if (lower.contains('photo')) return Icons.camera_alt;
    return Icons.interests;
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error', style: AppTextStyles.titleMedium(context)),
        content: Text(message, style: AppTextStyles.bodyMedium(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnrollmentSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFFF8F5),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: WavyBadgePainter(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isEditMode
                      ? 'Profile Updated Successfully'
                      : 'Profile Added Successfully',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      print('✅ Success dialog - returning to profile...');

                      // Close dialog
                      Navigator.of(context).pop();

                      // Pop AddChildInterestsPage with success result
                      Navigator.of(context).pop(true);

                      // Pop AddChildPage with success result
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _genderApi(String uiGender) =>
      uiGender.toLowerCase() == 'boy' ? 'male' : 'female';

  String _dateIso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (selectedInterestIds.isEmpty) {
      _showErrorDialog('Please select at least one interest');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      if (widget.isEditMode) {
        print('🔄 Updating child ID: ${widget.childData.childId}');

        final req = EditChildRequest(
          name: widget.childData.firstName.trim(),
          gender: _genderApi(widget.childData.gender),
          dob: _dateIso(widget.childData.dateOfBirth),
          interestIds: selectedInterestIds.toList(),
        );

        await GetChildservices.editChild(widget.childData.childId!, req);

        print('✅ Child updated successfully');
        _showEnrollmentSuccessDialog();
      } else {
        print('🔄 Creating new child profile...');

        final result = await AddChildService.createChild(
          firstName: widget.childData.firstName,
          dateOfBirth: widget.childData.dateOfBirth,
          gender: widget.childData.gender,
          interestIds: selectedInterestIds.toList(),
        );

        if (result['success'] == true) {
          print('✅ Child created successfully');
          _showEnrollmentSuccessDialog();
        } else {
          _showErrorDialog(
            result['error']?.toString() ?? 'Failed to create child',
          );
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorDialog(
        'Failed to ${widget.isEditMode ? 'update' : 'create'} child profile: $e',
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/App_icons/iconBack.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            AppColors.darkElements,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.isEditMode ? 'Edit Child' : 'Add Child',
        style: AppTextStyles.titleLarge(
          context,
        ).copyWith(color: AppColors.darkElements),
      ),
      centerTitle: false,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load interests',
              style: AppTextStyles.titleMedium(
                context,
              ).copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OrangeButton(
              onPressed: _loadInterests,
              child: Text(
                'Retry',
                style: AppTextStyles.titleSmall(
                  context,
                ).copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading interests...',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    if (interests.isEmpty) {
      return Center(
        child: Text(
          'No interests available',
          style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        children: interests.map((interest) {
          final isSelected = selectedInterestIds.contains(interest.id);
          final color = _chipColor(0);
          final icon = _iconForInterest(interest.name);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: isSubmitting
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          selectedInterestIds.remove(interest.id);
                        } else {
                          selectedInterestIds.add(interest.id);
                        }
                      });
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      interest.name,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: isSelected ? color : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionEnabled =
        selectedInterestIds.isNotEmpty && !isSubmitting && !isLoadingInterests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'What Interests Your Child?',
              style: AppTextStyles.titleMedium(
                context,
              ).copyWith(color: Colors.black87, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isEditMode
                  ? 'Update interests for ${widget.childData.firstName}'
                  : 'Select interests for ${widget.childData.firstName}',
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: isLoadingInterests
                  ? _buildLoadingState()
                  : (errorMessage != null
                        ? _buildErrorState()
                        : _buildInterestsGrid()),
            ),
            const SizedBox(height: 20),
            OrangeButton(
              isDisabled: !actionEnabled,
              onPressed: actionEnabled ? _submit : null,
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isEditMode
                          ? 'Update Child Profile'
                          : 'Save Child Profile',
                      style: AppTextStyles.titleMedium(
                        context,
                      ).copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavyBadgePainter extends CustomPainter {
  final Color color;

  WavyBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final waveCount = 12;
    final waveHeight = 4.0;

    for (int i = 0; i <= waveCount; i++) {
      final angle = (i / waveCount) * 2 * math.pi;
      final nextAngle = ((i + 1) / waveCount) * 2 * math.pi;

      final x1 = center.dx + (radius - waveHeight) * math.cos(angle);
      final y1 = center.dy + (radius - waveHeight) * math.sin(angle);

      final x2 = center.dx + radius * math.cos((angle + nextAngle) / 2);
      final y2 = center.dy + radius * math.sin((angle + nextAngle) / 2);

      if (i == 0) {
        path.moveTo(x1, y1);
      }
      path.quadraticBezierTo(
        x2,
        y2,
        center.dx + (radius - waveHeight) * math.cos(nextAngle),
        center.dy + (radius - waveHeight) * math.sin(nextAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
