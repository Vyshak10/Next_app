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
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Cover photo, avatar, and action buttons
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickCoverPhoto,
                  child: Container(
                    height: 200,
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
                // Action buttons (edit, settings, video)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.blueAccent),
                        onPressed: () {},
                        tooltip: 'Settings',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Avatar
                Positioned(
                  bottom: -48,
                  left: width / 2 - 48,
                  child: Material(
                    elevation: 6,
                    shape: const CircleBorder(),
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
                ),
                // Video upload button (bottom right of cover)
                Positioned(
                  bottom: 12,
                  right: 20,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('Upload 1-min Intro Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
            // Company name, tagline, sector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    companyData['name'] ?? 'Company Name',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
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
            _SectionCard(
              title: 'About Us',
              child: Text(
                companyData['about'] ?? 'We are a leading investment company focused on nurturing and scaling innovative startups. Our mission is to empower entrepreneurs and drive growth in the startup ecosystem.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            // Investment Focus
            _SectionCard(
              title: 'Investment Focus',
              child: _InvestmentFocusSection(companyData: companyData),
            ),
            // Key People
            if (companyData['keyPeople'] != null && (companyData['keyPeople'] as List).isNotEmpty)
              _SectionCard(
                title: 'Key People',
                child: Column(
                  children: List.generate((companyData['keyPeople'] as List).length, (i) {
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
                ),
              ),
            // Contact/Links
            _SectionCard(
              title: 'Contact',
              child: _ContactSection(companyData: companyData),
            ),
            // Portfolio/Investments section
            if (companyData['portfolio'] != null && (companyData['portfolio'] as List).isNotEmpty)
              _SectionCard(
                title: 'Investments',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: (companyData['portfolio'] as List).map<Widget>((startup) {
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

// Add a reusable section card widget for consistent section styling
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
