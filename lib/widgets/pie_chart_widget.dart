import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final double ingresos;
  final double egresos;

  const PieChartWidget({
    super.key,
    required this.ingresos,
    required this.egresos,
  });

  @override
  Widget build(BuildContext context) {
    final total = ingresos + egresos;

    if (total == 0) {
      return const Text("No hay datos aún");
    }

    final ingresoPorcentaje = (ingresos / total) * 100;
    final egresoPorcentaje = (egresos / total) * 100;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: ingresos,
                  color: Colors.green,
                  title: "${ingresoPorcentaje.toStringAsFixed(1)}%",
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: egresos,
                  color: Colors.red,
                  title: "${egresoPorcentaje.toStringAsFixed(1)}%",
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.circle, color: Colors.green, size: 12),
            SizedBox(width: 5),
            Text("Ingresos"),
            SizedBox(width: 20),
            Icon(Icons.circle, color: Colors.red, size: 12),
            SizedBox(width: 5),
            Text("Egresos"),
          ],
        )
      ],
    );
  }
}