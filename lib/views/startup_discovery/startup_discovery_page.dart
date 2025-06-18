import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/startup.dart';
import '../../services/api_service.dart';

class StartupDiscoveryPage extends StatefulWidget {
  const StartupDiscoveryPage({Key? key}) : super(key: key);

  @override
  _StartupDiscoveryPageState createState() => _StartupDiscoveryPageState();
}

class _StartupDiscoveryPageState extends State<StartupDiscoveryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Startup> _startups = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStartups();
  }

  Future<void> _loadStartups() async {
    try {
      final startups = await _apiService.getStartups();
      setState(() {
        _startups = startups.map((json) => Startup.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading startups: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect() async {
    if (_currentIndex >= _startups.length) return;

    try {
      await _apiService.connectWithStartup(_startups[_currentIndex].id);
      setState(() {
        _startups[_currentIndex] = _startups[_currentIndex].copyWith(
          isConnected: true,
        );
        _currentIndex++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting with startup: $e')),
      );
    }
  }

  void _handleSkip() {
    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_startups.isEmpty || _currentIndex >= _startups.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Startup Discovery')),
        body: const Center(
          child: Text('No more startups to discover'),
        ),
      );
    }

    final startup = _startups[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Discovery'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  if (startup.logoUrl != null)
                    Expanded(
                      flex: 3,
                      child: CachedNetworkImage(
                        imageUrl: startup.logoUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      flex: 3,
                      child: Center(
                        child: Icon(
                          Icons.business,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  // Startup Info
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            startup.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            startup.sector,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            startup.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: startup.tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                          if (startup.location != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 4),
                                Text(startup.location!),
                              ],
                            ),
                          ],
                          if (startup.website != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.language, size: 16),
                                const SizedBox(width: 4),
                                Text(startup.website!),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _handleSkip,
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.close),
                ),
                FloatingActionButton(
                  onPressed: _handleConnect,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 