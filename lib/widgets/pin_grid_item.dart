// =========================================================================
// widgets/pin_grid_item.dart
// Widget kustom untuk setiap sel dalam grid
// =========================================================================
import 'package:flutter/material.dart';
import '../../serial_provider.dart'; // Impor enum TestStatus

class PinGridItem extends StatelessWidget {
  final int pinNumber;
  final bool isCurrentlyTesting;
  final List<int>? connectedPins;
  final TestStatus testStatus;

  const PinGridItem({
    super.key,
    required this.pinNumber,
    required this.isCurrentlyTesting,
    this.connectedPins,
    required this.testStatus,
  });

  @override
  Widget build(BuildContext context) {
    final (Color borderColor, Color backgroundColor, String statusText) = _getPinStatus();

    return Card(
      elevation: isCurrentlyTesting ? 8 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('OUT $pinNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Logika untuk menentukan warna dan teks status pin
  (Color, Color, String) _getPinStatus() {
    // Jika tes sedang berjalan dan pin ini sedang dites
    if (isCurrentlyTesting) {
      return (Colors.blue.shade300, Colors.blue.shade300.withAlpha((0.2 * 255).toInt()), 'Testing...');
    }

    // Jika tidak ada hasil untuk pin ini (belum dites)
    if (connectedPins == null || testStatus == TestStatus.idle) {
      return (Colors.grey.shade700, Colors.grey.shade700.withAlpha((0.1 * 255).toInt()), 'Idle');
    }

    // Jika kabel terbuka (tidak ada koneksi)
    if (connectedPins!.isEmpty) {
      return (Colors.orange.shade300, Colors.orange.shade300.withAlpha((0.2 * 255).toInt()), 'Open');
    }

    // Jika koneksi benar (satu-ke-satu)
    if (connectedPins!.length == 1) {
      return (
        Colors.green.shade300,
        Colors.green.shade300.withAlpha((0.2 * 255).toInt()),
        'IN ${connectedPins!.first}',
      );
    }

    // Jika terjadi korsleting (satu-ke-banyak)
    if (connectedPins!.length > 1) {
      return (
        Colors.red.shade300,
        Colors.red.shade300.withAlpha((0.2 * 255).toInt()),
        'Short!\nIN ${connectedPins!.join(',')}',
      );
    }

    // Default case
    return (Colors.grey.shade700, Colors.grey.withAlpha((0.1 * 255).toInt()), 'Idle');
  }
}
