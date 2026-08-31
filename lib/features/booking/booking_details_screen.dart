import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_confirmed_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String destinationName;
  final String valetName;
  final String rating;
  final String distance;
  final String eta;
  final String price;
  final String slots;

  const BookingDetailsScreen({
    super.key,
    required this.destinationName,
    required this.valetName,
    required this.rating,
    required this.distance,
    required this.eta,
    required this.price,
    required this.slots,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState
    extends State<BookingDetailsScreen> {
  bool _isLoading = true;
  bool _isBooking = false;

  String _name = '';
  String _phone = '';
  String _carNumber = '';
  String _carModel = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================

  Future<void> _loadUserProfile() async {
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

        setState(() {
          _name =
              (data?['name'] ?? user.displayName ?? '')
                  .toString();

          _phone =
              (data?['phoneNumber'] ??
                      user.phoneNumber ??
                      '')
                  .toString();

          _carNumber =
              (data?['carNumber'] ?? '')
                  .toString();

          _carModel =
              (data?['carModel'] ?? '')
                  .toString();

          _isLoading = false;
        });
      } else {
        setState(() {
          _name = user.displayName ?? '';
          _phone = user.phoneNumber ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Unable to load vehicle details.',
        );
      }
    }
  }

  // ============================================================
  // CONFIRM BOOKING
  // ============================================================

  Future<void> _confirmBooking() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
      );
      return;
    }

    if (_carNumber.isEmpty ||
        _carModel.isEmpty) {
      _showMessage(
        'Please complete your vehicle profile first.',
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final DocumentReference bookingRef =
          FirebaseFirestore.instance
              .collection('bookings')
              .doc();

      final String bookingId =
          bookingRef.id;

      // ========================================================
      // SAVE BOOKING
      // ========================================================

      await bookingRef.set({
        'bookingId': bookingId,

        'userId': user.uid,

        'userName': _name,

        'phoneNumber': _phone,

        // Destination
        'destination':
            widget.destinationName,

        // Valet
        'valetName':
            widget.valetName,

        'rating':
            widget.rating,

        'distance':
            widget.distance,

        'eta':
            widget.eta,

        'slots':
            widget.slots,

        // Vehicle
        'carNumber':
            _carNumber.toUpperCase(),

        'carModel':
            _carModel,

        // Payment
        'price':
            widget.price,

        // Booking status
        'status':
            'confirmed',

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ========================================================
      // GO TO CONFIRMED SCREEN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmedScreen(
            bookingId: bookingId,
            destinationName:
                widget.destinationName,
            valetName:
                widget.valetName,
            carNumber:
                _carNumber.toUpperCase(),
            carModel:
                _carModel,
            price:
                widget.price,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Booking error: ${e.code}',
      );

      if (mounted) {
        _showMessage(
          'Unable to create booking: '
          '${e.message ?? e.code}',
        );
      }
    } catch (e) {
      debugPrint(
        'Booking error: $e',
      );

      if (mounted) {
        _showMessage(
          'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
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
  // DETAIL ROW
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF5F5F6),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF444444),
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        backgroundColor: Color(0xFFF8F8F9),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFEF0038),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F8F9),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isBooking
                        ? null
                        : () {
                            Navigator.pop(
                                context);
                          },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Confirm booking',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 48,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // ==========================================
                    // VALET CARD
                    // ==========================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                                  0xFFE7E7E7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                          0xFFFFE8EE),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .directions_car_outlined,
                                  color:
                                      Color(
                                          0xFFEF0038),
                                  size: 27,
                                ),
                              ),

                              const SizedBox(
                                  width: 13),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      widget.valetName,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 5),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color:
                                              Color(
                                            0xFFFFB000,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 4),
                                        Text(
                                          widget
                                              .rating,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                13,
                                            color:
                                                Color(
                                                    0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 20),

                          const Divider(
                            color:
                                Color(0xFFEAEAEA),
                          ),

                          const SizedBox(
                              height: 12),

                          _detailRow(
                            icon: Icons
                                .location_on_outlined,
                            title:
                                'Destination',
                            value:
                                widget
                                    .destinationName,
                          ),

                          _detailRow(
                            icon: Icons
                                .access_time,
                            title:
                                'Estimated arrival',
                            value:
                                widget.eta,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    // ==========================================
                    // VEHICLE CARD
                    // ==========================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                                  0xFFE7E7E7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Your vehicle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                              height: 14),

                          _detailRow(
                            icon: Icons
                                .confirmation_number_outlined,
                            title:
                                'Registration number',
                            value:
                                _carNumber
                                    .toUpperCase(),
                          ),

                          _detailRow(
                            icon: Icons
                                .directions_car_outlined,
                            title:
                                'Car model',
                            value:
                                _carModel,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    // ==========================================
                    // PRICE CARD
                    // ==========================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                                  0xFFE7E7E7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Estimated total',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        Color(
                                            0xFF777777),
                                  ),
                                ),
                                SizedBox(
                                    height: 4),
                                Text(
                                  'Valet service',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        15,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            widget.price,
                            style:
                                const TextStyle(
                              fontSize: 25,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  Color(
                                      0xFF171717),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CONFIRM BUTTON
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                18,
              ),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isBooking
                      ? null
                      : _confirmBooking,

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
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),

                  child: _isBooking
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}