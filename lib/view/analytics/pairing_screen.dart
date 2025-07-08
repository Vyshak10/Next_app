import 'package:flutter/material.dart';

class PairingScreen extends StatefulWidget {
  final int companyId; // Pass the logged-in company ID
  final VoidCallback? onGoToAnalytics;

  const PairingScreen({Key? key, required this.companyId, this.onGoToAnalytics}) : super(key: key);

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _paired = false;

  Future<void> _pair() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final code = _codeController.text.trim().toUpperCase();
    // For now, allow any code (even blank) to proceed
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _paired = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _paired
              ? _buildSuccessContent(context)
              : _buildPairForm(context),
        ),
      ),
    );
  }

  Widget _buildPairForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.link, size: 64, color: Colors.blueAccent),
        const SizedBox(height: 16),
        Text(
          'Enter the 8-character pairing code provided by the startup to monitor their analytics.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _codeController,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'Pairing Code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.vpn_key),
              counterText: '',
            ),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18),
            validator: (value) {
              // For now, allow any value (even blank)
              return null;
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(_loading ? 'Pairing...' : 'Pair', style: const TextStyle(fontSize: 18)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _loading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      _pair();
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified, size: 70, color: Colors.green),
        const SizedBox(height: 18),
        Text(
          'Paired Successfully!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[700]),
        ),
        const SizedBox(height: 10),
        Text(
          'You are now paired with the startup. You can now monitor their analytics.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.analytics),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text('Go to Analytics', style: TextStyle(fontSize: 18)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (widget.onGoToAnalytics != null) {
                widget.onGoToAnalytics!();
              } else {
                Navigator.pushReplacementNamed(context, '/analytics');
              }
            },
          ),
        ),
      ],
    );
  }
} 