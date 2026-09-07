import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final String valetName;
  final String destinationName;
  final String vehicle;
  final String carModel;
  final String amount;
  final Future<void> Function(BuildContext paymentContext) onPay;

  const PaymentScreen({
    super.key,
    this.valetName = 'QuickPark Valet',
    this.destinationName = 'UB City Mall Valet',
    this.vehicle = 'UP80HR8333',
    this.carModel = 'Vehicle',
    this.amount = '₹200',
    required this.onPay,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedPayment = 0;
  bool isPaying = false;

  static const Color red = Color(0xFFEF0038);
  static const Color darkText = Color(0xFF292929);
  static const Color greyText = Color(0xFF777777);

  Future<void> _pay() async {
    if (isPaying) return;

    setState(() {
      isPaying = true;
    });

    try {
      // UI/testing connection:
      // the existing PostgreSQL booking creation is called here.
      await widget.onPay(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isPaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        leading: IconButton(
          onPressed: isPaying
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: darkText,
          ),
        ),
        title: const Text(
          'Payment',
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
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // BOOKING SUMMARY
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFE5E5E7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFE9EF),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons
                                      .directions_car_outlined,
                                  color: red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.valetName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 13,
                                          color:
                                              Color(0xFFFFA800),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '4.8',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: greyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          const Divider(
                            height: 1,
                            color: Color(0xFFEAEAEA),
                          ),
                          const SizedBox(height: 11),

                          _summaryRow(
                            icon:
                                Icons.location_on_outlined,
                            label: 'Destination',
                            value:
                                widget.destinationName,
                          ),

                          const SizedBox(height: 11),

                          _summaryRow(
                            icon:
                                Icons.directions_car_outlined,
                            label: 'Vehicle',
                            value: widget.vehicle,
                            subtitle: widget.carModel,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _paymentOption(
                      index: 0,
                      icon:
                          Icons.account_balance_outlined,
                      title: 'UPI',
                      subtitle:
                          'Google Pay, PhonePe, Paytm',
                    ),

                    const SizedBox(height: 9),

                    _paymentOption(
                      index: 1,
                      icon:
                          Icons.credit_card_outlined,
                      title: 'Credit / Debit Card',
                      subtitle:
                          'Visa, Mastercard, RuPay',
                    ),

                    const SizedBox(height: 9),

                    _paymentOption(
                      index: 2,
                      icon:
                          Icons.payments_outlined,
                      title: 'Cash / Pay at Valet',
                      subtitle:
                          'Pay when you arrive',
                    ),

                    const SizedBox(height: 20),

                    // PRICE DETAILS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFE5E5E7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Valet service',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: greyText,
                                  ),
                                ),
                              ),
                              Text(
                                widget.amount,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            height: 1,
                            color: Color(0xFFEAEAEA),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              Text(
                                widget.amount,
                                style: const TextStyle(
                                  fontSize: 18,
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
                  ],
                ),
              ),
            ),

            // PAY BUTTON
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
                height: 48,
                child: ElevatedButton(
                  onPressed: isPaying ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    disabledBackgroundColor:
                        const Color(0xFFD8D8DA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          'Pay ${widget.amount}',
                          style: const TextStyle(
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
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: greyText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: greyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              if (subtitle != null &&
                  subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: greyText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedPayment == index;

    return GestureDetector(
      onTap: isPaying
          ? null
          : () {
              setState(() {
                selectedPayment = index;
              });
            },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF4F6)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? red
                : const Color(0xFFE5E5E7),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFE5EB)
                    : const Color(0xFFF3F3F5),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    selected ? red : greyText,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    selected ? red : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? red
                      : const Color(0xFFBDBDBD),
                  width: 1.3,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
