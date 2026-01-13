import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'pairing_screen.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userId;
  const AnalyticsDashboardScreen({super.key, required this.userId});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _selectedStartupIndex = 0;
  String _growthView = 'Month'; // 'Month', '6 Months', 'Year'

  final List<Map<String, dynamic>> _dummyStartups = [
    {
      'startupName': 'TechNova',
      'startupCode': 'ABCD1234',
      'totalInvestment': 150000.00,
      'postReach': 12000,
      'postImpressions': 45000,
      'companies': [
        {'name': 'Alpha Ventures', 'amount': 100000},
        {'name': 'Beta Capital', 'amount': 50000},
      ],
      'numPosts': 24,
      'avgEngagementRate': 7.2, // percent
      'lastPaired': '2024-06-10',
      'activityTimeline': [
        {'date': '2024-06-10', 'event': 'Paired with TechNova'},
        {'date': '2024-06-09', 'event': 'Investment increased by ₹50,000'},
        {'date': '2024-06-08', 'event': 'New post published'},
        {'date': '2024-06-07', 'event': 'Impressions milestone reached'},
      ],
      'growth': {
        'Month': [100, 120, 150, 180, 210, 250, 300, 350, 400, 470, 540, 600],
        '6 Months': [100, 180, 300, 400, 540, 600],
        'Year': [100, 180, 250, 320, 400, 480, 600, 700, 800, 900, 1000, 1200],
        'labels': {
          'Month': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          '6 Months': ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'],
          'Year': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        },
      },
    },
    {
      'startupName': 'GreenSpark',
      'startupCode': 'EFGH5678',
      'totalInvestment': 90000.00,
      'postReach': 8000,
      'postImpressions': 22000,
      'companies': [
        {'name': 'Eco Investors', 'amount': 60000},
        {'name': 'Future Fund', 'amount': 30000},
      ],
      'numPosts': 15,
      'avgEngagementRate': 5.8, // percent
      'lastPaired': '2024-06-09',
      'activityTimeline': [
        {'date': '2024-06-09', 'event': 'Paired with GreenSpark'},
        {'date': '2024-06-08', 'event': 'Investment increased by ₹30,000'},
        {'date': '2024-06-07', 'event': 'New post published'},
        {'date': '2024-06-06', 'event': 'Reached 20,000 impressions'},
      ],
      'growth': {
        'Month': [80, 100, 120, 140, 160, 180, 210, 230, 250, 270, 300, 340],
        '6 Months': [80, 120, 180, 230, 270, 340],
        'Year': [80, 120, 160, 200, 240, 280, 320, 360, 400, 440, 480, 520],
        'labels': {
          'Month': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          '6 Months': ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'],
          'Year': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        },
      },
    },
    {
      'startupName': 'MedixFlow',
      'startupCode': 'IJKL9012',
      'totalInvestment': 200000.00,
      'postReach': 18000,
      'postImpressions': 60000,
      'companies': [
        {'name': 'Health Angels', 'amount': 120000},
        {'name': 'Venture Med', 'amount': 80000},
      ],
      'numPosts': 32,
      'avgEngagementRate': 8.5, // percent
      'lastPaired': '2024-06-11',
      'activityTimeline': [
        {'date': '2024-06-11', 'event': 'Paired with MedixFlow'},
        {'date': '2024-06-10', 'event': 'Investment increased by ₹80,000'},
        {'date': '2024-06-09', 'event': 'New post published'},
        {'date': '2024-06-08', 'event': 'Reached 60,000 impressions'},
      ],
      'growth': {
        'Month': [150, 180, 210, 250, 300, 370, 450, 520, 600, 700, 820, 950],
        '6 Months': [150, 250, 370, 520, 700, 950],
        'Year': [150, 250, 370, 520, 700, 820, 950, 1100, 1300, 1500, 1700, 2000],
        'labels': {
          'Month': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          '6 Months': ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'],
          'Year': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        },
      },
    },
  ];

  void _showStartupSwitcher() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('Switch Startup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...List.generate(_dummyStartups.length, (i) {
                final s = _dummyStartups[i];
                return ListTile(
                  leading: Icon(Icons.business, color: i == _selectedStartupIndex ? Colors.blueAccent : Colors.grey),
                  title: Text(s['startupName'] as String),
                  subtitle: Text('Code: ${s['startupCode']}'),
                  trailing: i == _selectedStartupIndex ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _selectedStartupIndex = i;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dummyAnalytics = _dummyStartups[_selectedStartupIndex];
    final String startupName = dummyAnalytics['startupName'] as String;
    final String startupCode = dummyAnalytics['startupCode'] as String;
    final double totalInvestment = dummyAnalytics['totalInvestment'] as double;
    final int postReach = dummyAnalytics['postReach'] as int;
    final int postImpressions = dummyAnalytics['postImpressions'] as int;
    final List<dynamic> companies = dummyAnalytics['companies'] as List<dynamic>;
    final int numPosts = dummyAnalytics['numPosts'] as int;
    final double avgEngagementRate = dummyAnalytics['avgEngagementRate'] as double;
    final String lastPaired = dummyAnalytics['lastPaired'] as String;
    final List<dynamic> activityTimeline = dummyAnalytics['activityTimeline'] as List<dynamic>;
    final Map<String, dynamic>? growth = dummyAnalytics['growth'] as Map<String, dynamic>?;
    if (growth == null) {
      return Scaffold(
        body: Center(child: Text('Growth data not available', style: TextStyle(color: Colors.red, fontSize: 18))),
      );
    }
    final List<int> growthData = List<int>.from(growth[_growthView] as List? ?? []);
    final List<String> growthLabels = List<String>.from(growth['labels'][_growthView] as List? ?? []);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final double chartHeight = (MediaQuery.of(context).size.height * 0.22).clamp(120, 180);
          final double verticalPadding = MediaQuery.of(context).size.height < 700 ? 10 : 24;
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Pair More Startup and Switch Startup buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'Switch Startup',
                            child: IconButton(
                              icon: const Icon(Icons.swap_horiz_rounded, color: Colors.deepPurple, size: 28),
                              onPressed: _showStartupSwitcher,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Pair More Startup',
                            child: IconButton(
                              icon: const Icon(Icons.link_rounded, color: Colors.blueAccent, size: 28),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom,
                                    ),
                                    child: SizedBox(
                                      height: 480,
                                      child: PairingScreen(
                                        companyId: int.parse(widget.userId),
                                        onGoToAnalytics: () {
                                          Navigator.pop(context); // Close the sheet
                                          setState(() {}); // Optionally refresh analytics
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Startup Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade50,
                                    child: const Icon(Icons.business, color: Colors.blueAccent, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          startupName,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.code, size: 18, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text('Code: $startupCode', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Responsive chips using Wrap
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(Icons.calendar_today, 'Last Paired: $lastPaired'),
                                  _buildInfoChip(Icons.post_add, 'Posts: $numPosts'),
                                  _buildInfoChip(Icons.percent, 'Engagement: ${avgEngagementRate.toStringAsFixed(1)}%'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Growth Overview Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Growth Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ToggleButtons(
                              isSelected: [
                                _growthView == 'Month',
                                _growthView == '6 Months',
                                _growthView == 'Year',
                              ],
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.white,
                              fillColor: Colors.blueAccent,
                              color: Colors.blueAccent,
                              constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
                              onPressed: (index) {
                                setState(() {
                                  _growthView = ['Month', '6 Months', 'Year'][index];
                                });
                              },
                              children: const [
                                Text('Month'),
                                Text('6M'),
                                Text('Year'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: chartHeight,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (value, meta) {
                                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 11));
                                    }),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= growthLabels.length) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text(growthLabels[idx], style: const TextStyle(fontSize: 11)),
                                        );
                                      },
                                      reservedSize: 32,
                                    ),
                                  ),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                                minX: 0,
                                maxX: (growthData.length - 1).toDouble(),
                                minY: 0,
                                maxY: (growthData.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (int i = 0; i < growthData.length; i++)
                                        FlSpot(i.toDouble(), growthData[i].toDouble()),
                                    ],
                                    isCurved: true,
                                    color: Colors.blueAccent,
                                    barWidth: 4,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.15)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Section: Key Stats
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Text('Key Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Total Investment', '₹${totalInvestment.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Post Reach', postReach.toString(), Icons.visibility, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Impressions', postImpressions.toString(), Icons.trending_up, Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Section: Invested Companies
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Text('Invested Companies', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(companies.length, (i) {
                                final company = companies[i] as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.business, color: Colors.indigo, size: 22),
                                          const SizedBox(width: 8),
                                          Text(company['name'] as String, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                      Text('₹${company['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Section: Activity Timeline
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Text('Activity Timeline', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...activityTimeline.map((item) {
                                final map = item as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 10, color: Colors.blueAccent),
                                      const SizedBox(width: 10),
                                      Text(map['date'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(map['event'], style: const TextStyle(fontSize: 15))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blueAccent),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
} 