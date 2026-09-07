import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:flutter/material.dart';

import '../valet/valet_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../alerts/alerts_screen.dart';


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
  // REAL MAP + VALET LOCATIONS
  // ============================================================

  final MapController _mapController = MapController();

  final List<ValetLocation> _valetLocations = [];

  bool _isLoadingValets = true;
  String? _valetLoadError;

  String get _baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://127.0.0.1:3000';
  }

  @override
  void initState() {
    super.initState();
    _loadValets();
  }

  Future<void> _loadValets() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/valets'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['valets'] is! List) {
        throw Exception('Invalid valet API response');
      }

      final List<dynamic> apiValets =
          decoded['valets'] as List<dynamic>;

      final List<ValetLocation> loadedValets = [];

      for (int index = 0; index < apiValets.length; index++) {
        final item = apiValets[index];

        if (item is! Map) continue;

        final latitude = double.tryParse(
          item['latitude']?.toString() ?? '',
        );
        final longitude = double.tryParse(
          item['longitude']?.toString() ?? '',
        );

        if (latitude == null || longitude == null) continue;
        if (latitude < -90 || latitude > 90) continue;
        if (longitude < -180 || longitude > 180) continue;

        loadedValets.add(
          ValetLocation.fromApi(
            Map<String, dynamic>.from(item),
            color: index == 0
                ? const Color(0xFFEF0038)
                : const Color(0xFF222222),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _valetLocations
          ..clear()
          ..addAll(loadedValets);
        _isLoadingValets = false;
        _valetLoadError = null;
      });

      if (loadedValets.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final first = loadedValets.first;
          _mapController.move(
            LatLng(first.latitude, first.longitude),
            15.5,
          );
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingValets = false;
        _valetLoadError = error.toString();
      });
    }
  }

  void _animateMapTo(
    LatLng target, {
    double zoom = 16,
  }) {
    final start = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    const duration = Duration(milliseconds: 650);
    final stopwatch = Stopwatch()..start();

    Timer? timer;
    timer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (!mounted) {
          timer?.cancel();
          return;
        }
        final progress =
            (stopwatch.elapsedMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0);
        final eased = Curves.easeInOutCubic.transform(progress);

        final lat = start.latitude +
            (target.latitude - start.latitude) * eased;
        final lng = start.longitude +
            (target.longitude - start.longitude) * eased;
        final nextZoom =
            startZoom + (zoom - startZoom) * eased;

        _mapController.move(
          LatLng(lat, lng),
          nextZoom,
        );

        if (progress >= 1.0) {
          timer?.cancel();
          stopwatch.stop();
        }
      },
    );
  }

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertsScreen(),
        ),
      );
      return;
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
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(
                          12.9716,
                          77.5946,
                        ),
                        initialZoom: 14,
                        minZoom: 10,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.quickpark',
                          maxZoom: 19,
                        ),

                        MarkerLayer(
                          markers: _valetLocations.map((valet) {
                            return Marker(
                              point: LatLng(
                                valet.latitude,
                                valet.longitude,
                              ),
                              width: 90,
                              height: 72,
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey('marker-${valet.id}'),
                                tween: Tween<double>(
                                  begin: 0.55,
                                  end: 1.0,
                                ),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: _MapPriceMarker(
                                  price: valet.price,
                                  color: valet.color,
                                  onTap: () {
                                    _animateMapTo(
                                      LatLng(
                                        valet.latitude,
                                        valet.longitude,
                                      ),
                                      zoom: 16,
                                    );
                                    _selectValet(valet);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_isLoadingValets)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                  if (_valetLoadError != null && !_isLoadingValets)
                    Positioned(
                      top: 16,
                      left: 43,
                      right: 43,
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Unable to load valet locations',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isLoadingValets = true;
                                    _valetLoadError = null;
                                  });
                                  _loadValets();
                                },
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF0038),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    right: 18,
                    bottom: 205,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentLocation = 'Current location';
                        });

                        if (_valetLocations.isNotEmpty) {
                          final nearest = _valetLocations.first;
                          _animateMapTo(
                            LatLng(
                              nearest.latitude,
                              nearest.longitude,
                            ),
                            zoom: 16,
                          );
                        }
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
                      height: 205,
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
                          final valet = _valetLocations[index];
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
  final int id;
  final String name;
  final String address;
  final String price;
  final String distance;
  final String rating;
  final Color color;
  final double latitude;
  final double longitude;

  const ValetLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.distance,
    required this.rating,
    required this.color,
    required this.latitude,
    required this.longitude,
  });

  factory ValetLocation.fromApi(
    Map<String, dynamic> json, {
    required Color color,
  }) {
    final rawPrice = json['starting_price']?.toString() ?? '0';
    final rawDistance = json['distance_km']?.toString() ?? '0';

    final price = rawPrice.endsWith('.00')
        ? rawPrice.substring(0, rawPrice.length - 3)
        : rawPrice;

    final distance = rawDistance.endsWith('.00')
        ? rawDistance.substring(0, rawDistance.length - 3)
        : rawDistance;

    return ValetLocation(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'QuickPark Valet',
      address: json['address']?.toString() ?? 'Bengaluru',
      price: '₹$price',
      distance: '$distance km',
      rating: json['rating']?.toString() ?? '0.0',
      color: color,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
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
    final ui.Paint paint =
        ui.Paint()
          ..color = color
          ..style = ui.PaintingStyle.fill;

    final ui.Path path =
        ui.Path();

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

    final ui.Paint innerPaint =
        ui.Paint()
          ..color = Colors.white
          ..style = ui.PaintingStyle.fill;

    canvas.drawCircle(
      ui.Offset(
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
      width: 340,
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          // =========================================================
          // DISTANCE + RATING
          // =========================================================
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me,
                    size: 17,
                    color: Color(0xFFEF0038),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    valet.distance,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.star,
                size: 17,
                color: Color(0xFFE6A900),
              ),
              const SizedBox(width: 4),
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

          const SizedBox(height: 9),

          // =========================================================
          // VALET NAME
          // =========================================================
          Text(
            valet.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF252525),
            ),
          ),

          const SizedBox(height: 5),

          // =========================================================
          // ADDRESS
          // =========================================================
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

          // =========================================================
          // PRICE + SELECT
          // =========================================================
          Container(
            height: 58,
            padding: const EdgeInsets.only(
              left: 0,
              right: 0,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF0F0F1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
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
