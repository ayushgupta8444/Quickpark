import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../location/location_permission_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  const CarDetailsScreen({super.key});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _carNumberController =
      TextEditingController();

  final TextEditingController _carModelController =
      TextEditingController();

  bool _isLoading = false;
  bool _isFetchingProfile = true;

  User? _user;

  @override
  void initState() {
    super.initState();

    _user = FirebaseAuth.instance.currentUser;

    _loadExistingProfile();
  }

  // ============================================================
  // LOAD EXISTING PROFILE
  // ============================================================

  Future<void> _loadExistingProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isFetchingProfile = false;
        });
      }
      return;
    }

    // Firebase Auth se automatic information
    _nameController.text = user.displayName ?? '';

    // Phone login hua hai to phone automatically mil jayega
    _phoneController.text = user.phoneNumber ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      if (document.exists) {
        final Map<String, dynamic>? data = document.data();

        // Firestore mein saved values
        final String savedName =
            (data?['name'] ?? '').toString();

        final String savedPhone =
            (data?['phoneNumber'] ?? '').toString();

        final String savedCarNumber =
            (data?['carNumber'] ?? '').toString();

        final String savedCarModel =
            (data?['carModel'] ?? '').toString();

        // Agar Firestore mein value hai to use karo
        if (savedName.isNotEmpty) {
          _nameController.text = savedName;
        }

        if (savedPhone.isNotEmpty) {
          _phoneController.text = savedPhone;
        }

        _carNumberController.text = savedCarNumber;
        _carModelController.text = savedCarModel;
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingProfile = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('User is not logged in.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String name =
          _nameController.text.trim();

      final String phone =
          _phoneController.text.trim();

      final String carNumber =
          _carNumberController.text
              .trim()
              .toUpperCase();

      final String carModel =
          _carModelController.text.trim();

      // ========================================================
      // SAVE TO FIRESTORE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,

          // User information
          'name': name,
          'email': user.email ?? '',
          'phoneNumber': phone,
          'photoUrl': user.photoURL ?? '',

          // Vehicle information
          'carNumber': carNumber,
          'carModel': carModel,

          // Profile status
          'profileCompleted': true,

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('Profile saved successfully');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved successfully!',
          ),
        ),
      );

      // ========================================================
      // GO TO LOCATION PERMISSION
      // ========================================================

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LocationPermissionScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error: ${e.code}',
      );

      if (!mounted) return;

      _showMessage(
        'Database error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint(
        'Save profile error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to save profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    final String? photoUrl = _user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 30,
      backgroundColor: Color(0xFFFFE8EE),
      child: Icon(
        Icons.person,
        size: 32,
        color: Color(0xFFEF0038),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF666666),
      ),

      filled: true,

      fillColor: const Color(0xFFF7F7F7),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFF5003D),
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isFetchingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFEF0038),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // BACK BUTTON
                // ==================================================

                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },

                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Complete Your Profile',

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Add your personal and vehicle details to continue.',

                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // USER INFORMATION CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      _buildProfileImage(),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              _user?.displayName ??
                                  'QuickPark User',

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFF171717),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              _user?.email ?? '',

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 13,
                                color:
                                    Color(0xFF707070),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // PERSONAL DETAILS
                // ==================================================

                const Text(
                  'Personal Details',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 20),

                // NAME
                const Text(
                  'Full Name',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,

                  enabled: !_isLoading,

                  textInputAction:
                      TextInputAction.next,

                  keyboardType: TextInputType.name,

                  decoration: _inputDecoration(
                    hintText: 'e.g. Ayush Gupta',
                    icon: Icons.person_outline,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    if (value.trim().length < 2) {
                      return 'Please enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // PHONE
                const Text(
                  'Phone Number',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneController,

                  enabled: !_isLoading,

                  textInputAction:
                      TextInputAction.next,

                  keyboardType:
                      TextInputType.phone,

                  decoration: _inputDecoration(
                    hintText: '+91 9876543210',
                    icon: Icons.phone_outlined,
                  ),

                  validator: (value) {
                    final String phone =
                        value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Please enter your phone number';
                    }

                    // Keep only digits
                    final String digits =
                        phone.replaceAll(
                      RegExp(r'\D'),
                      '',
                    );

                    if (digits.length < 10) {
                      return 'Please enter a valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // VEHICLE SECTION
                // ==================================================

                const Text(
                  'Vehicle Details',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Enter the details of the car you use for parking.',

                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF707070),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // CAR NUMBER
                // ==================================================

                const Text(
                  'Car Registration Number',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _carNumberController,

                  enabled: !_isLoading,

                  textCapitalization:
                      TextCapitalization.characters,

                  textInputAction:
                      TextInputAction.next,

                  keyboardType:
                      TextInputType.text,

                  decoration: _inputDecoration(
                    hintText: 'e.g. MH12AB1234',
                    icon: Icons
                        .confirmation_number_outlined,
                  ),

                  validator: (value) {
                    final String carNumber =
                        value?.trim() ?? '';

                    if (carNumber.isEmpty) {
                      return 'Please enter your car number';
                    }

                    if (carNumber.length < 6) {
                      return 'Please enter a valid car number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // ==================================================
                // CAR MODEL
                // ==================================================

                const Text(
                  'Car Model',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _carModelController,

                  enabled: !_isLoading,

                  textInputAction:
                      TextInputAction.done,

                  keyboardType:
                      TextInputType.text,

                  decoration: _inputDecoration(
                    hintText: 'e.g. Hyundai Creta',
                    icon: Icons
                        .directions_car_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your car model';
                    }

                    if (value.trim().length < 2) {
                      return 'Please enter a valid car model';
                    }

                    return null;
                  },

                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _saveProfile();
                    }
                  },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SECURITY CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F7),

                    borderRadius:
                        BorderRadius.circular(14),

                    border: Border.all(
                      color:
                          const Color(0xFFFFE0E6),
                    ),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color:
                            Color(0xFFEF0038),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Your personal and vehicle information is securely stored and used only for your QuickPark bookings.',

                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color:
                                Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SAVE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _saveProfile,

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
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Continue',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // FOOTER
                // ==================================================

                const Center(
                  child: Text(
                    'You can update these details later from Profile.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _carNumberController.dispose();
    _carModelController.dispose();

    super.dispose();
  }
}