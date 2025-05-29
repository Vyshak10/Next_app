import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;

  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    fetchMeetings(_selectedDay);
    fetchProfiles();
    subscribeToUpdates();
  }

  void subscribeToUpdates() {
    supabase
        .channel('public:notifications')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (_) => fetchNotifications(),
    )
        .subscribe();

    supabase
        .channel('public:meetings')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meetings',
      callback: (_) => fetchMeetings(_selectedDay),
    )
        .subscribe();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    final response = await supabase
        .from('notifications')
        .select()
        .order('timestamp', ascending: false)
        .limit(20);

    if (response != null && response is List) {
      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } else {
      setState(() {
        notifications = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load notifications')),
      );
    }
  }

  Future<void> fetchProfiles() async {
    final response = await supabase
        .from('profiles')
        .select('id, name, email')
        .order('name', ascending: true);

    if (response != null && response is List) {
      setState(() {
        profiles = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> fetchMeetings(DateTime day) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      // First, get the meetings
      final meetingsResponse = await supabase
          .from('meetings')
          .select('*')
          .or('initiator_id.eq.$currentUserId,invitee_id.eq.$currentUserId')
          .gte('scheduled_time', start.toIso8601String())
          .lt('scheduled_time', end.toIso8601String())
          .order('scheduled_time', ascending: true);

      if (meetingsResponse != null && meetingsResponse is List) {
        List<Map<String, dynamic>> meetingsWithUserInfo = [];

        // For each meeting, fetch user information separately
        for (final meeting in meetingsResponse) {
          Map<String, dynamic> meetingWithInfo = Map<String, dynamic>.from(meeting);

          // Get initiator info
          if (meeting['initiator_id'] != null) {
            final initiatorResponse = await supabase
                .from('profiles')
                .select('id, name, email')
                .eq('id', meeting['initiator_id'])
                .single();

            if (initiatorResponse != null) {
              meetingWithInfo['initiator'] = initiatorResponse;
            }
          }

          // Get invitee info
          if (meeting['invitee_id'] != null) {
            final inviteeResponse = await supabase
                .from('profiles')
                .select('id, name, email')
                .eq('id', meeting['invitee_id'])
                .single();

            if (inviteeResponse != null) {
              meetingWithInfo['invitee'] = inviteeResponse;
            }
          }

          meetingsWithUserInfo.add(meetingWithInfo);
        }

        setState(() {
          meetings = meetingsWithUserInfo;
        });
      } else {
        setState(() => meetings = []);
      }
    } catch (e) {
      setState(() => meetings = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meetings: $e')),
      );
    }
  }

  Future<void> updateMeetingStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('meetings')
          .update({'status': newStatus})
          .eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting $newStatus successfully')),
      );
      fetchMeetings(_selectedDay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update meeting status')),
      );
    }
  }

  Future<void> scheduleMeeting({
    required String title,
    required String description,
    required DateTime scheduledTime,
    required String inviteeId,
  }) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to schedule meetings')),
        );
        return;
      }

      await supabase.from('meetings').insert({
        'title': title,
        'description': description,
        'scheduled_time': scheduledTime.toIso8601String(),
        'initiator_id': currentUserId,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create notification for the invitee
      await supabase.from('notifications').insert({
        'title': 'New Meeting Request',
        'body': 'You have been invited to: $title',
        'user_id': inviteeId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled successfully!')),
      );

      fetchMeetings(_selectedDay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule meeting: $e')),
      );
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Date: ${selectedDateTime.toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
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
                        final TimeOfDay? picked = await showTimePicker(
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedInviteeId,
                      decoration: const InputDecoration(
                        labelText: 'Select Invitee',
                        border: OutlineInputBorder(),
                      ),
                      items: profiles.map((profile) {
                        return DropdownMenuItem<String>(
                          value: profile['id'],
                          child: Text(profile['name'] ?? profile['email'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (String? value) {
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && selectedInviteeId != null) {
                      scheduleMeeting(
                        title: titleController.text,
                        description: descriptionController.text,
                        scheduledTime: selectedDateTime,
                        inviteeId: selectedInviteeId!,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                    }
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
    fetchMeetings(selectedDay);
  }

  String _getMeetingParticipantName(Map<String, dynamic> meeting) {
    final currentUserId = supabase.auth.currentUser?.id;
    if (meeting['initiator_id'] == currentUserId) {
      final inviteeName = meeting['invitee']?['name'] ??
          meeting['invitee']?['email'] ??
          'Unknown User';
      return 'with $inviteeName';
    } else {
      final initiatorName = meeting['initiator']?['name'] ??
          meeting['initiator']?['email'] ??
          'Unknown User';
      return 'from $initiatorName';
    }
  }

  bool _canRespondToMeeting(Map<String, dynamic> meeting) {
    final currentUserId = supabase.auth.currentUser?.id;
    final status = meeting['status'] ?? 'pending';
    return meeting['invitee_id'] == currentUserId && status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showScheduleMeetingDialog,
            tooltip: 'Schedule Meeting',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Notifications',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  title: Text(notif['title'] ?? 'No Title'),
                  subtitle: Text(notif['body'] ?? ''),
                  trailing: Text(
                    notif['timestamp'] != null
                        ? DateTime.parse(notif['timestamp'])
                        .toLocal()
                        .toString()
                        .split('.')[0]
                        : '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Scheduled Meetings',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: _onDaySelected,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...meetings.map((meeting) {
              final status = meeting['status'] ?? 'pending';
              final participantName = _getMeetingParticipantName(meeting);
              final canRespond = _canRespondToMeeting(meeting);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: status == 'accepted'
                        ? Colors.green
                        : status == 'declined'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(meeting['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meeting['description'] != null && meeting['description'].isNotEmpty)
                        Text(meeting['description']),
                      Text(participantName),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          color: status == 'accepted'
                              ? Colors.green
                              : status == 'declined'
                              ? Colors.red
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        meeting['scheduled_time'] != null
                            ? DateTime.parse(meeting['scheduled_time'])
                            .toLocal()
                            .toString()
                            .split('.')[0]
                            .substring(11, 16)
                            : '',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (canRespond)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green, size: 20),
                              onPressed: () => updateMeetingStatus(meeting['id'], 'accepted'),
                              tooltip: 'Accept',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () => updateMeetingStatus(meeting['id'], 'declined'),
                              tooltip: 'Decline',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (meetings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('No meetings scheduled for this day.',
                    style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleMeetingDialog,
        tooltip: 'Schedule Meeting',
        child: const Icon(Icons.add),
      ),
    );
  }
}