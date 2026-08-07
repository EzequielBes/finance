// mobile/lib/widgets/savings_plan_section.dart
import 'package:flutter/material.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/plans_repository.dart';

class SavingsPlanSection extends StatelessWidget {
  const SavingsPlanSection({super.key, required this.plan, required this.simulation});
  final Plan plan;
  final PlanSimulation? simulation;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // substituído na Task 8
  }
}
