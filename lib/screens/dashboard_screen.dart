import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analysis_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/wide_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _windowStart = 0;
  static const int _windowSize = 5;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AnalysisState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.works.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Search a topic first to see dashboard',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final summary = state.dashboardSummary;
    final trend = state.trendByYear;
    final years = trend.keys.toList();

    final maxWindow = (years.length - _windowSize).clamp(0, years.length);
    final windowStart = _windowStart.clamp(0, maxWindow);
    final windowEnd = (windowStart + _windowSize).clamp(0, years.length);
    final visibleYears = years.sublist(windowStart, windowEnd);
    final maxY = visibleYears.isEmpty
        ? 0.0
        : visibleYears
              .map((y) => trend[y]!)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic label
              Text(
                'Topic: "${state.query}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Summary cards grid
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                children: [
                  SummaryCard(
                    icon: Icons.article,
                    label: 'Total Publications',
                    value: '${summary['totalPublications']}',
                    color: Colors.indigo,
                  ),
                  SummaryCard(
                    icon: Icons.format_quote,
                    label: 'Avg Citations',
                    value: '${summary['avgCitations']}',
                    color: Colors.orange,
                  ),
                  SummaryCard(
                    icon: Icons.calendar_today,
                    label: 'Most Active Year',
                    value: '${summary['mostActiveYear']}',
                    color: Colors.teal,
                  ),
                  SummaryCard(
                    icon: Icons.people,
                    label: 'Top Author',
                    value: '${summary['topAuthor']}',
                    color: Colors.purple,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Top Journal card
              WideCard(
                icon: Icons.library_books,
                label: 'Top Journal',
                value: '${summary['topJournal']}',
                color: Colors.blue,
              ),
              const SizedBox(height: 10),

              // Most Influential Paper card
              WideCard(
                icon: Icons.star,
                label: 'Most Influential Paper',
                value: '${summary['mostInfluentialTitle']}',
                subtitle: '${summary['mostInfluentialCitations']} citations',
                color: Colors.amber,
              ),
              const SizedBox(height: 24),

              // Trend line chart
              const Text(
                'Publication Trend Over Time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              // Year range label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: windowStart > 0
                        ? () => setState(
                            () => _windowStart = (windowStart - _windowSize)
                                .clamp(0, maxWindow),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous 5 years',
                  ),
                  Text(
                    visibleYears.isEmpty
                        ? 'N/A'
                        : '${visibleYears.first} – ${visibleYears.last}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    onPressed: windowEnd < years.length
                        ? () => setState(
                            () => _windowStart = (windowStart + _windowSize)
                                .clamp(0, maxWindow),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next 5 years',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bar chart
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    maxY: maxY * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.indigo.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final year = visibleYears[group.x];
                          final count = rod.toY.toInt();
                          return BarTooltipItem(
                            '$year: $count papers',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(visibleYears.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: trend[visibleYears[i]]!.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 36,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= visibleYears.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${visibleYears[i]}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Page indicator
              Center(
                child: Text(
                  'Showing ${windowStart + 1}–$windowEnd of ${years.length} years',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Top Authors pie chart
              const Text(
                'Top Authors Distribution',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(
                            context,
                            state.topAuthors.take(5).toList(),
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.topAuthors
                          .take(5)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _pieColor(e.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      e.value.key,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    BuildContext context,
    List<MapEntry<String, int>> authors,
  ) {
    final total = authors.fold(0, (sum, e) => sum + e.value);
    return authors.asMap().entries.map((e) {
      final percent = e.value.value / total * 100;
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        color: _pieColor(e.key),
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _pieColor(int index) {
    const colors = [
      Colors.indigo,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
