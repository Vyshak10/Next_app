import 'package:flutter/material.dart';

class LocationServicesScreen extends StatefulWidget {
  const LocationServicesScreen({super.key});

  @override
  State<LocationServicesScreen> createState() => _LocationServicesScreenState();
}

class _LocationServicesScreenState extends State<LocationServicesScreen> {
  bool _locationEnabled = false;
  bool _preciseLocation = false;
  bool _backgroundLocation = false;
  String _locationAccuracy = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Location Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.teal.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Control how we use your location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Location Permission
          _buildSectionHeader('Location Permission'),
          _buildSettingsCard(
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Location Services'),
                  subtitle: const Text('Allow app to access your location'),
                  value: _locationEnabled,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() => _locationEnabled = value);
                  },
                ),
                if (_locationEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Precise Location'),
                    subtitle: const Text('Use exact location instead of approximate'),
                    value: _preciseLocation,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _preciseLocation = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Background Location'),
                    subtitle: const Text('Allow location access when app is closed'),
                    value: _backgroundLocation,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _backgroundLocation = value);
                    },
                  ),
                ],
              ],
            ),
          ),

          if (_locationEnabled) ...[
            const SizedBox(height: 24),

            // Location Accuracy
            _buildSectionHeader('Location Accuracy'),
            _buildSettingsCard(
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('High Accuracy'),
                    subtitle: const Text('Uses GPS, Wi-Fi, and mobile networks'),
                    value: 'High',
                    groupValue: _locationAccuracy,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _locationAccuracy = value!);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Balanced'),
                    subtitle: const Text('Uses Wi-Fi and mobile networks'),
                    value: 'Balanced',
                    groupValue: _locationAccuracy,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _locationAccuracy = value!);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Battery Saving'),
                    subtitle: const Text('Uses mobile networks only'),
                    value: 'Battery Saving',
                    groupValue: _locationAccuracy,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _locationAccuracy = value!);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location Usage
            _buildSectionHeader('How We Use Location'),
            _buildSettingsCard(
              Column(
                children: [
                  _buildInfoTile(
                    Icons.search,
                    'Find Nearby Opportunities',
                    'Discover startups and companies near you',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    Icons.people,
                    'Connect with Local Network',
                    'Meet professionals in your area',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    Icons.event,
                    'Event Recommendations',
                    'Get notified about nearby events',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Location
            _buildSectionHeader('Current Location'),
            _buildSettingsCard(
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.green),
                ),
                title: const Text('San Francisco, CA'),
                subtitle: const Text('Last updated: 2 minutes ago'),
                trailing: TextButton(
                  onPressed: () {
                    _showSnackBar('Refreshing location...');
                  },
                  child: const Text('Refresh'),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: () {
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Location Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Widget child) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    _showSnackBar('Location settings saved successfully');
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
}
