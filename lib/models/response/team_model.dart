import '../../utils/extractor.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final int version;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'active',
    this.version = 1,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map : const {};
    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: user['name']?.toString() ?? json['name']?.toString() ?? 'Team Member',
      email: user['email']?.toString() ?? json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'sales',
      status: json['status']?.toString() ?? 'active',
      version: Extractor.asInt(json['version'], 1),
    );
  }
}

class TeamInvitation {
  final String id;
  final String? email;
  final String? phone;
  final String role;
  final DateTime? createdAt;

  const TeamInvitation({
    required this.id,
    this.email,
    this.phone,
    required this.role,
    this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      try {
        dt = DateTime.parse(json['created_at'].toString()).toLocal();
      } catch (_) {}
    }
    return TeamInvitation(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'sales',
      createdAt: dt,
    );
  }
}
