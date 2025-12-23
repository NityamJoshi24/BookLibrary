import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Statistics',),
      elevation: 0,
      ),

      body: statsAsync.when(
          data: (stats) => _buildStatsContent(context, stats),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red,),
                SizedBox(height: 16,),
                Text('Error: $error'),
              ],
            ),
          ),
          loading: () => Center(child: CircularProgressIndicator(),)),
    );
  }
}

Widget _buildStatsContent(BuildContext context, ReadingStats stats) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressCard(context, stats),
        SizedBox(height: 16,),

        _buildBooksStatusCard(context,stats),
        SizedBox(height: 16,),

        _buildReadingVolumeCard(context, stats),
        SizedBox(height: 16,),

        _buildQuickStatsGrid(context, stats),
      ],
    ),
  );
}

Widget _buildProgressCard(BuildContext context, ReadingStats stats) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.completePercentage.toStringAsFixed(1)}% Complete',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.completePercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(stats.completePercentage),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.pagesRead} pages read',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stats.totalPages} total pages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildBooksStatusCard(BuildContext context, ReadingStats stats) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Books by Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20,),
          _buildStatsRow(
            context,
            'Total Books',
            stats.totalBooks.toString(),
            Icons.library_books,
            Colors.purple,
          ),
          Divider(height: 24,),
          _buildStatsRow(
            context,
            'Currently Reading',
            stats.booksReading.toString(),
            Icons.library_books,
            Colors.purple,
          ),
          Divider(height: 24,),
          _buildStatsRow(
            context,
            'Completed',
            stats.booksCompleted.toString(),
            Icons.library_books,
            Colors.purple,
          ),
          Divider(height: 24,),
          _buildStatsRow(
            context,
            'Want to Read',
            stats.booksWantToRead.toString(),
            Icons.library_books,
            Colors.purple,
          ),
        ],
      ),
    ),
  );
}


Widget _buildReadingVolumeCard(BuildContext context, ReadingStats stats) {
  return Card(
    elevation: 2,
    child: Padding(padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Volume',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 20,),
        _buildStatsRow(
          context,
          'Pages Read',
          stats.pagesRead.toString(),
          Icons.visibility,
          Colors.teal,
        ),
        Divider(height: 24,),
        _buildStatsRow(
          context,
          'Total Pages',
          stats.totalPages.toString(),
          Icons.auto_stories,
          Colors.indigo,
        ),
        Divider(height: 24,),
        _buildStatsRow(
          context,
          'Pages Remaining',
          stats.pagesRemaining.toString(),
          Icons.hourglass_empty,
          Colors.deepOrange,
        ),
      ],
    ),
    ),

  );
}

Widget _buildQuickStatsGrid(BuildContext context, ReadingStats stats) {
  return Row(
    children: [
      Expanded(child: _buildQuickStatsCard(
        context,
        'Avg Pages/Book',
        stats.averagePagesPerBook.toStringAsFixed(1),
        Icons.auto_graph,
        Colors.cyan
      )),
      SizedBox(width: 12,),
      Expanded(child: _buildQuickStatsCard(
        context,
        'In Progress',
        stats.booksInProgress.toString(),
        Icons.sync,
        Colors.amber,
      ))
    ],
  );
}

Widget _buildQuickStatsCard(
BuildContext context,
String label,
String value,
IconData icon,
Color color
) {
  return Card(
    elevation: 2,
    child: Padding(padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: color, size: 28,),
        ),
        SizedBox(height: 12,),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4,),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        )
      ],
    ),
    ),
  );
}

Widget _buildStatsRow(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color
) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24,),
      ),
      SizedBox(
        width: 16,
      ),
      Expanded(child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      )),
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color
        ),
      )
    ],
  );
}

Color _getProgressColor(double percentage) {
  if(percentage < 25) return Colors.red;
  if(percentage < 50) return Colors.orange;
  if(percentage < 75) return Colors.blue;
  return Colors.green;
}