import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book_apointment.dart';

class DoctorPublicProfile extends StatelessWidget {
  final String username;

  const DoctorPublicProfile({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. $username'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .where('nombreUsuario', isEqualTo: username)
            .where('rol', isEqualTo: 'doctor')
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No se encontró el doctor'));
          }

          var doctorData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          String doctorId = snapshot.data!.docs.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorHeader(doctorData),
                const SizedBox(height: 24),
                _buildDoctorInfo(doctorData),
                const SizedBox(height: 24),
                _buildScheduleSection(context, doctorData, doctorId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorHeader(Map<String, dynamic> doctorData) {
    return Row(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            doctorData['foto'] ?? 'https://via.placeholder.com/150',
          ),
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. ${doctorData['nombre'] ?? 'Nombre no disponible'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                doctorData['especialidad'] ?? 'Especialidad no especificada',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[700],
                ),
              ),
              if (doctorData['calificacion'] != null)
                Row(
                  children: [
                    ...List.generate(
                      (doctorData['calificacion'] as num).floor(),
                      (index) =>
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                    Text(
                        ' (${doctorData['totalCalificaciones'] ?? 0} reseñas)'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorInfo(Map<String, dynamic> doctorData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acerca del Doctor',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          doctorData['biografia'] ??
              'No hay información disponible sobre este doctor.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (doctorData['educacion'] != null) ...[
          const Text(
            'Educación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(doctorData['educacion'] as List<dynamic>).map(
            (edu) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $edu'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                doctorData['direccion'] ?? 'Dirección no disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (doctorData['telefono'] != null)
          Row(
            children: [
              Icon(Icons.phone, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                doctorData['telefono'],
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildScheduleSection(
      BuildContext context, Map<String, dynamic> doctorData, String doctorId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horarios Disponibles',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAvailabilityCalendar(doctorData),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookAppointmentScreen(doctorId: doctorId),
                ),
              );
            },
            child: const Text(
              'Agendar Cita',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar(Map<String, dynamic> doctorData) {
    var horarios = doctorData['horario'] as Map<String, dynamic>? ?? {};

    if (horarios.isEmpty) {
      return const Center(
        child: Text('Este doctor no tiene horarios configurados.'),
      );
    }

    List<String> dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];

    return Column(
      children: dias.map((dia) {
        List<dynamic> horas = horarios[dia] ?? [];
        if (horas.isEmpty) return Container();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _capitalizeFirstLetter(dia),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: horas
                        .map((hora) => Chip(
                              label: Text(hora),
                              backgroundColor: Colors.blue[100],
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _capitalizeFirstLetter(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
