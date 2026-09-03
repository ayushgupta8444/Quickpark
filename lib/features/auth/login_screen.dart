import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../location/location_permission_screen.dart';
import '../profile/car_details_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  bool _isLoading = false;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryRed = Color(0xFFEF0038);
  static const Color darkText = Color(0xFF181818);
  static const Color secondaryText = Color(0xFF737373);
  static const Color borderColor = Color(0xFFE0E1E4);

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  bool get _isPhoneValid {
    final String phone =
        _phoneController.text.trim();

    return RegExp(
      r'^[0-9]{10}$',
    ).hasMatch(phone);
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (!_isPhoneValid || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final String phoneNumber =
        '+91${_phoneController.text.trim()}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,

        // ------------------------------------------------------
        // AUTOMATIC VERIFICATION
        // ------------------------------------------------------

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final UserCredential result =
                await FirebaseAuth.instance
                    .signInWithCredential(
              credential,
            );

            final User? user = result.user;

            if (user == null) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }

              return;
            }

            await _savePhoneUser(user);

            if (mounted) {
              await _goToNextScreen(user);
            }
          } catch (e) {
            debugPrint(
              'Automatic verification error: $e',
            );

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },

        // ------------------------------------------------------
        // VERIFICATION FAILED
        // ------------------------------------------------------

        verificationFailed:
            (FirebaseAuthException e) {
          debugPrint(
            'Phone verification failed: ${e.code}',
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
          });

          String message =
              'Unable to send OTP. Please try again.';

          if (e.code ==
              'invalid-phone-number') {
            message =
                'Please enter a valid mobile number.';
          } else if (e.code ==
              'too-many-requests') {
            message =
                'Too many attempts. Please try again later.';
          } else if (e.message != null &&
              e.message!.isNotEmpty) {
            message = e.message!;
          }

          _showError(message);
        },

        // ------------------------------------------------------
        // CODE SENT
        // ------------------------------------------------------

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return OtpVerificationScreen(
                  verificationId:
                      verificationId,
                  phoneNumber:
                      phoneNumber,
                  resendToken:
                      resendToken,
                );
              },
            ),
          );
        },

        // ------------------------------------------------------
        // TIMEOUT
        // ------------------------------------------------------

        codeAutoRetrievalTimeout:
            (String verificationId) {
          debugPrint(
            'OTP auto retrieval timeout',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Send OTP error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // SAVE PHONE USER
  // ============================================================

  Future<void> _savePhoneUser(
    User user,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'provider': 'phone',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      debugPrint(
        'Save phone user error: $e',
      );
    }
  }

  // ============================================================
  // NEXT SCREEN
  // ============================================================

  Future<void> _goToNextScreen(
    User user,
  ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      final String carNumber =
          data?['carNumber']
                  ?.toString()
                  .trim() ??
              '';

      final String carModel =
          data?['carModel']
                  ?.toString()
                  .trim() ??
              '';

      if (!mounted) {
        return;
      }

      if (carNumber.isNotEmpty &&
          carModel.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LocationPermissionScreen();
            },
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const CarDetailsScreen();
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'Profile check error: $e',
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const CarDetailsScreen();
          },
        ),
        (route) => false,
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  // LOGIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            /*
             * ========================================================
             * REFERENCE DESIGN
             * ========================================================
             *
             * Logo       -> centered
             * Form       -> same left/right alignment
             * Title      -> large and bold
             * Input      -> wide professional field
             * Button     -> same width as input
             * Security   -> anchored near bottom
             *
             * The 45px horizontal margin is intentional.
             */

            const double horizontalPadding = 40.0;

            return Column(
              children: [
                // ==================================================
                // MAIN CONTENT
                // ==================================================

                Expanded(
                  child: SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),

                    child: Padding(
                      padding:
                          const EdgeInsets.only(
                        left:
                            horizontalPadding,
                        right:
                            horizontalPadding,
                        top: 22,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          // ========================================
                          // QUICKPARK LOGO
                          // ========================================

                          SizedBox(
                            width:
                                double.infinity,
                            height: 58,

                            child: Center(
                              child:
                                  Image.asset(
                                'assets/images/quickpark_logo2.png',
width: 210,
height: 62,
                                fit:
                                    BoxFit.contain,

                                filterQuality:
                                    FilterQuality
                                        .high,
                              ),
                            ),
                          ),

                          // ========================================
                          // LOGO → TITLE
                          // ========================================

                          const SizedBox(
  height: 34,
),
                          // ========================================
                          // TITLE
                          // ========================================

                          const Text(
                            'Enter your mobile number',

                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  darkText,
                              height: 1.15,
                              letterSpacing:
                                  -0.35,
                            ),
                          ),

                          // ========================================
                          // TITLE → SUBTITLE
                          // ========================================

                          const SizedBox(
                            height: 8,
                          ),

                          // ========================================
                          // SUBTITLE
                          // ========================================

                          const Text(
                            'Enter your phone number to book high-trust\n'
                            'valets in Bangalore',

                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w400,
                              color:
                                  secondaryText,
                              height: 1.35,
                            ),
                          ),

                          // ========================================
                          // SUBTITLE → LABEL
                          // ========================================

                          const SizedBox(
                            height: 30,
                          ),

                          // ========================================
                          // LABEL
                          // ========================================

                          const Text(
                            'MOBILE NUMBER',

                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  darkText,
                              height: 1,
                              letterSpacing:
                                  0.05,
                            ),
                          ),

                          // ========================================
                          // LABEL → INPUT
                          // ========================================

                          const SizedBox(
                            height: 9,
                          ),

                          // ========================================
                          // PHONE FIELD
                          // ========================================

                          _buildPhoneField(),

                          // ========================================
                          // INPUT → BUTTON
                          // ========================================

                          const SizedBox(
                            height: 24,
                          ),

                          // ========================================
                          // SEND OTP
                          // ========================================

                          _buildSendOtpButton(),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // SECURITY SECTION
                // ==================================================

                Padding(
                  padding:
                      const EdgeInsets.only(
                    left:
                        horizontalPadding,
                    right:
                        horizontalPadding,
                    bottom: 18,
                  ),

                  child:
                      _buildSecurityMessage(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _buildPhoneField() {
    return SizedBox(
      width: double.infinity,
      height: 48,

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(9),

          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),

        child: Row(
          children: [
            // ----------------------------------------------
            // LEFT PADDING
            // ----------------------------------------------

            const SizedBox(
              width: 13,
            ),

            // ----------------------------------------------
            // COUNTRY CODE
            // ----------------------------------------------

            const Text(
              '+91',

              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w500,
                color: darkText,
              ),
            ),

            // ----------------------------------------------
            // GAP
            // ----------------------------------------------

            const SizedBox(
              width: 10,
            ),

            // ----------------------------------------------
            // DIVIDER
            // ----------------------------------------------

            Container(
              width: 1,
              height: 20,
              color: borderColor,
            ),

            // ----------------------------------------------
            // PHONE NUMBER
            // ----------------------------------------------

            Expanded(
              child: TextField(
                controller:
                    _phoneController,

                keyboardType:
                    TextInputType.phone,

                textInputAction:
                    TextInputAction.done,

                maxLength: 10,

                onSubmitted: (_) {
                  if (_isPhoneValid) {
                    _sendOtp();
                  }
                },

                decoration:
                    const InputDecoration(
                  border:
                      InputBorder.none,

                  counterText: '',

                  hintText:
                      '98765 43210',

                  hintStyle:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w400,
                    color:
                        Color(
                      0xFF85858A,
                    ),
                  ),

                  contentPadding:
                      EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 1,
                  ),
                ),

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w400,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEND OTP BUTTON
  // ============================================================

  Widget _buildSendOtpButton() {
    final bool enabled =
        _isPhoneValid && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,

      child: ElevatedButton(
        onPressed:
            enabled ? _sendOtp : null,

        style:
            ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor:
              enabled
                  ? primaryRed
                  : const Color(
                      0xFFE0E2E6,
                    ),

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              const Color(
            0xFFE0E2E6,
          ),

          disabledForegroundColor:
              const Color(
            0xFF9BA4B0,
          ),

          padding:
              EdgeInsets.zero,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
        ),

        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,

                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Send OTP',

                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // SECURITY MESSAGE
  // ============================================================

  Widget _buildSecurityMessage() {
    return Column(
      children: [
        // ----------------------------------------------
        // DIVIDER
        // ----------------------------------------------

        Container(
          width: double.infinity,
          height: 1,
          color:
              const Color(0xFFF0F0F1),
        ),

        const SizedBox(
          height: 9,
        ),

        // ----------------------------------------------
        // SECURITY CONTENT
        // ----------------------------------------------

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ------------------------------------------
            // SHIELD
            // ------------------------------------------

            const SizedBox(
              width: 17,

              child: Icon(
                Icons.shield_outlined,
                size: 15,
                color:
                    Color(0xFF777A80),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // ------------------------------------------
            // TEXT
            // ------------------------------------------

            Expanded(
              child: Text(
                "We'll text you a one-time code. No password\n"
                'needed.',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w400,
                  color:
                      Color(0xFF73757A),
                  height: 1.35,
                ),
              ),
            ),

            const SizedBox(
              width: 17,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// OTP VERIFICATION SCREEN
// ============================================================================

class OtpVerificationScreen
    extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController
      _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  late String _verificationId;

  int? _resendToken;

  Timer? _timer;

  int _secondsRemaining = 30;

  bool _isLoading = false;

  static const Color primaryRed =
      Color(0xFFEF0038);

  static const Color darkText =
      Color(0xFF191919);

  static const Color secondaryText =
      Color(0xFF737373);

  static const Color borderColor =
      Color(0xFFE2E2E5);

  @override
  void initState() {
    super.initState();

    _verificationId =
        widget.verificationId;

    _resendToken =
        widget.resendToken;

    _otpController.addListener(
      _otpChanged,
    );

    _startTimer();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    _otpController.removeListener(
      _otpChanged,
    );

    _otpController.dispose();

    _otpFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // OTP CHANGE
  // ============================================================

  void _otpChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (_otpController.text.length ==
            6 &&
        !_isLoading) {
      _verifyOtp();
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 30;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          timer.cancel();

          setState(() {
            _secondsRemaining = 0;
          });
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  // ============================================================
  // MASK PHONE
  // ============================================================

  String get _maskedPhone {
    String number =
        widget.phoneNumber;

    if (number.startsWith('+91')) {
      number =
          number.substring(3);
    }

    if (number.length < 4) {
      return widget.phoneNumber;
    }

    return '+91 '
        '${number.substring(0, 3)}'
        '****'
        '${number.substring(number.length - 3)}';
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6 ||
        _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final PhoneAuthCredential
          credential =
          PhoneAuthProvider.credential(
        verificationId:
            _verificationId,
        smsCode:
            _otpController.text.trim(),
      );

      final UserCredential result =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user =
          result.user;

      if (user == null) {
        throw Exception(
          'User authentication failed',
        );
      }

      await _saveUser(user);

      if (!mounted) {
        return;
      }

      await _goNext(user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'OTP error: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (e.code ==
          'invalid-verification-code') {
        _showError(
          'Incorrect OTP.',
        );
      } else if (e.code ==
          'session-expired') {
        _showError(
          'OTP expired. Please request a new one.',
        );
      } else {
        _showError(
          'Unable to verify OTP.',
        );
      }
    } catch (e) {
      debugPrint(
        'OTP error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Unable to verify OTP.',
      );
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 ||
        _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .verifyPhoneNumber(
        phoneNumber:
            widget.phoneNumber,

        verificationCompleted:
            (PhoneAuthCredential
                credential) async {
          try {
            final UserCredential
                result =
                await FirebaseAuth
                    .instance
                    .signInWithCredential(
              credential,
            );

            final User? user =
                result.user;

            if (user != null &&
                mounted) {
              await _saveUser(user);
              await _goNext(user);
            }
          } catch (e) {
            debugPrint(
              'Automatic verification error: $e',
            );
          }
        },

        verificationFailed:
            (FirebaseAuthException e) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
          });

          _showError(
            e.message ??
                'Unable to resend OTP.',
          );
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _verificationId =
                verificationId;

            _resendToken =
                resendToken;

            _isLoading = false;

            _otpController.clear();
          });

          _startTimer();

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content:
                  Text(
                'New OTP sent.',
              ),
              behavior:
                  SnackBarBehavior
                      .floating,
            ),
          );
        },

        codeAutoRetrievalTimeout:
            (String verificationId) {
          _verificationId =
              verificationId;
        },

        forceResendingToken:
            _resendToken,
      );
    } catch (e) {
      debugPrint(
        'Resend error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Unable to resend OTP.',
      );
    }
  }

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<void> _saveUser(
    User user,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name':
              user.displayName ?? '',
          'email':
              user.email ?? '',
          'photoUrl':
              user.photoURL ?? '',
          'phoneNumber':
              user.phoneNumber ??
                  widget.phoneNumber,
          'provider': 'phone',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      debugPrint(
        'Firestore save error: $e',
      );
    }
  }

  // ============================================================
  // NEXT SCREEN
  // ============================================================

  Future<void> _goNext(
    User user,
  ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore
              .instance
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>?
          data =
          snapshot.data();

      final String carNumber =
          data?['carNumber']
                  ?.toString()
                  .trim() ??
              '';

      final String carModel =
          data?['carModel']
                  ?.toString()
                  .trim() ??
              '';

      if (!mounted) {
        return;
      }

      if (carNumber.isNotEmpty &&
          carModel.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LocationPermissionScreen();
            },
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const CarDetailsScreen();
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'Profile error: $e',
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const CarDetailsScreen();
          },
        ),
        (route) => false,
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior
                .floating,
        margin:
            const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  // OTP SCREEN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child:
            SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              29,
              20,
              29,
              30,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                // ================================================
                // BACK BUTTON
                // ================================================

                GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child:
                      const SizedBox(
                    width: 40,
                    height: 40,

                    child: Align(
                      alignment:
                          Alignment
                              .centerLeft,

                      child: Icon(
                        Icons
                            .arrow_back_ios_new,
                        size: 18,
                        color:
                            darkText,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                // ================================================
                // TITLE
                // ================================================

                const Text(
                  'Verify your number',

                  style:
                      TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        darkText,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'We sent a 6-digit code to',

                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        secondaryText,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ================================================
                // PHONE
                // ================================================

                Row(
                  children: [
                    Text(
                      _maskedPhone,

                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            darkText,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child:
                          const Text(
                        'Edit',

                        style:
                            TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 30,
                ),

                // ================================================
                // OTP BOXES
                // ================================================

                GestureDetector(
                  onTap: () {
                    _otpFocusNode
                        .requestFocus();
                  },

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children:
                        List.generate(
                      6,
                      (index) {
                        return _buildOtpBox(
                          index,
                        );
                      },
                    ),
                  ),
                ),

                // ================================================
                // HIDDEN OTP INPUT
                // ================================================

                SizedBox(
                  height: 1,

                  child: Opacity(
                    opacity: 0,

                    child:
                        TextField(
                      controller:
                          _otpController,

                      focusNode:
                          _otpFocusNode,

                      keyboardType:
                          TextInputType
                              .number,

                      maxLength: 6,

                      decoration:
                          const InputDecoration(
                        border:
                            InputBorder
                                .none,
                        counterText:
                            '',
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ================================================
                // RESEND
                // ================================================

                Center(
                  child:
                      _secondsRemaining >
                              0
                          ? Text(
                              'Resend code in '
                              '${_secondsRemaining}s',

                              style:
                                  const TextStyle(
                                fontSize:
                                    11,
                                color:
                                    secondaryText,
                              ),
                            )
                          : GestureDetector(
                              onTap:
                                  _resendOtp,

                              child:
                                  const Text(
                                'Resend code',

                                style:
                                    TextStyle(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      primaryRed,
                                ),
                              ),
                            ),
                ),

                const SizedBox(
                  height: 27,
                ),

                // ================================================
                // VERIFY BUTTON
                // ================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 44,

                  child:
                      ElevatedButton(
                    onPressed:
                        _otpController
                                        .text
                                        .length ==
                                    6 &&
                                !_isLoading
                            ? _verifyOtp
                            : null,

                    style:
                        ElevatedButton
                            .styleFrom(
                      elevation: 0,

                      backgroundColor:
                          primaryRed,

                      disabledBackgroundColor:
                          const Color(
                        0xFFE1E3E7,
                      ),

                      disabledForegroundColor:
                          const Color(
                        0xFF9CA5B2,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          9,
                        ),
                      ),
                    ),

                    child:
                        _isLoading
                            ? const SizedBox(
                                width:
                                    17,
                                height:
                                    17,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,

                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    Colors
                                        .white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Verify & Continue',

                                style:
                                    TextStyle(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OTP BOX
  // ============================================================

  Widget _buildOtpBox(
    int index,
  ) {
    final String otp =
        _otpController.text;

    final bool hasValue =
        index < otp.length;

    return Container(
      width: 42,
      height: 47,

      alignment:
          Alignment.center,

      decoration:
          BoxDecoration(
        color: hasValue
            ? const Color(
                0xFFFFF4F6,
              )
            : Colors.white,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color: hasValue
              ? primaryRed
              : borderColor,

          width:
              hasValue
                  ? 1.2
                  : 1,
        ),
      ),

      child: Text(
        hasValue
            ? otp[index]
            : '',

        style:
            const TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.w600,
          color: darkText,
        ),
      ),
    );
  }
}