import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:next_app/common_widget/items_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'NotificationsScreen.dart';
import 'company_detail_screen.dart';
import 'package:next_app/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Map<String, dynamic>? userProfile;

  const HomeScreen({super.key, this.onProfileTap, this.userProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late RealtimeChannel notifChannel;

  List<Map<String, dynamic>> companyData = [];
  bool isLoading = true;
  bool notifyEnabled = true;
  String selectedSector = 'All';

  final List<String> sectorOptions = [
    'All', 'Finance', 'Education', 'Healthcare', 'AI',
    'Aerospace', 'Design', 'Cybersecurity', 'Travel',
    'LegalTech', 'FoodTech', 'Agritech'
  ];

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  String userName = '';

  late AnimationController _gradientAnimationController; // Controller for gradient animation
  late Animation<AlignmentGeometry> _gradientBeginAnimation; // Animation for gradient begin
  late Animation<AlignmentGeometry> _gradientEndAnimation; // Animation for gradient end

  @override
  void initState() {
    super.initState();
    fetchStartupData();
    fetchNotificationPreference();
    subscribeToNotifications();
    fetchUserName();

    // Initialize gradient animation controller
    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 2), // Slightly shorter duration for a quicker pulse
      vsync: this,
    )..repeat(reverse: false); // Repeat animation only forward

    // Define animations for gradient begin and end points for a right-to-left pulse
    _gradientBeginAnimation = Tween<AlignmentGeometry>(
      begin: Alignment(1.0, 0.0), // Dark side fixed on the right
      end: Alignment(1.0, 0.0), // Dark side stays on the right
    ).animate(_gradientAnimationController);

    _gradientEndAnimation = Tween<AlignmentGeometry>(
      begin: Alignment(-0.5, 0.0), // Start transition slightly right of center
      end: Alignment(-1.5, 0.0), // Move transition further left
    ).animate(_gradientAnimationController);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    notifChannel.unsubscribe();
    _gradientAnimationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  Future<void> fetchStartupData() async {
    setState(() => isLoading = true);

    var query = supabase.from('startups').select();
    final searchQuery = searchController.text.trim();

    if (searchQuery.isNotEmpty && selectedSector != 'All') {
      query = query
          .or('name.ilike.%$searchQuery%,sector.ilike.%$searchQuery%')
          .eq('sector', selectedSector);
    } else if (searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,sector.ilike.%$searchQuery%');
    } else if (selectedSector != 'All') {
      query = query.eq('sector', selectedSector);
    }

    final response = await query;

    setState(() {
      companyData = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> fetchNotificationPreference() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final response = await supabase
          .from('profiles')
          .select('notify_enabled')
          .eq('id', userId)
          .single();
      setState(() {
        notifyEnabled = response['notify_enabled'] ?? true;
      });
    }
  }

  Future<void> toggleNotification() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final newValue = !notifyEnabled;
      await supabase
          .from('profiles')
          .update({'notify_enabled': newValue})
          .eq('id', userId);
      setState(() {
        notifyEnabled = newValue;
      });
    }
  }

  void subscribeToNotifications() {
    notifChannel = supabase.channel('public:notifications');

    notifChannel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord != null) {
          print("New Notification: ${newRecord['title']} - ${newRecord['body']}");
        }
      },
    ).subscribe();
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchStartupData();
    });
  }

  void onSectorSelected(String sector) {
    setState(() {
      selectedSector = sector;
    });
    fetchStartupData();
  }

  void navigateToCompanyDetail(Map<String, dynamic> companyData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          companyData: companyData,
          userId: supabase.auth.currentUser?.id ?? '',
        ),
      ),
    );
  }

  Future<void> fetchUserName() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Try to get name from profile table
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      setState(() {
        userName = response['full_name'] ?? user.email ?? '';
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  BoxDecoration _getGreetingDecoration({
    required AlignmentGeometry beginAlignment, // Accept animated begin alignment
    required AlignmentGeometry endAlignment, // Accept animated end alignment
  }) {
    final hour = DateTime.now().hour;

    LinearGradient gradient;

    if (hour >= 5 && hour < 12) {
      // Morning: smoother orange gradient from right darker to left lighter
      gradient = LinearGradient(
        colors: [Colors.orange.shade500!, Colors.orange.shade300!], // Darker to Lighter orange
        begin: beginAlignment, // Use passed animated begin
        end: endAlignment, // Use passed animated end
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: smoother yellow to orange gradient from right darker to left lighter
      gradient = LinearGradient(
        colors: [Colors.orange.shade400!, Colors.yellow.shade300!], // Darker orange to Lighter yellow
        begin: beginAlignment, // Use passed animated begin
        end: endAlignment, // Use passed animated end
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening: smoother blue gradient from right darker to left lighter
      gradient = LinearGradient(
        colors: [Colors.blue.shade800, Colors.blue.shade600], // Darker to Lighter blue
        begin: beginAlignment, // Use passed animated begin
        end: endAlignment, // Use passed animated end
      );
    } else {
      // Night: smoother night gradient from right darker to left lighter
      gradient = LinearGradient(
        colors: [Colors.black87, Colors.blueGrey.shade800], // Darker to Lighter color
        begin: beginAlignment, // Use passed animated begin
        end: endAlignment, // Use passed animated end
      );
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen build called. userProfile: ${widget.userProfile}');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchStartupData,
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your startups...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      leading: null,
                      title: Row(
                        children: [
                          Image.asset('assets/img/Icon.png', height: 32, width: 32),
                          const SizedBox(width: 8),
                          const Text(
                            'N.E.X.T',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        Tooltip(
                          message: notifyEnabled
                              ? "Tap: View Notifications\nLong Press: Disable Notifications"
                              : "Tap: View Notifications\nLong Press: Enable Notifications",
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                            onLongPress: toggleNotification,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: notifyEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                notifyEnabled ? Icons.notifications_active : Icons.notifications_off,
                                color: notifyEnabled ? Colors.blue : Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Greeting Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AnimatedBuilder( // Use AnimatedBuilder to rebuild on animation updates
                          animation: _gradientAnimationController,
                          builder: (context, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 800), // Smooth transition duration
                              padding: const EdgeInsets.all(20),
                              decoration: _getGreetingDecoration( // Pass animated alignments
                                beginAlignment: _gradientBeginAnimation.value,
                                endAlignment: _gradientEndAnimation.value,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      print('Avatar tapped!'); // Added print statement
                                      widget.onProfileTap?.call(); // Call the callback here
                                    },
                                    child: CircleAvatar(
                                      radius: 32, // Use home screen radius
                                      backgroundColor: Colors.white, // Use home screen background
                                      backgroundImage: widget.userProfile?['avatar_url'] != null && widget.userProfile!['avatar_url'] != ''
                                          ? NetworkImage(widget.userProfile!['avatar_url'])
                                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                      child: null, // No default text child when using backgroundImage fallback
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName.isNotEmpty
                                              ? '${getGreeting()}, $userName'
                                              : getGreeting(),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Discover innovative startups',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
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

                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                        fetchStartupData();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Sector Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
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

                    // Company List
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final company = companyData[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () => navigateToCompanyDetail(company),
                                child: CompanyCard(
                                  logoUrl: company['logo'],
                                  name: company['name'],
                                  sector: company['sector'],
                                  tags: List<String>.from(company['tags'] ?? []),
                                ),
                              ),
                            );
                          },
                          childCount: companyData.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RealtimeChannel>('notifChannel', notifChannel));
  }
}
