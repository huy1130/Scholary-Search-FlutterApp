import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analysis_provider.dart';

class TrendScreen extends ConsumerStatefulWidget {
  const TrendScreen({super.key});

  @override
  ConsumerState<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends ConsumerState<TrendScreen> {
  int _windowStart = 0;
  static const int _windowSize = 5;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Trends'),
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
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Search a topic first to see trends',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final trend = state.trendByYear;
    final years = trend.keys.toList();
    final maxWindow = (years.length - _windowSize).clamp(0, years.length);

    // Clamp windowStart
    final windowStart = _windowStart.clamp(0, maxWindow);
    final windowEnd = (windowStart + _windowSize).clamp(0, years.length);
    final visibleYears = years.sublist(windowStart, windowEnd);
    final maxY = visibleYears
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
              Text(
                'Topic: "${state.query}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on ${state.works.length} publications',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),

              const Text(
                'Publications per Year',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),

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
                height: 280,
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
              const SizedBox(height: 32),

              // Top Influential Papers
              const Text(
                'Top Influential Papers',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...state.topInfluentialPapers.asMap().entries.map((entry) {
                final i = entry.key;
                final work = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              work.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${work.citedByCount} citations · ${work.publicationYear ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Top Journals
              const Text(
                'Top Research Journals',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...state.topJournals.asMap().entries.map((entry) {
                final i = entry.key;
                final journal = entry.value;
                final maxCount = state.topJournals.first.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journal.key,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: journal.value / maxCount,
                              backgroundColor: Colors.grey[200],
                              color: Theme.of(context).colorScheme.primary,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${journal.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Top Authors
              const Text(
                'Top Contributing Authors',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...state.topAuthors.asMap().entries.map((entry) {
                final i = entry.key;
                final author = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(author.key, style: const TextStyle(fontSize: 13)),
                  trailing: Chip(
                    label: Text(
                      '${author.value} papers',
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
