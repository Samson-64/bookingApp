enum AppRole { client, staff, specialist }

AppRole appRoleFromString(String? value) => switch (value) {
      'SPECIALIST' => AppRole.specialist,
      'STAFF' => AppRole.staff,
      _ => AppRole.client,
    };

class AppUser {
  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? personId;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.personId,
    required this.createdAt,
  });

  bool get isSpecialist => role == AppRole.specialist;
  bool get isStaff => role == AppRole.staff;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: appRoleFromString(map['role']?.toString()),
      personId: map['person_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'email': email,
      };
}