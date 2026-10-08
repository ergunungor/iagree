import 'package:flutter/foundation.dart';

/// Giriş yapmış kullanıcı.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  UserProfile copyWith({String? name}) =>
      UserProfile(id: id, name: name ?? this.name, email: email);

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.name == name &&
      other.email == email;

  @override
  int get hashCode => Object.hash(id, name, email);
}
