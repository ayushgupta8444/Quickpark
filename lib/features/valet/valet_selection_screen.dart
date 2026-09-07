import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../booking/booking_details_screen.dart';
import '../booking/booking_scheduled_screen.dart';

class ValetSelectionScreen extends StatefulWidget {
  final String destinationName;

  const ValetSelectionScreen({
    super.key,
    required this.destinationName,
  });

  @override
  State<ValetSelectionScreen> createState() =>
      _ValetSelectionScreenState();
}

class _ValetSelectionScreenState
    extends State<ValetSelectionScreen> {
  // ============================================================
  // BACKEND
  // ============================================================

  static const String baseUrl =
      'http://10.0.2.2:3000';

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  String? _error;

  List<Valet> valets = [];

  bool _isFavorite = false;

  int _selectedPricingTier = 0;

  // Selected schedule (day + time slot)
  DateTime? _scheduledDateTime;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadValets();
  }

  // ============================================================
  // LOAD VALETS
  // ============================================================

  Future<void> _loadValets() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final http.Response response =
          await http.get(
        Uri.parse(
          '$baseUrl/api/valets',
        ),
      );

      debugPrint(
        'VALETS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'VALETS RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid server response.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Unable to load valets.',
        );
      }

      final dynamic rawValets =
          decoded['valets'];

      if (rawValets is! List) {
        throw Exception(
          'Invalid valet data.',
        );
      }

      final List<Valet> loadedValets =
          rawValets
              .whereType<Map>()
              .map(
                (dynamic item) =>
                    Valet.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        valets = loadedValets;
        _isLoading = false;
        _error = null;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'LOAD VALETS ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error =
            'Unable to load available valets.';
      });
    }
  }

  // ============================================================
  // SELECT VALET
  // ============================================================

  void _selectValet(
    Valet valet,
  ) {
    if (!mounted) return;

    debugPrint(
      'Selected valet ID: ${valet.id}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BookingDetailsScreen(
          destinationName:
              widget.destinationName,

          valetId:
              valet.id,

          valetName:
              valet.name,

          rating:
              valet.rating,

          distance:
              valet.distance,

          eta:
              valet.eta,

          price:
              valet.price,

          slots:
              valet.slots,
        ),
      ),
    );
  }

  // ============================================================
  // BOOK NOW
  // ============================================================

  void _bookNow() {
    if (valets.isEmpty) {
      return;
    }

    _selectValet(
      valets.first,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F8),

      body: SafeArea(
        bottom: false,
        child:
            _buildScreen(),
      ),
    );
  }

  // ============================================================
  // SCREEN
  // ============================================================

  Widget _buildScreen() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFFEF0038),
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (valets.isEmpty) {
      return _buildEmpty();
    }

    final Valet valet =
        valets.first;

    return Column(
      children: [
        Expanded(
          child:
              SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),

            child: Column(
              children: [
                _buildHeader(),

                _buildHeroImage(),

                _buildLocationInfo(
                  valet,
                ),

                _buildPricing(),

                _buildStaffSection(),

                const SizedBox(
                  height: 18,
                ),
              ],
            ),
          ),
        ),

        SafeArea(
          top: false,
          child: _buildBookingBar(valet),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 58,

      color: Colors.white,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      child: Row(
        children: [
          _HeaderButton(
            icon:
                Icons.arrow_back_ios_new,

            onTap: () {
              Navigator.pop(
                context,
              );
            },
          ),

          const Expanded(
            child: Text(
              'Valet Location',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF1C1C1C),
              ),
            ),
          ),

          _HeaderButton(
            icon:
                _isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,

            iconColor:
                _isFavorite
                    ? const Color(
                        0xFFEF0038,
                      )
                    : const Color(
                        0xFF333333,
                      ),

            onTap: () {
              setState(() {
                _isFavorite =
                    !_isFavorite;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroImage() {
    return SizedBox(
      height: 165,

      width:
          double.infinity,

      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=85',

              fit: BoxFit.cover,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  color:
                      const Color(
                    0xFFD9D9D9,
                  ),

                  child:
                      const Center(
                    child: Icon(
                      Icons.location_city,
                      size: 50,
                      color:
                          Color(
                        0xFF999999,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned.fill(
            child:
                DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topCenter,

                  end:
                      Alignment.bottomCenter,

                  colors: [
                    Colors.transparent,

                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // VERIFIED BADGE
          // ======================================================

          Positioned(
            left: 13,
            bottom: 12,

            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(0x22000000),
                    blurRadius: 5,
                    offset:
                        Offset(0, 2),
                  ),
                ],
              ),

              child: Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Container(
                    width: 16,
                    height: 16,

                    decoration:
                        const BoxDecoration(
                      shape:
                          BoxShape.circle,

                      color:
                          Color(0xFF16A05D),
                    ),

                    child:
                        const Icon(
                      Icons.check,
                      size: 11,
                      color:
                          Colors.white,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  const Text(
                    'Verified Valet',

                    style:
                        TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(
                        0xFF218A55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION INFO
  // ============================================================

  Widget _buildLocationInfo(
    Valet valet,
  ) {
    return Container(
      width:
          double.infinity,

      color:
          Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        15,
        16,
        15,
        14,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            _displayValetName(
              valet,
            ),

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF1D1D1D),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Vittal Mallya Rd, KG Halli, '
            'D’Souza Layout, Bangalore,\n'
            'Karnataka 560001',

            style:
                TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color:
                  Color(0xFF777777),
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          Row(
            children: [
              const Icon(
                Icons.star,
                size: 16,
                color:
                    Color(0xFFFFB000),
              ),

              const SizedBox(
                width: 4,
              ),

              Text(
                valet.rating,

                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF333333),
                ),
              ),

              const SizedBox(
                width: 3,
              ),

              const Text(
                '(120+ reviews)',

                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Color(0xFF777777),
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              const Icon(
                Icons.access_time,
                size: 15,
                color:
                    Color(0xFF444444),
              ),

              const SizedBox(
                width: 4,
              ),

              const Text(
                '10 AM - 11:30 PM',

                style:
                    TextStyle(
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING
  // ============================================================

  Widget _buildPricing() {
    return Container(
      width:
          double.infinity,

      color:
          Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        15,
        3,
        15,
        16,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Pricing Tiers',

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF292929),
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _PricingCard(
                  title:
                      'Up to 2 hr',

                  price:
                      '₹90',

                  selected:
                      _selectedPricingTier ==
                          0,

                  onTap: () {
                    setState(() {
                      _selectedPricingTier =
                          0;
                    });
                  },
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    _PricingCard(
                  title:
                      'Up to 4 hr',

                  price:
                      '₹120',

                  selected:
                      _selectedPricingTier ==
                          1,

                  onTap: () {
                    setState(() {
                      _selectedPricingTier =
                          1;
                    });
                  },
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    _PricingCard(
                  title:
                      'Full Day',

                  price:
                      '₹150',

                  selected:
                      _selectedPricingTier ==
                          2,

                  onTap: () {
                    setState(() {
                      _selectedPricingTier =
                          2;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAFF
  // ============================================================

  Widget _buildStaffSection() {
    return Container(
      width:
          double.infinity,

      color:
          Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        15,
        0,
        15,
        14,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'On-Duty Valet Staff',

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF292929),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const _StaffCard(
            name:
                'Ravi Kumar',

            rating:
                '4.8 Rating',

            imageUrl:
                'https://randomuser.me/api/portraits/men/32.jpg',
          ),

          const SizedBox(
            height: 6,
          ),

          const _StaffCard(
            name:
                'Suresh M',

            rating:
                '4.6 Rating',

            imageUrl:
                'https://randomuser.me/api/portraits/men/45.jpg',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING BAR
  // ============================================================

  Widget _buildBookingBar(
    Valet valet,
  ) {
    return Container(
      color:
          Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        15,
        10,
        15,
        10,
      ),

      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,

              child:
                  ElevatedButton(
                onPressed:
                    _bookNow,

                style:
                    ElevatedButton
                        .styleFrom(
                  elevation: 0,

                  backgroundColor:
                      const Color(
                    0xFFEF0038,
                  ),

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      11,
                    ),
                  ),
                ),

                child:
                    const Text(
                  'Book Now',

                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          SizedBox(
            width: 48,
            height: 44,

            child:
                OutlinedButton(
              onPressed:
                  () => _showScheduleSheet(valet),

              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    const Color(
                  0xFFEF0038,
                ),

                side:
                    const BorderSide(
                  color:
                      Color(
                    0xFFE6E6E6,
                  ),

                  width: 1,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),

                padding:
                    EdgeInsets.zero,
              ),

              child:
                  const Icon(
                Icons
                    .calendar_month_outlined,

                size: 21,

                color:
                    Color(
                  0xFFEF0038,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE BOOKING
  // ============================================================

  Future<void> _showScheduleSheet(Valet valet) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime selectedDate = _scheduledDateTime != null &&
            !_scheduledDateTime!.isBefore(today)
        ? DateTime(
            _scheduledDateTime!.year,
            _scheduledDateTime!.month,
            _scheduledDateTime!.day,
          )
        : today;

    TimeOfDay? selectedTime =
        _scheduledDateTime != null &&
                selectedDate.year == _scheduledDateTime!.year &&
                selectedDate.month == _scheduledDateTime!.month &&
                selectedDate.day == _scheduledDateTime!.day
            ? TimeOfDay.fromDateTime(_scheduledDateTime!)
            : null;

    final dates = List.generate(
      5,
      (index) => today.add(Duration(days: index)),
    );

    final timeSlots = <TimeOfDay>[];
    for (int hour = 10; hour <= 23; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 23 && minute > 30) continue;
        timeSlots.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isPastTime(DateTime date, TimeOfDay time) {
              if (date.year != today.year ||
                  date.month != today.month ||
                  date.day != today.day) {
                return false;
              }

              return DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              ).isBefore(DateTime.now());
            }

            String dateLabel(DateTime date) {
              if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day) {
                return 'Today';
              }

              const weekdays = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];
              return weekdays[date.weekday - 1];
            }

            String timeLabel(TimeOfDay time) {
              return time.format(context);
            }

            final priceText = _selectedPricingTier == 0
                ? '₹90 / 2 hrs'
                : _selectedPricingTier == 1
                    ? '₹120 / 4 hrs'
                    : '₹150 / Full Day';

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.66,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D0D0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TITLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  valet.name.trim().isEmpty
                                      ? 'UB City Mall Valet'
                                      : valet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  priceText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF0038),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F4F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 17,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELECT DATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF777777),
                              ),
                            ),
                            const SizedBox(height: 7),

                            // DATE SELECTOR
                            SizedBox(
                              height: 55,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: dates.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final date = dates[index];
                                  final selected =
                                      date.year == selectedDate.year &&
                                      date.month == selectedDate.month &&
                                      date.day == selectedDate.day;

                                  return GestureDetector(
                                    onTap: () {
                                      setSheetState(() {
                                        selectedDate = date;
                                        if (selectedTime != null &&
                                            isPastTime(date, selectedTime!)) {
                                          selectedTime = null;
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 54,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFEF0038)
                                            : const Color(0xFFF2F2F4),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dateLabel(date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${date.day} ${_monthName(date.month)}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF777777),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'SELECT TIME SLOT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF777777),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // TIME SLOTS
                            ...timeSlots.map((slot) {
                              final disabled =
                                  isPastTime(selectedDate, slot);
                              final selected = selectedTime != null &&
                                  selectedTime!.hour == slot.hour &&
                                  selectedTime!.minute == slot.minute;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: GestureDetector(
                                  onTap: disabled
                                      ? null
                                      : () {
                                          setSheetState(() {
                                            selectedTime = slot;
                                          });
                                        },
                                  child: Container(
                                    height: 41,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: disabled
                                          ? const Color(0xFFF7F7F7)
                                          : selected
                                              ? const Color(0xFFFFEEF2)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: disabled
                                            ? const Color(0xFFE8E8E8)
                                            : selected
                                                ? const Color(0xFFEF0038)
                                                : const Color(0xFFEDEDED),
                                        width: selected ? 1.2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            timeLabel(slot),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: disabled
                                                  ? const Color(0xFFAAAAAA)
                                                  : selected
                                                      ? const Color(0xFFEF0038)
                                                      : const Color(0xFF222222),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 17,
                                          height: 17,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? const Color(0xFFEF0038)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: disabled
                                                  ? const Color(0xFFCCCCCC)
                                                  : selected
                                                      ? const Color(0xFFEF0038)
                                                      : const Color(0xFF777777),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: selected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 11,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // CONFIRM AREA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFEDEDED)),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (selectedTime != null) ...[
                            Text.rich(
                              TextSpan(
                                text: 'Valet reserved for ',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF777777),
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${dateLabel(selectedDate)}, ${selectedDate.day} ${_monthName(selectedDate.month)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const TextSpan(text: ' at '),
                                  TextSpan(
                                    text: timeLabel(selectedTime!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: selectedTime == null
                                  ? null
                                  : () {
                                      final scheduled = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime!.hour,
                                        selectedTime!.minute,
                                      );
                                      Navigator.pop(
                                        sheetContext,
                                        scheduled,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFEF0038),
                                disabledBackgroundColor:
                                    const Color(0xFFE4E4E4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text(
                                'Confirm Schedule',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
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
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _scheduledDateTime = result;
    });

    // Open the dedicated scheduled-booking confirmation page.
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScheduledScreen(
          bookingId: _generateSixDigitBookingId(),
          valetName: valet.name.trim().isEmpty
              ? 'QuickPark Valet'
              : valet.name,
          destinationName: widget.destinationName.trim().isEmpty
              ? 'UB City Mall Valet'
              : widget.destinationName,
          scheduledDateTime: result,
          price: _selectedPricingTier == 0
              ? 90
              : _selectedPricingTier == 1
                  ? 120
                  : 150,
          duration: _selectedPricingTier == 0
              ? '2 hrs'
              : _selectedPricingTier == 1
                  ? '4 hrs'
                  : 'Full Day',
        ),
      ),
    );
  }

  String _generateSixDigitBookingId() {
    final value =
        DateTime.now().millisecondsSinceEpoch % 1000000;

    return value.toString().padLeft(6, '0');
  }

  // ============================================================
  // SCHEDULE HELPERS
  // ============================================================

  String _monthName(int month) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _formatScheduledDate(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '${dateTime.day} ${_monthName(dateTime.month)} at $hour:$minute $period';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),

        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(
          16,
        ),

        backgroundColor:
            const Color(
          0xFF302D33,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,

              size: 55,

              color:
                  Color(0xFFAAAAAA),
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              _error!,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 19,
                color:
                    Color(0xFF666666),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              height: 44,

              child:
                  ElevatedButton(
                onPressed:
                    _loadValets,

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFEF0038,
                  ),

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                child:
                    const Text(
                  'Try again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons
                .local_parking_outlined,

            size: 55,

            color:
                Color(0xFFAAAAAA),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'No valets available',

            style:
                TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF444444),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'No valet locations are available\n'
            'near ${widget.destinationName}.',

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 16,
              color:
                  Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _displayValetName(
    Valet valet,
  ) {
    if (valet.name
        .trim()
        .isEmpty) {
      return 'UB City Mall Valet';
    }

    return valet.name;
  }
}

// ==================================================================
// HEADER BUTTON
// ==================================================================

class _HeaderButton
    extends StatelessWidget {
  final IconData icon;

  final Color iconColor;

  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,

    this.iconColor =
        const Color(0xFF333333),

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 38,
        height: 38,

        decoration:
            const BoxDecoration(
          color:
              Color(0xFFF5F5F6),

          shape:
              BoxShape.circle,
        ),

        child:
            Icon(
          icon,

          size: 18,

          color:
              iconColor,
        ),
      ),
    );
  }
}

// ==================================================================
// PRICING CARD
// ==================================================================

class _PricingCard
    extends StatelessWidget {
  final String title;

  final String price;

  final bool selected;

  final VoidCallback onTap;

  const _PricingCard({
    required this.title,

    required this.price,

    required this.selected,

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),

        height: 53,

        decoration:
            BoxDecoration(
          color:
              selected
                  ? const Color(
                      0xFFFFF1F4,
                    )
                  : const Color(
                      0xFFF4F4F6,
                    ),

          borderRadius:
              BorderRadius.circular(
            10,
          ),

          border:
              Border.all(
            color:
                selected
                    ? const Color(
                        0xFFEF0038,
                      )
                    : Colors.transparent,

            width: 1.2,
          ),
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [
            Text(
              title,

              style:
                  TextStyle(
                fontSize: 13,

                color:
                    selected
                        ? const Color(
                            0xFFEF0038,
                          )
                        : const Color(
                            0xFF777777,
                          ),
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              price,

              style:
                  TextStyle(
                fontSize: 20,

                fontWeight:
                    FontWeight.w800,

                color:
                    selected
                        ? const Color(
                            0xFFEF0038,
                          )
                        : const Color(
                            0xFF333333,
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
// STAFF CARD
// ==================================================================

class _StaffCard
    extends StatelessWidget {
  final String name;

  final String rating;

  final String imageUrl;

  const _StaffCard({
    required this.name,

    required this.rating,

    required this.imageUrl,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 45,

      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF5F5F6,
        ),

        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),

      child: Row(
        children: [
          ClipOval(
            child:
                Image.network(
              imageUrl,

              width: 29,
              height: 29,

              fit: BoxFit.cover,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  width: 29,
                  height: 29,

                  color:
                      const Color(
                    0xFFD4D4D4,
                  ),

                  child:
                      const Icon(
                    Icons.person,

                    size: 18,

                    color:
                        Color(
                      0xFF777777,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  name,

                  style:
                      const TextStyle(
                    fontSize: 14.5,

                    fontWeight:
                        FontWeight.w700,

                    color:
                        Color(
                      0xFF303030,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 1,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.star,

                      size: 10,

                      color:
                          Color(
                        0xFFFFB000,
                      ),
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Text(
                      rating,

                      style:
                          const TextStyle(
                        fontSize: 12.5,

                        color:
                            Color(
                          0xFF777777,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 7,
              vertical: 4,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF8F0,
              ),

              borderRadius:
                  BorderRadius.circular(
                6,
              ),
            ),

            child:
                const Text(
              'Verified',

              style:
                  TextStyle(
                fontSize: 11.5,

                fontWeight:
                    FontWeight.w700,

                color:
                    Color(
                  0xFF218A55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// BOTTOM NAV ITEM
// ==================================================================

class _BottomNavItem
    extends StatelessWidget {
  final IconData icon;

  final IconData activeIcon;

  final String label;

  final bool selected;

  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,

    required this.activeIcon,

    required this.label,

    required this.selected,

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      behavior:
          HitTestBehavior.opaque,

      child: SizedBox(
        width: 65,

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [
            Icon(
              selected
                  ? activeIcon
                  : icon,

              size: 20,

              color:
                  selected
                      ? const Color(
                          0xFFEF0038,
                        )
                      : const Color(
                          0xFF777777,
                        ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              label,

              style:
                  TextStyle(
                fontSize: 12.5,

                fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight.w400,

                color:
                    selected
                        ? const Color(
                            0xFFEF0038,
                          )
                        : const Color(
                            0xFF777777,
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
// VALET MODEL
// ==================================================================

class Valet {
  final int id;

  final String name;

  final String rating;

  final String distance;

  final String eta;

  final String price;

  final String slots;

  const Valet({
    required this.id,

    required this.name,

    required this.rating,

    required this.distance,

    required this.eta,

    required this.price,

    required this.slots,
  });

  factory Valet.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawId =
        json['id'];

    final int parsedId =
        rawId is int
            ? rawId
            : int.tryParse(
                  rawId.toString(),
                ) ??
                0;

    return Valet(
      id: parsedId,

      name:
          json['name']
                  ?.toString() ??
              'QuickPark Valet',

      rating:
          json['rating']
                  ?.toString() ??
              '0.0',

      distance:
          _formatDistance(
        json['distance_km'],
      ),

      eta:
          _formatEta(
        json[
          'estimated_arrival_minutes'
        ],
      ),

      price:
          _formatPrice(
        json['starting_price'],
      ),

      slots:
          '${json['available_spots'] ?? 0} spots available',
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  static String _formatDistance(
    dynamic value,
  ) {
    final double? km =
        double.tryParse(
      value?.toString() ?? '',
    );

    if (km == null) {
      return 'Distance unavailable';
    }

    final int meters =
        (km * 1000).round();

    return '$meters m from entrance';
  }

  // ============================================================
  // ETA
  // ============================================================

  static String _formatEta(
    dynamic value,
  ) {
    final int? minutes =
        int.tryParse(
      value?.toString() ?? '',
    );

    if (minutes == null) {
      return 'ETA unavailable';
    }

    return 'Ready in ~$minutes min';
  }

  // ============================================================
  // PRICE
  // ============================================================

  static String _formatPrice(
    dynamic value,
  ) {
    final double? parsedPrice =
        double.tryParse(
      value?.toString() ?? '',
    );

    if (parsedPrice == null) {
      return '₹0';
    }

    if (parsedPrice ==
        parsedPrice.roundToDouble()) {
      return '₹${parsedPrice.toInt()}';
    }

    return '₹$parsedPrice';
  }
}