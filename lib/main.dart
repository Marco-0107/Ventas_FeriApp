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
      final prefs = await SharedPreferences.getInstance();
      final firstTime = prefs.getBool('first_time') ?? true;
      if (firstTime) {
        await prefs.setBool('first_time', false);
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
          'Ventas FeriAPP',
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
            Text('¡Feliz Día Lore y Mimi!',
                style: TextStyle(color: Colors.white, fontSize: 32)),
            SizedBox(height: 20),
            Text(
              'Esta app es para ayudarles en la feria, hecha con mucho amor 💚',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => InicioDiaPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
              ),
              child:
                  Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
          child: Text('Iniciar Día de Trabajo'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => VentasPage()),
            );
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

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'valor': valor,
        'fechaHora': fechaHora,
      };

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
        map['nombre'] as String,
        (map['valor'] as num).toDouble(),
        map['fechaHora'] as String,
      );
}

class VentasPage extends StatefulWidget {
  @override
  _VentasPageState createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> with TickerProviderStateMixin {
  final List<Venta> ventas = [];
  final nombreController = TextEditingController();
  final valorController = TextEditingController();
  final player = AudioPlayer();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          _loadVentas();
          nombreController.clear();
          valorController.clear();
        }
      });
    _loadVentas();
  }

  String get _salesKey =>
      _tabController.index == 0 ? 'lore_ventas' : 'mimi_ventas';

  double get total => ventas.fold(0.0, (sum, v) => sum + v.valor);

  Future<void> _loadVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_salesKey);
    setState(() {
      ventas.clear();
      if (data != null) {
        final list = jsonDecode(data) as List<dynamic>;
        ventas.addAll(list.map((e) => Venta.fromMap(e as Map<String, dynamic>)));
      }
    });
  }

  Future<void> _saveVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final list = ventas.map((v) => v.toMap()).toList();
    await prefs.setString(_salesKey, jsonEncode(list));
  }

  void _addVenta() async {
    final nombre = nombreController.text;
    final val = double.tryParse(valorController.text);
    final fechaHora = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    if (nombre.isNotEmpty && val != null) {
      setState(() => ventas.add(Venta(nombre, val, fechaHora)));
      await _saveVentas();
      await player.play(AssetSource('sounds/success.mp3'));
      nombreController.clear();
      valorController.clear();
    }
  }

  void _editVenta(int i) async {
    final nCtrl = TextEditingController(text: ventas[i].nombre);
    final vCtrl = TextEditingController(text: ventas[i].valor.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nCtrl, decoration: InputDecoration(labelText: 'Nombre')),
            TextField(controller: vCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Valor')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Guardar')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        ventas[i].nombre = nCtrl.text;
        ventas[i].valor = double.tryParse(vCtrl.text) ?? ventas[i].valor;
      });
      await _saveVentas();
    }
  }

  void _removeVenta(int i) async {
    setState(() => ventas.removeAt(i));
    await _saveVentas();
  }

  void _closeDay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar cierre'),
        content: Text('¿Seguro que quieres cerrar el día?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sí')),
        ],
      ),
    );
    if (confirm ?? false) {
      final prefs = await SharedPreferences.getInstance();
      final key = _tabController.index == 0 ? 'lore_historial' : 'mimi_historial';
      final hData = prefs.getString(key);
      final hist = hData != null ? jsonDecode(hData) as List : [];
      hist.add({
        'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'total': total,
        'ventas': ventas.map((v) => v.toMap()).toList(),
      });
      await prefs.setString(key, jsonEncode(hist));
      await prefs.remove(_salesKey);
      setState(() => ventas.clear());
    }
  }

  void _openHistory() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistorialPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas FeriAPP'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Lore'), Tab(text: 'Mimi')],
        ),
        actions: [
          IconButton(icon: Icon(Icons.history), onPressed: _openHistory),
          IconButton(icon: Icon(Icons.close), onPressed: _closeDay),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ventasView(), _ventasView()],
      ),
    );
  }

  Widget _ventasView() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          ElevatedButton(onPressed: _addVenta, child: Text('Agregar Venta')),
          SizedBox(height: 20),
          Text('Ventas del día', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: ventas.length,
              itemBuilder: (_, i) {
                final v = ventas[i];
                return ListTile(
                  title: Text('${v.nombre} - \$${v.valor.toStringAsFixed(0)}'),
                  subtitle: Text('Fecha y hora: ${v.fechaHora}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editVenta(i)),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('¿Eliminar esta venta?'),
                            content: Text('¿Seguro?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ).then((ok) {
                          if (ok ?? false) _removeVenta(i);
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Text('Total: \$${total.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}

class HistorialPage extends StatefulWidget {
  @override
  _HistorialPageState createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> historial = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) _loadHistorial();
      });
    _loadHistorial();
  }

  String get _historyKey => _tabController.index == 0 ? 'lore_historial' : 'mimi_historial';

  Future<void> _loadHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    setState(() {
      historial = data != null
          ? List<Map<String, dynamic>>.from(jsonDecode(data))
          : [];
    });
  }

  Future<void> _saveHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(historial));
  }

  void _removeDia(int i) {
    setState(() => historial.removeAt(i));
    _saveHistorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Días'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Lore'), Tab(text: 'Mimi')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [ _histList(), _histList() ],
      ),
    );
  }

  Widget _histList() {
    return ListView.builder(
      itemCount: historial.length,
      itemBuilder: (_, i) {
        final d = historial[i];
        return ListTile(
          title: Text('Fecha: ${d['fecha']} - Total: \$${(d['total'] as num).toStringAsFixed(0)}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('¿Eliminar este día?'),
                content: Text('¿Seguro?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                ],
              ),
            ).then((ok) {
              if (ok ?? false) _removeDia(i);
            }),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetalleDiaPage(
                ventas: d['ventas'],
                fecha: d['fecha'],
                historyKey: _historyKey,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DetalleDiaPage extends StatefulWidget {
  final List ventas;
  final String fecha;
  final String historyKey;

  DetalleDiaPage({
    required this.ventas,
    required this.fecha,
    required this.historyKey,
  });

  @override
  _DetalleDiaPageState createState() => _DetalleDiaPageState();
}

class _DetalleDiaPageState extends State<DetalleDiaPage> {
  late List ventasEditable;

  @override
  void initState() {
    super.initState();
    ventasEditable = List.from(widget.ventas);
  }

  void _editVentaDetalle(int i) async {
    final nCtrl = TextEditingController(text: ventasEditable[i]['nombre']);
    final vCtrl = TextEditingController(text: ventasEditable[i]['valor'].toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nCtrl, decoration: InputDecoration(labelText: 'Nombre')),
            TextField(controller: vCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Valor')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Guardar')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        ventasEditable[i]['nombre'] = nCtrl.text;
        ventasEditable[i]['valor'] = double.tryParse(vCtrl.text) ?? ventasEditable[i]['valor'];
      });
      final nuevoTotal = ventasEditable.fold<double>(0.0, (sum, v) {
        final val = v['valor'];
        return sum + ((val is num) ? val.toDouble() : 0.0);
      });
      final prefs = await SharedPreferences.getInstance();
      final hist = prefs.getString(widget.historyKey);
      if (hist != null) {
        final listH = jsonDecode(hist) as List<dynamic>;
        for (var dia in listH) {
          if (dia['fecha'] == widget.fecha) {
            dia['ventas'] = ventasEditable;
            dia['total'] = nuevoTotal;
            break;
          }
        }
        await prefs.setString(widget.historyKey, jsonEncode(listH));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ventas del ${widget.fecha}')),
      body: ListView.builder(
        itemCount: ventasEditable.length,
        itemBuilder: (_, i) {
          final v = ventasEditable[i];
          return ListTile(
            title: Text('${v['nombre']} - \$${v['valor'].toStringAsFixed(0)}'),
            subtitle: Text('Fecha y hora: ${v['fechaHora']}'),
            onTap: () => _editVentaDetalle(i),
          );
        },
      ),
    );
  }
}
