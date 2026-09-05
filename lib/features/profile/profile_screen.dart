import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String baseUrl = 'http://10.0.2.2:3000';
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/${Uri.encodeComponent(user.uid)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final Map<String, dynamic> body =
          Map<String, dynamic>.from(jsonDecode(response.body) as Map);

      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Unable to load profile').toString());
      }

      final Map<String, dynamic>? profile = body['profile'] is Map
          ? Map<String, dynamic>.from(body['profile'] as Map)
          : null;

      final String savedName = (profile?['name'] ?? '').toString().trim();
      final String savedEmail = (profile?['email'] ?? '').toString().trim();

      if (savedName.isNotEmpty) _nameController.text = savedName;
      if (savedEmail.isNotEmpty) _emailController.text = savedEmail;

      final List<VehicleData> vehicles = <VehicleData>[];
      final dynamic rawVehicles = body['vehicles'];

      if (rawVehicles is List) {
        for (final dynamic item in rawVehicles) {
          if (item is Map) {
            vehicles.add(VehicleData.fromMap(Map<String, dynamic>.from(item)));
          }
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

  String _serverMessage(http.Response response, String fallback) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return fallback;
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'firebaseUid': user.uid,
          'name': name,
          'phoneNumber': user.phoneNumber ?? '',
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to update profile'));
      }

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
      final response = await http.post(
        Uri.parse('$baseUrl/api/vehicles'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'firebaseUid': user.uid,
          'registrationNumber': vehicle.number,
          'carModel': vehicle.model,
          'isPrimary': vehicle.isPrimary || _vehicles.isEmpty,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to add vehicle'));
      }

      final Map<String, dynamic> body =
          Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      if (body['success'] != true || body['vehicle'] is! Map) {
        throw Exception((body['message'] ?? 'Unable to add vehicle').toString());
      }

      await _refreshVehicles(showError: false);

      if (!mounted) return;
      _showMessage('Vehicle added successfully.');
    } catch (e, stackTrace) {
      debugPrint('ADD VEHICLE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to add vehicle: $e');
    }
  }

  Future<void> _refreshVehicles({bool showError = true}) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vehicles/${Uri.encodeComponent(user.uid)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to load vehicles'));
      }

      final Map<String, dynamic> body =
          Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Unable to load vehicles').toString());
      }

      final List<VehicleData> vehicles = <VehicleData>[];
      final dynamic rawVehicles = body['vehicles'];
      if (rawVehicles is List) {
        for (final dynamic item in rawVehicles) {
          if (item is Map) {
            vehicles.add(VehicleData.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
      _sortVehicles(vehicles);

      if (!mounted) return;
      setState(() => _vehicles = vehicles);
    } catch (e, stackTrace) {
      debugPrint('REFRESH VEHICLES ERROR: $e');
      debugPrint(stackTrace.toString());
      if (showError && mounted) _showMessage('Unable to refresh vehicles: $e');
    }
  }

  Future<void> _showEditVehicleSelection() async {
    final VehicleData? selected = await showModalBottomSheet<VehicleData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.70,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 35,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D5D8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Edit Vehicle',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Select the vehicle you want to edit',
                    style: TextStyle(fontSize: 14, color: grey),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'MY VEHICLES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: grey,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ..._vehicles.map(
                    (VehicleData item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => Navigator.of(sheetContext).pop(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8EE),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_outlined,
                                    color: const Color(0xFFEF0038),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.model.isEmpty
                                            ? 'Vehicle'
                                            : item.model,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: black,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE8EE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Primary',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFEF0038),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF77777C),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    await _editVehicle(selected);
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
      final response = await http.put(
        Uri.parse('$baseUrl/api/vehicles/${vehicle.id}'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'firebaseUid': user.uid,
          'registrationNumber': updatedVehicle.number,
          'carModel': updatedVehicle.model,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to update vehicle'));
      }

      if (updatedVehicle.isPrimary && !vehicle.isPrimary) {
        await _setPrimaryVehicleById(vehicle.id, showMessage: false);
      }

      await _refreshVehicles(showError: false);

      if (!mounted) return;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Remove vehicle?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: black),
          ),
          content: Text(
            'Remove ${vehicle.model} (${vehicle.number}) from your profile?',
            style: const TextStyle(fontSize: 16, height: 1.4, color: grey),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: grey, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFEF0038), fontWeight: FontWeight.w700)),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/api/vehicles/${vehicle.id}'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'firebaseUid': user.uid}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to remove vehicle'));
      }

      await _refreshVehicles(showError: false);

      if (!mounted) return;
      _showMessage('Vehicle removed successfully.');
    } catch (e, stackTrace) {
      debugPrint('DELETE VEHICLE ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showMessage('Unable to remove vehicle: $e');
    }
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

    final User? user = _user ?? FirebaseAuth.instance.currentUser;
    final String name = _nameController.text.trim().isEmpty
        ? 'Your Name'
        : _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = user?.phoneNumber ?? '';
    final VehicleData? primaryVehicle = _vehicles.isEmpty
        ? null
        : _vehicles.firstWhere(
            (VehicleData vehicle) => vehicle.isPrimary,
            orElse: () => _vehicles.first,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ======================================================
            // HEADER
            // ======================================================
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
                child: Row(
                  children: <Widget>[
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: const Color(0xFFF7F7F8),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _showProfileEditSheet,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEDEDEF)),

            // ======================================================
            // PROFILE CONTENT
            // ======================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Profile identity row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Row(
                        children: <Widget>[
                          _buildAvatar(user),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (email.isNotEmpty) email,
                                    if (phone.isNotEmpty) phone,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F1)),

                    // ==================================================
                    // VEHICLES
                    // ==================================================
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Text(
                        'MY VEHICLES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: grey,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: primaryVehicle == null
                          ? _buildProfileEmptyVehicleCard()
                          : _buildProfileVehicleCard(primaryVehicle),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // PROFILE MENU
                    // ==================================================
                    _buildProfileMenuItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      onTap: () => _showMessage(
                        'Payment methods will be available soon.',
                      ),
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Locations',
                      subtitle: 'Home, Office',
                      onTap: () => _showMessage(
                        'Saved locations will be available soon.',
                      ),
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Support & Help',
                      onTap: () => _showMessage(
                        'Support & Help will be available soon.',
                      ),
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.info_outline,
                      title: 'About QuickPark',
                      onTap: () => _showMessage(
                        'QuickPark — valet parking, simplified.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildProfileBottomNavigation(),
    );
  }

  Widget _buildAvatar(User? user) {
    final String? photoUrl = user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(),
        ),
      );
    }

    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    final String name = _nameController.text.trim();
    final String initial = name.isEmpty ? 'Q' : name[0].toUpperCase();

    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F3),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFEF0038),
        ),
      ),
    );
  }

  Widget _buildProfileVehicleCard(VehicleData vehicle) {
    return Material(
      color: const Color(0xFFF4F4F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () { _showVehicleOptions(vehicle); },
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_shipping_outlined,
                  color: const Color(0xFFEF0038),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        vehicle.model.isEmpty ? 'Vehicle' : vehicle.model,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.number}${vehicle.color.isNotEmpty ? ' · ${vehicle.color}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Color(0xFF707074),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileEmptyVehicleCard() {
    return Material(
      color: const Color(0xFFF4F4F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _addVehicle,
        child: const SizedBox(
          height: 62,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: <Widget>[
                Icon(Icons.add_circle_outline, color: const Color(0xFFEF0038), size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Add your first vehicle',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Color(0xFF707074),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: subtitle == null ? 62 : 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 23, color: black),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: black,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 23,
                color: Color(0xFF707074),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBottomNavigation() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDEDEF)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            _buildProfileNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: false,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            _buildProfileNavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bookings',
              selected: false,
              onTap: () => _showMessage('Opening bookings...'),
            ),
            _buildProfileNavItem(
              icon: Icons.notifications_none_outlined,
              label: 'Alerts',
              selected: false,
              onTap: () => _showMessage('Alerts will be available soon.'),
            ),
            _buildProfileNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 23,
              color: selected ? red : const Color(0xFF6F7074),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? red : const Color(0xFF6F7074),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileEditSheet() async {
    final TextEditingController nameController =
        TextEditingController(text: _nameController.text);
    final TextEditingController emailController =
        TextEditingController(text: _emailController.text);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D7D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: black,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      _nameController.text = nameController.text;
                      _emailController.text = emailController.text;
                      Navigator.of(sheetContext).pop();
                      await _saveProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

    nameController.dispose();
    emailController.dispose();
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
          border: Border.all(color: const Color(0xFFEF0038), width: 1.1),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF0038),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleData vehicle) {
    return GestureDetector(
      onTap: () { _showVehicleOptions(vehicle); },
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
                      fontSize: 14,
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
                  fontSize: 11,
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
                  fontSize: 10,
                  color: const Color(0xFFEF0038),
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
                fontSize: 11,
                color: grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVehicleOptions(VehicleData vehicle) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 35,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D5D8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
                          color: const Color(0xFFEF0038),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              vehicle.model.isEmpty ? 'Vehicle' : vehicle.model,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicle.number,
                              style: const TextStyle(fontSize: 14, color: grey),
                            ),
                          ],
                        ),
                      ),
                      if (vehicle.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF0038),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MY VEHICLES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._vehicles.map(
                    (VehicleData item) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Material(
                        color: item.isPrimary
                            ? const Color(0xFFFFF1F4)
                            : const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            Navigator.of(sheetContext).pop('primary:${item.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 22,
                                  color: item.isPrimary
                                      ? red
                                      : const Color(0xFF555555),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.model.isEmpty
                                            ? 'Vehicle'
                                            : item.model,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.number,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.isPrimary)
                                  const Text(
                                    'Primary',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFEF0038),
                                    ),
                                  ),
                                const SizedBox(width: 7),
                                Icon(
                                  item.isPrimary
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: item.isPrimary
                                      ? red
                                      : const Color(0xFFB0B0B0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _VehicleActionRow(
                    icon: Icons.add_circle_outline,
                    title: 'Add vehicle',
                    onTap: () => Navigator.of(sheetContext).pop('add'),
                  ),
                  _VehicleActionRow(
                    icon: Icons.edit_outlined,
                    title: 'Edit vehicle',
                    onTap: () => Navigator.of(sheetContext).pop('edit'),
                  ),
                  _VehicleActionRow(
                    icon: Icons.delete_outline,
                    title: 'Remove vehicle',
                    isDestructive: true,
                    onTap: () => Navigator.of(sheetContext).pop('remove'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'add') {
      await _addVehicle();
      return;
    }

    if (action == 'edit') {
      await _showEditVehicleSelection();
      return;
    }

    if (action == 'remove') {
      await _showRemoveVehicleSheet();
      return;
    }

    if (action.startsWith('primary:')) {
      final String id = action.substring('primary:'.length);
      final VehicleData? selected = _vehicles.cast<VehicleData?>().firstWhere(
        (VehicleData? item) => item?.id == id,
        orElse: () => null,
      );

      if (selected == null || selected.isPrimary) return;

      await _setPrimaryVehicle(selected);

      if (!mounted) return;
      _showMessage('${selected.model} is now your primary vehicle.');
    }
  }

  Future<void> _setPrimaryVehicle(VehicleData selected) async {
    await _setPrimaryVehicleById(selected.id, showMessage: true);
  }

  Future<void> _setPrimaryVehicleById(
    String vehicleId, {
    required bool showMessage,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (showMessage) _showMessage('Please login again.');
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId/primary'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'firebaseUid': user.uid}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_serverMessage(response, 'Unable to set primary vehicle'));
      }

      await _refreshVehicles(showError: false);

      if (showMessage && mounted) {
        final VehicleData? selected = _vehicles.cast<VehicleData?>().firstWhere(
          (VehicleData? item) => item?.id == vehicleId,
          orElse: () => null,
        );
        _showMessage('${selected?.model ?? 'Vehicle'} is now your primary vehicle.');
      }
    } catch (e, stackTrace) {
      debugPrint('SET PRIMARY ERROR: $e');
      debugPrint(stackTrace.toString());
      if (mounted) _showMessage('Could not change primary vehicle: $e');
    }
  }

  Future<void> _showRemoveVehicleSheet() async {
    if (_vehicles.isEmpty) {
      _showMessage('No vehicles available to remove.');
      return;
    }

    final VehicleData? selected = await showModalBottomSheet<VehicleData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 35,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D5D8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'REMOVE VEHICLE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: grey,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Select a vehicle to remove',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ..._vehicles.map(
                    (VehicleData item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () {
                            Navigator.of(sheetContext).pop(item);
                          },
                          child: SizedBox(
                            height: 64,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 24,
                                    color: item.isPrimary
                                        ? red
                                        : const Color(0xFF555555),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          item.model.isEmpty
                                              ? 'Vehicle'
                                              : item.model,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.number,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.isPrimary)
                                    const Text(
                                      'PRIMARY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFEF0038),
                                      ),
                                    ),
                                  const SizedBox(width: 9),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 22,
                                    color: Color(0xFF77777C),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    await _confirmDeleteVehicle(selected);
  }

  Future<void> _confirmDeleteVehicle(VehicleData vehicle) async {
    if (_vehicles.length <= 1) {
      _showMessage('You must keep at least one vehicle.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove vehicle?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: black,
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${vehicle.model.isEmpty ? 'this vehicle' : vehicle.model} (${vehicle.number})?',
            style: const TextStyle(
              fontSize: 14,
              color: grey,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: black,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF0038),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _deleteVehicle(vehicle);
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
        style: const TextStyle(fontSize: 14, color: black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: grey),
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
            borderSide: const BorderSide(color: const Color(0xFFEF0038), width: 1.2),
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

class _VehicleActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _VehicleActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDestructive ? const Color(0xFFEF0038) : const Color(0xFF111111);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFFEF0038).withValues(alpha: 0.06),
        highlightColor: const Color(0xFFEF0038).withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 13,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: const Color(0xFFEF0038),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      model: (data['model'] ?? data['carModel'] ?? '').toString(),
      number: (data['number'] ?? data['registrationNumber'] ?? '').toString(),
      color: (data['color'] ?? 'Dark Gray').toString(),
      isPrimary: data['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'type': type,
        'model': model,
        'number': number,
        'color': color,
        'isPrimary': isPrimary,
      };

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
                  fontSize: 20,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Will be selected by default for valet booking',
                          style: TextStyle(fontSize: 11, color: grey),
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
                          side: const BorderSide(color: const Color(0xFFEF0038), width: 1.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
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
                            fontSize: 13,
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
        fontSize: 11,
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
        style: const TextStyle(fontSize: 14, color: black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: grey),
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
            borderSide: const BorderSide(color: const Color(0xFFEF0038), width: 1.1),
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
                fontSize: 12,
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
          style: const TextStyle(fontSize: 14, color: black),
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
