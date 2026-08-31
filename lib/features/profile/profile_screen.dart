import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _carNumberController =
      TextEditingController();

  final TextEditingController _carModelController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  User? _user;

  @override
  void initState() {
    super.initState();

    _user = FirebaseAuth.instance.currentUser;

    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    _user = user;

    // Firebase Auth values
    _nameController.text =
        user.displayName ?? '';

    _phoneController.text =
        user.phoneNumber ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          document =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      if (document.exists) {
        final data = document.data();

        // Firestore values
        final String name =
            (data?['name'] ?? '').toString();

        final String phone =
            (data?['phoneNumber'] ?? '').toString();

        final String carNumber =
            (data?['carNumber'] ?? '').toString();

        final String carModel =
            (data?['carModel'] ?? '').toString();

        if (name.isNotEmpty) {
          _nameController.text = name;
        }

        if (phone.isNotEmpty) {
          _phoneController.text = phone;
        }

        _carNumberController.text =
            carNumber;

        _carModelController.text =
            carModel;
      }
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to load profile.',
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'User is not logged in.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
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
      // UPDATE FIRESTORE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': name,
          'email': user.email ?? '',
          'phoneNumber': phone,
          'photoUrl': user.photoURL ?? '',
          'carNumber': carNumber,
          'carModel': carModel,
          'profileCompleted': true,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // UPDATE FIREBASE AUTH NAME
      // ========================================================

      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      await user.reload();

      _user =
          FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      _showMessage(
        'Profile updated successfully!',
      );

      setState(() {});
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
        'Profile update error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to update profile.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
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
  // INPUT DECORATION
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

      fillColor:
          const Color(0xFFF7F7F7),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFEF0038),
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    final String? photoUrl =
        _user?.photoURL;

    if (photoUrl != null &&
        photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 42,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 42,
      backgroundColor:
          Color(0xFFFFE8EE),
      child: Icon(
        Icons.person,
        size: 45,
        color: Color(0xFFEF0038),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              const EdgeInsets.symmetric(
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
                // PROFILE HEADER
                // ==================================================

                Center(
                  child: Column(
                    children: [
                      _buildProfileImage(),

                      const SizedBox(height: 14),

                      Text(
                        _nameController.text
                                .isEmpty
                            ? 'QuickPark User'
                            : _nameController.text,

                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF171717),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _user?.email ?? '',

                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Color(0xFF707070),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // PERSONAL INFORMATION
                // ==================================================

                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 20),

                // NAME
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _nameController,

                  enabled: !_isSaving,

                  textInputAction:
                      TextInputAction.next,

                  keyboardType:
                      TextInputType.name,

                  onChanged: (_) {
                    setState(() {});
                  },

                  decoration:
                      _inputDecoration(
                    hintText:
                        'Enter your name',
                    icon:
                        Icons.person_outline,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    if (value.trim().length <
                        2) {
                      return 'Please enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // PHONE
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _phoneController,

                  enabled: !_isSaving,

                  keyboardType:
                      TextInputType.phone,

                  textInputAction:
                      TextInputAction.next,

                  decoration:
                      _inputDecoration(
                    hintText:
                        '+91 9876543210',
                    icon:
                        Icons.phone_outlined,
                  ),

                  validator: (value) {
                    final String phone =
                        value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Please enter your phone number';
                    }

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

                const SizedBox(height: 32),

                // ==================================================
                // VEHICLE INFORMATION
                // ==================================================

                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 20),

                // CAR NUMBER
                const Text(
                  'Car Registration Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _carNumberController,

                  enabled: !_isSaving,

                  textCapitalization:
                      TextCapitalization
                          .characters,

                  textInputAction:
                      TextInputAction.next,

                  decoration:
                      _inputDecoration(
                    hintText:
                        'e.g. MH12AB1234',
                    icon:
                        Icons.confirmation_number_outlined,
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

                const SizedBox(height: 20),

                // CAR MODEL
                const Text(
                  'Car Model',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _carModelController,

                  enabled: !_isSaving,

                  textInputAction:
                      TextInputAction.done,

                  decoration:
                      _inputDecoration(
                    hintText:
                        'e.g. Hyundai Creta',
                    icon:
                        Icons.directions_car_outlined,
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
                        _isSaving
                            ? null
                            : _saveProfile,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFFEF0038),

                      foregroundColor:
                          Colors.white,

                      disabledBackgroundColor:
                          const Color(
                              0xFFEF0038),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(15),
                      ),
                    ),

                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // SECURITY CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(15),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                            0xFFFFF5F7),

                    borderRadius:
                        BorderRadius.circular(
                            14),

                    border: Border.all(
                      color:
                          const Color(
                              0xFFFFE0E6),
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
                          'Your profile information is securely stored in QuickPark and is used for your bookings.',

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _carNumberController.dispose();
    _carModelController.dispose();

    super.dispose();
  }
}