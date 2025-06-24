import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home.dart';
import 'animated_greeting_gradient_mixin.dart';

class CompanyProfileScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;
  const CompanyProfileScreen({Key? key, required this.companyData}) : super(key: key);

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<CompanyProfileScreen> {
  File? _coverPhoto;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _coverPhoto = File(picked.path);
      });
      // TODO: Upload logic here
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover photo updated (mock)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyData = widget.companyData;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          companyData['name'] ?? 'Company Name',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo with profile picture overlay
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickCoverPhoto,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      image: _coverPhoto != null
                          ? DecorationImage(image: FileImage(_coverPhoto!), fit: BoxFit.cover)
                          : (companyData['coverPhoto'] != null && companyData['coverPhoto'].toString().isNotEmpty)
                              ? DecorationImage(image: NetworkImage(companyData['coverPhoto']), fit: BoxFit.cover)
                              : null,
                    ),
                    child: _coverPhoto == null && (companyData['coverPhoto'] == null || companyData['coverPhoto'].toString().isEmpty)
                        ? AnimatedBuilder(
                            animation: gradientAnimationController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: getGreetingGradient(
                                    gradientBeginAnimation.value,
                                    gradientEndAnimation.value,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo, color: Colors.blueGrey, size: 32),
                                      SizedBox(height: 8),
                                      Text('Add Cover Photo', style: TextStyle(color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: -48,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: companyData['logo'] != null && companyData['logo'].toString().isNotEmpty
                        ? NetworkImage(companyData['logo'])
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: companyData['logo'] == null || companyData['logo'].toString().isEmpty
                        ? const Icon(Icons.business, size: 48, color: Colors.blueGrey)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            // Name, tagline, sector
            Center(
              child: Column(
                children: [
                  Text(
                    companyData['name'] ?? 'Company Name',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  if (companyData['tagline'] != null && companyData['tagline'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        companyData['tagline'],
                        style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (companyData['sector'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        companyData['sector'],
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // About Us
            Text('About Us', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              companyData['about'] ?? 'We are a leading investment company focused on nurturing and scaling innovative startups. Our mission is to empower entrepreneurs and drive growth in the startup ecosystem.',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            // Investment Focus
            Text('Investment Focus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _InvestmentFocusSection(companyData: companyData),
            const SizedBox(height: 24),
            // Key People (optional)
            if (companyData['keyPeople'] != null && (companyData['keyPeople'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key People', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate((companyData['keyPeople'] as List).length, (i) {
                    final person = companyData['keyPeople'][i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: person['photo'] != null ? NetworkImage(person['photo']) : null,
                        child: person['photo'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(person['name'] ?? ''),
                      subtitle: Text(person['role'] ?? ''),
                    );
                  }),
                ],
              ),
            if (companyData['keyPeople'] != null && (companyData['keyPeople'] as List).isNotEmpty)
              const SizedBox(height: 24),
            // Contact/Links
            Text('Contact', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ContactSection(companyData: companyData),
            const SizedBox(height: 32),
            // Marketing/CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Looking to invest in the next big thing?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Let startups know what makes your company the ideal partner for their growth journey. Showcase your portfolio, success stories, and vision.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement connect/startup pitch action
                    },
                    icon: const Icon(Icons.connect_without_contact),
                    label: const Text('Connect with Us'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            // Portfolio/Investments section
            if (companyData['portfolio'] != null && (companyData['portfolio'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Investments', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: (companyData['portfolio'] as List).map<Widget>((startup) {
                        // If startup is a map with logo and name, show logo; else just name
                        if (startup is Map && startup['logo'] != null) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(startup['logo']),
                                backgroundColor: Colors.grey[200],
                              ),
                              const SizedBox(height: 4),
                              Text(startup['name'] ?? '', style: const TextStyle(fontSize: 14)),
                            ],
                          );
                        } else {
                          return Chip(label: Text(startup.toString()));
                        }
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentFocusSection extends StatelessWidget {
  final Map<String, dynamic> companyData;
  const _InvestmentFocusSection({required this.companyData});

  @override
  Widget build(BuildContext context) {
    // Example fields: ticketSize, preferredSectors, stage, portfolio
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('Ticket Size: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(companyData['ticketSize'] ?? 'Up to \$1M'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.category, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 8),
            Text('Preferred Sectors: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(companyData['preferredSectors'] ?? 'Technology, Health, Fintech'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.timeline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text('Stage: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(companyData['stage'] ?? 'Seed, Series A'),
          ],
        ),
        if (companyData['portfolio'] != null && (companyData['portfolio'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Portfolio Highlights:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: List.generate((companyData['portfolio'] as List).length, (i) {
              final startup = companyData['portfolio'][i];
              return Chip(
                label: Text(startup),
                backgroundColor: Colors.blue.shade100,
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  final Map<String, dynamic> companyData;
  const _ContactSection({required this.companyData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyData['website'] != null)
          Row(
            children: [
              const Icon(Icons.language, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  companyData['website'],
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (companyData['email'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    companyData['email'],
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (companyData['phone'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    companyData['phone'],
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (companyData['linkedin'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    companyData['linkedin'],
                    style: const TextStyle(color: Colors.blueGrey, decoration: TextDecoration.underline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
