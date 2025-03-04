import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_list.dart';
import 'admin_stats.dart';
import 'payment_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const UserListScreen(),
    const AdminStatsScreen(),
    const PaymentDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          CircleAvatar(
            backgroundImage: const AssetImage('assets/admin_avatar.png'),
            backgroundColor: Colors.grey[200],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/admin_avatar.png'),
                    radius: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Inicio'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gestión de Usuarios'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Estadísticas'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pagos y Suscripciones'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Pagos',
          ),
        ],
      ),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Sistema',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatCards(context),
          const SizedBox(height: 20),
          _buildDoctorsWithExpiringSubs(context),
          const SizedBox(height: 20),
          _buildRecentActivities(context),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar datos'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalUsers = snapshot.data!.docs.length;
        int doctors =
            snapshot.data!.docs.where((doc) => doc['rol'] == 'doctor').length;
        int patients =
            snapshot.data!.docs.where((doc) => doc['rol'] == 'paciente').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Total Usuarios', totalUsers.toString(),
                Icons.people, Colors.blue),
            _buildStatCard('Doctores', doctors.toString(),
                Icons.medical_services, Colors.green),
            _buildStatCard(
                'Pacientes', patients.toString(), Icons.person, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsWithExpiringSubs(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suscripciones Próximas a Vencer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.warning, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'doctor')
                  .where('suscripcion.fechaVencimiento',
                      isLessThan: Timestamp.fromDate(
                          DateTime.now().add(const Duration(days: 7))))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                        'No hay doctores con suscripciones próximas a vencer'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doctor = docs[index];
                    var fechaVencimiento =
                        doctor['suscripcion']['fechaVencimiento'] as Timestamp;
                    return ListTile(
                      title: Text(doctor['nombre']),
                      subtitle: Text(
                          'Vence: ${_formatDate(fechaVencimiento.toDate())}'),
                      trailing: ElevatedButton(
                        child: const Text('Notificar'),
                        onPressed: () {
                          // Implementar notificación al doctor
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividades Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('citas')
                  .orderBy('fecha', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var citas = snapshot.data!.docs;
                if (citas.isEmpty) {
                  return const Text('No hay actividades recientes');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    var cita = citas[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(_getIconForActivity(cita['estado']),
                          color: _getColorForActivity(cita['estado'])),
                      title: Text(
                          '${cita['pacienteNombre']} - ${cita['doctorNombre']}'),
                      subtitle: Text(
                          '${_formatDate((cita['fecha'] as Timestamp).toDate())} - ${cita['estado']}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForActivity(String status) {
    switch (status) {
      case 'confirmada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      case 'pendiente':
        return Icons.schedule;
      case 'completada':
        return Icons.done_all;
      default:
        return Icons.event;
    }
  }

  Color _getColorForActivity(String status) {
    switch (status) {
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      case 'completada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
