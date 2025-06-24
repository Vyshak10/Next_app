import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/meeting.dart';
import '../../services/api_service.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({Key? key}) : super(key: key);

  @override
  _MeetingsPageState createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Meeting> _meetings = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final meetings = await _apiService.getUpcomingMeetings();
      setState(() {
        _meetings = meetings.map((json) => Meeting.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading meetings: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  List<Meeting> _getMeetingsForDay(DateTime day) {
    return _meetings.where((meeting) {
      final meetingDate = DateTime(
        meeting.startTime.year,
        meeting.startTime.month,
        meeting.startTime.day,
      );
      final selectedDate = DateTime(day.year, day.month, day.day);
      return meetingDate.isAtSameMomentAs(selectedDate);
    }).toList();
  }

  void _showCreateMeetingDialog() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    DateTime _startTime = DateTime.now();
    DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
    String _selectedParticipant = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Meeting'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(
                  '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_startTime),
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = DateTime(
                        _startTime.year,
                        _startTime.month,
                        _startTime.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(
                  '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_endTime),
                  );
                  if (time != null) {
                    setState(() {
                      _endTime = DateTime(
                        _endTime.year,
                        _endTime.month,
                        _endTime.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              // TODO: Add participant selection
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) return;

              try {
                final meetingData = {
                  'title': _titleController.text,
                  'description': _descriptionController.text,
                  'start_time': _startTime.toIso8601String(),
                  'end_time': _endTime.toIso8601String(),
                  'participant_id': _selectedParticipant,
                };

                await _apiService.createMeeting(meetingData);
                await _loadMeetings();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meeting scheduled successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error scheduling meeting: $e')),
                );
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showHostEventDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    DateTime _eventDate = DateTime.now();
    TimeOfDay _eventTime = TimeOfDay.now();
    final _linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Host Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Event Date'),
                subtitle: Text('${_eventDate.year}-${_eventDate.month}-${_eventDate.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    _eventDate = picked;
                  }
                },
              ),
              ListTile(
                title: const Text('Event Time'),
                subtitle: Text('${_eventTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _eventTime,
                  );
                  if (picked != null) {
                    _eventTime = picked;
                  }
                },
              ),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Event Link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) return;
              // Mock: Add event to meeting list
              setState(() {
                _meetings.add(Meeting(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: '[Event] ${_titleController.text}',
                  description: _descriptionController.text,
                  startTime: DateTime(
                    _eventDate.year,
                    _eventDate.month,
                    _eventDate.day,
                    _eventTime.hour,
                    _eventTime.minute,
                  ),
                  endTime: DateTime(
                    _eventDate.year,
                    _eventDate.month,
                    _eventDate.day,
                    _eventTime.hour + 1,
                    _eventTime.minute,
                  ),
                  status: 'event',
                  meetingLink: _linkController.text.isNotEmpty ? _linkController.text : null,
                ));
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event hosted successfully (mock)')),
                );
              }
            },
            child: const Text('Host Event'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateMeetingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'Host Event',
            onPressed: () => _showHostEventDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getMeetingsForDay,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getMeetingsForDay(_selectedDay ?? _focusedDay).length,
              itemBuilder: (context, index) {
                final meeting = _getMeetingsForDay(_selectedDay ?? _focusedDay)[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(meeting.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meeting.description),
                        const SizedBox(height: 4),
                        Text(
                          '${meeting.startTime.hour}:${meeting.startTime.minute.toString().padLeft(2, '0')} - ${meeting.endTime.hour}:${meeting.endTime.minute.toString().padLeft(2, '0')}',
                        ),
                        Text(
                          'Status: ${meeting.status}',
                          style: TextStyle(
                            color: meeting.status == 'scheduled'
                                ? Colors.green
                                : meeting.status == 'completed'
                                    ? Colors.blue
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.video_call),
                      onPressed: meeting.meetingLink != null
                          ? () {
                              // TODO: Launch meeting link
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 