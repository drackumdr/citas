import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  _AdminStatsScreenState createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // Filter options
  String _selectedPeriod = 'mes';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period filter
          _buildTimePeriodFilter(),

          const SizedBox(height: 20),

          // Stats cards
          _buildStatsCards(),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Revenue chart
                  _buildRevenueChart(),

                  const SizedBox(height: 20),

                  // User registration chart
                  _buildUserRegistrationChart(),

                  const SizedBox(height: 20),

                  // Appointments chart
                  _buildAppointmentsChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período de tiempo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('Semana', 'semana'),
                _buildFilterChip('Mes', 'mes'),
                _buildFilterChip('Año', 'año'),
                _buildFilterChip('Personalizado', 'custom'),
              ],
            ),
            if (_selectedPeriod == 'custom')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _selectDate(true),
                        icon: const Icon(Icons.calendar_today),
                        label:
                            Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                    const Text(' - '),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _selectDate(false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPeriod == value,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
            _updateDateRange();
          });
        }
      },
    );
  }

  void _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _updateDateRange() {
    DateTime now = DateTime.now();

    switch (_selectedPeriod) {
      case 'semana':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'mes':
        _startDate = DateTime(now.year, now.month - 1, now.day);
        _endDate = now;
        break;
      case 'año':
        _startDate = DateTime(now.year - 1, now.month, now.day);
        _endDate = now;
        break;
      // For 'custom', we don't change the dates here
    }
  }

  Widget _buildStatsCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        var stats = snapshot.data!;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ingresos',
                '\$${stats['revenue'].toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Nuevos Usuarios',
                stats['newUsers'].toString(),
                Icons.person_add,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Citas',
                stats['appointments'].toString(),
                Icons.calendar_today,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return FutureBuilder<List<RevenueStat>>(
      future: _loadRevenueData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text('No hay datos de ingresos disponibles')),
          );
        }

        return SizedBox(
          height: 300,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('dd/MM'),
                        intervalType: DateTimeIntervalType.days,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        numberFormat: NumberFormat.currency(symbol: '\$'),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries>[
                        ColumnSeries<RevenueStat, DateTime>(
                          dataSource: snapshot.data!,
                          xValueMapper: (RevenueStat data, _) => data.date,
                          yValueMapper: (RevenueStat data, _) => data.amount,
                          name: 'Ingresos',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserRegistrationChart() {
    return FutureBuilder<List<UserRegistrationStat>>(
      future: _loadUserRegistrationData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text('No hay datos de registro disponibles')),
          );
        }

        return SizedBox(
          height: 300,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro de Usuarios',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('dd/MM'),
                        intervalType: DateTimeIntervalType.days,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      legend: const Legend(isVisible: true),
                      series: <CartesianSeries>[
                        LineSeries<UserRegistrationStat, DateTime>(
                          dataSource: snapshot.data!,
                          xValueMapper: (UserRegistrationStat data, _) =>
                              data.date,
                          yValueMapper: (UserRegistrationStat data, _) =>
                              data.doctors,
                          name: 'Doctores',
                          color: Colors.blue,
                          markerSettings: const MarkerSettings(isVisible: true),
                        ),
                        LineSeries<UserRegistrationStat, DateTime>(
                          dataSource: snapshot.data!,
                          xValueMapper: (UserRegistrationStat data, _) =>
                              data.date,
                          yValueMapper: (UserRegistrationStat data, _) =>
                              data.patients,
                          name: 'Pacientes',
                          color: Colors.green,
                          markerSettings: const MarkerSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsChart() {
    return FutureBuilder<List<AppointmentStat>>(
      future: _loadAppointmentData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text('No hay datos de citas disponibles')),
          );
        }

        // Calculate totals for pie chart
        int confirmed = 0, canceled = 0, pending = 0, completed = 0;

        for (var stat in snapshot.data!) {
          confirmed += stat.confirmed;
          canceled += stat.canceled;
          pending += stat.pending;
          completed += stat.completed;
        }

        List<AppointmentStatusData> pieData = [
          AppointmentStatusData('Confirmadas', confirmed, Colors.green),
          AppointmentStatusData('Canceladas', canceled, Colors.red),
          AppointmentStatusData('Pendientes', pending, Colors.orange),
          AppointmentStatusData('Completadas', completed, Colors.blue),
        ];

        return SizedBox(
          height: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado de Citas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        // Pie chart
                        Expanded(
                          flex: 1,
                          child: SfCircularChart(
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                            series: <CircularSeries>[
                              PieSeries<AppointmentStatusData, String>(
                                dataSource: pieData,
                                xValueMapper: (AppointmentStatusData data, _) =>
                                    data.status,
                                yValueMapper: (AppointmentStatusData data, _) =>
                                    data.count,
                                pointColorMapper:
                                    (AppointmentStatusData data, _) =>
                                        data.color,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Line chart
                        Expanded(
                          flex: 2,
                          child: SfCartesianChart(
                            primaryXAxis: DateTimeAxis(
                              dateFormat: DateFormat('dd/MM'),
                              intervalType: DateTimeIntervalType.days,
                              majorGridLines: const MajorGridLines(width: 0),
                            ),
                            primaryYAxis: NumericAxis(
                              majorGridLines: const MajorGridLines(width: 0),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            legend: const Legend(isVisible: true),
                            series: <CartesianSeries>[
                              LineSeries<AppointmentStat, DateTime>(
                                dataSource: snapshot.data!,
                                xValueMapper: (AppointmentStat data, _) =>
                                    data.date,
                                yValueMapper: (AppointmentStat data, _) =>
                                    data.confirmed,
                                name: 'Confirmadas',
                                color: Colors.green,
                              ),
                              LineSeries<AppointmentStat, DateTime>(
                                dataSource: snapshot.data!,
                                xValueMapper: (AppointmentStat data, _) =>
                                    data.date,
                                yValueMapper: (AppointmentStat data, _) =>
                                    data.canceled,
                                name: 'Canceladas',
                                color: Colors.red,
                              ),
                              LineSeries<AppointmentStat, DateTime>(
                                dataSource: snapshot.data!,
                                xValueMapper: (AppointmentStat data, _) =>
                                    data.date,
                                yValueMapper: (AppointmentStat data, _) =>
                                    data.pending,
                                name: 'Pendientes',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStatistics() async {
    try {
      QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('citas')
          .where('fecha', isGreaterThanOrEqualTo: _startDate)
          .where('fecha', isLessThanOrEqualTo: _endDate)
          .get();

      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('fechaRegistro', isGreaterThanOrEqualTo: _startDate)
          .where('fechaRegistro', isLessThanOrEqualTo: _endDate)
          .get();

      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('fecha', isGreaterThanOrEqualTo: _startDate)
          .where('fecha', isLessThanOrEqualTo: _endDate)
          .get();

      double totalRevenue = paymentsSnapshot.docs.fold(
          0.0,
          (sum, doc) =>
              sum + (doc.data() as Map<String, dynamic>)['monto'] as double);

      return {
        'revenue': totalRevenue,
        'newUsers': usersSnapshot.docs.length,
        'appointments': appointmentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error loading statistics: $e');
      return {
        'revenue': 0.0,
        'newUsers': 0,
        'appointments': 0,
      };
    }
  }

  Future<List<RevenueStat>> _loadRevenueData() async {
    try {
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('fecha', isGreaterThanOrEqualTo: _startDate)
          .where('fecha', isLessThanOrEqualTo: _endDate)
          .get();

      Map<DateTime, double> revenueMap = {};

      for (var doc in paymentsSnapshot.docs) {
        DateTime date = (doc.data() as Map<String, dynamic>)['fecha'].toDate();
        double amount = (doc.data() as Map<String, dynamic>)['monto'] as double;

        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        if (revenueMap.containsKey(dateOnly)) {
          revenueMap[dateOnly] = revenueMap[dateOnly]! + amount;
        } else {
          revenueMap[dateOnly] = amount;
        }
      }

      List<RevenueStat> revenueData = revenueMap.entries
          .map((entry) => RevenueStat(date: entry.key, amount: entry.value))
          .toList();

      revenueData.sort((a, b) => a.date.compareTo(b.date));

      return revenueData;
    } catch (e) {
      print('Error loading revenue data: $e');
      return [];
    }
  }

  Future<List<UserRegistrationStat>> _loadUserRegistrationData() async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('fechaRegistro', isGreaterThanOrEqualTo: _startDate)
          .where('fechaRegistro', isLessThanOrEqualTo: _endDate)
          .get();

      Map<DateTime, Map<String, int>> registrationMap = {};

      for (var doc in usersSnapshot.docs) {
        DateTime date =
            (doc.data() as Map<String, dynamic>)['fechaRegistro'].toDate();
        String role = (doc.data() as Map<String, dynamic>)['rol'];

        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        if (!registrationMap.containsKey(dateOnly)) {
          registrationMap[dateOnly] = {'doctor': 0, 'paciente': 0};
        }

        if (role == 'doctor') {
          registrationMap[dateOnly]!['doctor'] =
              registrationMap[dateOnly]!['doctor']! + 1;
        } else if (role == 'paciente') {
          registrationMap[dateOnly]!['paciente'] =
              registrationMap[dateOnly]!['paciente']! + 1;
        }
      }

      List<UserRegistrationStat> registrationData = registrationMap.entries
          .map((entry) => UserRegistrationStat(
                date: entry.key,
                doctors: entry.value['doctor']!,
                patients: entry.value['paciente']!,
              ))
          .toList();

      registrationData.sort((a, b) => a.date.compareTo(b.date));

      return registrationData;
    } catch (e) {
      print('Error loading user registration data: $e');
      return [];
    }
  }

  Future<List<AppointmentStat>> _loadAppointmentData() async {
    try {
      QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('citas')
          .where('fecha', isGreaterThanOrEqualTo: _startDate)
          .where('fecha', isLessThanOrEqualTo: _endDate)
          .get();

      Map<DateTime, Map<String, int>> appointmentMap = {};

      for (var doc in appointmentsSnapshot.docs) {
        DateTime date = (doc.data() as Map<String, dynamic>)['fecha'].toDate();
        String status = (doc.data() as Map<String, dynamic>)['estado'];

        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        if (!appointmentMap.containsKey(dateOnly)) {
          appointmentMap[dateOnly] = {
            'confirmada': 0,
            'cancelada': 0,
            'pendiente': 0,
            'completada': 0,
          };
        }

        if (status == 'confirmada') {
          appointmentMap[dateOnly]!['confirmada'] =
              appointmentMap[dateOnly]!['confirmada']! + 1;
        } else if (status == 'cancelada') {
          appointmentMap[dateOnly]!['cancelada'] =
              appointmentMap[dateOnly]!['cancelada']! + 1;
        } else if (status == 'pendiente') {
          appointmentMap[dateOnly]!['pendiente'] =
              appointmentMap[dateOnly]!['pendiente']! + 1;
        } else if (status == 'completada') {
          appointmentMap[dateOnly]!['completada'] =
              appointmentMap[dateOnly]!['completada']! + 1;
        }
      }

      List<AppointmentStat> appointmentData = appointmentMap.entries
          .map((entry) => AppointmentStat(
                date: entry.key,
                confirmed: entry.value['confirmada']!,
                canceled: entry.value['cancelada']!,
                pending: entry.value['pendiente']!,
                completed: entry.value['completada']!,
              ))
          .toList();

      appointmentData.sort((a, b) => a.date.compareTo(b.date));

      return appointmentData;
    } catch (e) {
      print('Error loading appointment data: $e');
      return [];
    }
  }
}

// Data classes for charts
class RevenueStat {
  final DateTime date;
  final double amount;

  RevenueStat({required this.date, required this.amount});
}

class UserRegistrationStat {
  final DateTime date;
  final int doctors;
  final int patients;

  UserRegistrationStat(
      {required this.date, required this.doctors, required this.patients});
}

class AppointmentStat {
  final DateTime date;
  final int confirmed;
  final int canceled;
  final int pending;
  final int completed;

  AppointmentStat({
    required this.date,
    required this.confirmed,
    required this.canceled,
    required this.pending,
    required this.completed,
  });
}

class AppointmentStatusData {
  final String status;
  final int count;
  final Color color;

  AppointmentStatusData(this.status, this.count, this.color);
}
