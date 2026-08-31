import 'package:flutter/material.dart';
import '../booking/booking_details_screen.dart';

class ValetSelectionScreen extends StatelessWidget {
  final String destinationName;

  const ValetSelectionScreen({
    super.key,
    required this.destinationName,
  });

  // ============================================================
  // QUICKPARK VALETS
  // ============================================================

  final List<Valet> valets = const [
    Valet(
      name: 'QuickPark Valet',
      rating: '4.8',
      distance: '120 m from entrance',
      eta: 'Ready in ~3 min',
      price: '₹200',
      slots: '12 spots available',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),

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
                12,
              ),

              child: Row(
                children: [

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Color(0xFF222222),
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Available valets',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 20,
                  ),
                ],
              ),
            ),

            // ==================================================
            // DESTINATION
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),

              child: Row(
                children: [

                  Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EE),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFEF0038),
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

                        const Text(
                          'Your destination',

                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          destinationName,

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // AVAILABLE VALETS
            // ==================================================

            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount: valets.length,

                itemBuilder: (context, index) {
                  final valet = valets[index];

                  return _ValetCard(
                    valet: valet,

                    // ==================================================
                    // SELECT VALET
                    // ==================================================

                    onSelect: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailsScreen(
                            destinationName:
                                destinationName,

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
// VALET CARD
// ================================================================

class _ValetCard extends StatelessWidget {
  final Valet valet;
  final VoidCallback onSelect;

  const _ValetCard({
    required this.valet,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // ==================================================
          // VALET NAME
          // ==================================================

          Row(
            children: [

              Container(
                width: 50,
                height: 50,

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
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      valet.name,

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
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
                            fontSize: 13,
                            color:
                                Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // AVAILABLE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEAF8F0),

                  borderRadius:
                      BorderRadius.circular(8),
                ),

                child: const Text(
                  'AVAILABLE',

                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF1D8A50),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // DISTANCE
          // ==================================================

          Row(
            children: [

              const Icon(
                Icons.directions_walk_outlined,
                size: 19,
                color:
                    Color(0xFF666666),
              ),

              const SizedBox(
                width: 9,
              ),

              Text(
                valet.distance,

                style: const TextStyle(
                  fontSize: 14,
                  color:
                      Color(0xFF555555),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 11,
          ),

          // ==================================================
          // ETA
          // ==================================================

          Row(
            children: [

              const Icon(
                Icons.access_time,
                size: 19,
                color:
                    Color(0xFF666666),
              ),

              const SizedBox(
                width: 9,
              ),

              Text(
                valet.eta,

                style: const TextStyle(
                  fontSize: 14,
                  color:
                      Color(0xFF555555),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 11,
          ),

          // ==================================================
          // PARKING SLOTS
          // ==================================================

          Row(
            children: [

              const Icon(
                Icons.local_parking_outlined,
                size: 19,
                color:
                    Color(0xFF666666),
              ),

              const SizedBox(
                width: 9,
              ),

              Text(
                valet.slots,

                style: const TextStyle(
                  fontSize: 14,
                  color:
                      Color(0xFF555555),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          const Divider(
            height: 1,
            color:
                Color(0xFFEAEAEA),
          ),

          const SizedBox(
            height: 16,
          ),

          // ==================================================
          // PRICE + SELECT BUTTON
          // ==================================================

          Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      valet.price,

                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    const Text(
                      'starting price',

                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 48,

                child: ElevatedButton(
                  onPressed: onSelect,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFEF0038),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Select valet',

                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
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

// ================================================================
// VALET MODEL
// ================================================================

class Valet {
  final String name;
  final String rating;
  final String distance;
  final String eta;
  final String price;
  final String slots;

  const Valet({
    required this.name,
    required this.rating,
    required this.distance,
    required this.eta,
    required this.price,
    required this.slots,
  });
}