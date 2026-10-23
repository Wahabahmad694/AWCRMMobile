class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'User',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };
}

class Membership {
  final String organizationId;
  final String name;
  final Set<String> permissions;
  final String? role;
  final String? subscriptionStatus;

  const Membership({
    required this.organizationId,
    required this.name,
    required this.permissions,
    this.role,
    this.subscriptionStatus,
  });

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'name': name,
    'permissions': permissions.toList(),
    if (role != null) 'role': role,
    if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
  };

  factory Membership.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'] is Map
        ? json['organization'] as Map
        : const {};
    final id = json['organization_id'] ?? organization['id'];
    final perms = json['permissions'];
    return Membership(
      organizationId: id?.toString() ?? '',
      name:
          organization['name']?.toString() ??
          json['name']?.toString() ??
          'Organization',
      permissions: perms is List
          ? perms.whereType<String>().toSet()
          : <String>{},
      role: json['role']?.toString(),
      subscriptionStatus:
          organization['subscription_status']?.toString() ??
          json['subscription_status']?.toString(),
    );
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;
  final List<Membership> memberships;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.memberships,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final memberList = json['memberships'] is List
        ? (json['memberships'] as List)
              .whereType<Map>()
              .map((m) => Membership.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : <Membership>[];
    return AuthResult(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      user: UserProfile.fromJson(userJson),
      memberships: memberList,
    );
  }
}

class SessionItem {
  final String id;
  final String? userAgent;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  const SessionItem({
    required this.id,
    this.userAgent,
    this.ipAddress,
    this.createdAt,
    this.lastActiveAt,
    this.isCurrent = false,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d is String && d.isNotEmpty) {
        try {
          return DateTime.parse(d).toLocal();
        } catch (_) {}
      }
      return null;
    }

    return SessionItem(
      id: json['id']?.toString() ?? '',
      userAgent: json['user_agent']?.toString() ?? json['device']?.toString(),
      ipAddress: json['ip_address']?.toString() ?? json['ip']?.toString(),
      createdAt: parseDate(json['created_at']),
      lastActiveAt: parseDate(json['last_active_at'] ?? json['last_seen_at']),
      isCurrent: json['is_current'] == true || json['current'] == true,
    );
  }
}
