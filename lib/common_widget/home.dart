import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'company_detail_screen.dart';
import '../../view/subscription/subscription_screen.dart'; // Import SubscriptionScreen
import 'package:next_app/view/meetings/meeting_screen.dart';
import 'animated_greeting_gradient_mixin.dart';

// Constants
const String apiBaseUrl = 'https://indianrupeeservices.in/NEXT/backend';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onProfileTap;
  final String? userId;
  final bool verticalList;
  final bool isStartupUser;

  const HomeScreen({super.key, this.userProfile, this.onProfileTap, this.userId, this.verticalList = false, this.isStartupUser = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<HomeScreen> {
  final secureStorage = const FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();

  String userName = '';
  String selectedSector = 'All';
  List<Map<String, dynamic>> companyData = [];
  bool isLoading = true;
  bool notifyEnabled = true;
  int unreadNotificationCount = 0;
  bool _isLoadingData = false; // Add loading state flag

  final List<String> sectorOptions = [
    'All',
    'Fintech',
    'Healthtech',
    'Edtech',
    'AI',
    'Ecommerce',
    'SaaS',
    'AgriTech',
    'CleanTech',
    'Mobility',
    'Logistics',
    'Gaming',
    'Biotech',
    'Medtech',
    'Insurtech',
    'Proptech',
    'HRTech',
    'LegalTech',
    'Energy',
    'TravelTech',
    'FoodTech',
    'Robotics',
    'MarTech',
    'AdTech',
    'GovTech',
    'FashionTech'
  ];


  Timer? _debounce;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() async {
    // Initialize in sequence to avoid multiple simultaneous calls
    await fetchUserProfile();
    await fetchStartupData();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  // Start periodic notification checking
  void _startNotificationTimer() {
    if (notifyEnabled) {
      _notificationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        _fetchNotificationCount();
      });
      _fetchNotificationCount(); // Initial fetch
    }
  }

  Future<void> fetchStartupData() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingData) {
      print('⚠️ Already loading data, skipping request');
      return;
    }

    _isLoadingData = true;

    if (!mounted) {
      _isLoadingData = false;
      return;
    }

    setState(() => isLoading = true);

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (searchController.text.trim().isNotEmpty) {
        queryParams['search'] = searchController.text.trim();
      }
      if (selectedSector != 'All') {
        queryParams['sector'] = selectedSector;
      }

      final uri = Uri.parse('$apiBaseUrl/get_startups.php').replace(queryParameters: queryParams);

      print('🔍 Fetching from URL: $uri');

      // Get authentication token
      final token = await secureStorage.read(key: 'auth_token');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔐 Using authentication token');
      } else {
        print('⚠️ No auth token available');
      }

      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body length: ${response.body.length}');

      if (!mounted) {
        _isLoadingData = false;
        return;
      }

      if (response.statusCode == 200) {
        await _processSuccessResponse(response.body);
      } else {
        await _handleErrorResponse(response.statusCode, response.body);
      }
    } catch (e) {
      print('💥 Network/General error: $e');
      if (mounted) {
        setState(() {
          companyData = [];
          isLoading = false;
        });

        String errorMessage = _getErrorMessage(e);
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _processSuccessResponse(String responseBody) async {
    try {
      final responseBodyTrimmed = responseBody.trim();

      if (responseBodyTrimmed.isEmpty) {
        print('❌ Empty response body');
        setState(() {
          companyData = [];
          isLoading = false;
        });
        _showErrorSnackBar('Server returned empty response');
        return;
      }

      final data = json.decode(responseBodyTrimmed) as Map<String, dynamic>? ?? {};
      print('✅ JSON decoded successfully');
      print('🔍 Data keys: ${data.keys.toList()}');

      // Check for error status in response
      if (data['status'] == 'error') {
        print('❌ API returned error: ${data['message']}');
        setState(() {
          companyData = [];
          isLoading = false;
        });
        _showErrorSnackBar(data['message'] ?? 'Unknown API error');
        return;
      }

      // Extract startups data
      List<dynamic> startups = [];
      if (data['startups'] != null && data['startups'] is List) {
        startups = data['startups'];
      } else if (data['data'] != null && data['data'] is List) {
        startups = data['data'];
      } else {
        print('❌ No valid startups array found');
        setState(() {
          companyData = [];
          isLoading = false;
        });
        _showErrorSnackBar('No startups data found');
        return;
      }

      final processedStartups = _processStartupsData(startups);

      setState(() {
        companyData = processedStartups;
        isLoading = false;
      });

      print('🎉 Successfully loaded ${companyData.length} startups');

      if (processedStartups.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${processedStartups.length} startups'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (jsonError) {
      print('❌ JSON parsing error: $jsonError');
      print('📄 Raw response preview: ${responseBody.length > 200 ? "${responseBody.substring(0, 200)}..." : responseBody}');
      setState(() {
        companyData = [];
        isLoading = false;
      });
      _showErrorSnackBar('Invalid response format from server');
    }
  }

  List<Map<String, dynamic>> _processStartupsData(List<dynamic> startups) {
    List<Map<String, dynamic>> processedStartups = [];

    for (int i = 0; i < startups.length; i++) {
      try {
        final startup = startups[i];
        if (startup is! Map) {
          print('⚠️ Skipping invalid startup at index $i: not a map');
          continue;
        }

        Map<String, dynamic> processedStartup = Map<String, dynamic>.from(startup);

        // Ensure required fields have default values
        processedStartup['id'] = processedStartup['id']?.toString() ?? i.toString();
        processedStartup['name'] = processedStartup['name']?.toString() ?? 'Unknown Startup';
        processedStartup['sector'] = processedStartup['sector']?.toString() ?? '';
        processedStartup['bio'] = processedStartup['bio']?.toString() ?? '';
        processedStartup['location'] = processedStartup['location']?.toString() ?? '';
        processedStartup['website'] = processedStartup['website']?.toString() ?? '';
        processedStartup['role'] = processedStartup['role']?.toString() ?? '';
        processedStartup['skills'] = processedStartup['skills']?.toString() ?? '';
        processedStartup['description'] = processedStartup['description']?.toString() ?? '';

        // Handle avatar_url and logo fields
        processedStartup['avatar_url'] = processedStartup['avatar_url']?.toString() ??
            processedStartup['logo']?.toString() ?? '';

        // Process tags
        processedStartup['tags'] = _processTags(processedStartup['tags']);

        processedStartups.add(processedStartup);
        print('✅ Processed startup: ${processedStartup['name']}');

      } catch (e) {
        print('⚠️ Error processing startup at index $i: $e');
        continue;
      }
    }

    return processedStartups;
  }

  List<String> _processTags(dynamic tags) {
    if (tags == null) return <String>[];

    if (tags is List) {
      return List<String>.from(
          tags.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty)
      );
    } else if (tags is String && tags.isNotEmpty) {
      return tags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return <String>[];
  }

  Future<void> _handleErrorResponse(int statusCode, String responseBody) async {
    print('❌ HTTP Error: $statusCode');
    print('📄 Response body: $responseBody');

    setState(() {
      companyData = [];
      isLoading = false;
    });

    String errorMessage;
    if (statusCode == 401) {
      errorMessage = 'Authentication failed. Please login again.';
    } else if (statusCode == 404) {
      errorMessage = 'Startups endpoint not found.';
    } else if (statusCode == 500) {
      errorMessage = 'Server error. Please try again later.';
    } else {
      errorMessage = 'Server error: $statusCode';
    }

    _showErrorSnackBar(errorMessage);
  }

  String _getErrorMessage(dynamic error) {
    String errorMessage = 'Network error occurred';
    final errorString = error.toString();

    if (errorString.contains('TimeoutException')) {
      errorMessage = 'Request timed out. Please check your connection.';
    } else if (errorString.contains('SocketException')) {
      errorMessage = 'No internet connection';
    } else if (errorString.contains('FormatException')) {
      errorMessage = 'Invalid response format';
    }

    return errorMessage;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: fetchStartupData,
        ),
      ),
    );
  }

  // Fetch notification count
  Future<void> _fetchNotificationCount() async {
    if (!notifyEnabled) return;

    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/get_notifications.php?user_id=${widget.userId ?? '6852'}&count_only=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            unreadNotificationCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }
  Future<void> fetchUserProfile() async {
    try {
      print('🔄 Starting fetchUserProfile...');

      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) {
        print('❌ No auth token found');
        if (mounted) {
          setState(() {
            userName = 'User';
          });
        }
        return;
      }

      print('🔐 Auth token found, making API call...');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/get_profile.php?id=${widget.userId ?? '6852'}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Profile API Response Status: ${response.statusCode}');
      print('📄 Raw API Response: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body.trim()) as Map<String, dynamic>;
          print('✅ JSON decoded successfully');
          print('🔍 Full parsed data: $data');

          if (data['status'] == 'success') {
            final profile = data['profile'] ?? data['data'];
            print('👤 Profile object: $profile');

            if (profile != null && profile is Map) {
              final profileName = profile['name']?.toString() ??
                  profile['full_name']?.toString() ?? '';

              print('📝 Extracted name: "$profileName"');

              if (mounted) {
                setState(() {
                  userName = profileName.isNotEmpty ? profileName : 'User';
                });
                print('✅ User profile loaded: $userName');

                // Force a rebuild of the widget to ensure UI updates
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            } else {
              print('❌ Profile is null or not a Map');
              if (mounted) {
                setState(() {
                  userName = 'User';
                });
              }
            }
          } else {
            print('❌ API status not success: ${data['status']}');
            if (mounted) {
              setState(() {
                userName = 'User';
              });
            }
          }

        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          if (mounted) {
            setState(() {
              userName = 'User';
            });
          }
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            userName = 'User';
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          userName = 'User';
        });
      }
    }
  }
  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), fetchStartupData); // Increased debounce time
  }

  void onSectorSelected(String sector) {
    setState(() => selectedSector = sector);
    fetchStartupData();
  }

  void toggleNotification() {
    setState(() {
      notifyEnabled = !notifyEnabled;
      if (notifyEnabled) {
        _startNotificationTimer();
      } else {
        _notificationTimer?.cancel();
        unreadNotificationCount = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notifyEnabled ? 'Notifications enabled' : 'Notifications disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeetingScreen(),
      ),
    ).then((_) {
      _fetchNotificationCount();
    });
  }

  void navigateToCompanyDetail(Map<String, dynamic> company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          companyData: company,
          userId: widget.userId ?? '',
          isStartupUser: widget.isStartupUser,
        ),
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              fetchStartupData(),
              _fetchNotificationCount(),
            ]);
          },
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading your startups...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: Row(
                  children: [
                    Image.asset('assets/img/Icon.png', height: 32, width: 32),
                    const SizedBox(width: 8),
                    const Text(
                      'N.E.X.T',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                actions: [
                  // Upgrade Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _navigateToNotifications,
                    onDoubleTap: toggleNotification,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notifyEnabled
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            notifyEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: notifyEnabled ? Colors.blue : Colors.grey,
                            size: 24,
                          ),
                          if (notifyEnabled && unreadNotificationCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadNotificationCount > 99
                                      ? '99+'
                                      : unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedBuilder(
                    animation: gradientAnimationController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: getGreetingGradient(
                            gradientBeginAnimation.value,
                            gradientEndAnimation.value,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onProfileTap,
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                backgroundImage: widget.userProfile?['avatar_url'] != null &&
                                    widget.userProfile!['avatar_url'] != ''
                                    ? NetworkImage(widget.userProfile!['avatar_url'])
                                    : const AssetImage('assets/img/default_avatar.png') as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName.isNotEmpty && userName != 'User'
                                        ? '${getGreeting()}, $userName'
                                        : getGreeting(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  Text(
                                    'Discover innovative startups',
                                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search startups...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sectorOptions.map((sector) {
                            final isSelected = sector == selectedSector;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  sector,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[800],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) => onSectorSelected(sector),
                                selectedColor: Colors.blue,
                                backgroundColor: Colors.grey[200],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Startups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: widget.verticalList ? null : 120,
                        child: companyData.isEmpty
                            ? Center(child: Text('No startups found.', style: TextStyle(color: Colors.grey[600])))
                            : widget.verticalList
                            ? ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: companyData.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final startup = companyData[index];
                            return GestureDetector(
                              onTap: () => navigateToCompanyDetail(startup),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.07),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: (startup['avatar_url'] != null && startup['avatar_url'] != '')
                                          ? NetworkImage(startup['avatar_url'])
                                          : const AssetImage('assets/img/default_avatar.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            startup['name'] ?? 'Startup',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.1),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if ((startup['sector'] ?? '').isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent.withOpacity(0.13),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                startup['sector'],
                                                style: const TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          if ((startup['tagline'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                startup['tagline'],
                                                style: const TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.chevron_right, color: Colors.blueAccent, size: 28),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                            : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: companyData.length,
                          separatorBuilder: (context, i) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final startup = companyData[index];
                            return GestureDetector(
                              onTap: () => navigateToCompanyDetail(startup),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: (startup['avatar_url'] != null && startup['avatar_url'] != '')
                                          ? NetworkImage(startup['avatar_url'])
                                          : const AssetImage('assets/img/default_avatar.png') as ImageProvider,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      startup['name'] ?? 'Startup',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}