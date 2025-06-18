class Meeting {
  final String id;
  final String organizerId;
  final String participantId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? meetingLink;
  final String? notes;

  Meeting({
    required this.id,
    required this.organizerId,
    required this.participantId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.meetingLink,
    this.notes,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      organizerId: json['organizer_id'],
      participantId: json['participant_id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
      meetingLink: json['meeting_link'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizer_id': organizerId,
      'participant_id': participantId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'meeting_link': meetingLink,
      'notes': notes,
    };
  }

  Meeting copyWith({
    String? id,
    String? organizerId,
    String? participantId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? meetingLink,
    String? notes,
  }) {
    return Meeting(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      participantId: participantId ?? this.participantId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      meetingLink: meetingLink ?? this.meetingLink,
      notes: notes ?? this.notes,
    );
  }
} 