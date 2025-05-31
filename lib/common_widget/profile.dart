import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onBackTap;

  const ProfileScreen({super.key, required this.userId, this.onBackTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  double profileCompletion = 0.0;
  bool canEditFunding = true;
  String selectedCurrency = 'USD';
  double usdToInrRate = 83.0; // Current approximate rate, you might want to fetch this from an API
  int profileVisits = 0;
  bool isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPosts();
    _loadProfileVisits();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          profile = data;
          profileCompletion = _calculateProfileCompletion(data);
          // Check if funding can be edited
          if (data['last_funding_update'] != null) {
            final lastUpdate = DateTime.parse(data['last_funding_update']);
            final now = DateTime.now();
            final difference = now.difference(lastUpdate);
            canEditFunding = difference.inDays >= 30;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
      if (mounted && data != null) {
        setState(() => posts = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      _showSnackBar('Failed to load posts: $e');
    }
  }

  Future<void> _loadProfileVisits() async {
    try {
      final data = await supabase
          .from('profile_visits')
          .select('count')
          .eq('profile_id', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          profileVisits = data['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Failed to load profile visits: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final fileName = 'avatars/${widget.userId}.png';
      
      // Upload file
      await supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Get public URL
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update profile table with new avatar URL
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', widget.userId);

      if (mounted) {
        _loadProfile(); // Refresh profile data to show new avatar
        _showSnackBar('Avatar uploaded successfully!');
      }
    } catch (e) {
      print('Profile picture upload failed: $e');
      _showSnackBar('Upload failed: $e');
    }
  }

  Future<void> _toggleNotifications(bool newValue) async {
    try {
      await supabase
          .from('profiles')
          .update({'notify_enabled': newValue})
          .eq('id', widget.userId);
      
      if (mounted) {
        setState(() {
          profile!['notify_enabled'] = newValue;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to update notification preference: $e');
    }
  }

  double _calculateProfileCompletion(Map<String, dynamic> profileData) {
    int completedFields = 0;
    int totalFields = 11; // Updated total fields

    if (_isFieldCompleted(profileData, 'full_name')) completedFields++;
    if (_isFieldCompleted(profileData, 'avatar_url')) completedFields++;
    if (_isFieldCompleted(profileData, 'bio')) completedFields++;
    if (_isFieldCompleted(profileData, 'location')) completedFields++;
    if (_isFieldCompleted(profileData, 'website')) completedFields++;
    if (_isFieldCompleted(profileData, 'sector')) completedFields++;
    if (_isFieldCompleted(profileData, 'user_type')) completedFields++;
    if (_isFieldCompleted(profileData, 'name')) completedFields++;
    if (_isFieldCompleted(profileData, 'role')) completedFields++;
    if (_isFieldCompleted(profileData, 'skills')) completedFields++;
    if (_isFieldCompleted(profileData, 'description')) completedFields++;

    if (totalFields == 0) return 0.0;

    return completedFields / totalFields;
  }

  bool _isFieldCompleted(Map<String, dynamic> data, String fieldName) {
    return data[fieldName] != null && data[fieldName].toString().trim().isNotEmpty;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatCurrency(double amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    if (fromCurrency == 'USD' && toCurrency == 'INR') {
      return amount * usdToInrRate;
    } else if (fromCurrency == 'INR' && toCurrency == 'USD') {
      return amount / usdToInrRate;
    }
    return amount;
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: profile?['name']);
    final roleCtrl = TextEditingController(text: profile?['role']);
    final descCtrl = TextEditingController(text: profile?['description']);
    final skillCtrl = TextEditingController(text: profile?['skills']);
    
    // Company Info Controllers
    final companyNameCtrl = TextEditingController(text: profile?['company_name']);
    final foundedCtrl = TextEditingController(text: profile?['founded_date']);
    final companyStageCtrl = TextEditingController(text: profile?['company_stage']);
    final companySizeCtrl = TextEditingController(text: profile?['company_size']);
    final companyTypeCtrl = TextEditingController(text: profile?['company_type']);
    
    // Team Controllers
    final teamCtrl = TextEditingController(text: profile?['team_members']);
    final positionsCtrl = TextEditingController(text: profile?['open_positions']);
    
    // Product Controllers
    final productDescCtrl = TextEditingController(text: profile?['product_description']);
    final featuresCtrl = TextEditingController(text: profile?['product_features']);
    final uspCtrl = TextEditingController(text: profile?['product_usp']);
    final techCtrl = TextEditingController(text: profile?['tech_stack']);
    final devStageCtrl = TextEditingController(text: profile?['development_stage']);
    
    // Contact Controllers
    final emailCtrl = TextEditingController(text: profile?['business_email']);
    final locationCtrl = TextEditingController(text: profile?['office_location']);
    final websiteCtrl = TextEditingController(text: profile?['website']);
    final linkedinCtrl = TextEditingController(text: profile?['linkedin_url']);
    final twitterCtrl = TextEditingController(text: profile?['twitter_url']);

    bool isDescriptionValid = true;
    bool isCheckingUsername = false;
    bool isUsernameAvailable = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          int wordCount = descCtrl.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
          isDescriptionValid = wordCount >= 120 && wordCount <= 500;

          return AlertDialog(
            title: const Text("Edit Profile"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic Info
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Username",
                      errorText: !isUsernameAvailable ? "This username is already taken" : null,
                      suffixIcon: isCheckingUsername 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    ),
                    onChanged: (value) async {
                      if (value.trim() != profile?['name']) {
                        setState(() {
                          isCheckingUsername = true;
                          isUsernameAvailable = true;
                        });
                        
                        try {
                          final response = await supabase
                              .from('profiles')
                              .select()
                              .eq('name', value.trim())
                              .neq('id', widget.userId)
                              .maybeSingle();
                          
                          setState(() {
                            isCheckingUsername = false;
                            isUsernameAvailable = response == null;
                          });
                        } catch (e) {
                          setState(() {
                            isCheckingUsername = false;
                            isUsernameAvailable = true;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Role"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        wordCount = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
                        isDescriptionValid = wordCount >= 120 && wordCount <= 500;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Description",
                      helperText: "Word count: $wordCount/500 (minimum 120 words)",
                      errorText: !isDescriptionValid ? "Description must be between 120 and 500 words" : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillCtrl,
                    decoration: const InputDecoration(labelText: "Skills/Stage"),
                  ),
                  const SizedBox(height: 24), // Add spacing before the next section

                  // Company Info
                  const Text('Company Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companyNameCtrl,
                    decoration: const InputDecoration(labelText: "Company Name"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: foundedCtrl,
                    decoration: const InputDecoration(labelText: "Founded Date (YYYY-MM-DD)"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: companyStageCtrl.text.isEmpty ? null : companyStageCtrl.text,
                    decoration: const InputDecoration(labelText: "Company Stage"),
                    items: const [
                      DropdownMenuItem(value: "Idea", child: Text("Idea")),
                      DropdownMenuItem(value: "MVP", child: Text("MVP")),
                      DropdownMenuItem(value: "Early Stage", child: Text("Early Stage")),
                      DropdownMenuItem(value: "Growth", child: Text("Growth")),
                      DropdownMenuItem(value: "Scale", child: Text("Scale")),
                    ],
                    onChanged: (value) => companyStageCtrl.text = value ?? "",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companySizeCtrl,
                    decoration: const InputDecoration(labelText: "Company Size (Number of Employees)"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: companyTypeCtrl.text.isEmpty ? null : companyTypeCtrl.text,
                    decoration: const InputDecoration(labelText: "Company Type"),
                    items: const [
                      DropdownMenuItem(value: "B2B", child: Text("B2B")),
                      DropdownMenuItem(value: "B2C", child: Text("B2C")),
                      DropdownMenuItem(value: "B2B2C", child: Text("B2B2C")),
                      DropdownMenuItem(value: "C2C", child: Text("C2C")),
                    ],
                    onChanged: (value) => companyTypeCtrl.text = value ?? "",
                  ),
                  const SizedBox(height: 24), // Add spacing

                  // Team Info
                  const Text('Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: teamCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Team Members (One per line)",
                      helperText: "Format: Name - Role",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: positionsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Open Positions (One per line)",
                      helperText: "Format: Position - Requirements",
                    ),
                  ),
                  const SizedBox(height: 24), // Add spacing

                  // Product Info
                  const Text('Product/Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: productDescCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Product Description"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: featuresCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Key Features",
                      helperText: "One feature per line",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: uspCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Unique Selling Points",
                      helperText: "One USP per line",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: techCtrl,
                    decoration: const InputDecoration(
                      labelText: "Technology Stack",
                      helperText: "Comma-separated list of technologies",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: devStageCtrl.text.isEmpty ? null : devStageCtrl.text,
                    decoration: const InputDecoration(labelText: "Development Stage"),
                    items: const [
                      DropdownMenuItem(value: "Concept", child: Text("Concept")),
                      DropdownMenuItem(value: "Prototype", child: Text("Prototype")),
                      DropdownMenuItem(value: "Beta", child: Text("Beta")),
                      DropdownMenuItem(value: "MVP", child: Text("MVP")),
                      DropdownMenuItem(value: "Production", child: Text("Production")),
                    ],
                    onChanged: (value) => devStageCtrl.text = value ?? "",
                  ),
                  const SizedBox(height: 24), // Add spacing

                  // Contact Info
                  const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Business Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: "Office Location"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: websiteCtrl,
                    decoration: const InputDecoration(labelText: "Website"),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkedinCtrl,
                    decoration: const InputDecoration(labelText: "LinkedIn URL"),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: twitterCtrl,
                    decoration: const InputDecoration(labelText: "Twitter URL"),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: (isDescriptionValid && isUsernameAvailable && !isCheckingUsername) ? () async {
                  try {
                    await supabase.from('profiles').update({
                      'name': nameCtrl.text.trim(),
                      'role': roleCtrl.text.trim(), // Role is read-only but included for completeness in update map
                      'description': descCtrl.text.trim(),
                      'skills': skillCtrl.text.trim(),
                      'company_name': companyNameCtrl.text.trim(),
                      'founded_date': foundedCtrl.text.trim(),
                      'company_stage': companyStageCtrl.text.trim(),
                      'company_size': companySizeCtrl.text.trim(),
                      'company_type': companyTypeCtrl.text.trim(),
                      'team_members': teamCtrl.text.trim(),
                      'open_positions': positionsCtrl.text.trim(),
                      'product_description': productDescCtrl.text.trim(),
                      'product_features': featuresCtrl.text.trim(),
                      'product_usp': uspCtrl.text.trim(),
                      'tech_stack': techCtrl.text.trim(),
                      'development_stage': devStageCtrl.text.trim(),
                      'business_email': emailCtrl.text.trim(),
                      'office_location': locationCtrl.text.trim(),
                      'website': websiteCtrl.text.trim(),
                      'linkedin_url': linkedinCtrl.text.trim(),
                      'twitter_url': twitterCtrl.text.trim(),
                    }).eq('id', widget.userId);

                    Navigator.pop(context);
                    await _loadProfile();
                    _showSnackBar('Profile updated successfully!');
                  } catch (e) {
                    _showSnackBar('Failed to update profile: $e');
                  }
                } : null,
                child: const Text("Save"),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // Delete post images from storage if any
        final post = posts.firstWhere((p) => p['id'] == postId);
        final imageUrls = List<String>.from(post['image_urls'] ?? []);
        
        for (final imageUrl in imageUrls) {
          try {
            final fileName = imageUrl.split('/').last;
            await supabase.storage.from('post_images').remove([fileName]);
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }

        // Delete post from database
        await supabase
            .from('posts')
            .delete()
            .eq('id', postId);

        // Refresh posts list
        await _loadPosts();
        _showSnackBar('Post deleted successfully');
      }
    } catch (e) {
      _showSnackBar('Failed to delete post: $e');
    }
  }

  void _showPostDetail(Map<String, dynamic> post) {
    final imageUrls = List<String>.from(post['image_urls'] ?? []);
    final tags = List<String>.from(post['tags'] ?? []);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(post['title'] ?? 'Post'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _deletePost(post['id']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, size: 50),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (post['description'] != null && post['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(post['description']),
                        ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
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

  void _editFundingDialog() {
    if (!canEditFunding) {
      final lastUpdate = DateTime.parse(profile!['last_funding_update']);
      final nextUpdate = lastUpdate.add(const Duration(days: 30));
      final daysLeft = nextUpdate.difference(DateTime.now()).inDays;
      
      _showSnackBar('You can update your funding expectation in $daysLeft days');
      return;
    }

    final fundingCtrl = TextEditingController(
      text: profile?['funding_expectation'] != null 
        ? _convertCurrency(
            profile!['funding_expectation'],
            profile!['funding_currency'] ?? 'USD',
            selectedCurrency
          ).toString()
        : ''
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Update Funding Expectation"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: "Currency",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('USD - US Dollar'),
                      ),
                      DropdownMenuItem(
                        value: 'INR',
                        child: Text('INR - Indian Rupee'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          if (fundingCtrl.text.isNotEmpty) {
                            final currentAmount = double.tryParse(fundingCtrl.text) ?? 0;
                            final convertedAmount = _convertCurrency(
                              currentAmount,
                              selectedCurrency,
                              value
                            );
                            fundingCtrl.text = convertedAmount.toString();
                          }
                          selectedCurrency = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: fundingCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Funding Amount",
                      prefixText: selectedCurrency == 'USD' ? "\$" : "₹",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter funding amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Note: You can only update this once every 30 days",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final amount = double.parse(fundingCtrl.text);
                      final amountInUSD = selectedCurrency == 'USD' 
                        ? amount 
                        : _convertCurrency(amount, 'INR', 'USD');

                      await supabase.from('profiles').update({
                        'funding_expectation': amountInUSD,
                        'funding_currency': selectedCurrency,
                        'last_funding_update': DateTime.now().toIso8601String(),
                      }).eq('id', widget.userId);

                      Navigator.pop(context);
                      await _loadProfile();
                      _showSnackBar('Funding expectation updated successfully!');
                    } catch (e) {
                      _showSnackBar('Failed to update funding expectation: $e');
                    }
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _uploadPitchVideo() async {
    try {
      final picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      
      if (picked == null) return;

      setState(() {
        isUploadingVideo = true;
      });

      final file = File(picked.path);
      final fileName = 'pitch_videos/${widget.userId}.mp4';
      
      // Upload file
      await supabase.storage.from('pitch_videos').upload(
        fileName,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Get public URL
      final videoUrl = supabase.storage.from('pitch_videos').getPublicUrl(fileName);

      // Update profile table with new video URL
      await supabase
          .from('profiles')
          .update({'pitch_video_url': videoUrl})
          .eq('id', widget.userId);

      if (mounted) {
        setState(() {
          isUploadingVideo = false;
        });
        await _loadProfile();
        _showSnackBar('Pitch video uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploadingVideo = false;
        });
        _showSnackBar('Failed to upload video: $e');
      }
    }
  }

  BoxDecoration _getTimeBasedDecoration() {
    final hour = DateTime.now().hour;
    LinearGradient gradient;

    if (hour >= 5 && hour < 12) {
      // Morning: orange gradient
      gradient = LinearGradient(
        colors: [Colors.orange.shade500, Colors.orange.shade300],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: yellow to orange gradient
      gradient = LinearGradient(
        colors: [Colors.orange.shade400, Colors.yellow.shade300],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening: blue gradient
      gradient = LinearGradient(
        colors: [Colors.blue.shade800, Colors.blue.shade600],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else {
      // Night: dark gradient
      gradient = LinearGradient(
        colors: [Colors.black87, Colors.blueGrey.shade800],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: _getTimeBasedDecoration(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: _editProfileDialog,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: profileCompletion,
                                strokeWidth: 3,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                color: Colors.white,
                              ),
                            ),
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              backgroundImage: profile!['avatar_url'] != null &&
                                      profile!['avatar_url'] != ''
                                  ? NetworkImage(profile!['avatar_url'])
                                  : const AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBackTap,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _loadPosts();
                await _loadProfileVisits();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            profile!['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile!['email'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (profile!['role'] != null && profile!['role'] != '')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  profile!['role'],
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: profileCompletion,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Profile Complete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Profile Visits Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _getTimeBasedDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Visits',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileVisits.toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pitch Video Section
                    _buildSection(
                      title: 'Pitch Video',
                      icon: Icons.video_library_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile!['pitch_video_url'] != null) ...[
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      'https://img.youtube.com/vi/${profile!['pitch_video_url']}/maxresdefault.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.play_circle_outline,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                // TODO: Implement video player
                                _showSnackBar('Video player coming soon!');
                              },
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Watch Pitch Video'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.video_library_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No pitch video uploaded yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: isUploadingVideo ? null : _uploadPitchVideo,
                                    icon: isUploadingVideo
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.upload),
                                    label: Text(
                                      isUploadingVideo ? 'Uploading...' : 'Upload Video (2-3 mins)',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // About Section
                    if (profile!['description'] != null && profile!['description'] != '')
                      _buildSection(
                        title: 'About',
                        icon: Icons.info_outline,
                        child: Text(
                          profile!['description'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),

                    // Skills Section
                    if (profile!['skills'] != null && profile!['skills'] != '')
                      _buildSection(
                        title: 'Skills / Stage',
                        icon: Icons.psychology_outlined,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile!['skills']
                              .split(',')
                              .map<Widget>((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      skill.trim(),
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                    // Company Information Section
                    _buildSection(
                      title: 'Company Information',
                      icon: Icons.business,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile!['company_name'] != null &&
                              profile!['company_name'].isNotEmpty)
                            _buildInfoRow('Company Name', profile!['company_name']),
                          if (profile!['founded_date'] != null &&
                              profile!['founded_date'].isNotEmpty)
                            _buildInfoRow('Founded', profile!['founded_date']),
                          if (profile!['company_stage'] != null &&
                              profile!['company_stage'].isNotEmpty)
                            _buildInfoRow('Stage', profile!['company_stage']),
                          if (profile!['company_size'] != null &&
                              profile!['company_size'].isNotEmpty)
                            _buildInfoRow(
                                'Team Size', '${profile!['company_size']} employees'),
                          if (profile!['company_type'] != null &&
                              profile!['company_type'].isNotEmpty)
                            _buildInfoRow('Type', profile!['company_type']),
                        ],
                      ),
                    ),

                    // Team Section
                    _buildSection(
                      title: 'Team',
                      icon: Icons.people_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile!['team_members'] != null &&
                              profile!['team_members'].isNotEmpty) ...[
                            const Text(
                              'Team Members',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...profile!['team_members']
                                .split('\n')
                                .map((member) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(member)),
                                        ],
                                      ),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          if (profile!['open_positions'] != null &&
                              profile!['open_positions'].isNotEmpty) ...[
                            const Text(
                              'Open Positions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...profile!['open_positions']
                                .split('\n')
                                .map((position) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.work_outline,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(position)),
                                        ],
                                      ),
                                    )),
                          ],
                        ],
                      ),
                    ),

                    // Product/Service Section
                    _buildSection(
                      title: 'Product/Service',
                      icon: Icons.rocket_launch_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile!['product_description'] != null &&
                              profile!['product_description'].isNotEmpty)
                            _buildInfoRow(
                                'Description', profile!['product_description']),
                          if (profile!['product_features'] != null &&
                              profile!['product_features'].isNotEmpty) ...[
                            const Text(
                              'Key Features',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...profile!['product_features']
                                .split('\n')
                                .map((feature) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star_outline,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(feature)),
                                        ],
                                      ),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          if (profile!['product_usp'] != null &&
                              profile!['product_usp'].isNotEmpty) ...[
                            const Text(
                              'Unique Selling Points',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...profile!['product_usp']
                                .split('\n')
                                .map((usp) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.bolt_outlined,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(usp)),
                                        ],
                                      ),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          if (profile!['tech_stack'] != null &&
                              profile!['tech_stack'].isNotEmpty)
                            _buildInfoRow(
                                'Technology Stack', profile!['tech_stack']),
                          if (profile!['development_stage'] != null &&
                              profile!['development_stage'].isNotEmpty)
                            _buildInfoRow('Development Stage',
                                profile!['development_stage']),
                        ],
                      ),
                    ),

                    // Contact Information Section
                    _buildSection(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile!['business_email'] != null &&
                              profile!['business_email'].isNotEmpty)
                            _buildContactRow(Icons.email_outlined,
                                profile!['business_email'],
                                'mailto:${profile!['business_email']}'),
                          if (profile!['office_location'] != null &&
                              profile!['office_location'].isNotEmpty)
                            _buildContactRow(
                                Icons.location_on_outlined,
                                profile!['office_location']),
                          if (profile!['website'] != null &&
                              profile!['website'].isNotEmpty)
                            _buildContactRow(Icons.language_outlined,
                                profile!['website'], profile!['website']),
                          if (profile!['linkedin_url'] != null &&
                              profile!['linkedin_url'].isNotEmpty)
                            _buildContactRow(Icons.business_outlined, 'LinkedIn',
                                profile!['linkedin_url']),
                          if (profile!['twitter_url'] != null &&
                              profile!['twitter_url'].isNotEmpty)
                            _buildContactRow(Icons.chat_outlined, 'Twitter',
                                profile!['twitter_url']),
                        ],
                      ),
                    ),

                    // Posts Section
                    _buildSection(
                      title: 'Posts',
                      icon: Icons.grid_view,
                      child: posts.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_outlined,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      'No posts yet',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                    Text(
                                      'Go to Posts tab to create your first post!',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: posts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemBuilder: (_, index) {
                                final post = posts[index];
                                final imageUrls =
                                    List<String>.from(post['image_urls'] ?? []);

                                return GestureDetector(
                                  onTap: () => _showPostDetail(post),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey[200],
                                        ),
                                        child: imageUrls.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  imageUrls.first,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey),
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(Icons.image,
                                                    size: 32,
                                                    color: Colors.grey),
                                              ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _deletePost(post['id']),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, [String? url]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          if (url != null)
            InkWell(
              onTap: () async {
                // TODO: Implement URL launcher
                _showSnackBar('URL launcher coming soon!');
              },
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}