class PigeonUserDetails {
  final String email;
  final String name;

  PigeonUserDetails({required this.email, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
    };
  }

  factory PigeonUserDetails.fromMap(Map<String, dynamic> map) {
    return PigeonUserDetails(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
