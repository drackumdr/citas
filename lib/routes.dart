import 'package:flutter/material.dart';

import 'role_based_redirect.dart';
import 'login_screen.dart';
import 'patient_dashboard.dart';
import 'doctor_dashboard.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/doctor/profile_editor.dart';
import 'book_apointment.dart';
import 'features/medical_history/patient_history.dart';
import 'features/doctor/payment_screen.dart';
import 'features/doctor/doctor_public_profile.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String patientDashboard = '/patient_dashboard';
  static const String doctorDashboard = '/doctor_dashboard';
  static const String adminDashboard = '/admin_dashboard';
  static const String bookAppointment = '/book_appointment';
  static const String doctorProfile = '/doctor_profile';
  static const String medicalHistory = '/medical_history';
  static const String doctorPayment = '/doctor_payment';
  static const String doctorPublic = '/dr';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initial: (context) => const RoleBasedRedirect(),
      login: (context) => LoginScreen(),
      patientDashboard: (context) => const PatientDashboard(),
      doctorDashboard: (context) => const DoctorDashboard(),
      adminDashboard: (context) => const AdminDashboard(),
      bookAppointment: (context) => const BookAppointmentScreen(),
      doctorProfile: (context) => const DoctorProfileEditor(),
      medicalHistory: (context) => const PatientHistoryScreen(),
      doctorPayment: (context) => const DoctorPaymentScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/dr-') ?? false) {
      // Extract doctor username from URL
      final doctorUsername = settings.name!.substring(4);
      return MaterialPageRoute(
        builder: (context) => DoctorPublicProfile(username: doctorUsername),
        settings: settings,
      );
    }
    return null;
  }
}
