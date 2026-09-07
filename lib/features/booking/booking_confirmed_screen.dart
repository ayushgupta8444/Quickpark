import 'package:flutter/material.dart';

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

  static const Color red = Color(0xFFEF0038);
  static const Color darkText = Color(0xFF292929);
  static const Color greyText = Color(0xFF777777);

  // ============================================================
  // 6 DIGIT BOOKING ID
  // ============================================================

  String get sixDigitBookingId {
    final String digits =
        bookingId.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 6) {
      return digits.substring(0, 6);
    }

    if (digits.isEmpty) {
      return '000001';
    }

    return digits.padLeft(6, '0');
  }

  // ============================================================
  // PRICE
  // ============================================================

  String get displayPrice {
    final String value = price.trim();

    if (value.isEmpty) {
      return '₹0';
    }

    if (value.startsWith('₹')) {
      return value;
    }

    return '₹$value';
  }

  // ============================================================
  // VALLET
  // ============================================================

  String get displayValetName {
    if (valetName.trim().isEmpty) {
      return 'Ravi Kumar';
    }

    return valetName;
  }

  // ============================================================
  // VEHICLE
  // ============================================================

  String get displayVehicle {
    if (carNumber.trim().isNotEmpty) {
      return carNumber;
    }

    if (carModel.trim().isNotEmpty) {
      return carModel;
    }

    return 'Vehicle';
  }

  // ============================================================
  // DESTINATION
  // ============================================================

  String get displayDestination {
    if (destinationName.trim().isEmpty) {
      return 'UB City Mall Valet';
    }

    return destinationName;
  }

  // ============================================================
  // TRACK VALET
  // ============================================================

  void _openTrackValet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return TrackValetScreen(
            bookingId: sixDigitBookingId,
            destinationName: displayDestination,
            valetName: displayValetName,
            carNumber: displayVehicle,
            carModel: carModel,
          );
        },
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: greyText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: darkText,
                fontWeight: FontWeight.w700,
              ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: darkText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Booking Confirmed',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFEAEAEA),
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        top: false,

        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  14,
                  13,
                  14,
                  13,
                ),

                child: Column(
                  children: [
                    // ==================================================
                    // BOOKING CONFIRMED CARD
                    // ==================================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 14,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9EF),
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Column(
                        children: [
                          Container(
                            width: 45,
                            height: 45,

                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.check_circle_outline,
                              color: red,
                              size: 30,
                            ),
                          ),

                          const SizedBox(height: 9),

                          const Text(
                            'Booking Confirmed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Booking ID: $sixDigitBookingId',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // VALET STATUS
                    // ==================================================

                    Container(
                      width: double.infinity,
                      height: 32,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFB82E),
                        ),
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,

                            decoration: const BoxDecoration(
                              color: Color(0xFFF0A400),
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 7),

                          const Text(
                            'Valet is on the way',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB87900),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // BOOKING DETAILS
                    // ==================================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        10,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'BOOKING DETAILS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: greyText,
                            ),
                          ),

                          const SizedBox(height: 7),

                          _detailRow(
                            'Vehicle',
                            displayVehicle,
                          ),

                          _detailRow(
                            'Location',
                            displayDestination,
                          ),

                          _detailRow(
                            'Duration',
                            '2 hrs',
                          ),

                          const SizedBox(height: 5),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE1E1E3),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                              ),

                              Text(
                                displayPrice,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // ASSIGNED VALET
                    // ==================================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFE7E7E9),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'ASSIGNED VALET',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: greyText,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                width: 43,
                                height: 43,

                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8E8EA),
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF777777),
                                  size: 26,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayValetName,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,

                                            style:
                                                const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w800,
                                              color: darkText,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 4),

                                        const Icon(
                                          Icons.verified,
                                          size: 13,
                                          color:
                                              Color(0xFF16A05D),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 2),

                                    const Text(
                                      '4.8 ★ · Verified Agent',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: greyText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // TRACK VALET BUTTON
            // ========================================================

            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                10,
              ),

              decoration: const BoxDecoration(
                color: Colors.white,

                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEAEAEA),
                  ),
                ),
              ),

              child: SizedBox(
                height: 43,

                child: ElevatedButton(
                  onPressed: () {
                    _openTrackValet(context);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),

                  child: const Text(
                    'Track Valet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

// ==================================================================
// TRACK VALET SCREEN
// ==================================================================

class TrackValetScreen extends StatelessWidget {
  final String bookingId;
  final String destinationName;
  final String valetName;
  final String carNumber;
  final String carModel;

  const TrackValetScreen({
    super.key,
    required this.bookingId,
    required this.destinationName,
    required this.valetName,
    required this.carNumber,
    required this.carModel,
  });

  static const Color red = Color(0xFFEF0038);
  static const Color darkText = Color(0xFF292929);
  static const Color greyText = Color(0xFF777777);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE9E9),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: darkText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Track Valet',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFEAEAEA),
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Stack(
        children: [
          // ==================================================
          // MAP
          // ==================================================

          Positioned.fill(
            child: CustomPaint(
              painter: ParkingMapPainter(),
            ),
          ),

          // ==================================================
          // ESTIMATED ARRIVAL
          // ==================================================

          Positioned(
            top: 12,
            left: 13,
            right: 13,

            child: Container(
              height: 63,

              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Text(
                          'ESTIMATED ARRIVAL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: greyText,
                          ),
                        ),

                        const SizedBox(height: 3),

                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'Valet arriving in ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: darkText,
                                ),
                              ),

                              TextSpan(
                                text: '4 mins',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFFE0A000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 11,
                    height: 11,

                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFE0A000),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // DESTINATION LABEL
          // ==================================================

          Positioned(
            left: 27,
            top: 225,

            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(6),
              ),

              child: Text(
                destinationName.isEmpty
                    ? 'UB City Mall Valet'
                    : destinationName,

                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ),
          ),

          // ==================================================
          // USER LOCATION
          // ==================================================

          Positioned(
            left: 90,
            top: 325,

            child: Container(
              width: 24,
              height: 24,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,

                border: Border.all(
                  color: const Color(0xFF1788FF),
                  width: 5,
                ),
              ),
            ),
          ),

          // ==================================================
          // VALET MARKER
          // ==================================================

          Positioned(
            right: 52,
            top: 245,

            child: Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color: red,
                shape: BoxShape.circle,

                border: Border.all(
                  color: Colors.white,
                  width: 5,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        red.withOpacity(.35),
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                ],
              ),

              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),

          // ==================================================
          // BOTTOM VALET CARD
          // ==================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,

            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                14,
                15,
                14,
                17,
              ),

              decoration:
                  const BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.only(
                  topLeft:
                      Radius.circular(18),
                  topRight:
                      Radius.circular(18),
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Color(0x22000000),
                    blurRadius: 14,
                    offset:
                        Offset(0, -4),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  // ==========================================
                  // CAR INFORMATION
                  // ==========================================

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Your car is being parked',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w800,
                                color: darkText,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Valet agent: '
                              '${valetName.isEmpty ? 'Ravi Kumar' : valetName}',

                              style:
                                  const TextStyle(
                                fontSize: 13,
                                color: greyText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFE8ED,
                          ),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),

                        child: Text(
                          carNumber.isEmpty
                              ? carModel
                              : carNumber,

                          style:
                              const TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w800,
                            color: red,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // ==========================================
                  // VALET INFORMATION
                  // ==========================================

                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFE5E5E6),
                          shape:
                              BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.person,
                          color:
                              Color(0xFF777777),
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              valetName.isEmpty
                                  ? 'Ravi Kumar'
                                  : valetName,

                              style:
                                  const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w800,
                                color: darkText,
                              ),
                            ),

                            const SizedBox(height: 3),

                            const Text(
                              'Verified Valet Partner',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(
                                  0xFF16A05D,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ========================================
                      // CHAT
                      // ========================================

                      Container(
                        width: 39,
                        height: 39,

                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            9,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFE1E1E1,
                            ),
                          ),
                        ),

                        child: IconButton(
                          padding:
                              EdgeInsets.zero,

                          onPressed: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chat with valet',
                                ),
                              ),
                            );
                          },

                          icon:
                              const Icon(
                            Icons
                                .chat_bubble_outline,
                            size: 19,
                            color: darkText,
                          ),
                        ),
                      ),

                      const SizedBox(width: 7),

                      // ========================================
                      // CALL
                      // ========================================

                      Container(
                        width: 39,
                        height: 39,

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFE8ED,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            9,
                          ),
                        ),

                        child: IconButton(
                          padding:
                              EdgeInsets.zero,

                          onPressed: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Calling valet...',
                                ),
                              ),
                            );
                          },

                          icon:
                              const Icon(
                            Icons.phone,
                            size: 19,
                            color: red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// MAP PAINTER
// ==================================================================

class ParkingMapPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ==========================================================
    // BACKGROUND
    // ==========================================================

    final Paint background =
        Paint()
          ..color =
              const Color(0xFFD8E7E7);

    canvas.drawRect(
      Offset.zero & size,
      background,
    );

    // ==========================================================
    // GREEN AREAS
    // ==========================================================

    final Paint green =
        Paint()
          ..color =
              const Color(0xFFC4D7C8);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        80,
        size.width * .30,
        180,
      ),
      green,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .72,
        90,
        size.width * .28,
        180,
      ),
      green,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * .43,
        size.width * .30,
        220,
      ),
      green,
    );

    // ==========================================================
    // WATER
    // ==========================================================

    final Paint water =
        Paint()
          ..color =
              const Color(0xFFB8D4D9);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .76,
        size.height * .50,
        size.width * .24,
        220,
      ),
      water,
    );

    // ==========================================================
    // BUILDINGS
    // ==========================================================

    final Paint building =
        Paint()
          ..color =
              const Color(0xFFB8C9CB);

    for (int row = 0;
        row < 8;
        row++) {
      for (int col = 0;
          col < 6;
          col++) {
        final double x =
            12 + col * 67;

        final double y =
            110 + row * 62;

        if (x < size.width - 40 &&
            y < size.height - 170) {
          canvas.drawRect(
            Rect.fromLTWH(
              x,
              y,
              37,
              24,
            ),
            building,
          );
        }
      }
    }

    // ==========================================================
    // ROADS
    // ==========================================================

    final Paint road =
        Paint()
          ..color =
              const Color(0xFF9EAEB1)
          ..strokeWidth = 32
          ..style =
              PaintingStyle.stroke;

    final Path road1 =
        Path();

    road1.moveTo(
      -30,
      size.height * .30,
    );

    road1.lineTo(
      size.width + 30,
      size.height * .63,
    );

    canvas.drawPath(
      road1,
      road,
    );

    final Path road2 =
        Path();

    road2.moveTo(
      size.width * .16,
      -30,
    );

    road2.lineTo(
      size.width * .70,
      size.height + 30,
    );

    canvas.drawPath(
      road2,
      road,
    );

    // ==========================================================
    // ROAD LINES
    // ==========================================================

    final Paint roadLine =
        Paint()
          ..color =
              const Color(0xFFE6EEEE)
          ..strokeWidth = 2;

    canvas.drawLine(
      Offset(
        0,
        size.height * .30,
      ),
      Offset(
        size.width,
        size.height * .63,
      ),
      roadLine,
    );

    canvas.drawLine(
      Offset(
        size.width * .16,
        0,
      ),
      Offset(
        size.width * .70,
        size.height,
      ),
      roadLine,
    );

    // ==========================================================
    // SMALL STREET LINES
    // ==========================================================

    final Paint smallRoad =
        Paint()
          ..color =
              const Color(0xFFB9C8CA)
          ..strokeWidth = 1.2;

    for (int i = 0;
        i < 8;
        i++) {
      final double x =
          20 + i * 55;

      canvas.drawLine(
        Offset(
          x,
          90,
        ),
        Offset(
          x + 40,
          size.height * .72,
        ),
        smallRoad,
      );
    }

    // ==========================================================
    // ROUTE GLOW
    // ==========================================================

    final Paint routeGlow =
        Paint()
          ..color =
              const Color(0x55EF0038)
          ..strokeWidth = 11
          ..style =
              PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    // ==========================================================
    // ROUTE
    // ==========================================================

    final Paint route =
        Paint()
          ..color =
              const Color(0xFFEF0038)
          ..strokeWidth = 4
          ..style =
              PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    final Path routePath =
        Path();

    routePath.moveTo(
      size.width * .27,
      size.height * .48,
    );

    routePath.cubicTo(
      size.width * .35,
      size.height * .40,
      size.width * .40,
      size.height * .55,
      size.width * .49,
      size.height * .44,
    );

    routePath.cubicTo(
      size.width * .56,
      size.height * .35,
      size.width * .47,
      size.height * .31,
      size.width * .56,
      size.height * .26,
    );

    routePath.cubicTo(
      size.width * .63,
      size.height * .21,
      size.width * .69,
      size.height * .27,
      size.width * .78,
      size.height * .31,
    );

    canvas.drawPath(
      routePath,
      routeGlow,
    );

    canvas.drawPath(
      routePath,
      route,
    );

    // ==========================================================
    // MAP LABELS
    // ==========================================================

    _drawMapText(
      canvas,
      'STREET ROAD',
      Offset(
        size.width * .45,
        size.height * .31,
      ),
    );

    _drawMapText(
      canvas,
      'MAIN STREET',
      Offset(
        size.width * .57,
        size.height * .55,
      ),
    );

    _drawMapText(
      canvas,
      'FORUM MALL',
      Offset(
        size.width * .70,
        size.height * .40,
      ),
    );
  }

  // ============================================================
  // MAP TEXT
  // ============================================================

  void _drawMapText(
    Canvas canvas,
    String text,
    Offset position,
  ) {
    final TextPainter painter =
        TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 7,
          color: Color(0xFF687779),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    painter.layout();

    painter.paint(
      canvas,
      position,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}