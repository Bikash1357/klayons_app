import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/services/auth/signup_service.dart';
import 'package:klayons/services/auth/login_service.dart';
import 'package:klayons/utils/styles/fonts.dart';
import '../services/notification/fcmService.dart';
import '../utils/colour.dart';
import '../screens/home_screen.dart';
import 'dart:async';
import '../utils/styles/button.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String purpose;

  const OTPVerificationPage({
    Key? key,
    required this.email,
    required this.purpose,
  }) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _currentFocusIndex = 0;

  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _canResend = true;

  bool _isEmail(String input) {
    return input.contains('@');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      _currentFocusIndex = 0;
    });

    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _currentFocusIndex = i;
          });
        }
      });
    }

    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 30;
    });

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/auth_Background_Image.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    child: Text(
                      'OTP Verification',
                      style: AppTextStyles.titleMedium(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '6-digit code sent on ${_isEmail(widget.email) ? 'email' : 'WhatsApp'} at',
                        style: AppTextStyles.titleMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondary, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isEmail(widget.email)
                            ? widget.email
                            : '+91 ${widget.email}',
                        style: AppTextStyles.titleMedium(
                          context,
                        ).copyWith(color: AppColors.primaryOrange),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                6,
                                (index) => _buildOTPBox(index),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text(
                                    '00:${_resendCountdown.toString().padLeft(2, '0')}',
                                    style: AppTextStyles.titleSmall(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: (_canResend && !_isResending)
                                      ? _resendOTP
                                      : null,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    _isResending
                                        ? 'Resending...'
                                        : 'Resend Code',
                                    style: AppTextStyles.titleSmall(context)
                                        .copyWith(
                                          color: (_canResend && !_isResending)
                                              ? AppColors.primaryOrange
                                              : Colors.grey,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60),
                      OrangeButton(
                        onPressed: _verifyOTP,
                        isDisabled: _isLoading || !_isOTPComplete(),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Verifying...',
                                    style: AppTextStyles.titleMedium(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              )
                            : Text(
                                'Submit',
                                style: AppTextStyles.titleMedium(context)
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                              ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/App_icons/iconBack.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    AppColors.darkElements,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    bool isCurrentFocus = _currentFocusIndex == index;
    bool isFilled = _otpControllers[index].text.isNotEmpty;

    return Flexible(
      child: Container(
        width: 45,
        height: 50,
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isCurrentFocus ? AppColors.primaryOrange : Colors.grey[300]!,
            width: isCurrentFocus ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isCurrentFocus
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_otpControllers[index].text.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _otpControllers[index - 1].clear();
                  setState(() {
                    _currentFocusIndex = index - 1;
                  });
                } else if (_otpControllers[index].text.isNotEmpty) {
                  _otpControllers[index].clear();
                  setState(() {});
                }
              }
            }
          },
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty) {
                if (value.length > 1) {
                  _otpControllers[index].text = value.substring(
                    value.length - 1,
                  );
                }
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                  _currentFocusIndex = index + 1;
                } else {
                  _focusNodes[index].unfocus();
                }
              }
            },
            onTap: () {
              setState(() {
                _currentFocusIndex = index;
              });
              _otpControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _otpControllers[index].text.length,
              );
            },
          ),
        ),
      ),
    );
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getOTPCode().length == 6;
  }

  // ============= UPDATED: OTP VERIFICATION WITH FCM INTEGRATION =============
  Future<void> _verifyOTP() async {
    if (!_isOTPComplete()) {
      _showErrorMessage('Please enter complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting OTP verification for email: ${widget.email}');
      print('🎯 Purpose: ${widget.purpose}');
      print('🔢 OTP Code: ${_getOTPCode()}');

      final result = await AuthService.verifyOTP(
        email: widget.email,
        otpCode: _getOTPCode(),
        purpose: widget.purpose,
      );

      print('📋 OTP verification result: ${result.isSuccess}');
      print('💬 Message: ${result.message}');

      if (result.isSuccess) {
        print('🎉 OTP verification successful!');

        // Save the authentication token
        if (result.token != null && result.token!.isNotEmpty) {
          await TokenStorage.saveToken(result.token!);
          print('💾 Token saved successfully');

          // ========== FCM TOKEN INTEGRATION ==========
          print('🔔 Starting FCM token process...');

          // Get FCM token and send to backend
          bool fcmSuccess = await FCMService.getFCMTokenAndSendToBackend();

          if (fcmSuccess) {
            print('✅ FCM token successfully registered');
          } else {
            print('⚠️ FCM token registration failed, but continuing login');
            // Don't block user login if FCM fails
          }
          // =========================================

          _showSuccessMessage(
            result.message.isNotEmpty
                ? result.message
                : 'Verification successful!',
          );

          await Future.delayed(Duration(seconds: 1));

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => KlayonsHomePage()),
              (route) => false,
            );
          }
        } else {
          print('⚠️ No token received');
          _showErrorMessage('Verification successful but no token received');
        }
      } else {
        print('❌ OTP verification failed');
        String errorMessage = result.message.isNotEmpty
            ? result.message
            : 'Invalid OTP. Please try again.';
        _showErrorMessage(errorMessage);
        _clearOTPFields();
      }
    } catch (e) {
      print('🚨 OTP verification error: $e');
      _showErrorMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      print('Resending OTP to: ${widget.email}');

      final result = await AuthService.resendOTP(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (result.isSuccess) {
        _showSuccessMessage(
          result.message.isNotEmpty ? result.message : 'OTP has been resent.',
        );
        _clearOTPFields();
        _focusNodes[0].requestFocus();
        _currentFocusIndex = 0;
        _startResendTimer();
      } else {
        _showErrorMessage(
          result.message.isNotEmpty ? result.message : 'Failed to resend OTP.',
        );
      }
    } catch (e) {
      print('Resend OTP error: $e');
      _showErrorMessage('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {});
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
