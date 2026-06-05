import 'package:flutter/material.dart';
import '../models/work.dart';

class DetailScreen extends StatelessWidget {
  final Work work;
  const DetailScreen({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              work.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (work.authorNames.isNotEmpty) ...[
              const Text(
                'Authors',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                work.authorNames.join(', '),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                _infoCard(context, 'Year', '${work.publicationYear ?? 'N/A'}'),
                const SizedBox(width: 10),
                _infoCard(context, 'Citations', '${work.citedByCount}'),
                const SizedBox(width: 10),
                _infoCard(
                  context,
                  'Open Access',
                  work.isOpenAccess ? 'Yes' : 'No',
                  color: work.isOpenAccess ? Colors.green : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (work.sourceName != null) ...[
              const Text(
                'Journal / Source',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(work.sourceName!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],

            if (work.doi != null) ...[
              const Text('DOI', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                work.doi!,
                style: const TextStyle(fontSize: 13, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
            ],

            if (work.abstractText != null) ...[
              const Text(
                'Abstract',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                work.abstractText!,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
