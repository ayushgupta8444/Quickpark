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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Column(
            children: [
              const Spacer(),

              // ==================================================
              // SUCCESS ICON
              // ==================================================

              Container(
                width: 105,
                height: 105,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFEAF8F0),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check,
                  size: 55,
                  color:
                      Color(0xFF1D8A50),
                ),
              ),

              const SizedBox(
                  height: 28),

              const Text(
                'Booking Confirmed!',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF171717),
                ),
              ),

              const SizedBox(
                  height: 10),

              const Text(
                'Your valet has been reserved successfully.',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color:
                      Color(0xFF707070),
                ),
              ),

              const SizedBox(
                  height: 30),

              // ==================================================
              // BOOKING CARD
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(
                  18,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFF7F7F7),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Column(
                  children: [
                    _infoRow(
                      'Booking ID',
                      bookingId
                          .substring(
                            0,
                            bookingId.length >
                                    8
                                ? 8
                                : bookingId
                                    .length,
                          )
                          .toUpperCase(),
                    ),

                    _infoRow(
                      'Valet',
                      valetName,
                    ),

                    _infoRow(
                      'Destination',
                      destinationName,
                    ),

                    _infoRow(
                      'Vehicle',
                      '$carModel • $carNumber',
                    ),

                    _infoRow(
                      'Amount',
                      price,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==================================================
              // DONE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
   onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const MyBookingsScreen(),
    ),
    (route) => false,
  );
},

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFEF0038),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 12),

              const Text(
                'You can view your booking details later.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF888888),
                ),
              ),

              const SizedBox(
                  height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String title,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color:
                      Color(0xFFE5E5E5),
                ),
              ),
      ),

      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF777777),
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,

              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF171717),
              ),
            ),
          ),
        ],
      ),
    );
  }
}