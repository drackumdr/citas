import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorPaymentScreen extends StatefulWidget {
  const DoctorPaymentScreen({super.key});

  @override
  _DoctorPaymentScreenState createState() => _DoctorPaymentScreenState();
}

class _DoctorPaymentScreenState extends State<DoctorPaymentScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membresía y Facturación'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('usuarios').doc(_user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('No se encontró la información del usuario'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          bool hasSuscription = userData.containsKey('suscripcion');
          bool isActive =
              hasSuscription && userData['suscripcion']['activa'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubscriptionStatus(isActive, userData),
                const SizedBox(height: 24),
                _buildSubscriptionOptions(isActive),
                const SizedBox(height: 24),
                const Text(
                  'Historial de Facturación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInvoiceHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionStatus(
      bool isActive, Map<String, dynamic> userData) {
    if (!isActive) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'No tienes una suscripción activa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Activa tu membresía para acceder a todas las funciones de doctor y ser visible para los pacientes.',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _goToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Activar membresía'),
              ),
            ],
          ),
        ),
      );
    }

    // Subscription is active
    Timestamp? expiryDate = userData['suscripcion']['fechaVencimiento'];
    String planType = userData['suscripcion']['tipo'] ?? 'Mensual';

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Membresía Activa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Plan: $planType'),
            if (expiryDate != null)
              Text(
                'Válido hasta: ${DateFormat('dd/MM/yyyy').format(expiryDate.toDate())}',
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _managePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gestionar plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionOptions(bool isActive) {
    String title = isActive ? 'Cambiar Plan' : 'Seleccionar Plan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          title: 'Plan Mensual',
          price: '99.00',
          period: 'mes',
          features: [
            'Perfil personalizado',
            'Gestión de citas ilimitadas',
            'Notificaciones a pacientes',
            'Historial médico integrado',
          ],
          isRecommended: false,
          onTap: () => _selectPlan('Mensual'),
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          title: 'Plan Anual',
          price: '990.00',
          period: 'año',
          features: [
            'Ahorra 2 meses con pago anual',
            'Perfil personalizado',
            'Gestión de citas ilimitadas',
            'Notificaciones a pacientes',
            'Historial médico integrado',
            'Prioridad en soporte técnico',
          ],
          isRecommended: true,
          onTap: () => _selectPlan('Anual'),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isRecommended ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Recomendado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$$price',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('por $period'),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRecommended ? Colors.blue.shade700 : null,
                    foregroundColor: isRecommended ? Colors.white : null,
                  ),
                  child: Text(isRecommended
                      ? 'Seleccionar Plan Anual'
                      : 'Seleccionar Plan Mensual'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pagos')
          .where('usuarioId', isEqualTo: _user?.uid)
          .orderBy('fecha', descending: true)
          .limit(10)
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
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay historial de pagos disponible'),
            ),
          );
        }

        var pagos = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pagos.length,
          itemBuilder: (context, index) {
            var pago = pagos[index].data() as Map<String, dynamic>;
            DateTime fecha = (pago['fecha'] as Timestamp).toDate();
            String formattedDate = DateFormat('dd/MM/yyyy').format(fecha);
            double monto = (pago['monto'] as num).toDouble();
            String concepto = pago['concepto'] ?? 'Membresía';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.receipt),
                title: Text('Factura #${pago['numeroFactura'] ?? ''}'),
                subtitle: Text('$concepto - $formattedDate'),
                trailing: Text(
                  _currencyFormat.format(monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _downloadInvoice(pago),
              ),
            );
          },
        );
      },
    );
  }

  void _goToPayment() {
    // Implement payment flow
  }

  void _managePlan() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gestionar Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Cambiar plan'),
              onTap: () {
                Navigator.pop(context);
                // Show plan options
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Actualizar método de pago'),
              onTap: () {
                Navigator.pop(context);
                // Show payment method update
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text(
                'Cancelar suscripción',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlan(String planType) {
    // Implement plan selection
  }

  void _downloadInvoice(Map<String, dynamic> invoice) {
    // Implement invoice download
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar tu suscripción? Perderás acceso a todas las funciones premium cuando finalice tu período actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Atrás'),
          ),
          TextButton(
            onPressed: () {
              // Implement subscription cancellation
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar suscripción',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
