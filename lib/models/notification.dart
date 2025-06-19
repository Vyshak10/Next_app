import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({Key? key}) : super(key: key);

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _storage = const FlutterSecureStorage();
  DateTime _selectedDay = DateTime.now();
  List<dynamic> meetings = [];
  List<dynamic> notifications = [];
  List<dynamic> profiles = [];
  bool isLoading = true;

  String apiUrl = 'https://indianrupeeservices.in/NEXT/backend/api';

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchMeetings(_selectedDay),
      fetchNotifications(),
      fetchProfiles(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchMeetings(DateTime date) async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$apiUrl/meetings?date=${date.toIso8601String()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      meetings = jsonDecode(response.body);
    }
  }

  Future<void> fetchNotifications() async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$apiUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      notifications = jsonDecode(response.body);
    }
  }

  Future<void> fetchProfiles() async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      profiles = jsonDecode(response.body);
    }
  }

  Future<void> createMeeting({
    required String title,
    required String description,
    required String inviteeId,
    required DateTime scheduledTime,
  }) async {
    final token = await getAuthToken();
    final response = await http.post(
      Uri.parse('$apiUrl/meetings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'invitee_id': inviteeId,
        'scheduled_time': scheduledTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled successfully!')),
      );
      await fetchMeetings(_selectedDay);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule meeting')),
      );
    }
  }

  Future<void> updateMeetingStatus(int meetingId, String status) async {
    final token = await getAuthToken();
    final response = await http.put(
      Uri.parse('$apiUrl/meetings/$meetingId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      await fetchMeetings(_selectedDay);
      setState(() {});
    }
  }

  void _showScheduleMeetingDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDateTime = _selectedDay;
    TimeOfDay selectedTime = TimeOfDay.now();
    String? selectedInviteeId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Meeting'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Meeting Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text('Date: ${selectedDateTime.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDateTime = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Time: ${selectedTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                            selectedDateTime = DateTime(
                              selectedDateTime.year,
                              selectedDateTime.month,
                              selectedDateTime.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedInviteeId,
                      decoration: const InputDecoration(labelText: 'Select Invitee'),
                      items: profiles.map((profile) {
                        return DropdownMenuItem<String>(
                          value: profile['id'].toString(),
                          child: Text(profile['name'] ?? profile['email']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInviteeId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || selectedInviteeId == null) return;
                    await createMeeting(
                      title: titleController.text,
                      description: descriptionController.text,
                      inviteeId: selectedInviteeId!,
                      scheduledTime: selectedDateTime,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Replace this with your full widget structure or ask for full layout rebuild
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showScheduleMeetingDialog,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Meetings on ${_formatDate(_selectedDay)}'),
          const SizedBox(height: 8),
          ...meetings.map((meeting) => ListTile(
            title: Text(meeting['title']),
            subtitle: Text(_formatDateTime(meeting['scheduled_time'])),
            trailing: Text(meeting['status']),
          )),
          const Divider(height: 32),
          const Text('Recent Notifications'),
          ...notifications.map((notif) => ListTile(
            title: Text(notif['title']),
            subtitle: Text(_formatDateTime(notif['timestamp'])),
          )),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    final dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
