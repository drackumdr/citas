import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _selectedRole = 'todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildUserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddUserDialog();
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuario...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                _buildFilterChip('Pacientes', 'paciente'),
                _buildFilterChip('Doctores', 'doctor'),
                _buildFilterChip('Administradores', 'admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedRole == role,
        onSelected: (selected) {
          setState(() {
            _selectedRole = selected ? role : 'todos';
          });
        },
      ),
    );
  }

  Widget _buildUserList() {
    Query query = FirebaseFirestore.instance.collection('usuarios');

    // Apply filters
    if (_selectedRole != 'todos') {
      query = query.where('rol', isEqualTo: _selectedRole);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var users = snapshot.data!.docs;

        // Apply search filter in memory
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            var userData = user.data() as Map<String, dynamic>;
            String nombre = userData['nombre'] ?? '';
            String email = userData['email'] ?? '';
            return nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                email.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (users.isEmpty) {
          return const Center(child: Text('No se encontraron usuarios'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      userData['foto'] ?? 'https://via.placeholder.com/150'),
                ),
                title: Text(userData['nombre'] ?? 'Sin nombre'),
                subtitle: Text(userData['email'] ?? ''),
                trailing: _buildRoleChip(userData['rol']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserDetailScreen(userId: users[index].id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleChip(String role) {
    Color chipColor;
    switch (role) {
      case 'admin':
        chipColor = Colors.red;
        break;
      case 'doctor':
        chipColor = Colors.blue;
        break;
      case 'paciente':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        role,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String email = '';
    String rol = 'paciente';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  onSaved: (value) => nombre = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Email inválido'
                      : null,
                  onSaved: (value) => email = value!,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Rol'),
                  value: rol,
                  items: const [
                    DropdownMenuItem(
                        value: 'paciente', child: Text('Paciente')),
                    DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => rol = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Guardar'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                // Aquí se crearía primero el usuario en Authentication
                // y luego se guardaría en Firestore, pero esta es la parte de UI
                FirebaseFirestore.instance.collection('usuarios').add({
                  'nombre': nombre,
                  'email': email,
                  'rol': rol,
                  'fechaRegistro': Timestamp.now(),
                }).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario creado con éxito')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
