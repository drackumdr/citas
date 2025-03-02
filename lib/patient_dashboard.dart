import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    PatientHomeScreen(),
    MyAppointmentsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paciente"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar doctor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DoctorSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PatientHomeScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hola, ${user?.displayName ?? 'Paciente'}",
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                  user?.photoURL ?? 'https://via.placeholder.com/150')),
          const SizedBox(height: 20),
          const Text("Próxima Cita:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('citas')
                .where('pacienteId', isEqualTo: user?.uid)
                .where('estado', isEqualTo: 'confirmada')
                .orderBy('fecha')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              var citas = snapshot.data!.docs;
              if (citas.isEmpty) {
                return const Text("No tienes citas programadas.");
              }
              var cita = citas[0];

              return Card(
                child: ListTile(
                  title: Text("Doctor: ${cita['doctorNombre']}"),
                  subtitle: Text("Fecha: ${cita['fecha']}"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MyAppointmentsScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('citas')
          .where('pacienteId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        var citas = snapshot.data!.docs;
        return ListView.builder(
          itemCount: citas.length,
          itemBuilder: (context, index) {
            var cita = citas[index];
            return Card(
              child: ListTile(
                title: Text("Doctor: ${cita['doctorNombre']}"),
                subtitle: Text("Fecha: ${cita['fecha']}"),
                trailing: cita['estado'] == 'pendiente'
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('citas')
                              .doc(cita.id)
                              .update({'estado': 'cancelada'});
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    var doc = await _firestore.collection('users').doc(user?.uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['nombre'] ?? user?.displayName ?? '';
        _phoneController.text = doc['telefono'] ?? '';
      });
    }
  }

  void _saveProfile() async {
    await _firestore.collection('users').doc(user?.uid).update({
      'nombre': _nameController.text,
      'telefono': _phoneController.text,
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre")),
          TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Teléfono")),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _saveProfile, child: const Text("Guardar Cambios")),
          ElevatedButton(
              onPressed: _logout,
              child: const Text("Cerrar Sesión",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class DoctorSearchScreen extends StatelessWidget {
  const DoctorSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Doctor")),
      body: const Center(child: Text("Pantalla de búsqueda de doctores")),
    );
  }
}
