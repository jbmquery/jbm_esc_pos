// home_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/printer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPaperSize = "58mm";
  int selectedCopies = 1;
  String estadoApp = "free";
  bool isBlocked = false;
  bool isLoading = true;
  int diasRestantes = 0;

  // Datos visuales de impresora (luego se guardarán en Firebase)
  String printerName = "Ninguna seleccionada";
  String printerMac = "--:--:--:--:--:--";
  String printerType = "Bluetooth";

  final FirebaseService _firebaseService = FirebaseService();
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final result = await _firebaseService.checkAndInitializeDevice();

      if (result != null) {
        setState(() {
          estadoApp = result["estado"] ?? "free";
          isBlocked = result["is_blocked"] ?? false;
          printerName = result["printer_name"] ?? printerName;
          printerMac = result["printer_mac"] ?? printerMac;
          printerType = result["printer_type"] ?? printerType;
          selectedPaperSize = result["paper_size"] ?? selectedPaperSize;
          selectedCopies = result["copies"] ?? selectedCopies;
        });
      }
      if (result != null &&
          result["fecha_expiracion"] != null &&
          estadoApp == "free") {
        final Timestamp exp = result["fecha_expiracion"];
        final DateTime expiration = exp.toDate();
        final DateTime now = DateTime.now();

        diasRestantes = expiration.difference(now).inDays;

        if (diasRestantes < 0) {
          diasRestantes = 0;
        }
      }
    } catch (e) {
      print("ERROR INIT: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isBlocked) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Este dispositivo ha sido bloqueado.\nContacte al administrador.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración de Impresión"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1️⃣ Seleccionar impresora
            const Text(
              "1. Seleccionar impresora",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _openPrinterModal,
              child: const Text("Seleccionar Impresora"),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                title: Text(printerName),
                subtitle: Text("MAC: $printerMac\nTipo: $printerType"),
              ),
            ),

            const SizedBox(height: 30),

            /// 2️⃣ Tamaño de impresión
            const Text(
              "2. Elegir tamaño de impresión",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedPaperSize,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: "58mm",
                  child: Text("2 pulgadas (58mm)"),
                ),
                DropdownMenuItem(
                  value: "80mm",
                  child: Text("3 pulgadas (80mm)"),
                ),
                DropdownMenuItem(
                  value: "104mm",
                  child: Text("4 pulgadas (104mm)"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPaperSize = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            /// 3️⃣ Número de copias
            const Text(
              "3. Número de copias",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              value: selectedCopies,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text("1 copia")),
                DropdownMenuItem(value: 2, child: Text("2 copias")),
                DropdownMenuItem(value: 3, child: Text("3 copias")),
                DropdownMenuItem(value: 4, child: Text("4 copias")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCopies = value!;
                });
              },
            ),

            const Spacer(),

            /// Botones finales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openPremiumModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text("Adquirir Premium"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _firebaseService.registerDevice(
                        printerName: printerName,
                        printerMac: printerMac,
                        printerType: printerType,
                        paperSize: selectedPaperSize,
                        copies: selectedCopies,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Configuración guardada correctamente"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text("Guardar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 Modal impresora
  void _openPrinterModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar Impresora"),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<PrinterDevice>>(
              future: _printerService.scanBluetoothPrinters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    "Error al escanear dispositivos.",
                    style: TextStyle(color: Colors.red),
                  );
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return const Text(
                    "No se encontraron impresoras Bluetooth.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(device.name),
                        subtitle: Text(device.address),
                        onTap: () {
                          setState(() {
                            printerName = device.name;
                            printerMac = device.address;
                            printerType = device.type;
                          });

                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 🟡 Modal premium
  void _openPremiumModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Versión Premium"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Si desea adquirir la versión premium contacta a este número:",
              ),
              const SizedBox(height: 15),

              const Text(
                "+51 931530445",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              Text(
                "Estado: $estadoApp",
                style: TextStyle(
                  color: estadoApp == "premium"
                      ? Colors.green
                      : estadoApp == "expired"
                      ? Colors.red
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (estadoApp == "free") ...[
                const SizedBox(height: 5),
                Text(
                  "Días gratis: $diasRestantes",
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }
}
