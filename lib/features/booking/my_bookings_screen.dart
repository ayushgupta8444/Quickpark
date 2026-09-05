import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../destination/destination_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // ============================================================
  // API URL
  // ============================================================
  //
  // Android Emulator:
  // 10.0.2.2 = your Windows computer
  //
  // Backend:
  // http://localhost:3000
  //
  // From Android emulator we use:
  // http://10.0.2.2:3000
  //
  static const String baseUrl = 'http://10.0.2.2:3000';

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  // ============================================================
  // LOAD BOOKINGS
  // ============================================================

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login to view your bookings.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseUid = user.uid;

      final uri = Uri.parse(
        '$baseUrl/api/bookings/$firebaseUid',
      );

      debugPrint('GET BOOKINGS: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'BOOKINGS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'BOOKINGS RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body);

      if (json['success'] != true) {
        throw Exception(
          json['message']?.toString() ??
              'Unable to load bookings',
        );
      }

      final List<dynamic> bookingList =
          json['bookings'] ?? [];

      final List<Map<String, dynamic>> loadedBookings =
          bookingList
              .map(
                (booking) =>
                    Map<String, dynamic>.from(
                  booking as Map,
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _bookings = loadedBookings;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'BOOKINGS ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load bookings.\n\n$error';
      });
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F9),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF222222),
          ),
          onPressed: _goBack,
        ),

        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEF0038),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFF999999),
              ),

              const SizedBox(height: 18),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loadBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEF0038),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFFEF0038),
      onRefresh: _loadBookings,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),

        itemCount: _bookings.length,

        itemBuilder: (context, index) {
          return _BookingCard(
            data: _bookings[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.local_parking_outlined,
              size: 65,
              color: Color(0xFFCCCCCC),
            ),

            const SizedBox(height: 20),

            const Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your confirmed bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// BOOKING CARD
// ================================================================

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BookingCard({
    required this.data,
  });

  // ============================================================
  // SAFE VALUE HELPERS
  // ============================================================

  String _stringValue(
    String key, {
    String fallback = '',
  }) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String _price() {
    final value = data['amount'];

    if (value == null) {
      return '₹0';
    }

    try {
      final amount =
          double.parse(value.toString());

      if (amount == amount.roundToDouble()) {
        return '₹${amount.toInt()}';
      }

      return '₹${amount.toStringAsFixed(2)}';
    } catch (_) {
      return '₹${value.toString()}';
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'COMPLETED';

      case 'cancelled':
        return 'CANCELLED';

      case 'confirmed':
        return 'CONFIRMED';

      case 'pending':
        return 'PENDING';

      default:
        return status.toUpperCase();
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return const Color(0xFFFFEEEE);

      case 'completed':
        return const Color(0xFFF0F0F0);

      case 'pending':
        return const Color(0xFFFFF5E5);

      default:
        return const Color(0xFFEAF8F0);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return const Color(0xFFD00030);

      case 'completed':
        return const Color(0xFF666666);

      case 'pending':
        return const Color(0xFFC47A00);

      default:
        return const Color(0xFF1D8A50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valetName = _stringValue(
      'valet_name',
      fallback: 'QuickPark Valet',
    );

    final destination = _stringValue(
      'destination_name',
      fallback: 'Unknown destination',
    );

    final carModel = _stringValue(
      'car_model',
      fallback: 'Vehicle',
    );

    final registrationNumber = _stringValue(
      'registration_number',
    );

    final status = _stringValue(
      'status',
      fallback: 'confirmed',
    );

    final bookingId = _stringValue(
      'booking_id',
    );

    final price = _price();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE8EE),

                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.directions_car_outlined,
                  color: Color(0xFFEF0038),
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      valetName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              // STATUS

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color:
                      _statusBackground(status),

                  borderRadius:
                      BorderRadius.circular(8),
                ),

                child: Text(
                  _statusText(status),

                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        _statusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            height: 1,
            color: Color(0xFFEAEAEA),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // DESTINATION
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 19,
                color: Color(0xFF777777),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF999999),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // VEHICLE
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.directions_car_outlined,
                size: 19,
                color: Color(0xFF777777),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Vehicle',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF999999),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      carModel +
                          (registrationNumber
                                  .isNotEmpty
                              ? ' • $registrationNumber'
                              : ''),

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // PRICE
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 19,
                color: Color(0xFF777777),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        Color(0xFF666666),
                  ),
                ),
              ),

              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF171717),
                ),
              ),
            ],
          ),

          // ======================================================
          // BOOKING ID
          // ======================================================

          if (bookingId.isNotEmpty) ...[
            const SizedBox(height: 16),

            const Divider(
              height: 1,
              color: Color(0xFFEAEAEA),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Text(
                  'Booking ID',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF999999),
                  ),
                ),

                const Spacer(),

                Text(
                  bookingId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}