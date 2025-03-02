import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentDashboard extends StatefulWidget {
  const PaymentDashboard({super.key});

  @override
  _PaymentDashboardState createState() => _PaymentDashboardState();
}

class _PaymentDashboardState extends State<PaymentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: "Pagos Recientes"),
              Tab(text: "Suscripciones"),
              Tab(text: "Doctores Morosos"),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentPaymentsTab(),
                _buildSubscriptionsTab(),
                _buildOverdueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Recent payments tab
  Widget _buildRecentPaymentsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pagos')
          .orderBy('fecha', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay pagos recientes'));
        }

        var payments = snapshot.data!.docs;
        double totalAmount = 0;

        // Calculate total
        for (var payment in payments) {
          var data = payment.data() as Map<String, dynamic>;
          totalAmount += (data['monto'] as num).toDouble();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de Ingresos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total de pagos:'),
                          Text('${payments.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ingresos totales:'),
                          Text(
                            currencyFormat.format(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Pagos Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // List of payments
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    var payment =
                        payments[index].data() as Map<String, dynamic>;
                    DateTime date = (payment['fecha'] as Timestamp).toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy HH:mm').format(date);
                    double amount = (payment['monto'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.attach_money),
                        ),
                        title: Text(payment['concepto'] ?? 'Pago de membresía'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Doctor: ${payment['doctorNombre'] ?? 'No especificado'}'),
                            Text('Fecha: $formattedDate'),
                          ],
                        ),
                        trailing: Text(
                          currencyFormat.format(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => _showPaymentDetails(context, payment),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Active subscriptions tab
  Widget _buildSubscriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'doctor')
          .where('suscripcion.activa', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay doctores con suscripciones activas'));
        }

        var doctors = snapshot.data!.docs;

        // Count by subscription type
        int monthlyCount = 0;
        int yearlyCount = 0;

        for (var doctor in doctors) {
          var data = doctor.data() as Map<String, dynamic>;
          String type = data['suscripcion']['tipo'] ?? 'Mensual';

          if (type == 'Anual') {
            yearlyCount++;
          } else {
            monthlyCount++;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSubscriptionCard(
                      'Suscripciones Mensuales',
                      monthlyCount,
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSubscriptionCard(
                      'Suscripciones Anuales',
                      yearlyCount,
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Doctores con Suscripción Activa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // List of subscribed doctors
              Expanded(
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    var doctor = doctors[index].data() as Map<String, dynamic>;

                    String tipo = doctor['suscripcion']['tipo'] ?? 'Mensual';
                    DateTime fechaVencimiento =
                        (doctor['suscripcion']['fechaVencimiento'] as Timestamp)
                            .toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy').format(fechaVencimiento);

                    bool isExpiringSoon =
                        fechaVencimiento.difference(DateTime.now()).inDays < 7;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(doctor['foto'] ??
                              'https://via.placeholder.com/150'),
                        ),
                        title: Text(doctor['nombre'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Plan: $tipo'),
                            Row(
                              children: [
                                Text('Vence: $formattedDate'),
                                if (isExpiringSoon) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.warning,
                                      color: Colors.orange, size: 16),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _sendReminderEmail(doctor),
                          child: const Text('Recordar'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Overdue subscriptions tab
  Widget _buildOverdueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'doctor')
          .where('suscripcion.activa', isEqualTo: false)
          .where('suscripcion.fechaVencimiento',
              isLessThan: Timestamp.fromDate(DateTime.now()))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No hay doctores con suscripciones vencidas'));
        }

        var overdueUsers = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctores con Suscripciones Vencidas: ${overdueUsers.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                                'Estos doctores no pueden recibir citas nuevas hasta renovar su suscripción.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: overdueUsers.length,
                  itemBuilder: (context, index) {
                    var doctor =
                        overdueUsers[index].data() as Map<String, dynamic>;
                    DateTime fechaVencimiento =
                        (doctor['suscripcion']['fechaVencimiento'] as Timestamp)
                            .toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy').format(fechaVencimiento);
                    int diasVencido =
                        DateTime.now().difference(fechaVencimiento).inDays;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(doctor['foto'] ??
                              'https://via.placeholder.com/150'),
                        ),
                        title: Text(doctor['nombre'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Venció el: $formattedDate'),
                            Text(
                              'Días vencido: $diasVencido',
                              style: TextStyle(
                                color: diasVencido > 30
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.email),
                              tooltip: 'Enviar recordatorio',
                              onPressed: () => _sendReminderEmail(doctor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone),
                              tooltip: 'Llamar',
                              onPressed: () => _callDoctor(doctor),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to show payment details in a dialog
  void _showPaymentDetails(BuildContext context, Map<String, dynamic> payment) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    DateTime date = (payment['fecha'] as Timestamp).toDate();
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    double amount = (payment['monto'] as num).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle del Pago'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Concepto', payment['concepto'] ?? 'Pago de membresía'),
              _buildDetailRow(
                  'Doctor', payment['doctorNombre'] ?? 'No especificado'),
              _buildDetailRow('Fecha', formattedDate),
              _buildDetailRow('Monto', currencyFormat.format(amount)),
              _buildDetailRow(
                  'Método de Pago', payment['metodoPago'] ?? 'No especificado'),
              _buildDetailRow('ID Transacción',
                  payment['transaccionId'] ?? 'No disponible'),
              if (payment['estado'] != null)
                _buildDetailRow('Estado', payment['estado']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => _downloadInvoice(payment),
            child: const Text('Descargar Factura'),
          ),
        ],
      ),
    );
  }

  // Helper method to build detail rows for the payment dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  // Build summary card for subscriptions tab
  Widget _buildSubscriptionCard(
      String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to send reminder email
  void _sendReminderEmail(Map<String, dynamic> doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recordatorio enviado a ${doctor['nombre']}'),
      ),
    );

    // Here you would implement the actual email sending logic,
    // typically via a cloud function or backend service
  }

  // Helper method to initiate a call
  void _callDoctor(Map<String, dynamic> doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Llamando a ${doctor['nombre']}...'),
      ),
    );

    // Here you would implement the actual call logic,
    // typically launching the phone app with the doctor's number
  }

  // Helper method to download an invoice
  void _downloadInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Descargando factura...'),
      ),
    );

    // Here you would implement the actual invoice download logic,
    // typically generating a PDF and saving it to the device
  }
}
