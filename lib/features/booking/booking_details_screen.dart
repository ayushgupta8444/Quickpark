import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_confirmed_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  // ============================================================
  // DESTINATION
  // ============================================================

  final String destinationName;

  // ============================================================
  // VALET
  // ============================================================

  final int valetId;
  final String valetName;
  final String rating;
  final String distance;
  final String eta;
  final String price;
  final String slots;

  const BookingDetailsScreen({
    super.key,

    required this.destinationName,

    required this.valetId,
    required this.valetName,
    required this.rating,
    required this.distance,
    required this.eta,
    required this.price,
    required this.slots,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

// =================================================================
// STATE
// =================================================================

class _BookingDetailsScreenState
    extends State<BookingDetailsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color red =
      Color(0xFFEF0038);

  static const Color black =
      Color(0xFF171717);

  static const Color grey =
      Color(0xFF777777);

  static const Color background =
      Color(0xFFF8F8F9);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  bool _isBooking = false;

  String _name = '';

  String _phone = '';

  List<BookingVehicle> _vehicles = [];

  BookingVehicle? _selectedVehicle;

  String? _vehicleError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserProfileAndVehicles();
  }

  // ============================================================
  // LOAD USER + VEHICLES
  // ============================================================

  Future<void> _loadUserProfileAndVehicles() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _vehicleError =
            'Please login again.';
      });

      return;
    }

    try {
      // ========================================================
      // USER DOCUMENT
      // ========================================================

      final DocumentReference<
              Map<String, dynamic>>
          userRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);

      final DocumentSnapshot<
              Map<String, dynamic>>
          userSnapshot =
          await userRef.get();

      String name =
          user.displayName ?? '';

      String phone =
          user.phoneNumber ?? '';

      final List<BookingVehicle>
          loadedVehicles = [];

      if (userSnapshot.exists) {
        final Map<String, dynamic>?
            data =
            userSnapshot.data();

        name =
            (data?['name'] ??
                    user.displayName ??
                    '')
                .toString()
                .trim();

        phone =
            (data?['phoneNumber'] ??
                    user.phoneNumber ??
                    '')
                .toString()
                .trim();

        // ======================================================
        // FIRST: READ ROOT VEHICLES ARRAY
        // ======================================================

        final dynamic rawVehicles =
            data?['vehicles'];

        if (rawVehicles is List) {
          for (final dynamic item
              in rawVehicles) {
            if (item is! Map) {
              continue;
            }

            final Map<String, dynamic>
                vehicle =
                Map<String, dynamic>.from(
              item,
            );

            final String id =
                (vehicle['id'] ?? '')
                    .toString()
                    .trim();

            final String type =
                (vehicle['type'] ??
                        'Car')
                    .toString()
                    .trim();

            final String model =
                (vehicle['model'] ?? '')
                    .toString()
                    .trim();

            final String number =
                (vehicle['number'] ??
                        '')
                    .toString()
                    .trim()
                    .toUpperCase();

            final String color =
                (vehicle['color'] ??
                        'Dark Gray')
                    .toString()
                    .trim();

            final bool isPrimary =
                vehicle['isPrimary'] ==
                    true;

            if (model.isEmpty ||
                number.isEmpty) {
              continue;
            }

            loadedVehicles.add(
              BookingVehicle(
                id: id.isEmpty
                    ? '${model}_${number}'
                    : id,

                type: type,

                model: model,

                number: number,

                color: color,

                isPrimary:
                    isPrimary,
              ),
            );
          }
        }

        // ======================================================
        // OLD ROOT VEHICLE FALLBACK
        // ======================================================

        if (loadedVehicles.isEmpty) {
          final String oldNumber =
              (data?['carNumber'] ??
                      '')
                  .toString()
                  .trim()
                  .toUpperCase();

          final String oldModel =
              (data?['carModel'] ??
                      '')
                  .toString()
                  .trim();

          if (oldNumber.isNotEmpty &&
              oldModel.isNotEmpty) {
            loadedVehicles.add(
              BookingVehicle(
                id: 'legacy_vehicle',
                type: 'Car',
                model: oldModel,
                number: oldNumber,
                color: 'Dark Gray',
                isPrimary: true,
              ),
            );
          }
        }
      }

      // ========================================================
      // SECOND: TRY VEHICLES SUBCOLLECTION
      //
      // This supports the older structure too.
      //
      // If permission is denied, we DO NOT fail the whole page.
      // Root array / old fields are still usable.
      // ========================================================

      if (loadedVehicles.isEmpty) {
        try {
          final QuerySnapshot<
                  Map<String, dynamic>>
              vehicleSnapshot =
              await userRef
                  .collection('vehicles')
                  .orderBy(
                    'createdAt',
                    descending: false,
                  )
                  .get();

          for (final QueryDocumentSnapshot<
                  Map<String, dynamic>>
              doc
              in vehicleSnapshot.docs) {
            final Map<String, dynamic>
                data =
                doc.data();

            final String model =
                (data['model'] ?? '')
                    .toString()
                    .trim();

            final String number =
                (data['number'] ?? '')
                    .toString()
                    .trim()
                    .toUpperCase();

            if (model.isEmpty ||
                number.isEmpty) {
              continue;
            }

            loadedVehicles.add(
              BookingVehicle(
                id: doc.id,

                type:
                    (data['type'] ??
                            'Car')
                        .toString(),

                model: model,

                number: number,

                color:
                    (data['color'] ??
                            'Dark Gray')
                        .toString(),

                isPrimary:
                    data['isPrimary'] ==
                        true,
              ),
            );
          }
        } on FirebaseException catch (e) {
          debugPrint(
            'VEHICLE SUBCOLLECTION ERROR: '
            '${e.code} - ${e.message}',
          );

          // Do not fail if root array works.
        }
      }

      // ========================================================
      // PRIMARY FIRST
      // ========================================================

      loadedVehicles.sort(
        (a, b) {
          if (a.isPrimary &&
              !b.isPrimary) {
            return -1;
          }

          if (!a.isPrimary &&
              b.isPrimary) {
            return 1;
          }

          return 0;
        },
      );

      // ========================================================
      // SELECT PRIMARY OR FIRST
      // ========================================================

      BookingVehicle? selected;

      if (loadedVehicles.isNotEmpty) {
        final bool hasPrimary =
            loadedVehicles.any(
          (vehicle) =>
              vehicle.isPrimary,
        );

        if (hasPrimary) {
          selected =
              loadedVehicles.firstWhere(
            (vehicle) =>
                vehicle.isPrimary,
          );
        } else {
          selected =
              loadedVehicles.first;
        }
      }

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        _name = name;

        _phone = phone;

        _vehicles =
            loadedVehicles;

        _selectedVehicle =
            selected;

        _isLoading = false;

        _vehicleError =
            loadedVehicles.isEmpty
                ? 'No vehicles found. Add a vehicle from Profile.'
                : null;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'PROFILE FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _vehicleError =
            'Unable to load your vehicles: '
            '${e.message ?? e.code}';
      });
    } catch (e, stackTrace) {
      debugPrint(
        'PROFILE LOAD ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _vehicleError =
            'Unable to load your vehicles: $e';
      });
    }
  }

  // ============================================================
  // SELECT VEHICLE
  // ============================================================

  void _selectVehicle(
    BookingVehicle vehicle,
  ) {
    if (_isBooking) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  // ============================================================
  // CONFIRM BOOKING
  // ============================================================

  Future<void> _confirmBooking() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
      );

      return;
    }

    // ==========================================================
    // VEHICLE REQUIRED
    // ==========================================================

    final BookingVehicle? vehicle =
        _selectedVehicle;

    if (vehicle == null) {
      _showMessage(
        'Please select a vehicle first.',
      );

      return;
    }

    if (_isBooking) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // ========================================================
      // CREATE BOOKING DOCUMENT
      // ========================================================

      final DocumentReference<
              Map<String, dynamic>>
          bookingRef =
          FirebaseFirestore.instance
              .collection('bookings')
              .doc();

      final String bookingId =
          bookingRef.id;

      // ========================================================
      // SAVE BOOKING
      // ========================================================

      await bookingRef.set({
        // ------------------------------------------------------
        // BOOKING
        // ------------------------------------------------------

        'bookingId':
            bookingId,

        'status':
            'confirmed',

        // ------------------------------------------------------
        // USER
        // ------------------------------------------------------

        'userId':
            user.uid,

        'userName':
            _name,

        'phoneNumber':
            _phone,

        // ------------------------------------------------------
        // DESTINATION
        // ------------------------------------------------------

        'destination':
            widget.destinationName,

        // ------------------------------------------------------
        // VALET
        // ------------------------------------------------------

        'valetId':
            widget.valetId,

        'valetName':
            widget.valetName,

        'rating':
            widget.rating,

        'distance':
            widget.distance,

        'eta':
            widget.eta,

        'slots':
            widget.slots,

        // ------------------------------------------------------
        // VEHICLE
        // ------------------------------------------------------

        'vehicleId':
            vehicle.id,

        'vehicleType':
            vehicle.type,

        'vehicleModel':
            vehicle.model,

        'vehicleColor':
            vehicle.color,

        'carNumber':
            vehicle.number,

        'carModel':
            vehicle.model,

        // ------------------------------------------------------
        // PAYMENT
        // ------------------------------------------------------

        'price':
            widget.price,

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'BOOKING CREATED: $bookingId',
      );

      debugPrint(
        'VALET ID: ${widget.valetId}',
      );

      debugPrint(
        'VEHICLE ID: ${vehicle.id}',
      );

      // ========================================================
      // CHECK SCREEN
      // ========================================================

      if (!mounted) {
        return;
      }

      // ========================================================
      // GO TO CONFIRMED SCREEN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmedScreen(
            bookingId:
                bookingId,

            destinationName:
                widget.destinationName,

            valetName:
                widget.valetName,

            carNumber:
                vehicle.number,

            carModel:
                vehicle.model,

            price:
                widget.price,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '================================',
      );

      debugPrint(
        'BOOKING FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to create booking: '
        '${e.message ?? e.code}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '================================',
      );

      debugPrint(
        'BOOKING ERROR',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        stackTrace.toString(),
      );

      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to create booking: $e',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBooking = false;
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 4,
          overflow:
              TextOverflow.ellipsis,
        ),

        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(16),

        backgroundColor:
            const Color(0xFF302D33),

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
  // DETAIL ROW
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF3F3F4),

              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child: Icon(
              icon,
              color:
                  const Color(0xFF555555),
              size: 19,
            ),
          ),

          const SizedBox(
            width: 11,
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
                    fontSize: 10,
                    color: grey,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color: black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildVehicleCard(
    BookingVehicle vehicle,
  ) {
    final bool isSelected =
        _selectedVehicle?.id ==
            vehicle.id;

    final bool isBike =
        vehicle.type.toLowerCase() ==
            'bike';

    return GestureDetector(
      onTap: () {
        _selectVehicle(vehicle);
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),

        width: double.infinity,

        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border: Border.all(
            color: isSelected
                ? red
                : const Color(
                    0xFFE4E4E6,
                  ),

            width:
                isSelected ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 44,
              height: 44,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFE8EE,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Icon(
                isBike
                    ? Icons
                        .two_wheeler_outlined
                    : Icons
                        .directions_car_outlined,

                color: red,

                size: 23,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    vehicle.model,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color: black,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    vehicle.number,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color: grey,
                    ),
                  ),

                  if (vehicle.isPrimary)
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 4,
                      ),

                      child: Text(
                        'Primary vehicle',

                        style:
                            TextStyle(
                          fontSize: 9,
                          color: red,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            // ==================================================
            // RADIO
            // ==================================================

            Container(
              width: 21,
              height: 21,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color: isSelected
                      ? red
                      : const Color(
                          0xFFBDBDC2,
                        ),

                  width: 1.5,
                ),
              ),

              child: isSelected
                  ? Center(
                      child:
                          Container(
                        width: 11,
                        height: 11,

                        decoration:
                            const BoxDecoration(
                          color: red,
                          shape:
                              BoxShape
                                  .circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE SECTION
  // ============================================================

  Widget _buildVehicleSection() {
    // ==========================================================
    // NO VEHICLES
    // ==========================================================

    if (_vehicles.isEmpty) {
      return Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(15),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border: Border.all(
            color:
                const Color(0xFFE5E5E7),
          ),
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons
                  .directions_car_outlined,

              color: red,

              size: 22,
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child: Text(
                _vehicleError ??
                    'No vehicles found. Add a vehicle from Profile.',

                style:
                    const TextStyle(
                  fontSize: 12,
                  color: grey,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // VEHICLES
    // ==========================================================

    return Column(
      children: [
        for (int index = 0;
            index < _vehicles.length;
            index++) ...[
          _buildVehicleCard(
            _vehicles[index],
          ),

          if (index <
              _vehicles.length - 1)
            const SizedBox(
              height: 9,
            ),
        ],
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Scaffold(
        backgroundColor:
            background,

        body: Center(
          child:
              CircularProgressIndicator(
            color: red,
          ),
        ),
      );
    }

    // ==========================================================
    // SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor:
          background,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                7,
              ),

              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        _isBooking
                            ? null
                            : () {
                                Navigator.of(
                                  context,
                                ).pop();
                              },

                    icon:
                        const Icon(
                      Icons
                          .arrow_back_ios_new,
                      size: 19,
                      color: black,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Confirm booking',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                        color: black,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 48,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  7,
                  20,
                  20,
                ),

                child: Column(
                  children: [
                    // ==========================================
                    // VALET CARD
                    // ==========================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE5E5E7,
                          ),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          // ====================================
                          // VALET
                          // ====================================

                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFFFE8EE,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    13,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .directions_car_outlined,

                                  color: red,

                                  size: 25,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      widget
                                          .valetName,

                                      maxLines: 1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color:
                                            black,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .star,
                                          color:
                                              Color(
                                            0xFFFFB000,
                                          ),
                                          size:
                                              15,
                                        ),

                                        const SizedBox(
                                          width:
                                              4,
                                        ),

                                        Text(
                                          widget
                                              .rating,

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                11,
                                            color:
                                                grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Divider(
                            height: 1,
                            color:
                                Color(
                              0xFFEAEAEA,
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          // ====================================
                          // DESTINATION
                          // ====================================

                          _detailRow(
                            icon: Icons
                                .location_on_outlined,

                            title:
                                'Destination',

                            value: widget
                                .destinationName,
                          ),

                          // ====================================
                          // ETA
                          // ====================================

                          _detailRow(
                            icon: Icons
                                .access_time_outlined,

                            title:
                                'Estimated arrival',

                            value:
                                widget.eta,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==========================================
                    // VEHICLE TITLE
                    // ==========================================

                    const Align(
                      alignment:
                          Alignment.centerLeft,

                      child: Text(
                        'Select your vehicle',

                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                          color: black,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 9,
                    ),

                    // ==========================================
                    // VEHICLES
                    // ==========================================

                    _buildVehicleSection(),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==========================================
                    // PRICE
                    // ==========================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        17,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE5E5E7,
                          ),
                        ),
                      ),

                      child: Row(
                        children: [
                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  'Estimated total',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        11,
                                    color:
                                        grey,
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      4,
                                ),

                                Text(
                                  'Valet service',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    color:
                                        black,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            widget.price,

                            style:
                                const TextStyle(
                              fontSize: 23,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CONFIRM BUTTON
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                16,
              ),

              color:
                  Colors.white,

              child:
                  SizedBox(
                height: 53,

                child:
                    ElevatedButton(
                  onPressed:
                      (_isBooking ||
                              _selectedVehicle ==
                                  null)
                          ? null
                          : _confirmBooking,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        red,

                    disabledBackgroundColor:
                        const Color(
                      0xFFD8D8DA,
                    ),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      _isBooking
                          ? const SizedBox(
                              width: 22,
                              height: 22,

                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'Confirm Booking',

                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w700,
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

// =================================================================
// VEHICLE MODEL
// =================================================================

class BookingVehicle {
  final String id;

  final String type;

  final String model;

  final String number;

  final String color;

  final bool isPrimary;

  const BookingVehicle({
    required this.id,
    required this.type,
    required this.model,
    required this.number,
    required this.color,
    required this.isPrimary,
  });
}