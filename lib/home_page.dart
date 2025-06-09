// =========================================================================
// home_page.dart
// Berisi UI utama aplikasi
// =========================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'serial_provider.dart';
import 'widgets/pin_grid_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendapatkan akses ke SerialProvider
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('STM32 Cable Tester'),
            actions: [
              // Indikator status koneksi di AppBar
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Chip(
                  avatar: Icon(
                    provider.connectionStatus == ConnectionStatus.connected ? Icons.link : Icons.link_off,
                    color:
                        provider.connectionStatus == ConnectionStatus.connected ? Colors.greenAccent : Colors.redAccent,
                  ),
                  label: Text(provider.connectionStatus.name.toUpperCase()),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Baris untuk kontrol koneksi
                _buildConnectionControl(context, provider),
                const SizedBox(height: 16),

                // Baris untuk kontrol tes
                _buildTestControl(context, provider),
                const SizedBox(height: 8),

                // Baris untuk pesan status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      provider.lastMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Divider(),

                // Tampilan Grid hasil tes
                const Text("Hasil Pengetesan Kabel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(child: _buildResultGrid(context, provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionControl(BuildContext context, SerialProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.usb, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: provider.selectedPortName,
                hint: const Text('Pilih Port COM'),
                items: provider.availablePorts.map((port) => DropdownMenuItem(value: port, child: Text(port))).toList(),
                onChanged:
                    provider.connectionStatus == ConnectionStatus.disconnected
                        ? (value) {
                          if (value != null) {
                            provider.connectToPort(value);
                          }
                        }
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (provider.connectionStatus == ConnectionStatus.connected) {
                  provider.disconnect();
                } else if (provider.selectedPortName != null) {
                  provider.connectToPort(provider.selectedPortName!);
                }
              },
              icon: Icon(
                provider.connectionStatus == ConnectionStatus.connected ? Icons.close : Icons.power_settings_new,
              ),
              label: Text(provider.connectionStatus == ConnectionStatus.connected ? 'Disconnect' : 'Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    provider.connectionStatus == ConnectionStatus.connected
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControl(BuildContext context, SerialProvider provider) {
    bool canStart =
        provider.connectionStatus == ConnectionStatus.connected && provider.testStatus != TestStatus.running;
    bool canStop = provider.connectionStatus == ConnectionStatus.connected && provider.testStatus == TestStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: canStart ? () => provider.startTest() : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Test'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton.icon(
          onPressed: canStop ? () => provider.stopTest() : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop Test'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultGrid(BuildContext context, SerialProvider provider) {
    // Anda bisa mengganti 64 dengan jumlah pin total dari STM32 jika berbeda
    int totalPins = 64;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150, // Lebar maksimal setiap item
        childAspectRatio: 2 / 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalPins,
      itemBuilder: (context, index) {
        int pinNumber = index + 1;
        return PinGridItem(
          pinNumber: pinNumber,
          isCurrentlyTesting: provider.currentTestingOutPin == pinNumber,
          connectedPins: provider.testResults[pinNumber],
          testStatus: provider.testStatus,
        );
      },
    );
  }
}
