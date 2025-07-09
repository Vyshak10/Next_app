import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../common_widget/company_profile.dart';
import '../profile/user_profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  final ApiService _apiService = ApiService();

  void _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _results = [];
    });
    try {
      final results = await _apiService.searchUser(query, _filter);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _results = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFilterPressed() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('All'),
            onTap: () => Navigator.pop(context, 'All'),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Company'),
            onTap: () => Navigator.pop(context, 'Company'),
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch),
            title: const Text('Startup'),
            onTap: () => Navigator.pop(context, 'Startup'),
          ),
        ],
      ),
    );
    if (selected != null && selected != _filter) {
      setState(() {
        _filter = selected;
      });
      if (_searchController.text.trim().isNotEmpty) {
        _onSearch();
      }
    }
  }

  void _onResultTap(Map<String, dynamic> user) async {
    if (user['user_type'] == 'company') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompanyProfileScreen(companyData: user),
        ),
      );
    } else {
      // Fetch current userId from secure storage
      final storage = const FlutterSecureStorage();
      String? currentUserId = await storage.read(key: 'user_id');
      final String nonNullUserId = (currentUserId == null || currentUserId.isEmpty) ? '6852' : currentUserId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: nonNullUserId,
            targetUserId: user['id'].toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by username...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _onSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _onFilterPressed,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearch,
            tooltip: 'Search',
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('No results found.'))
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null || user['avatar_url'].toString().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name'] ?? user['username'] ?? 'Unknown'),
                      subtitle: Text(user['user_type'] ?? ''),
                      onTap: () => _onResultTap(user),
                    );
                  },
                ),
    );
  }
} 