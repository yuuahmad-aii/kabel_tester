// =========================================================================
// serial_provider.dart
// Berisi semua logika untuk handle serial port dan state aplikasi.
// =========================================================================
import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

// Enum untuk status koneksi agar lebih mudah dibaca
enum ConnectionStatus { disconnected, connected, connecting, error }

// Enum untuk status pengetesan
enum TestStatus { idle, running, finished, stopped }

class SerialProvider with ChangeNotifier {
  // --- State Konektivitas ---
  List<String> _availablePorts = [];
  SerialPort? _serialPort;
  StreamSubscription<Uint8List>? _dataSubscription;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _selectedPortName;

  // --- State Pengetesan ---
  TestStatus _testStatus = TestStatus.idle;
  int _currentTestingOutPin = 0;
  // Map untuk menyimpan hasil: Key = pin output, Value = list pin input yang terhubung
  final Map<int, List<int>> _testResults = {};
  String _lastMessage = "Selamat Datang! Hubungkan alat untuk memulai.";

  // --- Getters untuk UI ---
  List<String> get availablePorts => _availablePorts;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get selectedPortName => _selectedPortName;
  TestStatus get testStatus => _testStatus;
  int get currentTestingOutPin => _currentTestingOutPin;
  Map<int, List<int>> get testResults => _testResults;
  String get lastMessage => _lastMessage;

  SerialProvider() {
    _initPorts();
  }

  // Mencari semua port serial yang tersedia saat aplikasi dimulai
  void _initPorts() {
    _availablePorts = SerialPort.availablePorts;
    notifyListeners();
  }

  // Memilih dan menghubungkan ke port serial
  Future<void> connectToPort(String portName) async {
    _connectionStatus = ConnectionStatus.connecting;
    _selectedPortName = portName;
    notifyListeners();

    try {
      _serialPort = SerialPort(portName);
      if (!_serialPort!.openReadWrite()) {
        // Jika gagal membuka port
        throw Exception("Gagal membuka port serial: ${SerialPort.lastError}");
      }

      // Konfigurasi port (baud rate tidak terlalu relevan untuk USB CDC, tapi baik untuk di-set)
      _serialPort!.config.baudRate = 9600;

      _connectionStatus = ConnectionStatus.connected;
      _lastMessage = "Terhubung ke $portName. Siap untuk tes.";
      notifyListeners();

      // Mulai mendengarkan data dari port serial
      _listenToData();
    } catch (e) {
      _connectionStatus = ConnectionStatus.error;
      _lastMessage = "Error: $e";
      _selectedPortName = null;
      notifyListeners();
    }
  }

  // Berhenti mendengarkan dan menutup port
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _serialPort?.close();
    _serialPort = null;
    _connectionStatus = ConnectionStatus.disconnected;
    _testStatus = TestStatus.idle;
    _selectedPortName = null;
    _lastMessage = "Koneksi diputus.";
    _clearResults();
    notifyListeners();
  }

  // String buffer untuk menangani data yang masuk per potongan
  String _dataBuffer = '';

  void _listenToData() {
    if (_serialPort == null) return;

    final reader = SerialPortReader(_serialPort!);
    _dataSubscription = reader.stream.listen(
      (data) {
        // Gabungkan data baru ke buffer
        _dataBuffer += utf8.decode(data, allowMalformed: true);

        // Proses buffer jika mengandung baris baru
        while (_dataBuffer.contains('\r\n')) {
          // Ambil satu baris penuh pertama
          int lineEndIndex = _dataBuffer.indexOf('\r\n');
          String line = _dataBuffer.substring(0, lineEndIndex);

          // Hapus baris yang sudah diproses dari buffer
          _dataBuffer = _dataBuffer.substring(lineEndIndex + 2);

          // Parse baris data
          _parseLine(line.trim());
        }
      },
      onError: (error) {
        _connectionStatus = ConnectionStatus.error;
        _lastMessage = "Error baca data: $error";
        notifyListeners();
      },
      onDone: () {
        // Port ditutup
        disconnect();
      },
    );
  }

  // Mem-parsing setiap baris data yang diterima dari STM32
  void _parseLine(String line) {
    if (line.isEmpty) return;

    // Menangani pesan status sederhana
    switch (line.toLowerCase()) {
      case "ready":
        _testStatus = TestStatus.idle;
        _lastMessage = "Alat siap. Tekan 'Start Test'.";
        _clearResults();
        break;
      case "start":
        _testStatus = TestStatus.running;
        _lastMessage = "Tes sedang berjalan...";
        _clearResults();
        break;
      case "end":
        _testStatus = TestStatus.finished;
        _lastMessage = "Siklus tes selesai.";
        _currentTestingOutPin = 0; // Reset pin yang dites
        break;
      case "stop":
        _testStatus = TestStatus.stopped;
        _lastMessage = "Tes dihentikan oleh pengguna.";
        _currentTestingOutPin = 0; // Reset pin yang dites
        break;
      default:
        // Jika bukan pesan status, coba parse sebagai hasil tes `out;in1,in2...`
        _parseTestResult(line);
        break;
    }
    notifyListeners();
  }

  void _parseTestResult(String line) {
    final parts = line.split(';');
    if (parts.length == 2) {
      try {
        int outPin = int.parse(parts[0]);
        _currentTestingOutPin = outPin; // Update pin yang sedang dites

        List<int> inPins = [];
        if (parts[1].isNotEmpty && parts[1] != "error_write") {
          inPins = parts[1].split(',').map((e) => int.parse(e)).toList();
        }
        _testResults[outPin] = inPins;
      } catch (e) {
        // Gagal parsing, mungkin format tidak dikenal
        if (kDebugMode) {
          print("Gagal parse hasil tes: $line");
        }
      }
    }
  }

  // Mengirim perintah ke STM32
  Future<void> _sendCommand(String command) async {
    if (_serialPort != null && _serialPort!.isOpen) {
      try {
        final bytes = Uint8List.fromList(utf8.encode(command));
        _serialPort!.write(bytes);
      } catch (e) {
        _lastMessage = "Error kirim perintah: $e";
        notifyListeners();
      }
    }
  }

  void startTest() {
    _sendCommand("?");
  }

  void stopTest() {
    _sendCommand("!");
  }

  // Membersihkan hasil tes sebelumnya
  void _clearResults() {
    _testResults.clear();
    _currentTestingOutPin = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
