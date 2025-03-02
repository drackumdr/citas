import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});

  @override
  _HorarioScreenState createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, List<String>> _horarios = {};

  // Días de la semana
  final List<String> _dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  // Horas disponibles para seleccionar
  final List<String> _horasDisponibles = [
    '8:00 AM',
    '8:30 AM',
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '1:00 PM',
    '1:30 PM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
    '5:00 PM',
    '5:30 PM',
    '6:00 PM',
    '6:30 PM',
    '7:00 PM',
    '7:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(userId).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('horario')) {
          Map<String, dynamic> horarioData = data['horario'];
          Map<String, List<String>> horarios = {};

          // Convertir a Map<String, List<String>>
          horarioData.forEach((key, value) {
            if (value is List) {
              horarios[key] = List<String>.from(value);
            } else {
              horarios[key] = [];
            }
          });

          setState(() {
            _horarios = horarios;
            _isLoading = false;
          });
        } else {
          // Inicializar horario vacío para cada día
          Map<String, List<String>> horarios = {};
          for (String dia in _dias) {
            horarios[dia] = [];
          }

          setState(() {
            _horarios = horarios;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading schedule: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar horarios: $e')),
      );
    }
  }

  Future<void> _guardarHorarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;

      // Convertir _horarios a Map<String, dynamic> para Firestore
      Map<String, dynamic> horarioData = {};
      _horarios.forEach((key, value) {
        horarioData[key] = value;
      });

      await _firestore.collection('usuarios').doc(userId).update({
        'horario': horarioData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horarios actualizados correctamente')));

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context); // Volver a la pantalla anterior
    } catch (e) {
      print('Error saving schedule: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar horarios: $e')));
    }
  }

  void _toggleHorario(String dia, String hora) {
    setState(() {
      if (_horarios[dia]!.contains(hora)) {
        _horarios[dia]!.remove(hora);
      } else {
        _horarios[dia]!.add(hora);
        _horarios[dia]!.sort(); // Mantener ordenadas las horas
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurar Horarios')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Horarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarHorarios,
            tooltip: 'Guardar horarios',
          ),
        ],
      ),
      body: _buildDaysList(),
    );
  }

  Widget _buildDaysList() {
    return ListView.builder(
      itemCount: _dias.length,
      itemBuilder: (context, index) {
        String dia = _dias[index];
        String diaCapitalizado = dia[0].toUpperCase() + dia.substring(1);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              diaCapitalizado,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _horarios[dia]!.isEmpty
                  ? 'No disponible'
                  : '${_horarios[dia]!.length} horarios seleccionados',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _horasDisponibles
                      .map((hora) => _buildHoraChip(dia, hora))
                      .toList(),
                ),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check_box_outline_blank),
                    label: const Text('Deseleccionar Todo'),
                    onPressed: () {
                      setState(() {
                        _horarios[dia] = [];
                      });
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.check_box),
                    label: const Text('Seleccionar Todo'),
                    onPressed: () {
                      setState(() {
                        _horarios[dia] = List<String>.from(_horasDisponibles);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoraChip(String dia, String hora) {
    final isSelected = _horarios[dia]!.contains(hora);

    return FilterChip(
      selectedColor: Colors.blue.shade100,
      backgroundColor: Colors.grey.shade200,
      checkmarkColor: Colors.blue,
      label: Text(hora),
      selected: isSelected,
      onSelected: (_) => _toggleHorario(dia, hora),
    );
  }
}

// Segunda pantalla requerida para el perfil del doctor
class PerfilEditorScreen extends StatefulWidget {
  const PerfilEditorScreen({super.key});

  @override
  _PerfilEditorScreenState createState() => _PerfilEditorScreenState();
}

class _PerfilEditorScreenState extends State<PerfilEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _savingChanges = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();

  File? _photoFile;
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(userId).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _especialidadController.text = data['especialidad'] ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _direccionController.text = data['direccion'] ?? '';
          _biografiaController.text = data['biografia'] ?? '';
          _photoUrl = data['foto'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _photoFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')));
    }
  }

  Future<String?> _uploadImage() async {
    if (_photoFile == null) return null;

    try {
      String fileName =
          'doctor_profiles/${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child(fileName);

      await ref.putFile(_photoFile!);
      String downloadURL = await ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _savingChanges = true;
    });

    try {
      String userId = _auth.currentUser!.uid;
      Map<String, dynamic> updateData = {
        'nombre': _nombreController.text,
        'especialidad': _especialidadController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'biografia': _biografiaController.text,
      };

      // Si se seleccionó una nueva imagen, la subimos y actualizamos URL
      if (_photoFile != null) {
        String? newPhotoUrl = await _uploadImage();
        if (newPhotoUrl != null) {
          updateData['foto'] = newPhotoUrl;
        }
      }

      await _firestore.collection('usuarios').doc(userId).update(updateData);

      setState(() {
        _savingChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')));

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _savingChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savingChanges ? null : _saveProfile,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: _savingChanges
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Photo upload
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _photoFile != null
                        ? FileImage(_photoFile!) as ImageProvider
                        : (_photoUrl.isNotEmpty
                            ? NetworkImage(_photoUrl)
                            : const AssetImage('assets/default_doctor.png')
                                as ImageProvider),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form fields
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Este campo es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _especialidadController,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Este campo es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección del Consultorio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _biografiaController,
              decoration: const InputDecoration(
                labelText: 'Biografía Profesional',
                border: OutlineInputBorder(),
                hintText: 'Describe tu experiencia y formación...',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
