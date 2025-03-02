import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String? patientId;

  const PatientHistoryScreen({super.key, this.patientId});

  @override
  _PatientHistoryScreenState createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late String _patientId;
  bool _isCurrentUserPatient = false;
  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _patientId = widget.patientId ?? _currentUser!.uid;
    _isCurrentUserPatient = _patientId == _currentUser!.uid;
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      DocumentSnapshot patientDoc =
          await _firestore.collection('usuarios').doc(_patientId).get();

      if (patientDoc.exists) {
        setState(() {
          _patientName = patientDoc['nombre'] ?? 'Paciente';
        });
      }
    } catch (e) {
      print('Error loading patient data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Historial Médico${_isCurrentUserPatient ? '' : ' - $_patientName'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Consultas'),
            Tab(text: 'Medicamentos'),
            Tab(text: 'Documentos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar Historial',
            onPressed: _generatePdf,
          ),
          if (!_isCurrentUserPatient && _currentUser!.uid != _patientId)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir Historial',
              onPressed: () => _shareHistory(context),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConsultasTab(),
          _buildMedicamentosTab(),
          _buildDocumentosTab(),
        ],
      ),
      floatingActionButton: _isCurrentUserPatient
          ? null
          : FloatingActionButton(
              onPressed: () => _addNewRecord(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  // Building the Consultas tab
  Widget _buildConsultasTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('historiales')
          .doc(_patientId)
          .collection('consultas')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay consultas registradas'));
        }

        var consultas = snapshot.data!.docs;

        return ListView.builder(
          itemCount: consultas.length,
          itemBuilder: (context, index) {
            var consulta = consultas[index].data() as Map<String, dynamic>;
            DateTime fecha = (consulta['fecha'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Consulta: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
                    Text('Dr. ${consulta['doctorNombre']}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (consulta['diagnostico'] != null)
                      Text('Diagnóstico: ${consulta['diagnostico']}'),
                    if (consulta['tratamiento'] != null)
                      Text('Tratamiento: ${consulta['tratamiento']}'),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _showConsultaDetails(context, consulta),
              ),
            );
          },
        );
      },
    );
  }

  // Building the Medicamentos tab
  Widget _buildMedicamentosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('historiales')
          .doc(_patientId)
          .collection('medicamentos')
          .orderBy('fechaInicio', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay medicamentos registrados'));
        }

        var medicamentos = snapshot.data!.docs;

        return ListView.builder(
          itemCount: medicamentos.length,
          itemBuilder: (context, index) {
            var medicamento =
                medicamentos[index].data() as Map<String, dynamic>;
            bool activo = medicamento['activo'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.medication,
                  color: activo ? Colors.green : Colors.grey,
                ),
                title: Text(medicamento['nombre'] ?? 'Sin nombre'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosis: ${medicamento['dosis']}'),
                    Text('Frecuencia: ${medicamento['frecuencia']}'),
                    Text(
                      activo
                          ? 'Tratamiento en curso'
                          : 'Tratamiento finalizado',
                      style: TextStyle(
                        color: activo ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  // Building the Documentos tab
  Widget _buildDocumentosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('historiales')
          .doc(_patientId)
          .collection('documentos')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay documentos registrados'));
        }

        var documentos = snapshot.data!.docs;

        return ListView.builder(
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            var documento = documentos[index].data() as Map<String, dynamic>;
            DateTime fecha = (documento['fecha'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(documento['nombre'] ?? 'Documento sin nombre'),
                subtitle:
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _openDocumentUrl(documento['url']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => _downloadDocument(
                          documento['url'], documento['nombre']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show consultation details in a dialog
  void _showConsultaDetails(
      BuildContext context, Map<String, dynamic> consulta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Consulta del ${DateFormat('dd/MM/yyyy').format((consulta['fecha'] as Timestamp).toDate())}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Doctor: ${consulta['doctorNombre']}'),
              const SizedBox(height: 8),
              Text('Motivo: ${consulta['motivo'] ?? 'No especificado'}'),
              const Divider(),
              if (consulta['diagnostico'] != null) ...[
                const Text('Diagnóstico:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(consulta['diagnostico']),
                const SizedBox(height: 8),
              ],
              if (consulta['tratamiento'] != null) ...[
                const Text('Tratamiento:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(consulta['tratamiento']),
                const SizedBox(height: 8),
              ],
              if (consulta['observaciones'] != null) ...[
                const Text('Observaciones:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(consulta['observaciones']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Open document URL
  void _openDocumentUrl(String url) async {
    // Implement document viewing logic
  }

  // Download document
  void _downloadDocument(String url, String name) async {
    // Implement document download logic
  }

  // Add new medical record
  void _addNewRecord(BuildContext context) {
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
              'Agregar al Historial Médico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Consulta Médica'),
              onTap: () {
                Navigator.pop(context);
                _addConsulta(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Medicamento'),
              onTap: () {
                Navigator.pop(context);
                _addMedicamento(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Subir Documento'),
              onTap: () {
                Navigator.pop(context);
                _addDocumento(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add a consultation record
  void _addConsulta(BuildContext context) {
    // Implement consultation addition logic
  }

  // Add a medication record
  void _addMedicamento(BuildContext context) {
    // Implement medication addition logic
  }

  // Add a document record
  void _addDocumento(BuildContext context) {
    // Implement document addition logic
  }

  // Generate PDF report of medical history
  Future<void> _generatePdf() async {
    // Implement PDF generation logic using the pdf package
  }

  // Share history with another doctor
  void _shareHistory(BuildContext context) {
    // Implement history sharing logic
  }
}
