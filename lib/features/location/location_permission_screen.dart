import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../destination/destination_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  // Go to destination screen
  void _goToDestination() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DestinationScreen(),
      ),
    );
  }

  // Request location permission
  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.locationWhenInUse.request();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Permission granted
    if (status.isGranted) {
      _goToDestination();
    }

    // Permission denied
    else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required to find nearby valet.',
          ),
        ),
      );
    }

    // Permission permanently denied
    else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable location permission from Settings.',
          ),
        ),
      );

      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            children: [
              const Spacer(flex: 2),

              // Location icon
              Container(
                width: 170,
                height: 170,

                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8EE),
                  shape: BoxShape.circle,
                ),

                child: const Center(
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFEF0038),
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Heading
              const Text(
                'Find valet before\nyou arrive',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),

              const SizedBox(height: 24),

              // Description
              const Text(
                'Allow location access to discover\n'
                'verified nearby valets and reserve\n'
                'based on your ETA.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF707070),
                ),
              ),

              const SizedBox(height: 28),

              // Privacy card
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F6),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Color(0xFF555555),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Only used while finding and\n'
                        'tracking a booking.',

                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF707070),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Allow location button
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestLocation,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF0038),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEF0038),
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Allow location',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Not now button
              SizedBox(
                width: double.infinity,
                height: 56,

                child: OutlinedButton(
                  onPressed: _goToDestination,

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF171717),

                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    'Not now',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}