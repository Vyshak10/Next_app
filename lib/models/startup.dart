class Startup {
  final String id;
  final String name;
  final String? logoUrl;
  final String sector;
  final List<String> tags;
  final String description;
  final String? website;
  final String? location;
  final bool isConnected;

  Startup({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.sector,
    required this.tags,
    required this.description,
    this.website,
    this.location,
    this.isConnected = false,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      sector: json['sector'],
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'],
      website: json['website'],
      location: json['location'],
      isConnected: json['is_connected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'sector': sector,
      'tags': tags,
      'description': description,
      'website': website,
      'location': location,
      'is_connected': isConnected,
    };
  }

  Startup copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? sector,
    List<String>? tags,
    String? description,
    String? website,
    String? location,
    bool? isConnected,
  }) {
    return Startup(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      sector: sector ?? this.sector,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      website: website ?? this.website,
      location: location ?? this.location,
      isConnected: isConnected ?? this.isConnected,
    );
  }
} 