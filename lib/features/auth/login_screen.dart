import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../profile/car_details_screen.dart';
import '../location/location_permission_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _phoneController =
      TextEditingController();

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isLoading = false;
  bool _googleInitialized = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();

      if (!mounted) return;

      setState(() {
        _googleInitialized = true;
      });

      debugPrint('Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');

      if (!mounted) return;

      setState(() {
        _googleInitialized = false;
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // PHONE LOGIN
  // ============================================================

  Future<void> _continueWithPhone() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();

    // Validate phone number
    if (phone.length != 10 ||
        !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 10-digit mobile number',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final fullPhoneNumber = '+91$phone';

    debugPrint(
      'Sending OTP to $fullPhoneNumber',
    );

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,

        // ========================================================
        // VERIFICATION COMPLETED AUTOMATICALLY
        // ========================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final userCredential =
                await FirebaseAuth.instance
                    .signInWithCredential(credential);

            final user = userCredential.user;

            if (user != null) {
              await _savePhoneUserToFirestore(user);

              if (!mounted) return;

              await _goToNextScreen(user);
            }
          } catch (e) {
            debugPrint(
              'Automatic phone verification failed: $e',
            );
          }
        },

        // ========================================================
        // VERIFICATION FAILED
        // ========================================================

        verificationFailed:
            (FirebaseAuthException e) {
          debugPrint(
            'Phone verification failed: ${e.code}',
          );

          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          String message;

          switch (e.code) {
            case 'invalid-phone-number':
              message =
                  'The phone number entered is invalid.';
              break;

            case 'too-many-requests':
              message =
                  'Too many attempts. Please try again later.';
              break;

            case 'quota-exceeded':
              message =
                  'SMS quota exceeded. Please try again later.';
              break;

            default:
              message =
                  e.message ??
                  'Failed to send OTP. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        },

        // ========================================================
        // CODE SENT
        // ========================================================

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint(
            'OTP sent successfully',
          );

          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verificationId,
                phoneNumber: fullPhoneNumber,
                resendToken: resendToken,
              ),
            ),
          );
        },

        // ========================================================
        // AUTO RETRIEVAL TIMEOUT
        // ========================================================

        codeAutoRetrievalTimeout:
            (String verificationId) {
          debugPrint(
            'OTP auto retrieval timeout',
          );
        },

        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint(
        'Phone login error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE PHONE USER TO FIRESTORE
  // ============================================================

  Future<void> _savePhoneUserToFirestore(
    User user,
  ) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userRef.set(
      {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'provider': 'phone',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    debugPrint(
      'Phone user saved to Firestore: ${user.uid}',
    );
  }

  // ============================================================
  // SAVE GOOGLE USER TO FIRESTORE
  // ============================================================

  Future<void> _saveGoogleUserToFirestore(
    User user,
  ) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userRef.set(
      {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'provider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    debugPrint(
      'Google user saved to Firestore: ${user.uid}',
    );
  }

  // ============================================================
  // CHECK PROFILE AND NAVIGATE
  // ============================================================

  Future<void> _goToNextScreen(
    User user,
  ) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final String carNumber =
          (data?['carNumber'] ?? '')
              .toString()
              .trim();

      final String carModel =
          (data?['carModel'] ?? '')
              .toString()
              .trim();

      debugPrint(
        'Car Number: $carNumber',
      );

      debugPrint(
        'Car Model: $carModel',
      );

      if (!mounted) return;

      // ========================================================
      // PROFILE COMPLETE
      // ========================================================

      if (carNumber.isNotEmpty &&
          carModel.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LocationPermissionScreen(),
          ),
        );
      }

      // ========================================================
      // PROFILE NOT COMPLETE
      // ========================================================

      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CarDetailsScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Profile check failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to check profile: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> _continueWithGoogle() async {
    if (_isLoading) return;

    if (!_googleInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Sign-In is still initializing. '
            'Please try again.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // OPEN GOOGLE SIGN IN
      // ========================================================

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      // ========================================================
      // GET GOOGLE AUTH
      // ========================================================

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken =
          googleAuth.idToken;

      if (idToken == null ||
          idToken.isEmpty) {
        throw Exception(
          'Google ID token was not returned.',
        );
      }

      // ========================================================
      // CREATE FIREBASE CREDENTIAL
      // ========================================================

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Firebase user was not created.',
        );
      }

      debugPrint(
        'Google login successful: ${user.email}',
      );

      // ========================================================
      // SAVE USER
      // ========================================================

      await _saveGoogleUserToFirestore(user);

      // ========================================================
      // CHECK PROFILE
      // ========================================================

      await _goToNextScreen(user);
    }

    // ==========================================================
    // GOOGLE SIGN-IN ERROR
    // ==========================================================

    on GoogleSignInException catch (e) {
      debugPrint(
        'Google Sign-In Exception: ${e.code}',
      );

      if (!mounted) return;

      String message;

      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          message =
              'Google Sign-In was cancelled.';
          break;

        case GoogleSignInExceptionCode
            .clientConfigurationError:
          message =
              'Google Sign-In configuration is incorrect.';
          break;

        case GoogleSignInExceptionCode.interrupted:
          message =
              'Google Sign-In was interrupted.';
          break;

        default:
          message =
              'Google Sign-In failed: ${e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Exception: ${e.code}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase login failed: '
            '${e.message ?? e.code}',
          ),
        ),
      );
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Firebase Exception: ${e.code}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Database error: '
            '${e.message ?? e.code}',
          ),
        ),
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Google login error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    }

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Column(
            children: [
              const Spacer(),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 72,
                height: 72,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EE),
                  borderRadius:
                      BorderRadius.circular(22),
                ),

                child: const Center(
                  child: Text(
                    'Q',
                    style: TextStyle(
                      color: Color(0xFFEF0038),
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Welcome to QuickPark',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // SUBTITLE
              // ==================================================

              const Text(
                'Park smarter. Skip the waiting.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF707070),
                ),
              ),

              const SizedBox(height: 36),

              // ==================================================
              // MOBILE LABEL
              // ==================================================

              const Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  'Mobile number',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),

              const SizedBox(height: 9),

              // ==================================================
              // MOBILE INPUT
              // ==================================================

              Container(
                height: 56,

                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F6),
                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: Row(
                  children: [
                    const SizedBox(width: 16),

                    const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFD8D8D8),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextField(
                        controller:
                            _phoneController,

                        keyboardType:
                            TextInputType.phone,

                        maxLength: 10,

                        decoration:
                            const InputDecoration(
                          hintText:
                              'Enter mobile number',

                          border:
                              InputBorder.none,

                          counterText: '',

                          hintStyle:
                              TextStyle(
                            fontSize: 16,
                            color:
                                Color(0xFF888888),
                          ),
                        ),

                        style:
                            const TextStyle(
                          fontSize: 16,
                          color:
                              Color(0xFF171717),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CONTINUE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _continueWithPhone,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF0038),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        const Color(0xFFEF0038),

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // OR
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Color(0xFFE3E3E3),
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 14,
                    ),

                    child: Text(
                      'OR',

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF888888),
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Divider(
                      color: Color(0xFFE3E3E3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // GOOGLE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: OutlinedButton(
                  onPressed:
                      (_isLoading ||
                              !_googleInitialized)
                          ? null
                          : _continueWithGoogle,

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF171717),

                    side:
                        const BorderSide(
                      color:
                          Color(0xFFE0E0E0),
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Container(
                        width: 22,
                        height: 22,

                        decoration:
                            const BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color:
                              Color(0xFFF5F5F5),
                        ),

                        child:
                            const Center(
                          child: Text(
                            'G',

                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(
                                0xFF4285F4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        'Continue with Google',

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // TERMS
              // ==================================================

              const Text(
                'By continuing, you agree to our Terms\n'
                'of Service and Privacy Policy.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF888888),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// OTP VERIFICATION SCREEN
// =================================================================

class OtpVerificationScreen extends StatefulWidget {
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
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _otpController =
      TextEditingController();

  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpController.text.trim();

    if (otp.length != 6 ||
        !RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the 6-digit OTP',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // CREATE PHONE CREDENTIAL
      // ========================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // ========================================================
      // SIGN IN
      // ========================================================

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Firebase user was not created.',
        );
      }

      debugPrint(
        'Phone login successful: '
        '${user.phoneNumber}',
      );

      // ========================================================
      // SAVE USER
      // ========================================================

      await _saveUserToFirestore(user);

      // ========================================================
      // CHECK PROFILE
      // ========================================================

      await _goToNextScreen(user);
    }

    // ==========================================================
    // INVALID OTP
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'OTP verification error: ${e.code}',
      );

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'Incorrect OTP. Please try again.';
          break;

        case 'session-expired':
          message =
              'OTP expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session expired.';
          break;

        default:
          message =
              e.message ??
              'OTP verification failed.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }

    catch (e) {
      debugPrint(
        'OTP error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    }

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE PHONE USER
  // ============================================================

  Future<void> _saveUserToFirestore(
    User user,
  ) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userRef.set(
      {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'provider': 'phone',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // CHECK PROFILE
  // ============================================================

  Future<void> _goToNextScreen(
    User user,
  ) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final String carNumber =
          (data?['carNumber'] ?? '')
              .toString()
              .trim();

      final String carModel =
          (data?['carModel'] ?? '')
              .toString()
              .trim();

      if (!mounted) return;

      // ========================================================
      // PROFILE COMPLETE
      // ========================================================

      if (carNumber.isNotEmpty &&
          carModel.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LocationPermissionScreen(),
          ),
          (route) => false,
        );
      }

      // ========================================================
      // PROFILE INCOMPLETE
      // ========================================================

      else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CarDetailsScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'Profile check failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to check profile: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Verify phone number',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [
              const SizedBox(height: 40),

              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 80,
                height: 80,

                decoration:
                    const BoxDecoration(
                  color: Color(0xFFFFE8EE),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.sms_outlined,
                  size: 38,
                  color: Color(0xFFEF0038),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Enter verification code',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit OTP to\n'
                '${widget.phoneNumber}',
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF707070),
                ),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // OTP INPUT
              // ==================================================

              TextField(
                controller: _otpController,

                keyboardType:
                    TextInputType.number,

                maxLength: 6,

                textAlign: TextAlign.center,

                decoration:
                    InputDecoration(
                  hintText: 'Enter OTP',

                  counterText: '',

                  filled: true,

                  fillColor:
                      const Color(0xFFF5F5F6),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide:
                        BorderSide.none,
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFEF0038),
                      width: 1.5,
                    ),
                  ),
                ),

                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _verifyOtp,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF0038),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        const Color(0xFFEF0038),

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify OTP',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },

                child: const Text(
                  'Change phone number',
                  style: TextStyle(
                    color: Color(0xFFEF0038),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}