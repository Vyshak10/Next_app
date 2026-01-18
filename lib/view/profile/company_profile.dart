//profile.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:your_app_name/view/messages/chat_list_page.dart';
// If you need to use ChatListPage, use the correct import:
// import '../view/messages/chat_list_page.dart';
import '../../common_widget/animated_greeting_gradient_mixin.dart';
import '../settings/settings_screen.dart';
import '../../../services/image_picker_service.dart';
import 'dart:typed_data';
import 'dart:io'; // Added for File

class CompanyProfileScreen extends StatefulWidget {
  final String? userId;
  final VoidCallback onBackTap;

  const CompanyProfileScreen({super.key, this.userId, required this.onBackTap});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<CompanyProfileScreen> {
  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  late Razorpay _razorpay;
  
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  bool isEditing = false;
  bool isUploadingAvatar = false;
  bool _acceptingFunding = true;
  String? _resolvedUserId;
  
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

  Uint8List? _pickedAvatarBytes;

  // Dummy data for demonstration
  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Alice Johnson',
      'role': 'CEO',
      'photo': 'https://randomuser.me/api/portraits/women/44.jpg',
      'linkedin': 'https://linkedin.com/in/alicejohnson',
    },
    {
      'name': 'Bob Smith',
      'role': 'CTO',
      'photo': 'https://randomuser.me/api/portraits/men/32.jpg',
      'linkedin': 'https://linkedin.com/in/bobsmith',
    },
    {
      'name': 'Carol Lee',
      'role': 'CFO',
      'photo': 'https://randomuser.me/api/portraits/women/65.jpg',
      'linkedin': 'https://linkedin.com/in/carollee',
    },
  ];

  final List<Map<String, dynamic>> portfolio = [
    {
      'name': 'TechNova',
      'logo': 'assets/img/default_logo.png',
      'amount': '₹1,00,000',
      'date': '2023-11-10',
    },
    {
      'name': 'GreenSpark',
      'logo': 'assets/img/default_logo.png',
      'amount': '₹50,000',
      'date': '2024-01-15',
    },
    {
      'name': 'MedixFlow',
      'logo': 'assets/img/default_logo.png',
      'amount': '₹2,00,000',
      'date': '2024-03-22',
    },
  ];

  final List<Map<String, String>> achievements = [
    {
      'title': 'Best Startup Investor 2023',
      'icon': 'emoji_events',
      'desc': 'Awarded by Startup India',
    },
    {
      'title': 'ISO 9001 Certified',
      'icon': 'verified',
      'desc': 'Quality Management Certification',
    },
    {
      'title': 'Top 10 VC Firms',
      'icon': 'star',
      'desc': 'Recognized by VC Magazine',
    },
  ];

  @override
  void initState() {
    super.initState();
    _resolveUserIdAndFetch();
    _initializeRazorpay();
    // Smoother gradient animation
    gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    gradientBeginAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(
      parent: gradientAnimationController,
      curve: Curves.easeInOutCubicEmphasized,
    ));
    gradientEndAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(
      parent: gradientAnimationController,
      curve: Curves.easeInOutCubicEmphasized,
    ));
    gradientAnimationController.forward();
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

  Future<void> _resolveUserIdAndFetch() async {
    String? id = widget.userId;
    id ??= await storage.read(key: 'user_id');
    // If still null, use hardcoded company id
    id ??= '685322';
    setState(() => _resolvedUserId = id);
    await fetchProfileData(id);
    }

  Future<void> fetchProfileData(String userId) async {
    final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      final bytes = await pickImage();
      if (bytes == null) return;
      setState(() => isUploadingAvatar = true);
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/upload_avatar.php'),
      );
      request.fields['user_id'] = widget.userId ?? '';
      request.files.add(
        http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.png'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseString);
        if (jsonResponse['success'] == true) {
          if (widget.userId != null) {
            await fetchProfileData(widget.userId!);
          } else if (_resolvedUserId != null) {
            await fetchProfileData(_resolvedUserId!);
          }
          _showSuccessSnackBar('Avatar updated successfully');
          widget.onBackTap();
        } else {
          print('Upload failed: $responseString');
          _showErrorSnackBar('Failed to upload avatar');
        }
      } else {
        print('Upload failed: HTTP  ${response.statusCode} - $responseString');
        _showErrorSnackBar('Upload failed');
      }
    } catch (e) {
      print('Upload exception: $e');
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsItem(
                    icon: Icons.account_circle,
                    title: 'Profile',
                    subtitle: 'Edit your profile information',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => isEditing = true);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy',
                    subtitle: 'Control your privacy settings',
                    onTap: _showPrivacySettings,
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: _showNotificationSettings,
                  ),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    subtitle: 'Get help and find answers',
                    onTap: _showHelpAndFAQ,
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App information',
                    onTap: _showAboutDialog,
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: _showDeleteAccountDialog,
                    isDestructive: true,
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
            onPressed: () async {
              Navigator.pop(context);
              // Functional logout: clear secure storage and go to login/user type
              await storage.deleteAll();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/user-type', (route) => false);
              }
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
    final cacheBustedUrl = hasAvatar ? avatarUrl + '?t=' + DateTime.now().millisecondsSinceEpoch.toString() : null;
    final name = profile?['name'] ?? 'Azazle';
    final role = profile?['role'] ?? '';
    final userType = profile?['user_type'] ?? '';

    return Stack(
      children: [
        AnimatedBuilder(
          animation: gradientAnimationController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: getGreetingGradient(
                  gradientBeginAnimation.value,
                  gradientEndAnimation.value,
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
                            backgroundImage: _pickedAvatarBytes != null
                                ? MemoryImage(_pickedAvatarBytes!)
                                : (hasAvatar ? NetworkImage(cacheBustedUrl!) : null),
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
                            backgroundImage: _pickedAvatarBytes != null
                                ? MemoryImage(_pickedAvatarBytes!)
                                : (hasAvatar ? NetworkImage(cacheBustedUrl!) : null),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(4, (i) => const Icon(Icons.star, color: Colors.amber, size: 22)),
                      const Icon(Icons.star_half, color: Colors.amber, size: 22),
                      const SizedBox(width: 6),
                      const Text('4.5/5', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
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
          },
        ),
        // Place the settings icon in the header so it scrolls
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              tooltip: 'Settings',
            ),
          ),
        ),
      ],
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
              if ((profile?['industry'] ?? '').isNotEmpty)
                _buildInfoRow(Icons.apartment, 'Industry', profile?['industry']),
              if ((profile?['website'] ?? '').isNotEmpty)
                GestureDetector(
                  onTap: () => _launchWebsite(profile?['website']),
                  child: _buildInfoRow(Icons.language, 'Website', profile?['website']),
                ),
              if ((profile?['founded'] ?? '').isNotEmpty)
                _buildInfoRow(Icons.calendar_today, 'Founded', profile?['founded']),
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
    final videoUrl = profile?['pitch_video_url']?.toString().trim() ?? '';
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
                Icon(Icons.ondemand_video, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 10),
                const Text('Introduction Video', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (videoUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _launchYouTubeVideo(videoUrl),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black12,
                  ),
                  height: 180,
                  child: Center(child: Text('Video Preview or YouTube Thumbnail')),
                ),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Add Introduction Video'),
                onPressed: () {
                  // TODO: Implement upload or link input
                  _showAddPitchVideoDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPitchVideoDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Introduction Video'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter YouTube link or video URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty && _resolvedUserId != null) {
                await _savePitchVideoUrl(url);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePitchVideoUrl(String url) async {
    final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/update_profile.php');
    try {
      final response = await http.post(uri, body: {
        'id': _resolvedUserId,
        'pitch_video_url': url,
      });
      if (response.statusCode == 200) {
        setState(() {
          profile?['pitch_video_url'] = url;
        });
        _showSuccessSnackBar('Introduction video updated!');
      } else {
        _showErrorSnackBar('Failed to update introduction video');
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred');
    }
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
                  activeThumbColor: Colors.green.shade600,
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

  void _showDeleteAccountDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Call delete account logic (reuse SettingsScreen logic)
              final storage = FlutterSecureStorage();
              final token = await storage.read(key: 'auth_token');
              final userId = await storage.read(key: 'user_id');
              if (token != null && userId != null) {
                try {
                  final response = await http.post(
                    Uri.parse('https://indianrupeeservices.in/NEXT/backend/api/delete-account'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'user_id': userId}),
                  );
                  if (response.statusCode == 200) {
                    await storage.deleteAll();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/user-type', (route) => false);
                    }
                  } else {
                    throw Exception('Failed with status ${response.statusCode}');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _launchWebsite(String? url) async {
    if (url == null || url.isEmpty) return;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showErrorSnackBar('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      _buildInfoSection(),
                      _buildPitchVideoSection(),
                      _buildKeyMetrics(),
                      _buildTeamSection(),
                      _buildPortfolioSection(),
                      _buildContactActions(),
                      _buildAchievementsSection(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Add blue gradient greeting logic
  @override
  LinearGradient getGreetingGradient(AlignmentGeometry begin, AlignmentGeometry end) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning: very light to light blue
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          const Color(0xFFE3F0FF), // very light blue
          const Color(0xFFB3D8FF), // light blue
        ],
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: light blue to blue
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          const Color(0xFFB3D8FF), // light blue
          const Color(0xFF4F8CFF), // blue
        ],
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening: blue to deep blue
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          const Color(0xFF4F8CFF), // blue
          const Color(0xFF1A3A6B), // deep blue
        ],
      );
    } else {
      // Night: deep blue to navy
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          const Color(0xFF1A3A6B), // deep blue
          const Color(0xFF0A1A2F), // navy
        ],
      );
    }
  }

  Widget _buildKeyMetrics() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetric('Investments', '8', Icons.trending_up, Colors.blue),
            _buildMetric('Total Invested', '₹3,50,000', Icons.attach_money, Colors.green),
            _buildMetric('Startups', '3', Icons.business, Colors.purple),
            _buildMetric('Years Active', '5', Icons.calendar_today, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                final addButton = OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Team Member'),
                  onPressed: () async {
                    String name = '';
                    String role = '';
                    String? photoUrl;
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Add Team Member'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(labelText: 'Name'),
                                onChanged: (v) => name = v,
                              ),
                              TextField(
                                decoration: const InputDecoration(labelText: 'Role'),
                                onChanged: (v) => role = v,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Pick Photo'),
                                onPressed: () async {
                                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    photoUrl = picked.path;
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (name.isNotEmpty && role.isNotEmpty) {
                                  setState(() {
                                    teamMembers.add({
                                      'name': name,
                                      'role': role,
                                      'photo': photoUrl ?? 'https://randomuser.me/api/portraits/men/1.jpg',
                                    });
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('Team Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      addButton,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      const Icon(Icons.group, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text('Team Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      addButton,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: teamMembers.map((member) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120, minWidth: 80),
                child: _buildTeamMemberCard(member),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, String> member) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            // Pick new photo for this team member
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setState(() {
                member['photo'] = picked.path;
              });
            }
          },
          child: CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(member['photo']!),
            onBackgroundImageError: (_, __) {},
            child: Icon(Icons.person, size: 32, color: Colors.grey[400]),
          ),
        ),
        const SizedBox(height: 8),
        Text(member['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(member['role']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        IconButton(
          icon: const Icon(Icons.linked_camera, color: Colors.blueAccent),
          onPressed: () async {
            // Pick new photo for this team member (camera icon)
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setState(() {
                member['photo'] = picked.path;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work, color: Colors.purple),
                const SizedBox(width: 8),
                Text('Portfolio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...portfolio.map((startup) => ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(startup['logo'])),
              title: Text(startup['name']),
              subtitle: Text('Invested: ${startup['amount']} on ${startup['date']}'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.email),
            label: const Text('Contact Us'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final email = profile?['email'] ?? 'Not provided';
                  final phone = profile?['phone'] ?? 'Not provided';
                  final website = profile?['website'] ?? 'Not provided';
                  final linkedin = profile?['linkedin'] ?? 'Not provided';
                  final twitter = profile?['twitter'] ?? 'Not provided';
                  final facebook = profile?['facebook'] ?? 'Not provided';
                  final instagram = profile?['instagram'] ?? 'Not provided';
                  return AlertDialog(
                    title: const Text('Contact Details & Social Media'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(email),
                            onTap: email != 'Not provided' ? () => launchUrl(Uri.parse('mailto:$email')) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Phone'),
                            subtitle: Text(phone),
                            onTap: phone != 'Not provided' ? () => launchUrl(Uri.parse('tel:$phone')) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Website'),
                            subtitle: Text(website),
                            onTap: website != 'Not provided' ? () => launchUrl(Uri.parse(website.startsWith('http') ? website : 'https://$website')) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('LinkedIn'),
                            subtitle: Text(linkedin),
                            onTap: linkedin != 'Not provided' ? () => launchUrl(Uri.parse(linkedin)) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.alternate_email),
                            title: const Text('Twitter'),
                            subtitle: Text(twitter),
                            onTap: twitter != 'Not provided' ? () => launchUrl(Uri.parse(twitter)) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.facebook),
                            title: const Text('Facebook'),
                            subtitle: Text(facebook),
                            onTap: facebook != 'Not provided' ? () => launchUrl(Uri.parse(facebook)) : null,
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Instagram'),
                            subtitle: Text(instagram),
                            onTap: instagram != 'Not provided' ? () => launchUrl(Uri.parse(instagram)) : null,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Achievements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
                  tooltip: 'Upload Achievement',
                  onPressed: () async {
                    XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      String? title;
                      String? desc;
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Add Achievement'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Title'),
                                  onChanged: (v) => title = v,
                                ),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Description'),
                                  onChanged: (v) => desc = v,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (title != null && title!.isNotEmpty && desc != null && desc!.isNotEmpty) {
                                    setState(() {
                                      achievements.add({
                                        'title': title!,
                                        'desc': desc!,
                                        'icon': picked.path, // Store local path as icon
                                      });
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: achievements.map((ach) => _buildAchievementCard(ach)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, String> ach) {
    Widget iconWidget;
    if (ach['icon'] != null && ach['icon']!.endsWith('.jpg') || ach['icon']!.endsWith('.png')) {
      iconWidget = Image.file(
        File(ach['icon']!),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
      );
    } else {
      IconData icon = Icons.emoji_events;
      if (ach['icon'] == 'verified') icon = Icons.verified;
      if (ach['icon'] == 'star') icon = Icons.star;
      iconWidget = Icon(icon, color: Colors.amber, size: 32);
    }
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(ach['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(ach['desc'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}