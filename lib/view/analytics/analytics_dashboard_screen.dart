import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userId;

  const AnalyticsDashboardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final storage = const FlutterSecureStorage();

  int totalProfileViews = 0;
  int totalPostLikes = 0;
  int totalConnections = 0;
  List<Map<String, dynamic>> userPosts = [];
  List<Map<String, dynamic>> recentConnections = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String baseUrl = 'https://indianrupeeservices.in/NEXT/backend'; // Use your actual backend URL

  @override
  void initState() {
    super.initState();
    // Inject dummy data for demo/professional look
    totalProfileViews = 1240;
    totalPostLikes = 320;
    totalConnections = 87;
    userPosts = [
      {'title': 'AI Launch', 'likes': 120, 'views': 400, 'date': '2024-06-01'},
      {'title': 'Funding Secured', 'likes': 80, 'views': 300, 'date': '2024-05-25'},
      {'title': 'New Partnership', 'likes': 60, 'views': 220, 'date': '2024-05-20'},
      {'title': 'Product Update', 'likes': 40, 'views': 180, 'date': '2024-05-15'},
      {'title': 'Team Expansion', 'likes': 20, 'views': 140, 'date': '2024-05-10'},
    ];
    recentConnections = [
      {'name': 'Alice', 'type': 'Connection', 'date': '2024-06-01'},
      {'name': 'Bob', 'type': 'Like', 'date': '2024-05-30'},
      {'name': 'Charlie', 'type': 'View', 'date': '2024-05-29'},
      {'name': 'Diana', 'type': 'Connection', 'date': '2024-05-28'},
    ];
    _isLoading = false;
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadAllAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadProfileViews(),
        _loadPostLikes(),
        _loadConnections(),
        _loadUserPostsAnalytics(),
        _loadConnectionActivity(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileViews() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/profile-views?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalProfileViews = data['count'] ?? 0;
    }
  }

  Future<void> _loadPostLikes() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/post-likes?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalPostLikes = data['count'] ?? 0;
    }
  }

  Future<void> _loadConnections() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/connections?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalConnections = data['count'] ?? 0;
    }
  }

  Future<void> _loadUserPostsAnalytics() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/posts?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userPosts = List<Map<String, dynamic>>.from(data['posts']);
    }
  }

  Future<void> _loadConnectionActivity() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/recent-connections?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      recentConnections = List<Map<String, dynamic>>.from(data['connections']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage.contains('XMLHttpRequest')
                  ? 'Network error: Please check your internet connection or backend CORS settings.'
                  : 'Error: $_errorMessage'))
              : RefreshIndicator(
                  onRefresh: _loadAllAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary metrics card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryMetric(Icons.visibility, 'Views', totalProfileViews, Colors.blue),
                                _buildSummaryMetric(Icons.thumb_up, 'Likes', totalPostLikes, Colors.orange),
                                _buildSummaryMetric(Icons.people, 'Connections', totalConnections, Colors.green),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        // Bar chart for post likes
                        if (userPosts.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Post Likes Overview', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Shows likes for your recent posts',
                                    child: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 140,
                                    barTouchData: BarTouchData(enabled: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= userPosts.length) return Container();
                                            return Text(userPosts[idx]['title'].toString().split(' ')[0], style: TextStyle(fontSize: 10));
                                          },
                                          reservedSize: 32,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: [
                                      for (int i = 0; i < userPosts.length; i++)
                                        BarChartGroupData(x: i, barRods: [
                                          BarChartRodData(toY: (userPosts[i]['likes'] as int).toDouble(), color: Colors.blueAccent, width: 18),
                                        ]),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24.0),
                        // Line chart for post views
                        if (userPosts.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Post Views Trend', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Views trend for your recent posts',
                                    child: const Icon(Icons.show_chart, size: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: LineChart(
                                  LineChartData(
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          for (int i = 0; i < userPosts.length; i++)
                                            FlSpot(i.toDouble(), (userPosts[i]['views'] as int).toDouble()),
                                        ],
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 4,
                                        dotData: FlDotData(show: true),
                                      ),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= userPosts.length) return Container();
                                            return Text(userPosts[idx]['title'].toString().split(' ')[0], style: TextStyle(fontSize: 10));
                                          },
                                          reservedSize: 32,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24.0),
                        // Pie chart for engagement
                        Text('Engagement Breakdown', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: totalProfileViews.toDouble(),
                                  color: Colors.blue,
                                  title: 'Views',
                                  radius: 50,
                                  titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                PieChartSectionData(
                                  value: totalPostLikes.toDouble(),
                                  color: Colors.orange,
                                  title: 'Likes',
                                  radius: 45,
                                  titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                PieChartSectionData(
                                  value: totalConnections.toDouble(),
                                  color: Colors.green,
                                  title: 'Connections',
                                  radius: 40,
                                  titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                              sectionsSpace: 4,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        // Recent activity timeline
                        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (recentConnections.isEmpty)
                          Text('No recent activity.', style: TextStyle(color: Colors.grey[600])),
                        if (recentConnections.isNotEmpty)
                          Column(
                            children: recentConnections.map((activity) => ListTile(
                              leading: Icon(
                                activity['type'] == 'Connection' ? Icons.person_add :
                                activity['type'] == 'Like' ? Icons.thumb_up :
                                Icons.visibility,
                                color: activity['type'] == 'Connection' ? Colors.green :
                                       activity['type'] == 'Like' ? Colors.orange :
                                       Colors.blue,
                              ),
                              title: Text(activity['name']),
                              subtitle: Text('${activity['type']} • ${activity['date']}'),
                            )).toList(),
                          ),
                        const SizedBox(height: 32),
                        // Post Engagement List
                        Text('Post Engagement', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16.0),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userPosts.length,
                          itemBuilder: (context, index) {
                            final post = userPosts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              elevation: 1.0,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        post['title'] ?? 'Untitled Post',
                                        style: Theme.of(context).textTheme.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.rocket_launch_rounded, size: 18.0, color: Colors.orange[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          post['like_count'].toString(),
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryMetric(IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
          radius: 28,
        ),
        const SizedBox(height: 8),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// Simple bar chart for post likes (no external package)
class _SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  const _SimpleBarChart({required this.posts});

  @override
  Widget build(BuildContext context) {
    final maxLikes = posts.map((p) => (p['like_count'] ?? 0) as int).fold<int>(0, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: posts.map((post) {
        final likes = (post['like_count'] ?? 0) as int;
        final barHeight = maxLikes > 0 ? (likes / maxLikes) * 120 : 10;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: barHeight + 10,
                width: 18,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    likes.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post['title'] != null && post['title'].toString().isNotEmpty
                    ? post['title'].toString().substring(0, math.min(8, post['title'].toString().length))
                    : 'Post',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 