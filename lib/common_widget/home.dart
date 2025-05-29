import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:next_app/common_widget/items_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'NotificationsScreen.dart';
import 'company_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();
    fetchStartupData();
    fetchNotificationPreference();
    subscribeToNotifications();
    fetchUserName();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    notifChannel.unsubscribe();
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
        builder: (context) => CompanyDetailScreen(companyData: companyData),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with logo and N.E.X.T text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/img/Icon.png', height: 28, width: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'N.E.X.T',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
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
                        child: Icon(
                          notifyEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: notifyEnabled ? Colors.blue : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Greeting and user name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // User avatar with initials
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          userName.isNotEmpty
                              ? userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      // Greeting and name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty
                                  ? '${getGreeting()}, $userName'
                                  : getGreeting(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Here are your latest updates',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search by name or sector',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sector chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sectorOptions.map((sector) {
                    final isSelected = sector == selectedSector;
                    return ChoiceChip(
                      label: Text(sector),
                      selected: isSelected,
                      onSelected: (_) => onSectorSelected(sector),
                      selectedColor: Colors.blue.shade200,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey[800],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Company list with tap navigation
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: companyData.length,
                itemBuilder: (context, index) {
                  final company = companyData[index];
                  return GestureDetector(
                    onTap: () => navigateToCompanyDetail(company),
                    child: CompanyCard(
                      logoUrl: company['logo'],
                      name: company['name'],
                      sector: company['sector'],
                      tags: List<String>.from(company['tags'] ?? []),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RealtimeChannel>('notifChannel', notifChannel));
  }
}
