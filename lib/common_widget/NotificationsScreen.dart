import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: _showScheduleMeetingDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading data...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _selectedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                        });
                        fetchMeetings(selectedDay);
                      },
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const { CalendarFormat.month: 'Month' },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[700]),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[700]),
                        titleTextStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                      ),
                    ),
                  ),

                  // Scrollable Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scheduled Meetings Section Title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Meetings on ${_formatDate(_selectedDay)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),

                          // Meetings List for selected day
                          meetings.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No meetings scheduled',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap the + button to schedule a new meeting.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  physics: NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                                  shrinkWrap: true, // Make ListView take minimum space
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  itemCount: meetings.length,
                                  itemBuilder: (context, index) {
                                    final meeting = meetings[index];
                                    final isCurrentUserInitiator = meeting['initiator_id'] == supabase.auth.currentUser?.id;
                                    final otherParticipant = isCurrentUserInitiator
                                        ? meeting['invitee']
                                        : meeting['initiator'];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meeting['title'] ?? 'Meeting',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (meeting['description'] != null && meeting['description'].isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              meeting['description'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDateTime(meeting['scheduled_time']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                otherParticipant?['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                'Status: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              Text(
                                                meeting['status'].toUpperCase() ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getMeetingStatusColor(meeting['status']),
                                                ),
                                              ),
                                              if (meeting['status'] == 'pending' && !isCurrentUserInitiator) ...[
                                                const Spacer(),
                                                ElevatedButton(
                                                  onPressed: () => updateMeetingStatus(meeting['id'], 'accepted'),
                                                  child: const Text('Accept'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: () => updateMeetingStatus(meeting['id'], 'rejected'),
                                                  child: const Text('Reject'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: const BorderSide(color: Colors.red),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // Notifications Section Title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Recent Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),

                          // Notifications List
                           notifications.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.notifications_none_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No notifications yet',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                                    shrinkWrap: true, // Make ListView take minimum space
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notification['title'] ?? 'Notification',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notification['body'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDateTime(notification['timestamp']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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

  Color _getMeetingStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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