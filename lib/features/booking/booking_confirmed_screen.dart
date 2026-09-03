import 'package:flutter/material.dart';

import 'my_bookings_screen.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String destinationName;
  final String valetName;
  final String carNumber;
  final String carModel;
  final String price;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    required this.destinationName,
    required this.valetName,
    required this.carNumber,
    required this.carModel,
    required this.price,
  });

  static const Color red =
      Color(0xFFEF0038);

  static const Color black =
      Color(0xFF171717);

  static const Color grey =
      Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // HEADER
            // ======================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                0,
              ),

              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MyBookingsScreen(),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 19,
                      color: black,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Booking confirmed',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                        color: black,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 48,
                  ),
                ],
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  30,
                  20,
                  30,
                ),

                child: Column(
                  children: [
                    const SizedBox(
                      height: 35,
                    ),

                    // ==================================================
                    // SUCCESS ICON
                    // ==================================================

                    Container(
                      width: 86,
                      height: 86,

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFEAF8F0),
                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.check_rounded,
                        color:
                            Color(0xFF1D9A59),
                        size: 52,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    const Text(
                      'Booking Confirmed!',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                        color: black,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Your valet parking has been\nsuccessfully booked.',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: grey,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ==================================================
                    // BOOKING CARD
                    // ==================================================

                    Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                        17,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),

                        border: Border.all(
                          color:
                              const Color(
                            0xFFE5E5E7,
                          ),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          // ============================================
                          // VALET
                          // ============================================

                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFFFE8EE,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    13,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .directions_car_outlined,
                                  color: red,
                                  size: 25,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      valetName,

                                      maxLines: 1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color:
                                            black,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    const Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle,
                                          color:
                                              Color(
                                            0xFF1D9A59,
                                          ),
                                          size:
                                              14,
                                        ),

                                        SizedBox(
                                          width: 4,
                                        ),

                                        Text(
                                          'Confirmed',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                11,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                Color(
                                              0xFF1D9A59,
                                            ),
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
                            height: 17,
                          ),

                          const Divider(
                            height: 1,
                            color:
                                Color(0xFFEAEAEA),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ============================================
                          // DESTINATION
                          // ============================================

                          _InfoRow(
                            icon: Icons
                                .location_on_outlined,

                            title:
                                'Destination',

                            value:
                                destinationName,
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ============================================
                          // VEHICLE
                          // ============================================

                          _InfoRow(
                            icon: Icons
                                .directions_car_outlined,

                            title:
                                'Vehicle',

                            value:
                                '$carModel • $carNumber',
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ============================================
                          // AMOUNT
                          // ============================================

                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF5F5F6,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .payments_outlined,
                                  color:
                                      Color(
                                    0xFF555555,
                                  ),
                                  size: 19,
                                ),
                              ),

                              const SizedBox(
                                width: 11,
                              ),

                              const Expanded(
                                child:
                                    Text(
                                  'Amount',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color:
                                        grey,
                                  ),
                                ),
                              ),

                              Text(
                                price,

                                style:
                                    const TextStyle(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      black,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Divider(
                            height: 1,
                            color:
                                Color(0xFFEAEAEA),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ============================================
                          // BOOKING ID
                          // ============================================

                          Row(
                            children: [
                              const Text(
                                'Booking ID',

                                style:
                                    TextStyle(
                                  fontSize:
                                      11,
                                  color:
                                      Color(
                                    0xFF999999,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              Flexible(
                                child: Text(
                                  bookingId,

                                  textAlign:
                                      TextAlign
                                          .right,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    color:
                                        Color(
                                      0xFF555555,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // INFORMATION
                    // ==================================================

                    Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFF5F7,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),

                        border: Border.all(
                          color:
                              const Color(
                            0xFFFFE0E6,
                          ),
                        ),
                      ),

                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Icon(
                            Icons
                                .info_outline,
                            color: red,
                            size: 19,
                          ),

                          SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              'Your booking is saved. You can view it anytime from My Bookings.',
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                height:
                                    1.4,
                                color:
                                    Color(
                                  0xFF666666,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================================
            // VIEW MY BOOKINGS BUTTON
            // ==========================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                17,
              ),

              color: Colors.white,

              child: SizedBox(
                height: 53,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            const MyBookingsScreen(),
                      ),

                      (route) => false,
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: red,

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child: const Text(
                    'View My Bookings',

                    style: TextStyle(
                      fontSize: 15,
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

// =================================================================
// INFO ROW
// =================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF5F5F6),

            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),

          child: Icon(
            icon,
            color:
                const Color(0xFF555555),
            size: 19,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      Color(0xFF999999),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                value,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize: 13,
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
    );
  }
}