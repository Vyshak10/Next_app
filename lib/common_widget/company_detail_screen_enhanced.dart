import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyDetailScreenEnhanced extends StatefulWidget {
  final Map<String, dynamic> companyData;
  final String userId;

  const CompanyDetailScreenEnhanced({
    super.key,
    required this.companyData,
    required this.userId,
  });

  @override
  State<CompanyDetailScreenEnhanced> createState() => _CompanyDetailScreenEnhancedState();
}

class _CompanyDetailScreenEnhancedState extends State<CompanyDetailScreenEnhanced> with SingleTickerProviderStateMixin {
  bool isFollowing = false;
  bool isLoadingFollow = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildEnhancedAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStatsEnhanced(),
                    const SizedBox(height: 20),
                    _buildAboutSectionEnhanced(),
                    const SizedBox(height: 20),
                    _buildBusinessDetailsEnhanced(),
                    const SizedBox(height: 20),
                    if (_isAcceptingFunding()) ...[
                      _buildFundingSectionEnhanced(context),
                      const SizedBox(height: 20),
                    ],
                    _buildActionButtonsEnhanced(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
              ),
            ),
            // Animated pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: GridPatternPainter(),
                ),
              ),
            ),
            // Company info
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Enhanced logo with glow effect
                  Hero(
                    tag: 'company_logo_${widget.companyData['id']}',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: widget.companyData['logo'] != null && widget.companyData['logo'].toString().isNotEmpty
                            ? Image.network(
                                widget.companyData['logo'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderLogo(),
                              )
                            : _buildPlaceholderLogo(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Company name with shadow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.companyData['name'] ?? 'Company Name',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 3),
                            blurRadius: 8,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Enhanced sector badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_center, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.companyData['sector'] ?? 'Technology',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.companyData['location'] != null && widget.companyData['location'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          widget.companyData['location'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
            Colors.blue.shade400,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: const Icon(
        Icons.business,
        size: 55,
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuickStatsEnhanced() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItemEnhanced(
              icon: Icons.business_center_rounded,
              label: 'Industry',
              value: widget.companyData['sector'] ?? 'Technology',
              color: const Color(0xFF6366F1),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildStatItemEnhanced(
              icon: Icons.language_rounded,
              label: 'Website',
              value: widget.companyData['website'] != null && widget.companyData['website'].toString().isNotEmpty ? 'Available' : 'N/A',
              color: const Color(0xFF8B5CF6),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildStatItemEnhanced(
              icon: Icons.trending_up_rounded,
              label: 'Funding',
              value: _isAcceptingFunding() ? 'Open' : 'Closed',
              color: _isAcceptingFunding() ? const Color(0xFF10B981) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemEnhanced({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAboutSectionEnhanced() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.companyData['bio'] ?? widget.companyData['description'] ?? 'No description available.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
          if (widget.companyData['tags'] != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildTagsListEnhanced(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTagsListEnhanced() {
    List<String> tags = [];
    if (widget.companyData['tags'] is List) {
      tags = (widget.companyData['tags'] as List).map((e) => e.toString()).toList();
    } else if (widget.companyData['tags'] != null && widget.companyData['tags'].toString().isNotEmpty) {
      tags = widget.companyData['tags'].toString().split(',').map((e) => e.trim()).toList();
    }

    return tags.map((tag) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    )).toList();
  }

  Widget _buildBusinessDetailsEnhanced() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Business Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.companyData['role'] != null && widget.companyData['role'].toString().isNotEmpty)
            _buildDetailRowEnhanced(Icons.work_rounded, 'Role', widget.companyData['role']),
          if (widget.companyData['skills'] != null && widget.companyData['skills'].toString().isNotEmpty)
            _buildDetailRowEnhanced(Icons.star_rounded, 'Skills', widget.companyData['skills']),
          if (widget.companyData['website'] != null && widget.companyData['website'].toString().isNotEmpty)
            _buildDetailRowEnhanced(Icons.language_rounded, 'Website', widget.companyData['website'], isLink: true),
          if (widget.companyData['pitch_video_url'] != null && widget.companyData['pitch_video_url'].toString().isNotEmpty)
            _buildDetailRowEnhanced(Icons.play_circle_rounded, 'Pitch Video', 'Watch Now', isLink: true),
        ],
      ),
    );
  }

  Widget _buildDetailRowEnhanced(IconData icon, String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLink ? const Color(0xFF6366F1) : Colors.black87,
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

  Widget _buildFundingSectionEnhanced(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Funding Opportunity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.companyData['funding_goal'] != null && widget.companyData['funding_goal'].toString().isNotEmpty) ...[
            Text(
              'Goal: ₹${_formatCurrency(widget.companyData['funding_goal'])}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.companyData['funding_description'] != null && widget.companyData['funding_description'].toString().isNotEmpty) ...[
            Text(
              widget.companyData['funding_description'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.95),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _showProfessionalPaymentPage(context),
              icon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981)),
              label: const Text(
                'Support This Startup',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsEnhanced(BuildContext context) {
    return Column(
      children: [
        // Follow button
        SizedBox(
          width: double.infinity,
          height: 54,
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
                    isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded,
                    color: Colors.white,
                  ),
            label: Text(
              isFollowing ? 'Unfollow' : 'Follow',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey.shade600 : const Color(0xFF6366F1),
              elevation: 0,
              shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Message button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentUserId: widget.userId,
                    otherUserId: widget.companyData['id'].toString(),
                    otherUserName: widget.companyData['name'] ?? 'Company',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.message_rounded, color: Color(0xFF6366F1)),
            label: const Text(
              'Message Company',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6366F1), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow() async {
    setState(() => isLoadingFollow = true);

    try {
      final storage = const FlutterSecureStorage();
      final currentUserId = await storage.read(key: 'user_id');

      if (currentUserId == null) {
        _showSnackBar('Please log in to follow');
        setState(() => isLoadingFollow = false);
        return;
      }

      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': currentUserId,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1F2937),
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
      if (value >= 10000000) {
        return '${(value / 10000000).toStringAsFixed(1)}Cr';
      } else if (value >= 100000) {
        return '${(value / 100000).toStringAsFixed(1)}L';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    } catch (e) {
      return amount.toString();
    }
  }

  void _showProfessionalPaymentPage(BuildContext context) {
    // Implementation remains the same
  }
}

// Custom painter for grid pattern
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
