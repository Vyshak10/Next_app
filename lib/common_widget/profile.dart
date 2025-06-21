//profile.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBackTap;

  const ProfileScreen({Key? key, required this.userId, required this.onBackTap}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  late Razorpay _razorpay;
  
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  bool isEditing = false;
  bool isUploadingAvatar = false;
  bool _acceptingFunding = true;
  
  // Controllers for editing
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _bioController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _sectorController = TextEditingController();
  final _videoController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _fundingDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _sectorController.dispose();
    _videoController.dispose();
    _fundingGoalController.dispose();
    _fundingDescriptionController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // Payment Handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _showSuccessSnackBar('Payment successful! Payment ID: ${response.paymentId}');
    _recordPayment(response.paymentId!, response.orderId, response.signature);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorSnackBar('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showErrorSnackBar('External wallet selected: ${response.walletName}');
  }

  Future<void> _recordPayment(String paymentId, String? orderId, String? signature) async {
    try {
      final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/record_payment.php');
      final response = await http.post(uri, body: {
        'payment_id': paymentId,
        'order_id': orderId ?? '',
        'signature': signature ?? '',
        'recipient_id': widget.userId,
        'payer_id': await _getCurrentUserId(),
        'status': 'completed',
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('Payment recorded successfully');
        }
      }
    } catch (e) {
      print('Error recording payment: $e');
    }
  }

  Future<String> _getCurrentUserId() async {
    // Get current user ID from secure storage or your auth system
    return await storage.read(key: 'user_id') ?? 'anonymous';
  }

  Future<void> _createPaymentOrder(double amount, String currency) async {
    try {
      final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_payment_order.php');
      final response = await http.post(uri, body: {
        'amount': (amount * 100).toString(), // Razorpay expects amount in paise
        'currency': currency,
        'recipient_id': widget.userId,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _openRazorpayCheckout(data['order_id'], amount, currency);
        } else {
          _showErrorSnackBar('Failed to create payment order');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error creating payment order: $e');
    }
  }

  void _openRazorpayCheckout(String orderId, double amount, String currency) {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
      'amount': (amount * 100).toInt(),
      'name': 'Fund ${profile?['name'] ?? 'User'}',
      'description': 'Supporting ${profile?['name'] ?? 'this person'}\'s work',
      'order_id': orderId,
      'prefill': {
        'contact': '',
        'email': ''
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showErrorSnackBar('Error opening Razorpay: $e');
    }
  }

  void _showFundingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SizedBox.shrink(),
      ),
    );
  }

  Future<void> fetchProfileData() async {
    final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=${widget.userId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Process posts with proper image URL handling
        final rawPosts = List<Map<String, dynamic>>.from(data['posts'] ?? []);
        for (var post in rawPosts) {
          if (post['image_urls'] is String) {
            try {
              post['image_urls'] = json.decode(post['image_urls']);
            } catch (_) {
              post['image_urls'] = [];
            }
          }
        }
        
        setState(() {
          profile = Map<String, dynamic>.from(data['profile'] ?? {});
          posts = rawPosts;
          
          // Initialize controllers with profile data
          _updateControllers();
          
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load profile data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Network error occurred');
    }
  }

  void _updateControllers() {
    _nameController.text = profile?['name'] ?? '';
    _roleController.text = profile?['role'] ?? '';
    _bioController.text = profile?['bio'] ?? '';
    _descriptionController.text = profile?['description'] ?? '';
    _skillsController.text = profile?['skills'] ?? '';
    _websiteController.text = profile?['website'] ?? '';
    _locationController.text = profile?['location'] ?? '';
    _sectorController.text = profile?['sector'] ?? '';
    _videoController.text = profile?['pitch_video_url'] ?? '';
  }

  Future<void> saveProfileChanges() async {
    final uri = Uri.parse("https://indianrupeeservices.in/NEXT/backend/update_profile.php");
    try {
      final response = await http.post(uri, body: {
        "id": widget.userId,
        "name": _nameController.text.trim(),
        "role": _roleController.text.trim(),
        "bio": _bioController.text.trim(),
        "description": _descriptionController.text.trim(),
        "skills": _skillsController.text.trim(),
        "website": _websiteController.text.trim(),
        "location": _locationController.text.trim(),
        "sector": _sectorController.text.trim(),
        "pitch_video_url": _videoController.text.trim(),
      });
      
      if (response.statusCode == 200) {
        // Update local profile data immediately for real-time reflection
        setState(() {
          profile?['name'] = _nameController.text.trim();
          profile?['role'] = _roleController.text.trim();
          profile?['bio'] = _bioController.text.trim();
          profile?['description'] = _descriptionController.text.trim();
          profile?['skills'] = _skillsController.text.trim();
          profile?['website'] = _websiteController.text.trim();
          profile?['location'] = _locationController.text.trim();
          profile?['sector'] = _sectorController.text.trim();
          profile?['pitch_video_url'] = _videoController.text.trim();
          isEditing = false;
        });
        
        _showSuccessSnackBar('Profile updated successfully');
        // Optionally refresh from server to ensure consistency
        // await fetchProfileData();
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred');
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      setState(() => isUploadingAvatar = true);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/upload_avatar.php'),
      );
      
      request.fields['user_id'] = widget.userId;
      request.files.add(await http.MultipartFile.fromPath('avatar', image.path));
      
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseString);
        if (jsonResponse['success'] == true) {
          await fetchProfileData(); // Refresh profile data
          _showSuccessSnackBar('Avatar updated successfully');
        } else {
          _showErrorSnackBar('Failed to upload avatar');
        }
      } else {
        _showErrorSnackBar('Upload failed');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading avatar: $e');
    } finally {
      setState(() => isUploadingAvatar = false);
    }
  }

  Future<void> _launchYouTubeVideo(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not launch video');
    }
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Images
                      if (post['image_urls'] != null && post['image_urls'].isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: post['image_urls'].length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  post['image_urls'][index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Post Content
                      if (post['content'] != null && post['content'].toString().isNotEmpty) ...[
                        const Text(
                          'Content',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['content'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Post Description
                      if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['description'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Post Date
                      if (post['created_at'] != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Posted on ${post['created_at']}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Likes and other stats
                      if (post['likes_count'] != null || post['comments_count'] != null)
                        Row(
                          children: [
                            if (post['likes_count'] != null) ...[
                              const Icon(Icons.favorite, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('${post['likes_count']} likes'),
                              const SizedBox(width: 16),
                            ],
                            if (post['comments_count'] != null) ...[
                              const Icon(Icons.comment, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text('${post['comments_count']} comments'),
                            ],
                          ],
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

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 4,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage your app preferences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Settings options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsItem(
                    icon: Icons.account_balance_wallet,
                    title: 'Funding Settings',
                    subtitle: _acceptingFunding ? 'Currently accepting funding' : 'Not accepting funding',
                    onTap: _showFundingSettings,
                  ),
                  _buildSettingsItem(
                    icon: Icons.palette,
                    title: 'Theme',
                    subtitle: 'Light',
                    onTap: () => _showThemeDialog(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () => _showNotificationSettings(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy',
                    subtitle: 'Control your privacy settings',
                    onTap: () => _showPrivacySettings(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    subtitle: 'Get help and find answers',
                    onTap: () => _showHelpAndFAQ(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    subtitle: 'Legal terms and conditions',
                    onTap: () => _showTermsAndConditions(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.policy,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => _showPrivacyPolicy(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () => _showLogoutDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade600 : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light Theme'),
              leading: Radio<String>(
                value: 'light',
                groupValue: 'light',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
            ListTile(
              title: const Text('Dark Theme'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: 'light',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<String>(
                value: 'system',
                groupValue: 'light',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.pop(context);
    _showErrorSnackBar('Notification settings coming soon!');
  }

  void _showPrivacySettings() {
    Navigator.pop(context);
    _showErrorSnackBar('Privacy settings coming soon!');
  }

  void _showHelpAndFAQ() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Q: How do I update my profile?'),
              Text('A: Tap the edit icon next to "Profile Information" to make changes.'),
              SizedBox(height: 8),
              Text('Q: How do I upload a profile picture?'),
              Text('A: Tap the camera icon on your profile picture to upload a new one.'),
              SizedBox(height: 8),
              Text('Q: How do I add a pitch video?'),
              Text('A: Enter your YouTube video ID in the profile edit section.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'Your App Name',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.apps, size: 48),
      children: const [
        Text('A professional networking and profile management application.'),
      ],
    );
  }

  void _showTermsAndConditions() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms and Conditions\n\n'
            '1. Acceptance of Terms\n'
            'By using this application, you agree to these terms.\n\n'
            '2. User Responsibilities\n'
            'Users are responsible for maintaining accurate profile information.\n\n'
            '3. Privacy\n'
            'We respect your privacy and handle data responsibly.\n\n'
            '4. Prohibited Activities\n'
            'Users must not engage in harmful or illegal activities.\n\n'
            '5. Modifications\n'
            'These terms may be updated from time to time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'We collect and use your information to provide and improve our services.\n\n'
            'Information We Collect:\n'
            '• Profile information you provide\n'
            '• Usage data and preferences\n'
            '• Device information\n\n'
            'How We Use Your Information:\n'
            '• To provide app functionality\n'
            '• To improve user experience\n'
            '• To communicate with you\n\n'
            'Data Security:\n'
            'We implement appropriate security measures to protect your information.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add logout logic here
              _showErrorSnackBar('Logout functionality to be implemented');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarUrl = profile?['avatar_url'];
    final hasAvatar = avatarUrl != null && avatarUrl.toString().isNotEmpty;
    final name = profile?['name'] ?? 'Unknown User';
    final role = profile?['role'] ?? '';
    final userType = profile?['user_type'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
            Colors.blue.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar 
                      ? Icon(Icons.person, size: 55, color: Colors.grey[600]) 
                      : null,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar 
                      ? Icon(Icons.person, size: 55, color: Colors.grey[600]) 
                      : null,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade600,
                    child: isUploadingAvatar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            onPressed: _uploadAvatar,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Name and Role
          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                role,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (userType.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                userType.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isEditing ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (isEditing) {
                        saveProfileChanges();
                      } else {
                        setState(() => isEditing = true);
                      }
                    },
                    icon: Icon(
                      isEditing ? Icons.save : Icons.edit,
                      color: isEditing ? Colors.green.shade600 : Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (isEditing) ...[
              _buildEditableField("Name", _nameController),
              _buildEditableField("Role", _roleController),
              _buildEditableField("Bio", _bioController, maxLines: 2),
              _buildEditableField("Description", _descriptionController, maxLines: 3),
              _buildEditableField("Skills", _skillsController),
              _buildEditableField("Website", _websiteController),
              _buildEditableField("Location", _locationController),
              _buildEditableField("Sector", _sectorController),
              _buildEditableField("YouTube Video ID", _videoController),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isEditing = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveProfileChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildInfoRow(Icons.info, 'Bio', profile?['bio']),
              _buildInfoRow(Icons.description, 'Description', profile?['description']),
              _buildInfoRow(Icons.work, 'Skills', profile?['skills']),
              _buildInfoRow(Icons.language, 'Website', profile?['website']),
              _buildInfoRow(Icons.location_on, 'Location', profile?['location']),
              _buildInfoRow(Icons.business, 'Sector', profile?['sector']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchVideoSection() {
    final videoId = profile?['pitch_video_url']?.toString().trim() ?? '';
    if (videoId.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pitch Video',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _launchYouTubeVideo(videoId),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_library, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Video not available', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo_library,
                        color: Colors.purple.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Posts',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${posts.length} posts',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            posts.isEmpty
                ? Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Share your first post to get started',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final imageUrls = post['image_urls'] ?? [];
                      final firstImage = imageUrls.isNotEmpty ? imageUrls[0] : null;
                      
                      return GestureDetector(
                        onTap: () => _showPostDetails(post),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                firstImage != null
                                    ? Image.network(
                                        firstImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                if (imageUrls.length > 1)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.photo_library, color: Colors.white, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${imageUrls.length}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
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
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showFundingSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Funding Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Accept Funding'),
                  subtitle: const Text('Allow others to support you financially'),
                  value: _acceptingFunding,
                  onChanged: (value) {
                    setDialogState(() {
                      _acceptingFunding = value;
                    });
                  },
                  activeColor: Colors.green.shade600,
                ),
                if (_acceptingFunding) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fundingGoalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Funding Goal (₹)',
                      prefixIcon: const Icon(Icons.track_changes),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Optional target amount',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fundingDescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Funding Description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Describe what the funding will be used for',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
              _showSuccessSnackBar('Funding settings will be saved with profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackTap,
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildInfoSection(),
                  _buildPitchVideoSection(),
                  _buildPostsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}