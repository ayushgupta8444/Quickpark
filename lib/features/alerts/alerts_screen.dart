import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<_AlertItem> _alerts = [
    _AlertItem(
      title: 'Valet is on the way',
      description: 'Your valet for UB City Mall is arriving.',
      time: '2 min ago',
      type: _AlertType.valet,
      isUnread: true,
    ),
    _AlertItem(
      title: 'Booking Confirmed',
      description: 'Your booking #123456 has been confirmed.',
      time: '1 hour ago',
      type: _AlertType.booking,
      isUnread: true,
    ),
    _AlertItem(
      title: 'Payment Successful',
      description: 'Your payment of ₹200 has been received.',
      time: '2 hours ago',
      type: _AlertType.payment,
      isUnread: false,
    ),
    _AlertItem(
      title: 'Vehicle Parked',
      description: 'Your vehicle has been parked successfully.',
      time: 'Yesterday',
      type: _AlertType.vehicle,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final todayAlerts =
        _alerts.where((alert) => alert.time != 'Yesterday').toList();
    final earlierAlerts =
        _alerts.where((alert) => alert.time == 'Yesterday').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all',
              style: TextStyle(
                color: Color(0xFFEF0038),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _alerts.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                if (todayAlerts.isNotEmpty) ...[
                  _buildSectionTitle('Today'),
                  const SizedBox(height: 10),
                  ...todayAlerts.map(_buildAlertCard),
                ],
                if (earlierAlerts.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _buildSectionTitle('Earlier'),
                  const SizedBox(height: 10),
                  ...earlierAlerts.map(_buildAlertCard),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF555555),
      ),
    );
  }

  Widget _buildAlertCard(_AlertItem alert) {
    return GestureDetector(
      onTap: () {
        setState(() {
          alert.isUnread = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isUnread
                ? const Color(0xFFFCE4EC)
                : const Color(0xFFF0F0F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertIcon(alert.type),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: alert.isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                      if (alert.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF0038),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    alert.time,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAAAAAA),
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

  Widget _buildAlertIcon(_AlertType type) {
    late final IconData icon;
    late final Color background;
    late final Color iconColor;

    switch (type) {
      case _AlertType.valet:
        icon = Icons.directions_car_rounded;
        background = const Color(0xFFFFEBF1);
        iconColor = const Color(0xFFEF0038);
        break;
      case _AlertType.booking:
        icon = Icons.check_circle_outline_rounded;
        background = const Color(0xFFEAF7EF);
        iconColor = const Color(0xFF27AE60);
        break;
      case _AlertType.payment:
        icon = Icons.account_balance_wallet_outlined;
        background = const Color(0xFFFFF5E5);
        iconColor = const Color(0xFFF39C12);
        break;
      case _AlertType.vehicle:
        icon = Icons.local_parking_rounded;
        background = const Color(0xFFEAF2FF);
        iconColor = const Color(0xFF3478F6);
        break;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (final alert in _alerts) {
        alert.isUnread = false;
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBF1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFEF0038),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No alerts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your booking and valet updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AlertType { valet, booking, payment, vehicle }

class _AlertItem {
  final String title;
  final String description;
  final String time;
  final _AlertType type;
  bool isUnread;

  _AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    required this.isUnread,
  });
}
