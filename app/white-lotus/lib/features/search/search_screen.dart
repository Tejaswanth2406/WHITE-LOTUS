import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search documents, notes, and metadata',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Recent matches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    _MatchRow(label: 'Quarterly planning.md', type: 'Notes'),
                    _MatchRow(label: 'Budget snapshot.pdf', type: 'PDF'),
                    _MatchRow(label: 'Device inventory.xlsx', type: 'Spreadsheet'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.label, required this.type});

  final String label;
  final String type;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.find_in_page_rounded),
      title: Text(label),
      subtitle: Text(type),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }
}
