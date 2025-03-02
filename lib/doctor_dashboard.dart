import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/doctor/perfil_doctor_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    DoctorHomeScreen(),
    const ScheduleScreen(),
    const AppointmentsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Dashboard")),
      drawer: DoctorDrawer(),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Horarios'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DoctorDrawer extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  DoctorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user?.photoURL ?? '')),
          ),
          ListTile(
            title: const Text("Cerrar Sesión"),
            leading: const Icon(Icons.exit_to_app),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!.exists) {
          return const Center(child: Text('Error: Perfil no encontrado'));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool suscripcionActiva = false;

        if (data.containsKey('suscripcion')) {
          suscripcionActiva = data['suscripcion']['activa'] ?? false;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                    user?.photoURL ?? 'https://via.placeholder.com/150'),
              ),
              const SizedBox(height: 20),
              Text(
                data['nombre'] ?? user?.displayName ?? 'Doctor',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                data['email'] ?? user?.email ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                'Suscripción activa: ${suscripcionActiva ? 'Sí' : 'No'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DoctorHomeScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bienvenido, ${user?.displayName}",
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                  user?.photoURL ?? 'https://via.placeholder.com/150')),
          const SizedBox(height: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              var data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Especialidad: ${data['especialidad'] ?? 'No especificado'}",
                      style: const TextStyle(fontSize: 18)),
                  Text("Total de citas: ${data['total_citas'] ?? 0}",
                      style: const TextStyle(fontSize: 18)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('usuarios').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
              child: Text("Error cargando información del perfil"));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        Map<String, dynamic> horario = userData['horario'] ?? {};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi Horario de Atención',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildDayScheduleCard('lunes', 'Lunes', horario),
                    _buildDayScheduleCard('martes', 'Martes', horario),
                    _buildDayScheduleCard('miércoles', 'Miércoles', horario),
                    _buildDayScheduleCard('jueves', 'Jueves', horario),
                    _buildDayScheduleCard('viernes', 'Viernes', horario),
                    _buildDayScheduleCard('sábado', 'Sábado', horario),
                    _buildDayScheduleCard('domingo', 'Domingo', horario),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HorarioScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Horarios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayScheduleCard(
      String day, String label, Map<String, dynamic> horario) {
    List<dynamic> horas = horario[day] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            horas.isEmpty
                ? const Text('No hay horarios disponibles')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: horas.map<Widget>((hora) {
                      return Chip(
                        label: Text(hora),
                        backgroundColor: Colors.blue.shade100,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: "Pendientes"),
            Tab(text: "Confirmadas"),
            Tab(text: "Historial"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList('pendiente'),
              _buildAppointmentsList('confirmada'),
              _buildAppointmentsList('completada', includeRechazadas: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(String estado,
      {bool includeRechazadas = false}) {
    Query query = FirebaseFirestore.instance
        .collection('citas')
        .where('doctorId', isEqualTo: user?.uid);

    if (includeRechazadas) {
      query =
          query.where('estado', whereIn: [estado, 'rechazada', 'cancelada']);
    } else {
      query = query.where('estado', isEqualTo: estado);
    }

    query = query.orderBy('fecha', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("No hay citas ${estado}s"),
          );
        }

        var citas = snapshot.data!.docs;
        return ListView.builder(
          itemCount: citas.length,
          itemBuilder: (context, index) {
            var cita = citas[index];
            var citaData = cita.data() as Map<String, dynamic>;
            String estadoCita = citaData['estado'];

            // Convertir Timestamp a DateTime
            DateTime fecha = (citaData['fecha'] as Timestamp).toDate();
            String fechaFormateada =
                "${fecha.day}/${fecha.month}/${fecha.year}";

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(
                  "Paciente: ${citaData['pacienteNombre']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Fecha: $fechaFormateada - Hora: ${citaData['hora']}"),
                    if (citaData['motivoConsulta'] != null &&
                        citaData['motivoConsulta'].toString().isNotEmpty)
                      Text(
                        "Motivo: ${citaData['motivoConsulta']}",
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                trailing: estadoCita == 'pendiente'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _confirmarCita(cita.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _rechazarCita(cita.id),
                          ),
                        ],
                      )
                    : _buildEstadoChip(estadoCita),
                isThreeLine: citaData['motivoConsulta'] != null &&
                    citaData['motivoConsulta'].toString().isNotEmpty,
                onTap: () => _verDetalleCita(citaData, cita.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case 'confirmada':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rechazada':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'cancelada':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'completada':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Text(estado.toUpperCase()),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  void _confirmarCita(String citaId) {
    FirebaseFirestore.instance
        .collection('citas')
        .doc(citaId)
        .update({'estado': 'confirmada'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita confirmada')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  void _rechazarCita(String citaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar cita'),
        content: const Text('¿Estás seguro de que deseas rechazar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('citas')
                  .doc(citaId)
                  .update({'estado': 'rechazada'}).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cita rechazada')),
                );
              }).catchError((error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              });
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _verDetalleCita(Map<String, dynamic> citaData, String citaId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Cita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('Paciente', citaData['pacienteNombre']),
            _buildDetailItem('Fecha', _formatTimestamp(citaData['fecha'])),
            _buildDetailItem('Hora', citaData['hora']),
            _buildDetailItem('Estado', citaData['estado']),
            if (citaData['motivoConsulta'] != null)
              _buildDetailItem('Motivo', citaData['motivoConsulta']),
            const SizedBox(height: 16),
            if (citaData['estado'] == 'confirmada')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('citas')
                        .doc(citaId)
                        .update({'estado': 'completada'}).then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cita marcada como completada')),
                      );
                    });
                  },
                  child: const Text('Marcar como Completada'),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
