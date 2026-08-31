import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../destination/destination_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DestinationScreen(),
      ),
    );
  },
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

      body: user == null
          ? const Center(
              child: Text(
                'Please login to view your bookings.',
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              // =================================================
              // FIRESTORE QUERY
              // orderBy removed to avoid composite index error
              // =================================================

              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                // =================================================
                // LOADING
                // =================================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF0038),
                    ),
                  );
                }

                // =================================================
                // ERROR
                // =================================================

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),

                      child: Text(
                        'Unable to load bookings.\n\n'
                        '${snapshot.error}',

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  );
                }

                // =================================================
                // GET BOOKINGS
                // =================================================

                final bookings =
                    snapshot.data?.docs.toList() ?? [];

                // =================================================
                // SORT LOCALLY
                // Latest booking first
                // =================================================

                bookings.sort((a, b) {
                  final aData =
                      a.data() as Map<String, dynamic>;

                  final bData =
                      b.data() as Map<String, dynamic>;

                  final aTime =
                      aData['createdAt'] as Timestamp?;

                  final bTime =
                      bData['createdAt'] as Timestamp?;

                  // Both don't have time
                  if (aTime == null &&
                      bTime == null) {
                    return 0;
                  }

                  // a doesn't have time
                  if (aTime == null) {
                    return 1;
                  }

                  // b doesn't have time
                  if (bTime == null) {
                    return -1;
                  }

                  // Newest first
                  return bTime.compareTo(aTime);
                });

                // =================================================
                // NO BOOKINGS
                // =================================================

                if (bookings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          Icon(
                            Icons.local_parking_outlined,
                            size: 65,
                            color: Color(0xFFCCCCCC),
                          ),

                          SizedBox(
                            height: 20,
                          ),

                          Text(
                            'No bookings yet',

                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF222222),
                            ),
                          ),

                          SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Your confirmed bookings will appear here.',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // =================================================
                // BOOKINGS LIST
                // =================================================

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),

                  itemCount:
                      bookings.length,

                  itemBuilder:
                      (context, index) {
                    final data =
                        bookings[index].data()
                            as Map<String, dynamic>;

                    return _BookingCard(
                      data: data,
                    );
                  },
                );
              },
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

  @override
  Widget build(BuildContext context) {
    final String valetName =
        data['valetName']?.toString() ??
            'QuickPark Valet';

    final String destination =
        data['destination']?.toString() ??
            'Unknown destination';

    final String carModel =
        data['carModel']?.toString() ??
            'Vehicle';

    final String registrationNumber =
        data['registrationNumber']?.toString() ??
            '';

    final String price =
        data['price']?.toString() ??
            '₹0';

    final String status =
        data['status']?.toString() ??
            'confirmed';

    final String bookingId =
        data['bookingId']?.toString() ??
            '';

    // ============================================================
    // STATUS TEXT
    // ============================================================

    String statusText;

    if (status == 'completed') {
      statusText = 'COMPLETED';
    } else if (status == 'cancelled') {
      statusText = 'CANCELLED';
    } else {
      statusText = 'CONFIRMED';
    }

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

          // ========================================================
          // HEADER
          // ========================================================

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
                  color:
                      Color(0xFFEF0038),
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      valetName,

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      destination,

                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              // ====================================================
              // STATUS
              // ====================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      status == 'cancelled'
                          ? const Color(
                              0xFFFFEEEE,
                            )
                          : status == 'completed'
                              ? const Color(
                                  0xFFF0F0F0,
                                )
                              : const Color(
                                  0xFFEAF8F0,
                                ),

                  borderRadius:
                      BorderRadius.circular(8),
                ),

                child: Text(
                  statusText,

                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,

                    color:
                        status == 'cancelled'
                            ? const Color(
                                0xFFD00030,
                              )
                            : status ==
                                    'completed'
                                ? const Color(
                                    0xFF666666,
                                  )
                                : const Color(
                                    0xFF1D8A50,
                                  ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Divider(
            height: 1,
            color:
                Color(0xFFEAEAEA),
          ),

          const SizedBox(
            height: 16,
          ),

          // ========================================================
          // DESTINATION
          // ========================================================

          Row(
            children: [

              const Icon(
                Icons.location_on_outlined,
                size: 19,
                color:
                    Color(0xFF777777),
              ),

              const SizedBox(
                width: 9,
              ),

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

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      destination,

                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ========================================================
          // VEHICLE
          // ========================================================

          Row(
            children: [

              const Icon(
                Icons.directions_car_outlined,
                size: 19,
                color:
                    Color(0xFF777777),
              ),

              const SizedBox(
                width: 9,
              ),

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

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      '$carModel'
                      '${registrationNumber.isNotEmpty ? ' • $registrationNumber' : ''}',

                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ========================================================
          // PRICE
          // ========================================================

          Row(
            children: [

              const Icon(
                Icons.payments_outlined,
                size: 19,
                color:
                    Color(0xFF777777),
              ),

              const SizedBox(
                width: 9,
              ),

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

                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF171717),
                ),
              ),
            ],
          ),

          // ========================================================
          // BOOKING ID
          // ========================================================

          if (bookingId.isNotEmpty) ...[

            const SizedBox(
              height: 16,
            ),

            const Divider(
              height: 1,
              color:
                  Color(0xFFEAEAEA),
            ),

            const SizedBox(
              height: 12,
            ),

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

                  style:
                      const TextStyle(
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