import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'patient_dashboard.dart';
import 'doctor_dashboard.dart';
// You can import the AdminDashboard if it exists

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Not logged in, show login screen
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // User is logged in, check role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection(
                  'usuarios') // Collection name is 'usuarios' in the project
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Show loading while fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Handle case where user exists in Auth but not in Firestore
              return const Center(
                child: Text("Error: User profile not found"),
              );
            }

            // Check user role
            String rol = userSnapshot.data!
                .get('rol'); // Field name is 'rol' in the project

            // Redirect based on role
            if (rol == 'admin') {
              // Uncomment if you have an AdminDashboard
              // return AdminDashboard();

              // Temporary placeholder for admin
              return Scaffold(
                appBar: AppBar(title: const Text("Admin Dashboard")),
                body:
                    const Center(child: Text("Admin Dashboard - Coming Soon")),
              );
            } else if (rol == 'doctor') {
              return const DoctorDashboard();
            } else {
              return const PatientDashboard();
            }
          },
        );
      },
    );
  }
}
