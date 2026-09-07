import 'package:flutter/material.dart';

class BookingScheduledScreen extends StatelessWidget {
  final String bookingId;
  final String valetName;
  final String destinationName;
  final DateTime scheduledDateTime;
  final int price;
  final String duration;
  final String vehicle;

  const BookingScheduledScreen({
    super.key,
    required this.bookingId,
    required this.valetName,
    required this.destinationName,
    required this.scheduledDateTime,
    required this.price,
    required this.duration,
    this.vehicle = 'Vehicle not selected',
  });

  static const Color red = Color(0xFFEF0038);
  static const Color darkText = Color(0xFF292929);
  static const Color greyText = Color(0xFF777777);

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  String _weekday(int weekday) {
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  String _dateLabel() {
    final now = DateTime.now();

    final selected = DateTime(
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
    );

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrow = today.add(
      const Duration(days: 1),
    );

    if (selected == today) {
      return 'Today';
    }

    if (selected == tomorrow) {
      return 'Tomorrow';
    }

    return '${_weekday(scheduledDateTime.weekday)}, '
        '${scheduledDateTime.day} '
        '${_month(scheduledDateTime.month)}';
  }

  String _formatTime(BuildContext context) {
    return TimeOfDay.fromDateTime(
      scheduledDateTime,
    ).format(context);
  }

  String _displayBookingId() {
    final digits = bookingId.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return '000001';
    }

    if (digits.length >= 6) {
      return digits.substring(
        digits.length - 6,
      );
    }

    return digits.padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          'Booking Scheduled',
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

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  14,
                  16,
                  14,
                  14,
                ),
                child: Column(
                  children: [
                    // BOOKING SCHEDULED
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 19,
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
                            'Booking Scheduled',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: QPK-${_displayBookingId()}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // STATUS
                    Container(
                      width: double.infinity,
                      height: 42,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F7),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: red),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            'Valet scheduled successfully',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOOKING DETAILS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        12,
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
                          const SizedBox(height: 8),

                          _detailRow(
                            'Vehicle',
                            vehicle,
                          ),

                          _detailRow(
                            'Location',
                            destinationName,
                          ),

                          _detailRow(
                            'Scheduled',
                            '${_dateLabel()}, '
                            '${_formatTime(context)}',
                          ),

                          _detailRow(
                            'Duration',
                            duration,
                          ),

                          const SizedBox(height: 5),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE1E1E3),
                          ),

                          const SizedBox(height: 9),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              Text(
                                '₹$price',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ASSIGNED VALET
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
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
                          const SizedBox(height: 9),

                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration:
                                    const BoxDecoration(
                                  color: Color(0xFFE5E5E7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF777777),
                                  size: 27,
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
                                            valetName,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w800,
                                              color: darkText,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified,
                                          color: Color(0xFF16A05D),
                                          size: 14,
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

            // BOTTOM BUTTONS
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
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: red,
                          side: const BorderSide(
                            color: red,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Edit Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          _showCancelDialog(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF777777),
                          side: const BorderSide(
                            color: Color(0xFF777777),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Cancel Schedule',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel Schedule?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this scheduled booking?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule cancelled'),
                  ),
                );
              },
              child: const Text(
                'Cancel Schedule',
                style: TextStyle(color: red),
              ),
            ),
          ],
        );
      },
    );
  }
}
