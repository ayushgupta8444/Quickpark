import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../destination/destination_screen.dart';
import '../profile/profile_screen.dart';
import 'booking_confirmed_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const String baseUrl = 'http://10.0.2.2:3000';

  bool _isLoading = true;
  String? _errorMessage;

  // 0 = Active Service, 1 = Upcoming, 2 = Past
  int _selectedTab = 0;

  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  // ============================================================
  // LOAD BOOKINGS FROM POSTGRESQL
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

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final firebaseUid = user.uid;

      final uri = Uri.parse(
        '$baseUrl/api/bookings/${Uri.encodeComponent(firebaseUid)}',
      );

      debugPrint('GET BOOKINGS: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('BOOKINGS STATUS: ${response.statusCode}');
      debugPrint('BOOKINGS RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid bookings response.');
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Unable to load bookings',
        );
      }

      final rawBookings = decoded['bookings'];

      final List<Map<String, dynamic>> loadedBookings = [];

      if (rawBookings is List) {
        for (final booking in rawBookings) {
          if (booking is Map) {
            loadedBookings.add(
              Map<String, dynamic>.from(booking),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _bookings = loadedBookings;
        _isLoading = false;
        _errorMessage = null;
      });

      debugPrint(
        'BOOKINGS LOADED: ${loadedBookings.length}',
      );
    } catch (error) {
      debugPrint('BOOKINGS ERROR: $error');

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
        builder: (_) => const DestinationScreen(),
      ),
    );
  }

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  bool _isActive(Map<String, dynamic> data) {
    final status = _stringValue(
      data,
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    return {
      'active',
      'in_progress',
      'in-progress',
      'in progress',
      'arriving',
      'arrived',
      'vehicle_received',
      'vehicle-received',
      'parking',
      'parked',
      'retrieving',
      'ready_for_pickup',
      'ready-for-pickup',
    }.contains(status);
  }

  bool _isPast(Map<String, dynamic> data) {
    final status = _stringValue(
      data,
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    return {
      'completed',
      'cancelled',
      'canceled',
      'expired',
      'no_show',
      'no-show',
      'rejected',
      'payment_failed',
      'payment-failed',
    }.contains(status);
  }

  List<Map<String, dynamic>> get _upcomingBookings {
    return _bookings.where((booking) {
      return !_isActive(booking) && !_isPast(booking);
    }).toList();
  }

  List<Map<String, dynamic>> get _activeBookings {
    return _bookings.where(_isActive).toList();
  }

  List<Map<String, dynamic>> get _pastBookings {
    return _bookings.where(_isPast).toList();
  }

  // ============================================================
  // SAFE VALUES
  // ============================================================

  String _stringValue(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];

    if (value == null) return fallback;

    final text = value.toString();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  String _price(Map<String, dynamic> data) {
    final value = data['amount'];

    if (value == null) return '₹0';

    final amount = double.tryParse(
      value.toString(),
    );

    if (amount == null) {
      return '₹${value.toString()}';
    }

    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _formatBookingDate(Map<String, dynamic> data) {
    // If scheduled_at is added to the backend later, this screen
    // will automatically prefer it.
    final scheduledAt =
        _parseDate(data['scheduled_at']) ??
        _parseDate(data['scheduledAt']);

    final createdAt =
        _parseDate(data['created_at']) ??
        _parseDate(data['createdAt']);

    final dateTime = scheduledAt ?? createdAt;

    if (dateTime == null) {
      return 'Booking time unavailable';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final dateOnly = DateTime(
      local.year,
      local.month,
      local.day,
    );

    final difference =
        dateOnly.difference(today).inDays;

    String day;

    if (difference == 0) {
      day = 'Today';
    } else if (difference == 1) {
      day = 'Tomorrow';
    } else if (difference == -1) {
      day = 'Yesterday';
    } else {
      day =
          '${local.day} ${_monthName(local.month)}';
    }

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period =
        local.hour >= 12 ? 'PM' : 'AM';

    return '$day · $hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _displayStatus(Map<String, dynamic> data) {
    final status = _stringValue(
      data,
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    if (_isActive(data)) {
      return 'In Progress';
    }

    if (status == 'completed') {
      return 'Completed';
    }

    if (status == 'cancelled' ||
        status == 'canceled') {
      return 'Cancelled';
    }

    if (status == 'pending') {
      return 'Pending';
    }

    return 'Scheduled';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF222222),
            ),
            onPressed: _goBack,
          ),

          const Expanded(
            child: Text(
              'My Bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF171717),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(
              Icons.refresh,
              size: 20,
              color: Color(0xFF555555),
            ),
            onPressed: _loadBookings,
          ),
        ],
      ),
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
      return RefreshIndicator(
        color: const Color(0xFFEF0038),
        onRefresh: _loadBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 520,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 58,
                        color: Color(0xFFCCCCCC),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load bookings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF0038),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
              ),
            ),
          ],
        ),
      );
    }

    final activeBookings = _activeBookings;
    final upcomingBookings = _upcomingBookings;
    final pastBookings = _pastBookings;

    final List<Map<String, dynamic>> selectedBookings;

    if (_selectedTab == 0) {
      selectedBookings = activeBookings;
    } else if (_selectedTab == 1) {
      selectedBookings = upcomingBookings;
    } else {
      selectedBookings = pastBookings;
    }

    return RefreshIndicator(
      color: const Color(0xFFEF0038),
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          25,
        ),
        children: [
          _buildBookingTabs(
            activeCount: activeBookings.length,
            upcomingCount: upcomingBookings.length,
            pastCount: pastBookings.length,
          ),

          const SizedBox(height: 18),

          if (selectedBookings.isEmpty)
            SizedBox(
              height: 470,
              child: _buildTabEmptyState(
                selectedTab: _selectedTab,
              ),
            )
          else
            ...selectedBookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BookingCard(
                  data: booking,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE / UPCOMING TABS
  // ============================================================

  Widget _buildBookingTabs({
    required int activeCount,
    required int upcomingCount,
    required int pastCount,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BookingTab(
              label: 'Active Service',
              count: activeCount,
              selected: _selectedTab == 0,
              onTap: () {
                if (_selectedTab == 0) return;

                setState(() {
                  _selectedTab = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _BookingTab(
              label: 'Upcoming',
              count: upcomingCount,
              selected: _selectedTab == 1,
              onTap: () {
                if (_selectedTab == 1) return;

                setState(() {
                  _selectedTab = 1;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _BookingTab(
              label: 'Past',
              count: pastCount,
              selected: _selectedTab == 2,
              onTap: () {
                if (_selectedTab == 2) return;

                setState(() {
                  _selectedTab = 2;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabEmptyState({
    required int selectedTab,
  }) {
    final isActiveTab = selectedTab == 0;
    final isUpcomingTab = selectedTab == 1;

    final IconData icon = isActiveTab
        ? Icons.directions_car_outlined
        : isUpcomingTab
            ? Icons.calendar_today_outlined
            : Icons.history_outlined;

    final String title = isActiveTab
        ? 'No active service'
        : isUpcomingTab
            ? 'No upcoming bookings'
            : 'No past bookings';

    final String subtitle = isActiveTab
        ? 'Your active valet service will appear here.'
        : isUpcomingTab
            ? 'Your scheduled bookings will appear here.'
            : 'Your completed and cancelled bookings will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFFBDBDBD),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
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
            const Text(
              'P',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD1D1D1),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your confirmed bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAEAEA),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DestinationScreen(),
                ),
              );
            },
          ),

          _BottomNavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Bookings',
            selected: true,
            onTap: () {},
          ),

          _BottomNavItem(
            icon: Icons.notifications_none_outlined,
            label: 'Alerts',
            selected: false,
            onTap: () {},
          ),

          _BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF666666),
      ),
    );
  }
}

// ============================================================
// BOOKING CARD
// ============================================================

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BookingCard({
    required this.data,
  });

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _stringValue(
    String key, {
    String fallback = '',
  }) {
    final value = data[key];

    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // BOOKING ID
  // ============================================================

  String _bookingId() {
    final value =
        data['booking_id'] ??
        data['bookingId'] ??
        data['id'];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // ACTIVE
  // ============================================================

  bool get isActive {
    final status = _stringValue(
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    return {
      'active',
      'in_progress',
      'in-progress',
      'in progress',
      'arriving',
      'arrived',
      'vehicle_received',
      'vehicle-received',
      'parking',
      'parked',
      'retrieving',
      'ready_for_pickup',
      'ready-for-pickup',
    }.contains(status);
  }

  // ============================================================
  // PAST
  // ============================================================

  bool get isPast {
    final status = _stringValue(
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    return {
      'completed',
      'cancelled',
      'canceled',
      'expired',
      'no_show',
      'no-show',
      'rejected',
      'payment_failed',
      'payment-failed',
    }.contains(status);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText() {
    final status = _stringValue(
      'status',
      fallback: 'confirmed',
    ).toLowerCase().trim();

    if (isActive) {
      return 'In Progress';
    }

    if (status == 'completed') {
      return 'Completed';
    }

    if (status == 'cancelled' ||
        status == 'canceled') {
      return 'Cancelled';
    }

    if (status == 'pending') {
      return 'Pending';
    }

    return 'Scheduled';
  }

  Color _statusBackground() {
    if (isActive) {
      return const Color(0xFFFFF5DF);
    }

    if (isPast) {
      return const Color(0xFFF0F0F0);
    }

    return const Color(0xFFFFE9EE);
  }

  Color _statusColor() {
    if (isActive) {
      return const Color(0xFFB77A00);
    }

    if (isPast) {
      return const Color(0xFF666666);
    }

    return const Color(0xFFE9003C);
  }

  // ============================================================
  // PRICE
  // ============================================================

  String _price() {
    final value = data['amount'];

    if (value == null) {
      return '₹0';
    }

    final amount = double.tryParse(
      value.toString(),
    );

    if (amount == null) {
      return '₹${value.toString()}';
    }

    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _bookingDate() {
    final scheduled =
        _parseDate(data['scheduled_at']) ??
        _parseDate(data['scheduledAt']);

    final created =
        _parseDate(data['created_at']) ??
        _parseDate(data['createdAt']);

    final dateTime =
        scheduled ?? created;

    if (dateTime == null) {
      return 'Booking time unavailable';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final dateOnly = DateTime(
      local.year,
      local.month,
      local.day,
    );

    final difference =
        dateOnly.difference(today).inDays;

    String day;

    if (difference == 0) {
      day = 'Today';
    } else if (difference == 1) {
      day = 'Tomorrow';
    } else if (difference == -1) {
      day = 'Yesterday';
    } else {
      day =
          '${local.day} ${_monthName(local.month)}';
    }

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period =
        local.hour >= 12 ? 'PM' : 'AM';

    return '$day · $hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // OPEN BOOKING CONFIRMED SCREEN
  // ============================================================

  void _openBookingConfirmed(
    BuildContext context,
  ) {
    final bookingId = _bookingId();

    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Booking ID not available.',
          ),
        ),
      );
      return;
    }

    final valetName = _stringValue(
      'valet_name',
      fallback: _stringValue(
        'valetName',
        fallback: 'QuickPark Valet',
      ),
    );

    final destinationName = _stringValue(
      'destination_name',
      fallback: _stringValue(
        'destinationName',
        fallback: 'Unknown destination',
      ),
    );

    final carNumber = _stringValue(
      'registration_number',
      fallback: _stringValue(
        'registrationNumber',
      ),
    );

    final carModel = _stringValue(
      'car_model',
      fallback: _stringValue(
        'carModel',
        fallback: 'Vehicle',
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmedScreen(
          bookingId: bookingId,
          destinationName: destinationName,
          valetName: valetName,
          carNumber: carNumber,
          carModel: carModel,
          price: _price(),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final valetName = _stringValue(
      'valet_name',
      fallback: 'QuickPark Valet',
    );

    final carModel = _stringValue(
      'car_model',
      fallback: 'Vehicle',
    );

    final registrationNumber =
        _stringValue(
      'registration_number',
    );

    final customerName = _stringValue(
      'full_name',
      fallback: _stringValue(
        'customer_name',
      ),
    );

    final vehicleText = [
      if (registrationNumber.isNotEmpty)
        registrationNumber,
      if (customerName.isNotEmpty)
        customerName,
    ].join(' · ');

    final secondaryVehicleText =
        vehicleText.isNotEmpty
            ? vehicleText
            : carModel;

    return GestureDetector(
      onTap: () {
        _openBookingConfirmed(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF0B52B),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'CURRENT BOOKING'
                            : isPast
                                ? 'PAST BOOKING'
                                : 'UPCOMING BOOKING',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        valetName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF171717),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _statusBackground(),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusText(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              secondaryVehicleText,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 9),
            const Divider(
              height: 1,
              color: Color(0xFFEAEAEA),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _bookingDate(),
                    style: const TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF777777),
                    ),
                  ),
                ),
                Text(
                  _price(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFFEF0038),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING TAB
// ============================================================

class _BookingTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _BookingTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? const Color(0xFF171717)
                    : const Color(0xFF777777),
              ),
            ),

            if (count > 0) ...[
              const SizedBox(width: 6),

              Container(
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFE8EE)
                      : const Color(0xFFE1E1E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFFEF0038)
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV ITEM
// ============================================================

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFFEF0038)
        : const Color(0xFF777777);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: color,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
