import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import MessagesScreen
import 'chat_screen.dart'; // Import ChatScreen
import 'package:url_launcher/url_launcher.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;
  final String widget.userId;

  const CompanyDetailScreen({
    super.key,
    required this.companyData,
    required this.widget.userId,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool isFollowing = false;
  bool isLoadingFollow = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz4KICAgIDxwYXR0ZXJuIGlkPSJncmlkIiB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHBhdHRlcm5Vbml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8cGF0aCBkPSJNIDQwIDAgTCAwIDAgMCA0MCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEiLz4KICAgIDwvcGF0dGVybj4KICA8L2RlZnM+CiAgPHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNncmlkKSIvPgo8L3N2Zz4='),
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Company info
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Enhanced company logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: widget.companyData['logo'] != null && widget.companyData['logo'].toString().isNotEmpty
                                  ? Image.network(
                                widget.companyData['logo'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderLogo();
                                },
                              )
                                  : _buildPlaceholderLogo(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Company name with enhanced styling
                          Text(
                            widget.companyData['name'] ?? 'Company Name',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Enhanced sector badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.companyData['sector'] ?? 'Technology',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Location if available
                          if (widget.companyData['location'] != null && widget.companyData['location'].toString().isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  widget.companyData['location'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Professional content sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats row
                  _buildQuickStats(),
                  const SizedBox(height: 24),

                  // About section
                  _buildAboutSection(),
                  const SizedBox(height: 24),

                  // Business details
                  _buildBusinessDetails(),
                  const SizedBox(height: 24),

                  // Funding section (if accepting funding)
                  if (_isAcceptingFunding()) ...[
                    _buildFundingSection(context),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  _buildActionButtons(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.business,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.business_center,
              label: 'Industry',
              value: widget.companyData['sector'] ?? 'Technology',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.web,
              label: 'Website',
              value: widget.companyData['website'] != null && widget.companyData['website'].toString().isNotEmpty 
                  ? 'Available' 
                  : 'Not provided',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up,
              label: 'Funding',
              value: _isAcceptingFunding() ? 'Open' : 'Closed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.companyData['bio'] ?? widget.companyData['description'] ?? 'No description available.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          if (widget.companyData['tags'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildTagsList(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTagsList() {
    List<String> tags = [];
    if (widget.companyData['tags'] is List) {
      tags = (widget.companyData['tags'] as List).map((e) => e.toString()).toList();
    } else if (widget.companyData['tags'] != null && widget.companyData['tags'].toString().isNotEmpty) {
      tags = widget.companyData['tags'].toString().split(',').map((e) => e.trim()).toList();
    }

    return tags.map((tag) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    )).toList();
  }

  Widget _buildBusinessDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.companyData['role'] != null && widget.companyData['role'].toString().isNotEmpty)
            _buildDetailRow(Icons.work, 'Role', widget.companyData['role']),
          if (widget.companyData['skills'] != null && widget.companyData['skills'].toString().isNotEmpty)
            _buildDetailRow(Icons.star, 'Skills', widget.companyData['skills']),
          if (widget.companyData['website'] != null && widget.companyData['website'].toString().isNotEmpty)
            _buildDetailRow(Icons.web, 'Website', widget.companyData['website'], isLink: true),
          if (widget.companyData['pitch_video_url'] != null && widget.companyData['pitch_video_url'].toString().isNotEmpty)
            _buildDetailRow(Icons.play_circle, 'Pitch Video', 'Available', isLink: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLink ? Colors.blue.shade600 : Colors.black87,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monetization_on, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Funding Opportunity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.companyData['funding_goal'] != null && widget.companyData['funding_goal'].toString().isNotEmpty) ...[
            Text(
              'Funding Goal: ₹${_formatCurrency(widget.companyData['funding_goal'])}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.companyData['funding_description'] != null && widget.companyData['funding_description'].toString().isNotEmpty) ...[
            Text(
              widget.companyData['funding_description'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showProfessionalPaymentPage(context),
              icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
              label: const Text(
                'Support This Startup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Follow/Unfollow button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoadingFollow ? null : _toggleFollow,
            icon: isLoadingFollow
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isFollowing ? Icons.person_remove : Icons.person_add,
                    color: Colors.white,
                  ),
            label: Text(
              isFollowing ? 'Unfollow' : 'Follow',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey.shade600 : Colors.blueAccent,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Message button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentwidget.userId: widget.userId,
                    otherwidget.userId: widget.companyData['id'].toString(),
                    otherUserName: widget.companyData['name'] ?? 'Company',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text(
              'Message Company',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Support button (if not already shown in funding section)
        if (!_isAcceptingFunding()) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                _showMouDialog(context, () => _showProfessionalPaymentPage(context));
              },
              icon: Icon(Icons.favorite, color: Colors.green.shade600),
              label: Text(
                'Support Company',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.shade600, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        // UPI button
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text('Pay with UPI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await launchUPIPayment(
                context: context,
                upiId: widget.companyData['upi_id'] ?? 'yourupi@okicici', // Replace with actual UPI ID or add to your data
                name: widget.companyData['name'] ?? 'Company',
                amount: '100', // You can get this from user input or dialog
                transactionNote: 'Support for ${widget.companyData['name']}',
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow() async {
    setState(() => isLoadingFollow = true);

    try {
      final storage = const FlutterSecureStorage();
      final currentwidget.userId = await storage.read(key: 'user_id');

      if (currentwidget.userId == null) {
        _showSnackBar('Please log in to follow');
        setState(() => isLoadingFollow = false);
        return;
      }

      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': currentwidget.userId,
          'following_id': widget.companyData['id'].toString(),
          'action': isFollowing ? 'unfollow' : 'follow',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            isFollowing = !isFollowing;
          });
          _showSnackBar(isFollowing ? 'Following now!' : 'Unfollowed');
        } else {
          _showSnackBar(data['message'] ?? 'Failed to update follow status');
        }
      } else {
        _showSnackBar('Server error. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => isLoadingFollow = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isAcceptingFunding() {
    return widget.companyData['accepting_funding'] == 1 || 
           widget.companyData['accepting_funding'] == '1' ||
           widget.companyData['accepting_funding'] == true;
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    try {
      double value = double.parse(amount.toString());
      if (value >= 10000000) { // 1 crore
        return '${(value / 10000000).toStringAsFixed(1)}Cr';
      } else if (value >= 100000) { // 1 lakh
        return '${(value / 100000).toStringAsFixed(1)}L';
      } else if (value >= 1000) { // 1 thousand
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    } catch (e) {
      return amount.toString();
    }
  }

  void _showProfessionalPaymentPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalPaymentPage(
          companyData: companyData,
          widget.userId: widget.userId,
        ),
      ),
    );
  }

  void _showMouDialog(BuildContext context, VoidCallback onAgreed) {
    final companyName = widget.companyData['name'] ?? 'Partner';
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    bool agreed = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('📄 Memorandum of Understanding (MoU)'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Between Xpress AI and $companyName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Dated: $dateStr'),
                    const SizedBox(height: 12),
                    Text('This MoU outlines a mutual understanding between Xpress AI, developers of the Next.js application "N.E.X.T", and $companyName, regarding collaboration in the use, testing, and enhancement of the platform.'),
                    const SizedBox(height: 12),
                    const Text('1. Purpose', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('To collaborate on the use and/or testing of "N.E.X.T", a web application developed in Next.js for startup and innovation management.'),
                    const SizedBox(height: 8),
                    const Text('2. Responsibilities', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Xpress AI will provide platform access, updates, and technical support.\n$companyName agrees to use the platform, provide feedback, and maintain confidentiality.'),
                    const SizedBox(height: 8),
                    const Text('3. Confidentiality', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Both parties will keep any shared technical or business information confidential.'),
                    const SizedBox(height: 8),
                    const Text('4. Duration & Termination', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('This MoU is valid for 3 months from the signing date and may be ended by either party with written notice.'),
                    const SizedBox(height: 16),
                    Text('Signed by:'),
                    const SizedBox(height: 8),
                    Text('Xpress AI\nRole: Developer / Owner\nDate: _____________'),
                    Text('$companyName\nRole: Startup\nDate: _____________'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (v) => setState(() => agreed = v ?? false),
                        ),
                        const Expanded(child: Text('I agree to the terms above.')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: agreed ? () {
                    Navigator.pop(context);
                    onAgreed();
                  } : null,
                  child: const Text('OK / Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> launchUPIPayment({
    required BuildContext context,
    required String upiId,
    required String name,
    required String amount,
    String? transactionNote,
  }) async {
    final uri = Uri.parse(
      'upi://pay?pa=$upiId&pn=$name&am=$amount&tn=${Uri.encodeComponent(transactionNote ?? "")}&cu=INR',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch UPI app')),
      );
    }
  }
}

// Professional Payment Page
class ProfessionalPaymentPage extends StatefulWidget {
  final Map<String, dynamic> companyData;
  final String widget.userId;

  const ProfessionalPaymentPage({
    super.key,
    required this.companyData,
    required this.widget.userId,
  });

  @override
  State<ProfessionalPaymentPage> createState() => _ProfessionalPaymentPageState();
}

class _ProfessionalPaymentPageState extends State<ProfessionalPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  late Razorpay _razorpay;
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  final List<int> _quickAmounts = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Support Startup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company info header
            _buildCompanyHeader(),
            const SizedBox(height: 24),

            // Amount selection
            _buildAmountSection(),
            const SizedBox(height: 24),

            // Personal details
            _buildPersonalDetailsSection(),
            const SizedBox(height: 24),

            // Payment methods
            _buildPaymentMethodsSection(),
            const SizedBox(height: 24),

            // Message section
            _buildMessageSection(),
            const SizedBox(height: 32),

            // Pay button
            _buildPayButton(),
            const SizedBox(height: 16),

            // Security notice
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.companyData['logo'] != null && widget.companyData['logo'].toString().isNotEmpty
                  ? Image.network(
                widget.companyData['logo'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade600],
                      ),
                    ),
                    child: const Icon(Icons.business, color: Colors.white, size: 30),
                  );
                },
              )
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                  ),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supporting',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.companyData['name'] ?? 'Company Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (widget.companyData['sector'] != null)
                  Text(
                    widget.companyData['sector'],
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
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) => GestureDetector(
              onTap: () {
                setState(() {
                  _amountController.text = amount.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _amountController.text == amount.toString() 
                      ? Colors.blue.shade600 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _amountController.text == amount.toString() 
                        ? Colors.blue.shade600 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    color: _amountController.text == amount.toString() 
                        ? Colors.white 
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          // Custom amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter Custom Amount',
              prefixText: '₹ ',
              hintText: 'Minimum ₹10',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodOption(
            'card',
            'Credit/Debit Card',
            Icons.credit_card,
            'Pay securely with your card',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'upi',
            'UPI',
            Icons.account_balance_wallet,
            'Pay with UPI apps like GPay, PhonePe',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'netbanking',
            'Net Banking',
            Icons.account_balance,
            'Pay directly from your bank account',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'wallet',
            'Digital Wallets',
            Icons.wallet,
            'Pay with Paytm, Amazon Pay, etc.',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon, String subtitle) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == value ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == value ? Colors.blue.shade600 : Colors.grey.shade300,
            width: _selectedPaymentMethod == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == value ? Colors.blue.shade600 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedPaymentMethod == value ? Colors.blue.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedPaymentMethod == value)
              Icon(
                Icons.check_circle,
                color: Colors.blue.shade600,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Message (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write a message of support for this startup...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Pay ₹${_amountController.text.isEmpty ? "0" : _amountController.text}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'Your payment is secured by Razorpay with 256-bit SSL encryption',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    // Validate inputs
    if (_amountController.text.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 10) {
      _showError('Minimum amount is ₹10');
      return;
    }

    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    var options = {
      'key': 'rzp_test_YOUR_KEY_ID', // Replace with your actual Razorpay key
      'amount': (amount * 100).toInt(),
      'name': widget.companyData['name'] ?? 'Company',
      'description': 'Support for ${widget.companyData['name'] ?? 'Company'}',
      'prefill': {
        'contact': _phoneController.text,
        'email': _emailController.text,
        'name': _nameController.text,
      },
      'method': {
        'card': _selectedPaymentMethod == 'card',
        'upi': _selectedPaymentMethod == 'upi',
        'netbanking': _selectedPaymentMethod == 'netbanking',
        'wallet': _selectedPaymentMethod == 'wallet',
      },
      'theme': {
        'color': '#4CAF50',
      },
      'notes': {
        'recipient_id': widget.companyData['id'],
        'supporter_message': _messageController.text,
        'payment_method': _selectedPaymentMethod,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isProcessing = false;
    });
    
    Navigator.pop(context);
    
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for supporting ${widget.companyData['name']}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment ID: ${response.paymentId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
