import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';
import 'features/admin/admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'login_screen.dart';
import 'patient_dashboard.dart';
import 'book_apointment.dart';
import 'features/medical_history/patient_history.dart';
import 'features/doctor/perfil_doctor_screen.dart';
import 'features/admin/user_detail_screen.dart';
import 'features/doctor/doctor_public_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/appointment/book': (context) => const BookAppointmentScreen(),
        '/doctor/dashboard': (context) => const DoctorDashboard(),
        '/patient/dashboard': (context) => const PatientDashboard(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/doctor/profile/edit': (context) => const PerfilEditorScreen(),
        '/doctor/schedule': (context) => const HorarioScreen(),
        '/patient/history': (context) => const PatientHistoryScreen(),
      },
      // Define a route generator for routes with parameters
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/doctor/profile/public/') ?? false) {
          // Extract the username from the route
          final username = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => DoctorPublicProfile(username: username),
          );
        } else if (settings.name?.startsWith('/admin/users/detail/') ?? false) {
          // Extract the user ID from the route
          final userId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => UserDetailScreen(userId: userId),
          );
        } else if (settings.name?.startsWith('/patient/history/') ?? false) {
          // Extract the patient ID from the route
          final patientId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => PatientHistoryScreen(patientId: patientId),
          );
        } else if (settings.name?.startsWith('/appointment/book/') ?? false) {
          // Extract the doctor ID from the route
          final doctorId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(doctorId: doctorId),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasData) {
          // User is logged in, determine their role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (userSnapshot.hasError) {
                return Center(
                  child: Text("Error: ${userSnapshot.error}"),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final String role = userData['rol'] ?? 'paciente';

                // Return the correct dashboard based on user role
                switch (role) {
                  case 'doctor':
                    return const DoctorDashboard();
                  case 'admin':
                    return const AdminDashboard();
                  case 'paciente':
                  default:
                    return const PatientDashboard();
                }
              }

              // If the user doesn't have a role yet, show login
              return LoginScreen();
            },
          );
        }

        // User is not logged in
        return LoginScreen();
      },
    );
  }
}
