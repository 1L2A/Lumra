import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/categoryStyle.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _selectedCategory;
  double? _selectedCount;

  // ADDED: toggle state to switch between daily and weekly view
  bool showDaily = true;

  // Helper: compute week of month for a given date
  int weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return ((date.day + firstDay.weekday - 1) / 7).ceil();
  }

  //  button for weekly + daily
  Widget _toggleButton(String label, bool isDailyButton) {
    bool isActive = showDaily == isDailyButton;
    return GestureDetector(
      onTap: () => setState(() => showDaily = isDailyButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? BColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'K2D',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : BColors.textprimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();
    final String currentMonth = DateFormat('MMMM').format(now);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int totalWeeks =
        ((daysInMonth + DateTime(now.year, now.month, 1).weekday - 1) / 7)
            .ceil();
    final int currentWeek = weekOfMonth(now);
    // Dummy weekly data dynamically based on number of weeks
    final Map<String, double> weeklyData = {
      for (int i = 0; i < totalWeeks; i++)
        'Week ${i + 1}': (10 + i * 10).toDouble(),
    };

    // Dummy data – some can be 0
    //get actual data later, then still use the method down to remove the ones with no activities
    final Map<String, double> categoryCounts = {
      'mindfulness': 4,
      'creative': 2,
      'sport': 5,
      'learning': 3,
      'relaxation': 1,
      'social': 2,
      'motivation': 3,
    };

    // (dummy) generate daily data for the first week
    final Map<String, double> dailyData = {
      'Sun': 10,
      'Mon': 30,
      'Tue': 90,
      'Wed': 80,
      'Thu': 40,
      'Fri': 10,
      'Sat': 9,
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

              // -------------- WEEKLY  and Daily--------------
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
                      // ----------------  WEEKLY BOX ----------------
                      Container(
                        width: double.infinity,
                        height: 300,
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
                        // interactive Daily/Weekly container inside same class
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    showDaily
                                        ? "Daily Progress - Week $currentWeek"
                                        : "$currentMonth Weekly Progress",

                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: BColors.textprimary,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: BColors.lightGrey.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Row(
                                      children: [
                                        _toggleButton("Daily", true),
                                        _toggleButton("Weekly", false),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              //  LINE CHART
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: 100,
                                      gridData: FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 20,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                                  value.toInt().toString(),
                                                  style: const TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            reservedSize: 26,
                                            getTitlesWidget: (value, meta) {
                                              int i = value.toInt();
                                              final keys = showDaily
                                                  ? dailyData.keys.toList()
                                                  : weeklyData.keys.toList();
                                              if (i < 0 || i >= keys.length)
                                                return const SizedBox.shrink();
                                              final isCurrentWeek =
                                                  !showDaily &&
                                                  (i + 1) == currentWeek;
                                              final isToday =
                                                  showDaily &&
                                                  i ==
                                                      (DateTime.now().weekday %
                                                          7);

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Text(
                                                  keys[i],
                                                  style: TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 11,
                                                    color:
                                                        isToday || isCurrentWeek
                                                        ? const Color.fromARGB(
                                                            255,
                                                            25,
                                                            27,
                                                            26,
                                                          )
                                                        : Colors.grey,
                                                    fontWeight:
                                                        isToday || isCurrentWeek
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                      ),

                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: List.generate(
                                            //we will replace later with actual data
                                            showDaily
                                                ? dailyData.length
                                                : weeklyData.length,
                                            (i) => FlSpot(
                                              i.toDouble(),
                                              showDaily
                                                  ? dailyData.values.elementAt(
                                                      i,
                                                    ) //we will replace later with actual data
                                                  : weeklyData.values.elementAt(
                                                      i,
                                                    ), //we will replace later with actual data
                                            ),
                                          ),
                                          isCurved: true,
                                          barWidth: 3.1,
                                          color: BColors.primary,
                                          dotData: FlDotData(show: true),

                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                BColors.primary.withOpacity(
                                                  0.4,
                                                ),
                                                BColors.primary.withOpacity(
                                                  0.05,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // ---------------- TASK (LEFT) + FOCUS ROOM + MOOD (RIGHT) ----------------
                      SizedBox(
                        height: 230, // height of total section
                        child: Row(
                          children: [
                            // ======================================================
                            // LEFT SIDE — TASK BOX
                            // ======================================================
                            Expanded(
                              child: Container(
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
                                          // ---- DONUT CHART ----
                                          PieChart(
                                            PieChartData(
                                              startDegreeOffset: -90,
                                              centerSpaceRadius: 25,
                                              sectionsSpace: 2,
                                              sections: [
                                                PieChartSectionData(
                                                  value: 4, // dummy
                                                  title: '4',
                                                  color: BColors.primary,
                                                  radius: 24,
                                                  titleStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                PieChartSectionData(
                                                  value: 3, // dummy
                                                  title: '3',
                                                  color: BColors.secondry,
                                                  radius: 20,
                                                  titleStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          color: BColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Completed",
                                          style: TextStyle(
                                            fontFamily: 'K2D',
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          color: BColors.secondry,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Incomplete",
                                          style: TextStyle(
                                            fontFamily: 'K2D',
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // ======================================================
                            // RIGHT SIDE — FOCUS ROOM + MOOD
                            // ======================================================
                            Expanded(
                              child: Column(
                                children: [
                                  // ----------------- FOCUS ROOM (TOP) -----------------
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(BSizes.md),
                                      decoration: BoxDecoration(
                                        color: BColors.white,
                                        borderRadius: BorderRadius.circular(
                                          BSizes.cardRadiusLg,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.07,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Focus Room",
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontFamily: 'K2D',
                                                  fontWeight: FontWeight.w700,
                                                  color: BColors.textprimary,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                "35 min", // dummy
                                                style: textTheme.headlineSmall
                                                    ?.copyWith(
                                                      fontFamily: 'K2D',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: BColors.primary
                                                          .withOpacity(0.7),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ----------------- MOOD (BOTTOM) -----------------
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(BSizes.md),
                                      decoration: BoxDecoration(
                                        color: BColors.white,
                                        borderRadius: BorderRadius.circular(
                                          BSizes.cardRadiusLg,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.07,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Mood",
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontFamily: 'K2D',
                                                  fontWeight: FontWeight.w700,
                                                  color: BColors.textprimary,
                                                ),
                                          ),
                                          const SizedBox(height: 8),

                                          Expanded(
                                            child: Center(
                                              child: Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    0xFFFFF59D,
                                                  ).withOpacity(0.15),
                                                  shape: BoxShape.circle,

                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFFFF59D,
                                                      ).withOpacity(0.4),
                                                      blurRadius: 12,
                                                      spreadRadius: 2,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.sentiment_neutral,
                                                  color: Color(
                                                    0xFFFFF59D,
                                                  ), // mood color
                                                  size: 50,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 3,
                                              ),
                                              child: Transform.rotate(
                                                angle: -0.2,
                                                child: Text(
                                                  key.isNotEmpty
                                                      ? "${key[0].toUpperCase()}${key.substring(1).toLowerCase()}"
                                                      : key,
                                                  style: const TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                  ),
                                                ),
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
                                  '${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1)}: ${_selectedCount!.toInt()} activities',
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
