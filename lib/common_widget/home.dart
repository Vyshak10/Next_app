import 'package:flutter/material.dart';
import 'package:next_app/common_widget/items_card.dart'; // Assuming you have this widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Define your data here OUTSIDE the build method
  final List<Map<String, dynamic>> companyData = [
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "TechNova",
      "sector": "Information Technology",
      "tags": ["AI", "Cloud", "SaaS"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "HealthBridge",
      "sector": "Healthcare",
      "tags": ["MedTech", "Wellness", "Diagnostics"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "EduSmart",
      "sector": "Education",
      "tags": ["E-Learning", "K12", "EdTech"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "AgroPulse",
      "sector": "Agritech",
      "tags": ["Farming", "Supply Chain", "AI"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "FinFox",
      "sector": "Finance",
      "tags": ["Investments", "Robo Advisor", "FinTech"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "GreenWatt",
      "sector": "Renewable Energy",
      "tags": ["Solar", "Wind", "Clean Energy"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "AutoPilot AI",
      "sector": "Automobile",
      "tags": ["Autonomous", "EV", "Mobility"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "Foodiverse",
      "sector": "FoodTech",
      "tags": ["Delivery", "Recipe AI", "Groceries"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "Buildo",
      "sector": "Construction",
      "tags": ["Materials", "Contracts", "IoT"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "TravelSync",
      "sector": "Travel",
      "tags": ["Booking", "AI Planner", "Flights"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "MarketMe",
      "sector": "Marketing",
      "tags": ["SEO", "Ads", "Email"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "LegalEase",
      "sector": "LegalTech",
      "tags": ["Contracts", "Law", "Automation"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "AquaGuard",
      "sector": "Water Tech",
      "tags": ["Filtration", "IoT", "Sustainability"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "PetPals",
      "sector": "PetCare",
      "tags": ["Veterinary", "Marketplace", "Grooming"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "BookNest",
      "sector": "Publishing",
      "tags": ["E-books", "Self Publishing", "Print"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "FitSphere",
      "sector": "Fitness",
      "tags": ["Training", "Wearables", "Tracking"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "DataHive",
      "sector": "Big Data",
      "tags": ["Analytics", "ETL", "Data Lakes"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "Eventastic",
      "sector": "Events",
      "tags": ["Ticketing", "Planning", "Venue"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/company.png",
      "name": "CyberShield",
      "sector": "Cybersecurity",
      "tags": ["Firewall", "Monitoring", "Security"],
    },
    {
      "logo": "https://img.icons8.com/ios-filled/50/startup.png",
      "name": "SpaceXpress",
      "sector": "Aerospace",
      "tags": ["Satellites", "Launch", "Research"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/img/Icon.png',
                      height: 32,
                      width: 32,
                    ),
                    const Icon(Icons.notifications),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Company List
              ListView.builder(
                physics: NeverScrollableScrollPhysics(), // since inside scrollview
                shrinkWrap: true,
                itemCount: companyData.length,
                itemBuilder: (context, index) {
                  final company = companyData[index];
                  return CompanyCard(
                    logoUrl: company['logo'],
                    name: company['name'],
                    sector: company['sector'],
                    tags: List<String>.from(company['tags']),
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
