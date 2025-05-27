import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:next_app/common_widget/items_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'NotificationsScreen.dart'; // Adjust path if needed
import 'company_detail_screen.dart'; // Add this import

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
    )
        .subscribe();
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

  // Navigation function to company detail page
  void navigateToCompanyDetail(Map<String, dynamic> companyData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(companyData: companyData),
      ),
    );
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
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/img/Icon.png', height: 32, width: 32),
                    Row(
                      children: [
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
                        IconButton(
                          icon: Icon(
                            notifyEnabled ? Icons.notifications : Icons.notifications_off,
                            color: notifyEnabled ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          onPressed: toggleNotification,
                          tooltip: notifyEnabled ? "Disable Notifications" : "Enable Notifications",
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