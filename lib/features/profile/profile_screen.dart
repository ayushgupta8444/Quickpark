import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color red = Color(0xFFEF0038);
  static const Color black = Color(0xFF171717);
  static const Color grey = Color(0xFF737373);
  static const Color border = Color(0xFFE1E1E5);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  User? _user;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isEditingProfile = false;
  List<VehicleData> _vehicles = <VehicleData>[];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    _user = user;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';

    try {
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      final String savedName = (data['name'] ?? '').toString().trim();
      final String savedEmail = (data['email'] ?? '').toString().trim();

      if (savedName.isNotEmpty) _nameController.text = savedName;
      if (savedEmail.isNotEmpty) _emailController.text = savedEmail;

      final List<VehicleData> vehicles = <VehicleData>[];
      final dynamic rawVehicles = data['vehicles'];

      if (rawVehicles is List) {
        for (final dynamic item in rawVehicles) {
          if (item is Map) {
            final Map<String, dynamic> map =
                Map<String, dynamic>.from(item);
            vehicles.add(VehicleData.fromMap(map));
          }
        }
      }

      // Migrate the old single vehicle fields into the new array once.
      if (vehicles.isEmpty) {
        final String oldNumber =
            (data['carNumber'] ?? '').toString().trim().toUpperCase();
        final String oldModel = (data['carModel'] ?? '').toString().trim();

        if (oldNumber.isNotEmpty && oldModel.isNotEmpty) {
          final VehicleData migrated = VehicleData(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: 'Car',
            model: oldModel,
            number: oldNumber,
            color: 'Dark Gray',
            isPrimary: true,
          );

          vehicles.add(migrated);

          await userRef.set(
            <String, dynamic>{
              'vehicles': <Map<String, dynamic>>[migrated.toMap()],
              'carNumber': migrated.number,
              'carModel': migrated.model,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      _sortVehicles(vehicles);

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('PROFILE LOAD ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Unable to load your profile: $e');
    }
  }

  void _sortVehicles(List<VehicleData> vehicles) {
    vehicles.sort((VehicleData a, VehicleData b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return 0;
    });
  }

  Future<void> _saveProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();

    if (name.length < 2) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (email.isNotEmpty && !email.contains('@')) {
      _showMessage('Please enter a valid email.');
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (user.displayName != name) {
        await user.updateDisplayName(name);
        await user.reload();
      }

      _user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;
      setState(() => _isEditingProfile = false);
      _showMessage('Profile updated successfully.');
    } catch (e, stackTrace) {
      debugPrint('PROFILE SAVE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to update profile: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
    }
  }

  Future<VehicleData?> _openVehicleSheet({VehicleData? existingVehicle}) {
    return showModalBottomSheet<VehicleData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return AddVehicleSheet(existingVehicle: existingVehicle);
      },
    );
  }

  Future<void> _addVehicle() async {
    final VehicleData? vehicle = await _openVehicleSheet();
    if (!mounted || vehicle == null) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userRef.get();

      final List<VehicleData> current = _readVehicles(snapshot.data());
      final bool shouldBePrimary = current.isEmpty || vehicle.isPrimary;

      final VehicleData savedVehicle = vehicle.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        isPrimary: shouldBePrimary,
      );

      final List<VehicleData> updated = current
          .map(
            (VehicleData item) => shouldBePrimary
                ? item.copyWith(isPrimary: false)
                : item,
          )
          .toList();

      if (shouldBePrimary) {
        updated.insert(0, savedVehicle);
      } else {
        updated.add(savedVehicle);
      }

      _sortVehicles(updated);
      final VehicleData primary = updated.first;

      await userRef.set(
        <String, dynamic>{
          'vehicles': updated.map((VehicleData v) => v.toMap()).toList(),
          'carNumber': primary.number,
          'carModel': primary.model,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => _vehicles = updated);
      _showMessage('Vehicle added successfully.');
    } catch (e, stackTrace) {
      debugPrint('ADD VEHICLE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to add vehicle: $e');
    }
  }

  Future<void> _editVehicle(VehicleData vehicle) async {
    final VehicleData? updatedVehicle =
        await _openVehicleSheet(existingVehicle: vehicle);
    if (!mounted || updatedVehicle == null) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final List<VehicleData> updated = _vehicles.map((VehicleData item) {
        if (item.id == vehicle.id) {
          return updatedVehicle.copyWith(id: vehicle.id);
        }
        return item;
      }).toList();

      if (updatedVehicle.isPrimary) {
        for (int i = 0; i < updated.length; i++) {
          updated[i] = updated[i].copyWith(
            isPrimary: updated[i].id == vehicle.id,
          );
        }
      } else if (vehicle.isPrimary) {
        final bool hasPrimary = updated.any((VehicleData v) => v.isPrimary);
        if (!hasPrimary && updated.isNotEmpty) {
          updated[0] = updated[0].copyWith(isPrimary: true);
        }
      }

      _sortVehicles(updated);
      final VehicleData primary = updated.first;

      await userRef.set(
        <String, dynamic>{
          'vehicles': updated.map((VehicleData v) => v.toMap()).toList(),
          'carNumber': primary.number,
          'carModel': primary.model,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => _vehicles = updated);
      _showMessage('Vehicle updated successfully.');
    } catch (e, stackTrace) {
      debugPrint('EDIT VEHICLE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to update vehicle: $e');
    }
  }

  Future<void> _deleteVehicle(VehicleData vehicle) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove vehicle?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: black,
            ),
          ),
          content: Text(
            'Remove ${vehicle.model} (${vehicle.number}) from your profile?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: grey, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userRef.get();

      final List<VehicleData> current = _readVehicles(snapshot.data());
      List<VehicleData> remaining = current
          .where((VehicleData item) => item.id != vehicle.id)
          .toList();

      if (remaining.isNotEmpty) {
        final bool hasPrimary =
            remaining.any((VehicleData item) => item.isPrimary);

        if (vehicle.isPrimary || !hasPrimary) {
          remaining = remaining.asMap().entries.map((entry) {
            return entry.value.copyWith(isPrimary: entry.key == 0);
          }).toList();
        }

        _sortVehicles(remaining);
      }

      final Map<String, dynamic> data = <String, dynamic>{
        'vehicles': remaining.map((VehicleData v) => v.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (remaining.isEmpty) {
        data['carNumber'] = '';
        data['carModel'] = '';
      } else {
        final VehicleData primary = remaining.firstWhere(
          (VehicleData v) => v.isPrimary,
          orElse: () => remaining.first,
        );
        data['carNumber'] = primary.number;
        data['carModel'] = primary.model;
      }

      await userRef.set(data, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _vehicles = remaining);
      _showMessage('Vehicle removed successfully.');
    } catch (e, stackTrace) {
      debugPrint('DELETE VEHICLE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to remove vehicle: $e');
    }
  }

  List<VehicleData> _readVehicles(Map<String, dynamic>? data) {
    final List<VehicleData> result = <VehicleData>[];
    final dynamic raw = data?['vehicles'];

    if (raw is List) {
      for (final dynamic item in raw) {
        if (item is Map) {
          result.add(VehicleData.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return result;
  }

  void _toggleEditProfile() {
    if (_isSavingProfile) return;

    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (!_isEditingProfile) {
        _nameController.text = _user?.displayName ?? '';
        _emailController.text = _user?.email ?? '';
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: red),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(37, 16, 37, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: black,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Just a few details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: black,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'Set up your profile for effortless paperless\nvaleting',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FULL NAME (REQUIRED)',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
              const SizedBox(height: 7),
              _buildTextField(
                controller: _nameController,
                hint: 'Priya Sharma',
                enabled: _isEditingProfile,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 21),
              const Text(
                'EMAIL ADDRESS (OPTIONAL)',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
              const SizedBox(height: 7),
              _buildTextField(
                controller: _emailController,
                hint: 'priya@email.com',
                enabled: _isEditingProfile,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const Text(
                'YOUR VEHICLES',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
              const SizedBox(height: 9),
              _buildVehicleArea(),
              const SizedBox(height: 40),
              if (_isEditingProfile)
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSavingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: ElevatedButton(
                    onPressed: _vehicles.isEmpty ? _addVehicle : () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 13),
              if (!_isEditingProfile)
                Center(
                  child: TextButton(
                    onPressed: _toggleEditProfile,
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(
                        color: grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleArea() {
    if (_vehicles.isEmpty) return _buildFirstVehicleButton();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (BuildContext context, int index) {
          if (index == _vehicles.length) return _buildAddAnotherCard();
          return _buildVehicleCard(_vehicles[index]);
        },
      ),
    );
  }

  Widget _buildFirstVehicleButton() {
    return GestureDetector(
      onTap: _addVehicle,
      child: Container(
        height: 49,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: red, width: 1.1),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 13),
            Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: red),
            ),
            const SizedBox(width: 9),
            const Text(
              'Add your first vehicle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleData vehicle) {
    return GestureDetector(
      onTap: () => _showVehicleOptions(vehicle),
      child: Container(
        width: 137,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    vehicle.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: black,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: vehicle.isPrimary
                        ? red
                        : const Color(0xFFB7B7B7),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vehicle.number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
            ),
            const Spacer(),
            if (vehicle.isPrimary)
              const Text(
                'Primary vehicle',
                style: TextStyle(
                  fontSize: 8,
                  color: red,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnotherCard() {
    return GestureDetector(
      onTap: _addVehicle,
      child: Container(
        width: 86,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add, size: 22, color: Color(0xFF777777)),
            SizedBox(height: 7),
            Text(
              'Add another',
              style: TextStyle(
                fontSize: 9,
                color: grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleOptions(VehicleData vehicle) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 35,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D5D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        color: red,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            vehicle.model,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.number,
                            style: const TextStyle(fontSize: 12, color: grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined, color: red),
                  title: const Text(
                    'Edit vehicle',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _editVehicle(vehicle);
                    });
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: red),
                  title: const Text(
                    'Remove vehicle',
                    style: TextStyle(
                      color: red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _deleteVehicle(vehicle);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    required TextInputType keyboardType,
  }) {
    return SizedBox(
      height: 39,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: grey),
          filled: true,
          fillColor: const Color(0xFFFAFAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: red, width: 1.2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: border),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

class VehicleData {
  final String id;
  final String type;
  final String model;
  final String number;
  final String color;
  final bool isPrimary;

  const VehicleData({
    required this.id,
    required this.type,
    required this.model,
    required this.number,
    required this.color,
    required this.isPrimary,
  });

  factory VehicleData.fromMap(Map<String, dynamic> data) {
    return VehicleData(
      id: (data['id'] ?? data['vehicleId'] ?? '').toString(),
      type: (data['type'] ?? 'Car').toString(),
      model: (data['model'] ?? '').toString(),
      number: (data['number'] ?? '').toString(),
      color: (data['color'] ?? 'Dark Gray').toString(),
      isPrimary: data['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'vehicleId': id,
      'type': type,
      'model': model,
      'number': number,
      'color': color,
      'isPrimary': isPrimary,
    };
  }

  VehicleData copyWith({
    String? id,
    String? type,
    String? model,
    String? number,
    String? color,
    bool? isPrimary,
  }) {
    return VehicleData(
      id: id ?? this.id,
      type: type ?? this.type,
      model: model ?? this.model,
      number: number ?? this.number,
      color: color ?? this.color,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

// ============================================================================
// ADD / EDIT VEHICLE BOTTOM SHEET
// ============================================================================

class AddVehicleSheet extends StatefulWidget {
  final VehicleData? existingVehicle;

  const AddVehicleSheet({
    super.key,
    this.existingVehicle,
  });

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  static const Color red = Color(0xFFEF0038);
  static const Color black = Color(0xFF181818);
  static const Color grey = Color(0xFF777777);
  static const Color border = Color(0xFFD9D9DD);

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  String _selectedType = 'Car';
  String _selectedColor = 'Dark Gray';
  bool _isPrimary = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingVehicle != null;

  @override
  void initState() {
    super.initState();

    final VehicleData? vehicle = widget.existingVehicle;
    if (vehicle != null) {
      _selectedType = vehicle.type;
      _selectedColor = vehicle.color;
      _isPrimary = vehicle.isPrimary;
      _modelController.text = vehicle.model;
      _plateController.text = vehicle.number;
    }
  }

  void _saveVehicle() {
    final String model = _modelController.text.trim();
    final String plate = _plateController.text.trim().toUpperCase();

    if (model.length < 2) {
      _showMessage('Please enter make & model.');
      return;
    }

    if (plate.length < 6) {
      _showMessage('Please enter a valid license plate.');
      return;
    }

    setState(() => _isSaving = true);

    final VehicleData vehicle = VehicleData(
      id: widget.existingVehicle?.id ?? '',
      type: _selectedType,
      model: model,
      number: plate,
      color: _selectedColor,
      isPrimary: _isPrimary,
    );

    Navigator.of(context).pop(vehicle);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E1E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
              const SizedBox(height: 17),
              _buildTypeSelector(),
              const SizedBox(height: 19),
              _buildLabel('MAKE & MODEL'),
              const SizedBox(height: 7),
              _buildInput(
                controller: _modelController,
                hint: 'Hyundai Creta',
              ),
              const SizedBox(height: 17),
              _buildLabel('LICENSE PLATE'),
              const SizedBox(height: 7),
              _buildInput(
                controller: _plateController,
                hint: 'KA 03 MN 4521',
                capitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 17),
              _buildLabel('VEHICLE COLOR (OPTIONAL)'),
              const SizedBox(height: 7),
              _buildColorDropdown(),
              const SizedBox(height: 17),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Set as primary vehicle',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Will be selected by default for valet booking',
                          style: TextStyle(fontSize: 9, color: grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPrimary,
                    activeThumbColor: Colors.white,
                    activeTrackColor: red,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Color(0xFFD0D0D2),
                    onChanged: _isSaving
                        ? null
                        : (bool value) {
                            setState(() => _isPrimary = value);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: red,
                          side: const BorderSide(color: red, width: 1.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Save Changes' : 'Save Vehicle',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: black,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        textCapitalization: capitalization,
        style: const TextStyle(fontSize: 12, color: black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: red, width: 1.1),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _typeOption('Car', Icons.directions_car_outlined)),
          Expanded(child: _typeOption('Bike', Icons.two_wheeler_outlined)),
        ],
      ),
    );
  }

  Widget _typeOption(String type, IconData icon) {
    final bool selected = _selectedType == type;

    return GestureDetector(
      onTap: _isSaving
          ? null
          : () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: selected ? red : grey),
            const SizedBox(width: 4),
            Text(
              type,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? black : grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDropdown() {
    const List<String> colors = <String>[
      'Dark Gray',
      'Black',
      'White',
      'Silver',
      'Red',
      'Blue',
      'Other',
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: colors.contains(_selectedColor) ? _selectedColor : 'Other',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: grey),
          style: const TextStyle(fontSize: 12, color: black),
          items: colors.map((String color) {
            return DropdownMenuItem<String>(
              value: color,
              child: Text(color),
            );
          }).toList(),
          onChanged: _isSaving
              ? null
              : (String? value) {
                  if (value == null) return;
                  setState(() => _selectedColor = value);
                },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }
}
