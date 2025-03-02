import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? doctorId;

  const BookAppointmentScreen({super.key, this.doctorId});

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? selectedDoctor;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If a doctorId is passed to the widget, use it
    selectedDoctor = widget.doctorId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agendar Cita")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only show doctor selector if no doctor was pre-selected
              if (widget.doctorId == null) ...[
                const Text("Selecciona un Doctor",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildDoctorDropdown(),
                const SizedBox(height: 20),
              ] else ...[
                _buildDoctorInfo(),
                const SizedBox(height: 20),
              ],

              const Text("Selecciona Fecha",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildDatePicker(),
              const SizedBox(height: 20),

              const Text("Selecciona Hora",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTimePicker(),
              const SizedBox(height: 20),

              const Text("Motivo de la Consulta (opcional)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  hintText: "Describa brevemente el motivo de su consulta",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _bookAppointment,
                  child: const Text("Confirmar Cita"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Display information about the selected doctor
  Widget _buildDoctorInfo() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.doctorId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text("Error al cargar información del doctor");
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("No se encontró información del doctor");
        }

        var doctorData = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                  doctorData['foto'] ?? 'https://via.placeholder.com/150'),
            ),
            title: Text("Dr. ${doctorData['nombre'] ?? 'No disponible'}"),
            subtitle: Text(
                doctorData['especialidad'] ?? 'Especialidad no especificada'),
          ),
        );
      },
    );
  }

  /// 🔹 Muestra la lista de doctores disponibles en Firestore
  Widget _buildDoctorDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'doctor')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        var doctors = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          items: doctors.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(data['nombre'] ?? 'Doctor sin nombre'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedDoctor = value;
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      },
    );
  }

  /// 🔹 Selector de Fecha
  Widget _buildDatePicker() {
    return ListTile(
      title: Text("${selectedDate.toLocal()}".split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
    );
  }

  /// 🔹 Selector de Hora
  Widget _buildTimePicker() {
    return ListTile(
      title: Text(selectedTime.format(context)),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) {
          setState(() {
            selectedTime = picked;
          });
        }
      },
    );
  }

  /// 🔹 Guarda la cita en Firestore
  void _bookAppointment() async {
    if (selectedDoctor == null && widget.doctorId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Selecciona un doctor")));
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no autenticado")),
      );
      return;
    }

    String finalDoctorId = selectedDoctor ?? widget.doctorId!;

    // Fetch doctor information
    DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(finalDoctorId)
        .get();

    if (!doctorDoc.exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Doctor no encontrado")));
      return;
    }

    var doctorData = doctorDoc.data() as Map<String, dynamic>;
    String doctorName = doctorData['nombre'] ?? 'Doctor';

    DateTime fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Format the time for display
    final hour = selectedTime.hour.toString().padLeft(2, '0');
    final minute = selectedTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    await FirebaseFirestore.instance.collection('citas').add({
      'pacienteId': user.uid,
      'pacienteNombre': user.displayName ?? 'Paciente',
      'doctorId': finalDoctorId,
      'doctorNombre': doctorName,
      'fecha': Timestamp.fromDate(fullDateTime),
      'hora': formattedTime,
      'motivoConsulta': _motivoController.text.trim(),
      'estado': 'pendiente',
      'fechaCreacion': Timestamp.now(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Cita agendada con éxito")));
    Navigator.pop(context);
  }
}
