import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../valet/valet_selection_screen.dart';
import '../profile/profile_screen.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() =>
      _DestinationScreenState();
}

class _DestinationScreenState
    extends State<DestinationScreen> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  int _selectedBottomIndex = 0;

  String _currentLocation =
      'Koramangala 80 Feet Road';

  // ============================================================
  // VALET LOCATIONS
  // ============================================================

  final List<ValetLocation> _valetLocations = [
    const ValetLocation(
      name: 'UB City Mall Valet',
      address: 'Vittal Mallya Road, Lavelle Road',
      price: '₹90',
      distance: '1.2 km',
      rating: '4.8',
      color: Color(0xFFEF0038),
      mapX: 0.52,
      mapY: 0.28,
    ),
    const ValetLocation(
      name: 'Phoenix Marketcity',
      address: 'Mahadevapura, Bengaluru',
      price: '₹120',
      distance: '8.5 km',
      rating: '4.6',
      color: Color(0xFF222222),
      mapX: 0.76,
      mapY: 0.47,
    ),
    const ValetLocation(
      name: 'Forum Mall Valet',
      address: 'Koramangala, Bengaluru',
      price: '₹60',
      distance: '3.4 km',
      rating: '4.7',
      color: Color(0xFF222222),
      mapX: 0.26,
      mapY: 0.66,
    ),
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECT VALET
  // ============================================================

  void _selectValet(
    ValetLocation valet,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ValetSelectionScreen(
          destinationName: valet.name,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // SEARCH LOCATION
  // ============================================================

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D7D7),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Search destination',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181818),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F6),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: TextField(
                  autofocus: true,
                  controller: _searchController,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        _currentLocation =
                            value.trim();
                      });

                      Navigator.pop(context);
                    }
                  },
                  decoration:
                      const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFFEF0038),
                    ),
                    hintText:
                        'Enter destination',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _SearchSuggestion(
                icon: Icons.my_location,
                title: 'Use current location',
                subtitle:
                    'Find valet parking near you',
                onTap: () {
                  setState(() {
                    _currentLocation =
                        'Current location';
                  });

                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 8),

              _SearchSuggestion(
                icon: Icons.location_on_outlined,
                title: 'Koramangala 80 Feet Road',
                subtitle: 'Bengaluru',
                onTap: () {
                  setState(() {
                    _currentLocation =
                        'Koramangala 80 Feet Road';
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            26,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D7D7),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Filter parking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              const _FilterOption(
                icon: Icons.currency_rupee,
                title: 'Price',
                subtitle:
                    'Show affordable parking first',
              ),

              const _FilterOption(
                icon: Icons.near_me_outlined,
                title: 'Distance',
                subtitle:
                    'Show nearest valet locations',
              ),

              const _FilterOption(
                icon: Icons.star_outline,
                title: 'Rating',
                subtitle:
                    'Show highest rated valets',
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style:
                      ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        const Color(0xFFEF0038),
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(
    int index,
  ) {
    if (index == 3) {
      _openProfile();
      return;
    }

    setState(() {
      _selectedBottomIndex = index;
    });

    if (index == 1) {
      _showComingSoon('Bookings');
    }

    if (index == 2) {
      _showComingSoon('Alerts');
    }
  }

  void _showComingSoon(
    String pageName,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$pageName will be available soon.',
        ),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
      ),
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
          const Color(0xFFF4F4F5),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ======================================================
            // TOP SEARCH
            // ======================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                10,
              ),

              child: GestureDetector(
                onTap: _openSearch,

                child: Container(
                  height: 46,

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color:
                            Color(0x12000000),
                        blurRadius: 10,
                        offset:
                            Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                      ),

                      const Icon(
                        Icons.search,
                        size: 21,
                        color:
                            Color(0xFFEF0038),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          _currentLocation,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            color:
                                Color(0xFF555555),
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap:
                            _openFilters,

                        child:
                            const Padding(
                          padding:
                              EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                          ),
                          child: Icon(
                            Icons
                                .tune_outlined,
                            size: 19,
                            color:
                                Color(
                              0xFF333333,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ======================================================
            // MAP
            // ======================================================

            Expanded(
              child: Stack(
                children: [
                  // MAP BACKGROUND

                  Positioned.fill(
                    child: CustomPaint(
                      painter:
                          _CityMapPainter(),
                    ),
                  ),

                  // ==================================================
                  // PRICE MARKERS
                  // ==================================================

                  ..._valetLocations.map(
                    (valet) {
                      return Positioned(
                        left:
                            MediaQuery.of(
                                      context,
                                    )
                                    .size
                                    .width *
                                valet.mapX -
                            25,

                        top:
                            MediaQuery.of(
                                      context,
                                    )
                                    .size
                                    .height *
                                valet.mapY -
                            40,

                        child:
                            _MapPriceMarker(
                          price:
                              valet.price,
                          color:
                              valet.color,
                          onTap: () {
                            _selectValet(
                              valet,
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // CURRENT LOCATION
                  // ==================================================

                  Positioned(
                    right: 18,
                    bottom: 210,

                    child:
                        GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentLocation =
                              'Current location';
                        });
                      },

                      child:
                          Container(
                        width: 42,
                        height: 42,

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          shape:
                              BoxShape.circle,

                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Color(
                                0x18000000,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),

                        child:
                            const Icon(
                          Icons
                              .my_location,
                          size: 20,
                          color:
                              Color(
                            0xFF444444,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // VALET CARDS
                  // ==================================================

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,

                    child:
                        SizedBox(
                      height: 132,

                      child:
                          ListView.separated(
                        scrollDirection:
                            Axis.horizontal,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                        ),

                        itemCount:
                            _valetLocations
                                .length,

                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                          width: 10,
                        ),

                        itemBuilder:
                            (context, index) {
                          final valet =
                              _valetLocations[
                                  index];

                          return
                              _ValetCard(
                            valet: valet,

                            onSelect: () {
                              _selectValet(
                                valet,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // BOTTOM NAVIGATION
            // ======================================================

            Container(
              height: 78,

              decoration:
                  const BoxDecoration(
                color: Colors.white,

                border: Border(
                  top: BorderSide(
                    color:
                        Color(0xFFE8E8E8),
                    width: 1,
                  ),
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceAround,

                children: [
                  _BottomNavItem(
                    icon:
                        Icons.home_outlined,
                    activeIcon:
                        Icons.home_rounded,
                    label: 'Home',
                    selected:
                        _selectedBottomIndex ==
                            0,
                    onTap: () {
                      _onBottomNavigationTap(
                        0,
                      );
                    },
                  ),

                  _BottomNavItem(
                    icon:
                        Icons
                            .calendar_today_outlined,
                    activeIcon:
                        Icons
                            .calendar_today,
                    label: 'Bookings',
                    selected:
                        _selectedBottomIndex ==
                            1,
                    onTap: () {
                      _onBottomNavigationTap(
                        1,
                      );
                    },
                  ),

                  _BottomNavItem(
                    icon:
                        Icons
                            .notifications_none_outlined,
                    activeIcon:
                        Icons
                            .notifications,
                    label: 'Alerts',
                    selected:
                        _selectedBottomIndex ==
                            2,
                    onTap: () {
                      _onBottomNavigationTap(
                        2,
                      );
                    },
                  ),

                  _BottomNavItem(
                    icon:
                        Icons
                            .person_outline,
                    activeIcon:
                        Icons.person,
                    label: 'Profile',
                    selected:
                        _selectedBottomIndex ==
                            3,
                    onTap: () {
                      _onBottomNavigationTap(
                        3,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// VALET LOCATION MODEL
// ==================================================================

class ValetLocation {
  final String name;
  final String address;
  final String price;
  final String distance;
  final String rating;
  final Color color;
  final double mapX;
  final double mapY;

  const ValetLocation({
    required this.name,
    required this.address,
    required this.price,
    required this.distance,
    required this.rating,
    required this.color,
    required this.mapX,
    required this.mapY,
  });
}

// ==================================================================
// MAP PRICE MARKER
// ==================================================================

class _MapPriceMarker extends StatelessWidget {
  final String price;
  final Color color;
  final VoidCallback onTap;

  const _MapPriceMarker({
    required this.price,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),

            decoration:
                BoxDecoration(
              color: color,

              borderRadius:
                  BorderRadius.circular(
                7,
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

            child: Text(
              price,

              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          CustomPaint(
            size:
                const Size(18, 23),

            painter:
                _PinPainter(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// PIN PAINTER
// ==================================================================

class _PinPainter
    extends CustomPainter {
  final Color color;

  const _PinPainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final Path path =
        Path();

    path.moveTo(
      size.width / 2,
      size.height,
    );

    path.cubicTo(
      size.width * 0.30,
      size.height * 0.68,
      0,
      size.height * 0.48,
      0,
      size.height * 0.30,
    );

    path.cubicTo(
      0,
      size.height * 0.10,
      size.width * 0.22,
      0,
      size.width / 2,
      0,
    );

    path.cubicTo(
      size.width * 0.78,
      0,
      size.width,
      size.height * 0.10,
      size.width,
      size.height * 0.30,
    );

    path.cubicTo(
      size.width,
      size.height * 0.48,
      size.width * 0.70,
      size.height * 0.68,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(
      path,
      paint,
    );

    final Paint innerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width / 2,
        size.height * 0.29,
      ),
      3,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PinPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}

// ==================================================================
// VALET CARD
// ==================================================================

class _ValetCard
    extends StatelessWidget {
  final ValetLocation valet;
  final VoidCallback onSelect;

  const _ValetCard({
    required this.valet,
    required this.onSelect,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 205,

      padding:
          const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        9,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x18000000),
            blurRadius: 12,
            offset:
                Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ========================================================
          // TITLE + RATING
          // ========================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  valet.name,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF252525),
                  ),
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              const Icon(
                Icons.star,
                size: 13,
                color:
                    Color(0xFFE6A900),
              ),

              const SizedBox(
                width: 2,
              ),

              Text(
                valet.rating,

                style:
                    const TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF333333),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 4,
          ),

          // ========================================================
          // ADDRESS
          // ========================================================

          Text(
            valet.address,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 9.5,
              color:
                  Color(0xFF888888),
            ),
          ),

          const Spacer(),

          // ========================================================
          // PRICE + DISTANCE + SELECT
          // ========================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Row(
                    children: [
                      Text(
                        valet.price,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(
                            0xFFEF0038,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      const Text(
                        '/ 2 hrs',

                        style:
                            TextStyle(
                          fontSize: 9,
                          color:
                              Color(
                            0xFF777777,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    valet.distance,

                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          Color(0xFF888888),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              GestureDetector(
                onTap: onSelect,

                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFFFE9EE,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      7,
                    ),
                  ),

                  child:
                      const Text(
                    'Select',

                    style:
                        TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(
                        0xFFEF0038,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
        width: 70,

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              selected
                  ? activeIcon
                  : icon,

              size: 22,

              color: selected
                  ? const Color(
                      0xFFEF0038,
                    )
                  : const Color(
                      0xFF777777,
                    ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              label,

              style:
                  TextStyle(
                fontSize: 9,

                fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight.w400,

                color: selected
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
// SEARCH SUGGESTION
// ==================================================================

class _SearchSuggestion
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 8,
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

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

              child: Icon(
                icon,
                size: 20,
                color:
                    const Color(
                  0xFF444444,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color:
                  Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// FILTER OPTION
// ==================================================================

class _FilterOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 17,
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

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

            child: Icon(
              icon,
              size: 20,
              color:
                  const Color(
                0xFF444444,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,

                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right,
            color:
                Color(0xFF999999),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// CITY MAP PAINTER
// ==================================================================

class _CityMapPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ------------------------------------------------------------
    // BACKGROUND
    // ------------------------------------------------------------

    final Paint backgroundPaint =
        Paint()
          ..color =
              const Color(0xFFF1F2F2);

    canvas.drawRect(
      Offset.zero &
          size,
      backgroundPaint,
    );

    // ------------------------------------------------------------
    // CITY BLOCKS
    // ------------------------------------------------------------

    final Paint blockPaint =
        Paint()
          ..color =
              const Color(0xFFD8DADB)
          ..style =
              PaintingStyle.fill;

    final math.Random random =
        math.Random(14);

    final List<Rect> blocks = [];

    for (int i = 0; i < 85; i++) {
      final double width =
          8 + random.nextDouble() * 22;

      final double height =
          5 + random.nextDouble() * 18;

      final double left =
          random.nextDouble() *
              (size.width - width);

      final double top =
          random.nextDouble() *
              (size.height - height);

      final Rect rect =
          Rect.fromLTWH(
        left,
        top,
        width,
        height,
      );

      blocks.add(rect);
    }

    for (final Rect block in blocks) {
      canvas.drawRect(
        block,
        blockPaint,
      );
    }

    // ------------------------------------------------------------
    // RIVER
    // ------------------------------------------------------------

    final Paint riverPaint =
        Paint()
          ..color =
              const Color(0xFFDCE4E5)
          ..style =
              PaintingStyle.fill;

    final Path river =
        Path();

    river.moveTo(
      size.width * 0.82,
      0,
    );

    river.cubicTo(
      size.width * 0.72,
      size.height * 0.15,
      size.width * 0.92,
      size.height * 0.25,
      size.width * 0.78,
      size.height * 0.40,
    );

    river.cubicTo(
      size.width * 0.65,
      size.height * 0.55,
      size.width * 0.92,
      size.height * 0.66,
      size.width * 0.80,
      size.height * 0.82,
    );

    river.cubicTo(
      size.width * 0.74,
      size.height * 0.91,
      size.width * 0.88,
      size.height * 0.96,
      size.width * 0.92,
      size.height,
    );

    river.lineTo(
      size.width,
      size.height,
    );

    river.lineTo(
      size.width,
      0,
    );

    river.close();

    canvas.drawPath(
      river,
      riverPaint,
    );

    // ------------------------------------------------------------
    // ROADS
    // ------------------------------------------------------------

    final Paint roadPaint =
        Paint()
          ..color =
              const Color(0xFFBFC2C3)
          ..strokeWidth = 1.4
          ..style =
              PaintingStyle.stroke;

    final Paint mainRoadPaint =
        Paint()
          ..color =
              const Color(0xFFB2B5B6)
          ..strokeWidth = 2.5
          ..style =
              PaintingStyle.stroke;

    // Vertical roads

    for (int i = 0; i < 10; i++) {
      final double x =
          size.width *
              (0.10 + i * 0.08);

      final Path path =
          Path();

      path.moveTo(
        x,
        size.height,
      );

      path.cubicTo(
        x - 15,
        size.height * 0.70,
        x + 22,
        size.height * 0.45,
        x + 3,
        0,
      );

      canvas.drawPath(
        path,
        roadPaint,
      );
    }

    // Horizontal roads

    for (int i = 0; i < 9; i++) {
      final double y =
          size.height *
              (0.10 + i * 0.09);

      final Path path =
          Path();

      path.moveTo(
        0,
        y,
      );

      path.cubicTo(
        size.width * 0.30,
        y - 15,
        size.width * 0.60,
        y + 20,
        size.width,
        y - 3,
      );

      canvas.drawPath(
        path,
        roadPaint,
      );
    }

    // ------------------------------------------------------------
    // MAIN DIAGONAL ROADS
    // ------------------------------------------------------------

    final Path diagonal1 =
        Path();

    diagonal1.moveTo(
      size.width * 0.05,
      size.height * 0.82,
    );

    diagonal1.cubicTo(
      size.width * 0.28,
      size.height * 0.62,
      size.width * 0.46,
      size.height * 0.42,
      size.width * 0.75,
      size.height * 0.10,
    );

    canvas.drawPath(
      diagonal1,
      mainRoadPaint,
    );

    final Path diagonal2 =
        Path();

    diagonal2.moveTo(
      size.width * 0.02,
      size.height * 0.20,
    );

    diagonal2.cubicTo(
      size.width * 0.32,
      size.height * 0.34,
      size.width * 0.58,
      size.height * 0.65,
      size.width * 0.84,
      size.height * 0.85,
    );

    canvas.drawPath(
      diagonal2,
      mainRoadPaint,
    );

    // ------------------------------------------------------------
    // CENTRAL CIRCLE / CITY
    // ------------------------------------------------------------

    final Offset center =
        Offset(
      size.width * 0.46,
      size.height * 0.48,
    );

    final Paint circlePaint =
        Paint()
          ..color =
              const Color(0xFFD1D3D4)
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1.1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        i *
            math.min(
              size.width,
              size.height,
            ) *
            0.075,
        circlePaint,
      );
    }

    // ------------------------------------------------------------
    // SMALL STREET LINES
    // ------------------------------------------------------------

    final Paint streetPaint =
        Paint()
          ..color =
              const Color(0xFFC7C9CA)
          ..strokeWidth = 0.7;

    for (int i = 0; i < 22; i++) {
      final double angle =
          i *
              math.pi /
              11;

      final double startRadius =
          math.min(
                size.width,
                size.height,
              ) *
              0.07;

      final double endRadius =
          math.min(
                size.width,
                size.height,
              ) *
              0.30;

      final Offset start =
          Offset(
        center.dx +
            math.cos(angle) *
                startRadius,
        center.dy +
            math.sin(angle) *
                startRadius,
      );

      final Offset end =
          Offset(
        center.dx +
            math.cos(angle) *
                endRadius,
        center.dy +
            math.sin(angle) *
                endRadius,
      );

      canvas.drawLine(
        start,
        end,
        streetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _CityMapPainter oldDelegate,
  ) {
    return false;
  }
}