import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'package:klayons/utils/colour.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/confermation_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart'; // if needed for route pop targets
import '../../../../services/user_child/post_addchildservice.dart';
import '../../../../services/user_child/get_ChildServices.dart';
import '../../../../utils/styles/button.dart';

class Interest {
  final int id;
  final String name;

  const Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) =>
      Interest(id: json['id'] as int, name: json['name'] as String);
}

class InterestService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app/api';

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
      setState(() {
        interests = loaded;
        isLoadingInterests = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoadingInterests = false;
      });
    }
  }

  Color _chipColor(int index) {
    // extend palette as needed
    const base = Colors.orange;
    return base;
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

  void _showConfirmationPopup(String childName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: ConfirmationPage(
            title: widget.isEditMode
                ? 'Profile Updated!'
                : 'Child Added Successfully!',
            subtitle: widget.isEditMode
                ? "Great! $childName's profile has been updated with new interests."
                : "Welcome $childName! Let's start the learning journey together.",
            buttonText: 'Back to Profile',
            primaryColor: Colors.orange,
            backgroundColor: const Color(0xFFFFF8F5),
            onButtonPressed: () {
              Navigator.of(context).pop(); // close dialog
              // pop back to profile flow; adjust pops as per actual nav stack
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ),
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
        final req = EditChildRequest(
          name: '${widget.childData.firstName} ${widget.childData.lastName}'
              .trim(),
          gender: _genderApi(widget.childData.gender),
          dob: _dateIso(widget.childData.dateOfBirth),
          interestIds: selectedInterestIds.toList(),
        );

        await GetChildservices.editChild(widget.childData.childId!, req);
        _showConfirmationPopup(widget.childData.firstName);
      } else {
        final result = await AddChildService.createChild(
          firstName: widget.childData.firstName,
          lastName: widget.childData.lastName,
          dateOfBirth: widget.childData.dateOfBirth,
          gender: widget.childData.gender,
          interestIds: selectedInterestIds.toList(),
        );

        if (result['success'] == true) {
          _showConfirmationPopup(widget.childData.firstName);
        } else {
          _showErrorDialog(
            result['error']?.toString() ?? 'Failed to create child',
          );
        }
      }
    } catch (e) {
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
        widget.isEditMode ? 'EDIT CHILD' : 'ADD CHILD',
        style: AppTextStyles.titleMedium(
          context,
        ).copyWith(color: Colors.black, letterSpacing: 1.2),
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
            Icon(Icons.error_outline, color: Colors.grey, size: 64),
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

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: interests.length,
      itemBuilder: (context, index) {
        final interest = interests[index];
        final isSelected = selectedInterestIds.contains(interest.id);
        final color = _chipColor(index);
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
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? color : Colors.white!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        interest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall(context).copyWith(
                          color: isSelected ? color : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              'WHAT INTERESTS YOUR CHILD?',
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
                  ? SizedBox(
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
