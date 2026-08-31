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
  final TextEditingController _searchController =
      TextEditingController();

  final List<Destination> destinations = [
    const Destination(
      name: 'Ferry Building',
      distance: '2.1 mi',
      icon: Icons.access_time,
    ),
    const Destination(
      name: 'Embarcadero Center',
      distance: '1.8 mi',
      icon: Icons.business_center_outlined,
    ),
    const Destination(
      name: 'SFMOMA',
      distance: '0.9 mi',
      icon: Icons.star_border,
    ),
    const Destination(
      name: 'Home',
      distance: '4.6 mi',
      icon: Icons.home_outlined,
    ),
  ];

  // ============================================================
  // FILTER DESTINATIONS
  // ============================================================

  List<Destination> get filteredDestinations {
    final query =
        _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return destinations;
    }

    return destinations.where((destination) {
      return destination.name
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECT DESTINATION
  // ============================================================

  void _selectDestination(
      Destination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ValetSelectionScreen(
          destinationName: destination.name,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                14,
              ),

              child: Row(
                children: [

                  // LEFT SPACE
                  const SizedBox(
                    width: 44,
                  ),

                  // TITLE
                  const Expanded(
                    child: Text(
                      'Choose destination',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),
                  ),

                  // ==================================================
                  // PROFILE BUTTON
                  // ==================================================

                  Material(
                    color: const Color(
                      0xFFF5F5F6,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child: InkWell(
                      onTap: _openProfile,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      child: const SizedBox(
                        width: 44,
                        height: 44,

                        child: Icon(
                          Icons
                              .person_outline,
                          size: 24,
                          color:
                              Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // SEARCH BAR
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Container(
                height: 52,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF5F5F6),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Row(
                  children: [

                    const SizedBox(
                      width: 16,
                    ),

                    const Icon(
                      Icons.search,
                      size: 23,
                      color:
                          Color(0xFF222222),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: TextField(
                        controller:
                            _searchController,

                        onChanged: (_) {
                          setState(() {});
                        },

                        decoration:
                            const InputDecoration(
                          hintText:
                              'Search destination',

                          border:
                              InputBorder.none,

                          hintStyle:
                              TextStyle(
                            fontSize: 16,
                            color:
                                Color(0xFF777777),
                          ),
                        ),

                        style:
                            const TextStyle(
                          fontSize: 16,
                          color:
                              Color(0xFF171717),
                        ),
                      ),
                    ),

                    // ==================================================
                    // CLEAR SEARCH
                    // ==================================================

                    if (_searchController
                        .text
                        .isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController
                              .clear();

                          setState(() {});
                        },

                        child:
                            const Padding(
                          padding:
                              EdgeInsets.only(
                            right: 16,
                          ),

                          child: Icon(
                            Icons.close,
                            size: 20,
                            color:
                                Color(0xFF777777),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 26,
            ),

            // ==================================================
            // SUGGESTED
            // ==================================================

            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'SUGGESTED',

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 0.5,
                    color:
                        Color(0xFF777777),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // DESTINATION LIST
            // ==================================================

            Expanded(
              child:
                  filteredDestinations.isEmpty
                      ? const Center(
                          child: Text(
                            'No destinations found',

                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Color(
                                0xFF777777,
                              ),
                            ),
                          ),
                        )

                      : ListView.builder(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 20,
                          ),

                          itemCount:
                              filteredDestinations
                                  .length,

                          itemBuilder:
                              (context, index) {
                            final destination =
                                filteredDestinations[
                                    index];

                            return _DestinationTile(
                              destination:
                                  destination,

                              onTap: () {
                                _selectDestination(
                                  destination,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DESTINATION TILE
// ================================================================

class _DestinationTile
    extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(14),

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 7,
        ),

        child: Row(
          children: [

            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 48,
              height: 48,

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFF5F5F6),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Icon(
                destination.icon,

                color:
                    const Color(0xFF444444),

                size: 22,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ==================================================
            // DESTINATION NAME
            // ==================================================

            Expanded(
              child: Text(
                destination.name,

                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF222222),
                ),
              ),
            ),

            // ==================================================
            // DISTANCE
            // ==================================================

            Text(
              destination.distance,

              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(0xFF777777),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // ==================================================
            // ARROW
            // ==================================================

            const Icon(
              Icons.chevron_right,
              size: 20,
              color:
                  Color(0xFF777777),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DESTINATION MODEL
// ================================================================

class Destination {
  final String name;
  final String distance;
  final IconData icon;

  const Destination({
    required this.name,
    required this.distance,
    required this.icon,
  });
}