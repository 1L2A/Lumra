import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/categoryStyle.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _selectedCategory;
  double? _selectedCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Dummy data – some can be 0
    //get actual data later, then still use the method down to remove the ones with no activities
    final Map<String, double> categoryCounts = {
      'mindfulness': 4,
      'creative': 0,
      'sport': 5,
      'learning': 3,
      'relaxation': 0,
      'social': 2,
      'motivation': 3,
    };

    // Keep only categories with value > 0
    final entries = categoryCounts.entries.where((e) => e.value > 0).toList();

    // Build bar groups from filtered entries
    final List<BarChartGroupData> barGroups = List.generate(entries.length, (
      i,
    ) {
      final key = entries[i].key;
      final value = entries[i].value;
      final style = CategoryStyles.byKey(key);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 22,
            color: style.iconColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(0),
          ),
        ],
      );
    });

    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              SizedBox(
                width: double.infinity,
                child: BAppBarTheme.createHeader(
                  context: context,
                  title: 'Dashboard',
                ),
              ),

              // -------------- WEEKLY -------------- //not done yet only the rectangle
              Padding(
                padding: EdgeInsets.fromLTRB(
                  BSizes.lg,
                  0,
                  BSizes.lg,
                  BSizes.lg + 80,
                ),
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- EMPTY WEEKLY BOX ----------------
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: BColors.white,
                          borderRadius: BorderRadius.circular(
                            BSizes.cardRadiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // ---------------- TASK + FOCUS ROOM----------------
                      Row(
                        children: [
                          // ===== TASK BOX =====
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(BSizes.md),
                              height: 150,
                              decoration: BoxDecoration(
                                color: BColors.white,
                                borderRadius: BorderRadius.circular(
                                  BSizes.cardRadiusLg,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Task",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.w700,
                                      color: BColors.textprimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            startDegreeOffset: -90,
                                            centerSpaceRadius: 28,
                                            sectionsSpace: 2,
                                            sections: [
                                              PieChartSectionData(
                                                value:
                                                    4, //we will replace later with actual data
                                                color: BColors.primary,
                                                radius: 24,
                                                showTitle: false,
                                              ),
                                              PieChartSectionData(
                                                value:
                                                    3, //we will replace later with actual data
                                                color: BColors.secondry,
                                                radius: 20,
                                                showTitle: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '7', //we will replace later with actual data
                                              style: const TextStyle(
                                                fontFamily: 'K2D',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: BColors.textprimary,
                                              ),
                                            ),
                                            Text(
                                              'tasks',
                                              style: TextStyle(
                                                fontFamily: 'K2D',
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // ===== FOCUS ROOM BOX =====
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(BSizes.md),
                              height: 150,
                              decoration: BoxDecoration(
                                color: BColors.white,
                                borderRadius: BorderRadius.circular(
                                  BSizes.cardRadiusLg,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Focus Room",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.w700,
                                      color: BColors.textprimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      "35 min", //we will replace later with actual data
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontFamily: 'K2D',
                                        fontWeight: FontWeight.bold,
                                        color: BColors.primary.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ---------------- ACTIVITIES BAR CHART ----------------
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(BSizes.md),
                        decoration: BoxDecoration(
                          color: BColors.white,
                          borderRadius: BorderRadius.circular(
                            BSizes.cardRadiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Activities",
                              style: textTheme.titleMedium?.copyWith(
                                fontFamily: 'K2D',
                                fontWeight: FontWeight.w700,
                                color: BColors.textprimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (entries.isEmpty)
                              const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    "No activities yet",
                                    style: TextStyle(
                                      fontFamily: 'K2D',
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 260,
                                child: BarChart(
                                  BarChartData(
                                    // touch + tooltip using filtered entries
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              final entry =
                                                  entries[group.x.toInt()];
                                              final key = entry.key;
                                              final value = entry.value;

                                              return BarTooltipItem(
                                                '$key\n${value.toInt()} activities',
                                                const TextStyle(
                                                  fontFamily: 'K2D',
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                      ),
                                    ),

                                    alignment: BarChartAlignment.spaceAround,
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                            color: BColors.borderPrimary
                                                .withOpacity(0.25),
                                            strokeWidth: 1.5,
                                          ),
                                    ),

                                    titlesData: FlTitlesData(
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          reservedSize: 32,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontFamily: 'K2D',
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          getTitlesWidget: (value, meta) {
                                            int i = value.toInt();
                                            if (i < 0 || i >= entries.length) {
                                              return const SizedBox.shrink();
                                            }

                                            final key = entries[i].key;
                                            return Text(
                                              key.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                fontFamily: 'K2D',
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    barGroups: barGroups,
                                  ),
                                ),
                              ),

                            if (_selectedCategory != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1)}: ${_selectedCount!.toInt()} activities', //later make method that returns this data
                                  style: const TextStyle(
                                    fontFamily: 'K2D',
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
