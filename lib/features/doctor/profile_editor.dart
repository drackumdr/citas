import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DoctorProfileEditor extends StatefulWidget {
  const DoctorProfileEditor({super.key});

  @override
  _DoctorProfileEditorState createState() => _DoctorProfileEditorState();
}

class _DoctorProfileEditorState extends State<DoctorProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _educacionController = TextEditingController();

  List<String> _educacionList = [];
  File? _selectedImage;
  bool _loading = true;
  String _currentImageUrl = '';
  bool _usernameChecking = false;
  bool _usernameAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    if (_user == null) return;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(_user!.uid).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _especialidadController.text = data['especialidad'] ?? '';
          _biografiaController.text = data['biografia'] ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _direccionController.text = data['direccion'] ?? '';
          _nombreUsuarioController.text = data['nombreUsuario'] ?? '';
          _currentImageUrl = data['foto'] ?? '';

          if (data['educacion'] != null) {
            _educacionList = List<String>.from(data['educacion']);
          }

          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _currentImageUrl;

    try {
      String fileName =
          'doctor_profiles/${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child(fileName);

      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e')),
      );
      return null;
    }
  }

  Future<void> _checkUsernameAvailability() async {
    String username = _nombreUsuarioController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _usernameChecking = true;
    });

    try {
      QuerySnapshot query = await _firestore
          .collection('usuarios')
          .where('nombreUsuario', isEqualTo: username)
          .where(FieldPath.documentId, isNotEqualTo: _user!.uid)
          .get();

      setState(() {
        _usernameChecking = false;
        _usernameAvailable = query.docs.isEmpty;
      });
    } catch (e) {
      setState(() {
        _usernameChecking = false;
      });
    }
  }

  void _addEducation() {
    String education = _educacionController.text.trim();
    if (education.isEmpty) return;

    setState(() {
      _educacionList.add(education);
      _educacionController.clear();
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _educacionList.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nombreUsuarioController.text.isNotEmpty && !_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre de usuario no disponible')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      String? imageUrl = await _uploadImage();

      await _firestore.collection('usuarios').doc(_user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'especialidad': _especialidadController.text.trim(),
        'biografia': _biografiaController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'nombreUsuario': _nombreUsuarioController.text.trim(),
        'educacion': _educacionList,
        if (imageUrl != null) 'foto': imageUrl,
        'perfilCompletado': true,
      });

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Profesional'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de perfil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (_currentImageUrl.isNotEmpty
                              ? NetworkImage(_currentImageUrl)
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
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Datos personales
              const Text(
                'Información Personal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _especialidadController,
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu especialidad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _biografiaController,
                decoration: const InputDecoration(
                  labelText: 'Biografía Profesional',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una biografía';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Educación
              const Text(
                'Educación y Credenciales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _educacionController,
                      decoration: const InputDecoration(
                        labelText: 'Título o Certificación',
                        hintText: 'Ej: Medicina General, Universidad...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addEducation,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de educación
              ..._educacionList.asMap().entries.map((entry) {
                int idx = entry.key;
                String edu = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(edu),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeEducation(idx),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Información de contacto
              const Text(
                'Información de Contacto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  labelText: 'Dirección Consultorio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Configuración de página pública
              const Text(
                'Configuración de Página Web',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreUsuarioController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  hintText: 'Su URL será: thundershield.tech/dr-username',
                  border: const OutlineInputBorder(),
                  prefixText: 'dr-',
                  suffixIcon: _usernameChecking
                      ? const CircularProgressIndicator()
                      : _nombreUsuarioController.text.isNotEmpty
                          ? Icon(
                              _usernameAvailable
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _usernameAvailable
                                  ? Colors.green
                                  : Colors.red,
                            )
                          : null,
                ),
                onChanged: (value) {
                  if (value.length > 3) {
                    _checkUsernameAvailability();
                  }
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
