class AppUser {
  final String uid;
  final String name;
  final String email;
  final String gradeLevel;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.gradeLevel,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'gradeLevel': gradeLevel,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'],
    name: map['name'],
    email: map['email'],
    gradeLevel: map['gradeLevel'],
  );
}
