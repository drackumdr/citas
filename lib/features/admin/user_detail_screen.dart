import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String _currentRole = 'paciente';
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(widget.userId).get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _nombreController.text = _userData?['nombre'] ?? '';
          _emailController.text = _userData?['email'] ?? '';
          _telefonoController.text = _userData?['telefono'] ?? '';
          _currentRole = _userData?['rol'] ?? 'paciente';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no encontrado')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('usuarios').doc(widget.userId).update({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'rol': _currentRole,
      });

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
            '¿Estás seguro de querer eliminar al usuario ${_nombreController.text}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _deleteUser,
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you'd also delete the Auth account or disable it
      await _firestore.collection('usuarios').doc(widget.userId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );

      Navigator.pop(context); // Go back to user list
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalles de Usuario')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Usuario'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    _userData?['foto'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User ID
              _buildDetailField('ID de Usuario', widget.userId),
              const SizedBox(height: 16),

              // Editable fields
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: _isEditing
                      ? const OutlineInputBorder()
                      : InputBorder.none,
                  enabled: _isEditing,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: _isEditing
                      ? const OutlineInputBorder()
                      : InputBorder.none,
                  enabled: _isEditing,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un email';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingrese un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: _isEditing
                      ? const OutlineInputBorder()
                      : InputBorder.none,
                  enabled: _isEditing,
                ),
              ),
              const SizedBox(height: 16),

              // Role selection
              if (_isEditing) ...[
                const Text(
                  'Rol del Usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRoleSelector(),
              ] else
                _buildDetailField('Rol', _currentRole),

              const SizedBox(height: 24),

              // Account information
              const Text(
                'Información de Cuenta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildDetailField(
                  'Fecha de Registro',
                  _userData?['fechaRegistro'] != null
                      ? _formatTimestamp(
                          _userData!['fechaRegistro'] as Timestamp)
                      : 'No disponible'),

              const SizedBox(height: 16),

              // Additional sections for doctor or patient
              if (_currentRole == 'doctor') _buildDoctorSection(),

              if (_currentRole == 'paciente') _buildPatientSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('Paciente'),
              value: 'paciente',
              groupValue: _currentRole,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _currentRole = value;
                  });
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Doctor'),
              value: 'doctor',
              groupValue: _currentRole,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _currentRole = value;
                  });
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Administrador'),
              value: 'admin',
              groupValue: _currentRole,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _currentRole = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Doctor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildDetailField(
            'Especialidad', _userData?['especialidad'] ?? 'No especificada'),

        const SizedBox(height: 8),

        // Check subscription status
        FutureBuilder<Map<String, dynamic>>(
          future: _loadDoctorSubscription(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            var subData = snapshot.data!;

            return Card(
              color: subData['activa'] ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          subData['activa'] ? Icons.check_circle : Icons.cancel,
                          color: subData['activa'] ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suscripción ${subData['activa'] ? 'Activa' : 'Inactiva'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (subData['tipo'] != null)
                      Text('Plan: ${subData['tipo']}'),
                    if (subData['fechaVencimiento'] != null)
                      Text('Vence el: ${subData['fechaVencimiento']}'),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Show appointment statistics
        FutureBuilder<Map<String, int>>(
          future: _loadDoctorStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            var stats = snapshot.data!;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Citas Totales', stats['total'].toString()),
                _buildStatCard('Completadas', stats['completadas'].toString()),
                _buildStatCard('Canceladas', stats['canceladas'].toString()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPatientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Paciente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Show appointment history
        FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('citas')
              .where('pacienteId', isEqualTo: widget.userId)
              .orderBy('fecha', descending: true)
              .limit(5)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay citas registradas'),
                ),
              );
            }

            var citas = snapshot.data!.docs;

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Últimas Citas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ...citas.map((cita) {
                    var data = cita.data() as Map<String, dynamic>;
                    DateTime fecha = (data['fecha'] as Timestamp).toDate();

                    return ListTile(
                      title: Text(
                          'Dr. ${data['doctorNombre'] ?? 'No especificado'}'),
                      subtitle: Text(_formatDate(fecha)),
                      trailing: Chip(
                        label: Text(data['estado'] ?? 'pendiente'),
                        backgroundColor: _getStatusColor(data['estado']),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadDoctorSubscription() async {
    if (_userData == null || !_userData!.containsKey('suscripcion')) {
      return {
        'activa': false,
      };
    }

    Map<String, dynamic> suscripcion = _userData!['suscripcion'];

    String fechaStr = 'No disponible';
    if (suscripcion['fechaVencimiento'] != null) {
      Timestamp ts = suscripcion['fechaVencimiento'];
      fechaStr = _formatDate(ts.toDate());
    }

    return {
      'activa': suscripcion['activa'] ?? false,
      'tipo': suscripcion['tipo'] ?? 'No especificado',
      'fechaVencimiento': fechaStr,
    };
  }

  Future<Map<String, int>> _loadDoctorStats() async {
    QuerySnapshot citas = await _firestore
        .collection('citas')
        .where('doctorId', isEqualTo: widget.userId)
        .get();

    int total = citas.docs.length;
    int completadas = citas.docs.where((doc) {
      return (doc.data() as Map<String, dynamic>)['estado'] == 'completada';
    }).length;
    int canceladas = citas.docs.where((doc) {
      var estado = (doc.data() as Map<String, dynamic>)['estado'];
      return estado == 'cancelada' || estado == 'rechazada';
    }).length;

    return {
      'total': total,
      'completadas': completadas,
      'canceladas': canceladas,
    };
  }

  String _formatTimestamp(Timestamp timestamp) {
    return _formatDate(timestamp.toDate());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      case 'rechazada':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
