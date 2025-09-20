class AppUser {
  final String uid;
  final String name;
  final String email;
  final String gradeLevel;
  final int mastery;
  final int coins;
  final String? avatar;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.gradeLevel,
    this.mastery = 0,
    this.coins = 0,
    this.avatar,
  });

  // Create AppUser from a Firestore map (defensive parsing)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AppUser(
      uid: (map['uid'] ?? map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      gradeLevel: (map['gradeLevel'] ?? map['grade'] ?? '') as String,
      mastery: parseInt(map['mastery']),
      coins: parseInt(map['coins']),
      avatar: map['avatar'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'gradeLevel': gradeLevel,
      'mastery': mastery,
      'coins': coins,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
