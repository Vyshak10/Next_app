import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  UserProfile? _profile;
  File? _newProfileImage;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _apiService.getProfile(widget.userId);
      setState(() {
        _profile = UserProfile.fromJson(response);
        _nameController.text = _profile!.name;
        _descriptionController.text = _profile!.description ?? '';
        _skills.addAll(_profile!.skills);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Upload new profile image if selected
      String? newAvatarUrl;
      if (_newProfileImage != null) {
        final imageBytes = await _newProfileImage!.readAsBytes();
        final response = await _apiService.uploadProfilePicture(
          widget.userId,
          imageBytes,
        );
        newAvatarUrl = response['avatar_url'];
      }

      // Update profile
      final updatedProfile = _profile!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        skills: _skills,
        avatarUrl: newAvatarUrl ?? _profile!.avatarUrl,
      );

      await _apiService.updateProfile(updatedProfile.toJson());

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _newProfileImage != null
                          ? FileImage(_newProfileImage!)
                          : _profile!.avatarUrl != null
                              ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                              : null,
                      child: _profile!.avatarUrl == null && _newProfileImage == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                enabled: _isEditing,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Skills
              if (_isEditing) ...[
                const Text('Skills', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () {
                        setState(() => _skills.remove(skill));
                      },
                    );
                  }).toList(),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Add Skill',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty && !_skills.contains(value)) {
                      setState(() => _skills.add(value));
                    }
                  },
                ),
              ] else ...[
                const Text('Skills', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _skills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 