class LoginRequest {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;

  LoginRequest({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'mobile': mobile,
      };
}
