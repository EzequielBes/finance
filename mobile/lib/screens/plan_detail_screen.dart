// mobile/lib/screens/plan_detail_screen.dart
import 'package:flutter/material.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final int planId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do plano')),
      body: Center(child: Text('Plano #$planId (em construção)')),
    );
  }
}
