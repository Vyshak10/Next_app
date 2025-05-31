import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userId;

  const AnalyticsDashboardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // State variables to hold analytics data
  int totalProfileViews = 0;
  int totalPostLikes = 0;
  int totalConnections = 0;
  List<Map<String, dynamic>> userPosts = [];
  List<Map<String, dynamic>> recentConnections = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    _loadUserPostsAnalytics();
    _loadConnectionActivity();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Fetch total profile views for the current user
      final profileViewsData = await supabase
          .from('profile_visits')
          .select('count')
          .eq('profile_id', widget.userId)
          .single();
      totalProfileViews = profileViewsData['count'] ?? 0;

      // Fetch total likes on posts by the current user
      final userPostsResult = await supabase
          .from('posts')
          .select('id')
          .eq('user_id', widget.userId);

      List<String> userPostIds = userPostsResult.map((post) => post['id'] as String).toList();

      if (userPostIds.isNotEmpty) {
         final postLikesData = await supabase
            .from('likes')
            .select('count')
            .inFilter('post_id', userPostIds);

         totalPostLikes = postLikesData[0]['count'] ?? 0;
      } else {
        totalPostLikes = 0;
      }

      // Fetch total connections for the current user
      final acceptedConnections = await supabase
          .from('connections')
          .select('count')
          .or('user_id.eq.${widget.userId},connected_user_id.eq.${widget.userId}')
          .eq('status', 'accepted');

      totalConnections = acceptedConnections[0]['count'] ?? 0;

      setState(() {
        this.totalProfileViews = totalProfileViews;
        this.totalPostLikes = totalPostLikes;
        this.totalConnections = totalConnections;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load overall analytics: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

   Future<void> _loadUserPostsAnalytics() async {
     try {
       final postsData = await supabase
           .from('posts')
           .select('id, title, created_at')
           .eq('user_id', widget.userId);

       if (mounted && postsData != null) {
         List<Map<String, dynamic>> postsWithLikes = [];
         for (var post in postsData) {
           final likesData = await supabase
               .from('likes')
               .select('count')
               .eq('post_id', post['id']);

           post['like_count'] = likesData[0]['count'] ?? 0;
           postsWithLikes.add(post);
         }

         setState(() {
           userPosts = postsWithLikes;
         });
       }
     } catch (e) {
       setState(() {
         _errorMessage += '\nFailed to load post analytics: ${e.toString()}';
         _isLoading = false;
       });
     }
   }

   Future<void> _loadConnectionActivity() async {
     try {
       final connectionsData = await supabase
           .from('connections')
           .select('user_id, connected_user_id, created_at')
           .or('user_id.eq.${widget.userId},connected_user_id.eq.${widget.userId}')
           .eq('status', 'accepted')
           .order('created_at', ascending: false)
           .limit(5);

       if (mounted && connectionsData != null) {
          List<Map<String, dynamic>> connectionsWithNames = [];
          for(var connection in connectionsData) {
            final otherUserId = connection['user_id'] == widget.userId ? connection['connected_user_id'] : connection['user_id'];

            final otherUserProfile = await supabase
              .from('profiles')
              .select('name')
              .eq('id', otherUserId)
              .maybeSingle();

            connection['other_user_name'] = otherUserProfile?['name'] ?? 'Unknown User';
            connectionsWithNames.add(connection);
          }

         setState(() {
           recentConnections = connectionsWithNames;
           _isLoading = false;
         });
       }
     } catch (e) {
       setState(() {
         _errorMessage += '\nFailed to load connection activity: ${e.toString()}';
         _isLoading = false;
       });
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Metrics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      Card(
                        elevation: 2.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetricRow('Total Profile Views:', totalProfileViews),
                              _buildMetricRow('Total Post Likes:', totalPostLikes),
                              _buildMetricRow('Total Connections:', totalConnections),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Post Engagement',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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

                      const SizedBox(height: 24.0),
                      Text(
                        'Connection Activity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentConnections.length,
                        itemBuilder: (context, index) {
                          final connection = recentConnections[index];
                          final connectedUserName = connection['other_user_name'] ?? 'Unknown User';
                          final connectionDate = DateTime.parse(connection['created_at']).toLocal().toString().split(' ')[0];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Connected with $connectedUserName',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    connectionDate,
                                    style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  Widget _buildMetricRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 