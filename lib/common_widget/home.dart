import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_app/common_widget/items_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Import your NotificationsScreen file here
import 'NotificationsScreen.dart';  // Adjust the path if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

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
  RealtimeChannel? notifChannel;

  @override
  void initState() {
    super.initState();
    fetchStartupData();
    fetchNotificationPreference();
    subscribeToNotifications();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    // Unsubscribe notification realtime channel properly
    notifChannel?.unsubscribe();
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
    notifChannel = supabase.channel('public:notifications_channel');

    notifChannel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
      ),
          (payload, [ref]) {
        final newRecord = payload['new'];
        if (newRecord != null && notifyEnabled && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newRecord['title']}: ${newRecord['body']}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    notifChannel!.subscribe();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/img/Icon.png', height: 32, width: 32),

                    // Notification and toggle buttons grouped
                    Row(
                      children: [
                        // Open notifications list screen button
                        IconButton(
                          icon: const Icon(Icons.notifications_active, size: 28),
                          color: Colors.blue,
                          tooltip: 'View Notifications',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),

                        // Enable/disable notification toggle
                        IconButton(
                          icon: Icon(
                            notifyEnabled ? Icons.notifications : Icons.notifications_off,
                            color: notifyEnabled ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          onPressed: toggleNotification,
                          tooltip: notifyEnabled
                              ? "Disable Notifications"
                              : "Enable Notifications",
                        ),
                      ],
                    ),
                  ],
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

              // Filter Chips
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

              // Company List
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: companyData.length,
                itemBuilder: (context, index) {
                  final company = companyData[index];
                  return CompanyCard(
                    logoUrl: company['logo'],
                    name: company['name'],
                    sector: company['sector'],
                    tags: List<String>.from(company['tags'] ?? []),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
