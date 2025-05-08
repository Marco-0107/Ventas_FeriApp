import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(VentasFeriAPP());
}

class VentasFeriAPP extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ventas FeriAPP',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF7F5F9),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool firstTime = prefs.getBool("first_time") ?? true;

      if (firstTime) {
        await prefs.setBool("first_time", false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => FelicitarMamaPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => InicioDiaPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Text(
          "Ventas FeriAPP",
          style: TextStyle(color: Colors.white, fontSize: 32),
        ),
      ),
    );
  }
}

class FelicitarMamaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "¡Feliz Día Mamá!",
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            SizedBox(height: 20),
            Text(
              "Esta app es para ayudarte en la feria, hecha con mucho amor 💚",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => InicioDiaPage()));
              },
              child: Text("Continuar"),
            )
          ],
        ),
      ),
    );
  }
}

class InicioDiaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Iniciar Día de Trabajo"),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => VentasPage()));
          },
        ),
      ),
    );
  }
}

class Venta {
  String nombre;
  double valor;
  String fechaHora;

  Venta(this.nombre, this.valor, this.fechaHora);

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'valor': valor,
      'fechaHora': fechaHora,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      map['nombre'],
      map['valor'],
      map['fechaHora'],
    );
  }
}

class VentasPage extends StatefulWidget {
  @override
  _VentasPageState createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final List<Venta> ventas = [];
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  double get total => ventas.fold(0, (sum, venta) => sum + venta.valor);

  Future<void> cargarVentas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? datos = prefs.getString("ventas_dia");
    if (datos != null) {
      List<dynamic> lista = jsonDecode(datos);
      setState(() {
        ventas.clear();
        ventas.addAll(lista.map((e) => Venta.fromMap(e)).toList());
      });
    }
  }

  Future<void> guardarVentas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> lista = ventas.map((e) => e.toMap()).toList();
    prefs.setString("ventas_dia", jsonEncode(lista));
  }

  void agregarVenta() async {
    final String nombre = nombreController.text;
    final double? valor = double.tryParse(valorController.text);
    final String fechaHora =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    if (nombre.isNotEmpty && valor != null) {
      setState(() {
        ventas.add(Venta(nombre, valor, fechaHora));
        nombreController.clear();
        valorController.clear();
      });
      await guardarVentas();
      await player.play(AssetSource('sounds/success.mp3'));
    }
  }

  void eliminarVenta(int index) async {
    setState(() {
      ventas.removeAt(index);
    });
    await guardarVentas();
  }

  void cerrarDia() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmar cierre"),
        content: Text("¿Estás seguro de que quieres cerrar el día?"),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: Text("Sí"), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? historial = prefs.getString("historial_dias");
      List<dynamic> listaHistorial =
          historial != null ? jsonDecode(historial) : [];
      listaHistorial.add({
        "fecha": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "total": total,
        "ventas": ventas.map((e) => e.toMap()).toList()
      });
      await prefs.setString("historial_dias", jsonEncode(listaHistorial));
      await prefs.remove("ventas_dia");
      setState(() {
        ventas.clear();
      });
    }
  }

  void irAHistorial() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistorialPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas FeriAPP'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: irAHistorial,
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: cerrarDia,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(labelText: 'Nombre del producto'),
            ),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Valor'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: agregarVenta,
              child: Text('Agregar Venta'),
            ),
            SizedBox(height: 20),
            Text(
              'Ventas del día',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ventas.length,
                itemBuilder: (context, index) {
                  final venta = ventas[index];
                  return ListTile(
                    title: Text('${venta.nombre} - \$${venta.valor.toStringAsFixed(0)}'),
                    subtitle: Text('Fecha y hora: ${venta.fechaHora}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => eliminarVenta(index),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total: \$${total.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 5),
            Text("Hecha por Marco Cerda con ayuda de ChatGPT - v1.0.1", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class HistorialPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> cargarHistorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? historial = prefs.getString("historial_dias");
    if (historial != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(historial));
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Días'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: cargarHistorial(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final historial = snapshot.data!;
          return ListView.builder(
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final dia = historial[index];
              return ListTile(
                title: Text('Fecha: ${dia['fecha']} - Total: \$${dia['total']}'),
              );
            },
          );
        },
      ),
    );
  }
}
