import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPaperSize = "58mm";
  int selectedCopies = 1;

  // Datos visuales de impresora (luego se guardarán en Firebase)
  String printerName = "Ninguna seleccionada";
  String printerMac = "--:--:--:--:--:--";
  String printerType = "Bluetooth";

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      // 🔜 AQUÍ IRÁ LA LÓGICA PARA GUARDAR EN FIREBASE
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
        String tempName = "";
        String tempMac = "";
        String tempType = "Bluetooth";

        return AlertDialog(
          title: const Text("Seleccionar Impresora"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                /// 🔜 AQUÍ LUEGO IRÁ LA LISTA REAL DE DISPOSITIVOS BLUETOOTH
                const Text(
                  "Aquí se mostrará la lista de dispositivos térmicos detectados.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Nombre de la impresora",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => tempName = value,
                ),

                const SizedBox(height: 15),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Dirección MAC",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => tempMac = value,
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: tempType,
                  decoration: const InputDecoration(
                    labelText: "Tipo de conexión",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "Bluetooth",
                      child: Text("Bluetooth"),
                    ),
                    DropdownMenuItem(value: "USB", child: Text("USB")),
                    DropdownMenuItem(value: "WiFi", child: Text("WiFi")),
                  ],
                  onChanged: (value) {
                    tempType = value!;
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      printerName = tempName.isEmpty ? "Sin nombre" : tempName;
                      printerMac = tempMac.isEmpty
                          ? "--:--:--:--:--:--"
                          : tempMac;
                      printerType = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar selección"),
                ),
              ],
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
            children: const [
              Text(
                "Si desea adquirir la versión premium contacta a este número:",
              ),
              SizedBox(height: 15),

              Text(
                "+51 931530445",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              SizedBox(height: 10),

              Text(
                "Estado: Free",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
