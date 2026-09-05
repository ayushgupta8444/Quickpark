import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../valet/valet_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/my_bookings_screen.dart';

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
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search destination',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (
        BuildContext dialogContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final double topInset = MediaQuery.of(dialogContext).padding.top;

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Transparent background. Tapping outside closes search.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const SizedBox.expand(),
                ),
              ),

              // Search panel stays at the TOP.
              Positioned(
                top: topInset + 8,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: const Color(0x26000000),
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search destination',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF181818),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              autofocus: true,
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  setState(() {
                                    _currentLocation = value.trim();
                                  });
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFFEF0038),
                                ),
                                hintText: 'Enter destination',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF777777),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF181818),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          _SearchSuggestion(
                            icon: Icons.my_location,
                            title: 'Use current location',
                            subtitle: 'Find valet parking near you',
                            onTap: () {
                              setState(() {
                                _currentLocation = 'Current location';
                              });
                              Navigator.of(dialogContext).pop();
                            },
                          ),

                          const SizedBox(height: 6),

                          _SearchSuggestion(
                            icon: Icons.location_on_outlined,
                            title: 'Koramangala 80 Feet Road',
                            subtitle: 'Bengaluru',
                            onTap: () {
                              setState(() {
                                _currentLocation =
                                    'Koramangala 80 Feet Road';
                              });
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
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
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MyBookingsScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      _openProfile();
      return;
    }

    setState(() {
      _selectedBottomIndex = index;
    });

    if (index == 2) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Alerts will be available soon.',
            style: TextStyle(fontSize: 14),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ======================================================
            // SEARCH BAR
            // ======================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                43,
                14,
                43,
                8,
              ),
              child: GestureDetector(
                onTap: _openSearch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 47,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.search,
                        size: 24,
                        color: Color(0xFFEF0038),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openFilters,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Icon(
                            Icons.tune,
                            size: 21,
                            color: Color(0xFF333333),
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
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CityMapPainter(),
                    ),
                  ),

                  ..._valetLocations.map(
                    (valet) {
                      return Positioned(
                        left: MediaQuery.sizeOf(context).width *
                                valet.mapX -
                            25,
                        top: MediaQuery.sizeOf(context).height *
                                0.49 *
                                valet.mapY -
                            40,
                        child: _MapPriceMarker(
                          price: valet.price,
                          color: valet.color,
                          onTap: () => _selectValet(valet),
                        ),
                      );
                    },
                  ),

                  Positioned(
                    right: 18,
                    bottom: 205,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentLocation =
                              'Current location';
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 9,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          size: 21,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // LARGE VALET CARDS
                  // ==================================================

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: SizedBox(
                      height: 158,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 43,
                        ),
                        itemCount: _valetLocations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final valet =
                              _valetLocations[index];

                          return _ValetCard(
                            valet: valet,
                            onSelect: () => _selectValet(valet),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE9E9EA),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    selected:
                        _selectedBottomIndex == 0,
                    onTap: () =>
                        _onBottomNavigationTap(0),
                  ),
                  _BottomNavItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Bookings',
                    selected:
                        _selectedBottomIndex == 1,
                    onTap: () =>
                        _onBottomNavigationTap(1),
                  ),
                  _BottomNavItem(
                    icon: Icons.notifications_none_outlined,
                    activeIcon: Icons.notifications,
                    label: 'Alerts',
                    selected:
                        _selectedBottomIndex == 2,
                    onTap: () =>
                        _onBottomNavigationTap(2),
                  ),
                  _BottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    selected:
                        _selectedBottomIndex == 3,
                    onTap: () =>
                        _onBottomNavigationTap(3),
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
              horizontal: 10,
              vertical: 6,
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
                fontSize: 12,
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
      width: 285,
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        18,
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  valet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF252525),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.star,
                size: 17,
                color: Color(0xFFE6A900),
              ),
              const SizedBox(width: 3),
              Text(
                valet.rating,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            valet.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),

          const Spacer(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valet.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF0038),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '/ 2 hrs',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSelect,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF0038),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            valet.distance,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
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
        width: 76,

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
                fontSize: 11,

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
    final Paint background = Paint()
      ..color = const Color(0xFFF1F2F2);

    canvas.drawRect(
      Offset.zero & size,
      background,
    );

    // Subtle water / river on the right.
    final Paint water = Paint()
      ..color = const Color(0xFFE1E8E9)
      ..style = PaintingStyle.fill;

    final Path river = Path()
      ..moveTo(size.width * 0.82, 0)
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.18,
        size.width * 0.88,
        size.height * 0.30,
        size.width * 0.75,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.62,
        size.width * 0.86,
        size.height * 0.77,
        size.width * 0.79,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(river, water);

    // City blocks.
    final math.Random random = math.Random(31);
    final Paint blockPaint = Paint()
      ..color = const Color(0xFFD7D9DA)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 115; i++) {
      final double w = 7 + random.nextDouble() * 18;
      final double h = 5 + random.nextDouble() * 14;

      final double x =
          random.nextDouble() * (size.width * 0.76 - w);
      final double y =
          random.nextDouble() * (size.height - h);

      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        blockPaint,
      );
    }

    // Organic city roads.
    final Paint road = Paint()
      ..color = const Color(0xFFC6C9CA)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint mainRoad = Paint()
      ..color = const Color(0xFFB9BDBE)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Vertical curved streets.
    for (int i = 0; i < 8; i++) {
      final double x =
          size.width * (0.10 + i * 0.085);

      final Path path = Path()
        ..moveTo(x, size.height)
        ..cubicTo(
          x - 12,
          size.height * 0.74,
          x + 18,
          size.height * 0.42,
          x + 3,
          0,
        );

      canvas.drawPath(path, road);
    }

    // Horizontal streets.
    for (int i = 0; i < 9; i++) {
      final double y =
          size.height * (0.08 + i * 0.10);

      final Path path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.27,
          y - 13,
          size.width * 0.58,
          y + 16,
          size.width,
          y - 4,
        );

      canvas.drawPath(path, road);
    }

    // Main diagonal roads like the reference.
    final Path diagonalA = Path()
      ..moveTo(size.width * 0.04, size.height * 0.86)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.63,
        size.width * 0.46,
        size.height * 0.40,
        size.width * 0.73,
        size.height * 0.08,
      );

    final Path diagonalB = Path()
      ..moveTo(size.width * 0.00, size.height * 0.22)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.35,
        size.width * 0.52,
        size.height * 0.63,
        size.width * 0.78,
        size.height * 0.87,
      );

    canvas.drawPath(diagonalA, mainRoad);
    canvas.drawPath(diagonalB, mainRoad);

    // Central city network.
    final Offset center = Offset(
      size.width * 0.47,
      size.height * 0.50,
    );

    final Paint ringPaint = Paint()
      ..color = const Color(0xFFD0D3D4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        i *
            math.min(size.width, size.height) *
            0.075,
        ringPaint,
      );
    }

    final Paint radialPaint = Paint()
      ..color = const Color(0xFFD0D3D4)
      ..strokeWidth = 0.75;

    for (int i = 0; i < 20; i++) {
      final double angle =
          i * math.pi / 10;

      final double radius =
          math.min(size.width, size.height) * 0.31;

      canvas.drawLine(
        Offset(
          center.dx +
              math.cos(angle) * 20,
          center.dy +
              math.sin(angle) * 20,
        ),
        Offset(
          center.dx +
              math.cos(angle) * radius,
          center.dy +
              math.sin(angle) * radius,
        ),
        radialPaint,
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