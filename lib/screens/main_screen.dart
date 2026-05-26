import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'student/dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return const EnhancedStudentDashboard();
      },
    );
  }
}
