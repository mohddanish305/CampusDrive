class UserProfile {
  String fullName;
  String email;
  String collegeName;
  String branch;
  String year;
  String? profileImagePath;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.collegeName,
    required this.branch,
    required this.year,
    this.profileImagePath,
  });

  // Factory for empty/default profile
  factory UserProfile.empty() {
    return UserProfile(
      fullName: 'User Name',
      email: '',
      collegeName: '',
      branch: '',
      year: '1',
      profileImagePath: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'college_name': collegeName,
      'branch': branch,
      'year': year,
      'profile_image_path': profileImagePath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      collegeName: map['college_name'] ?? '',
      branch: map['branch'] ?? '',
      year: map['year']?.toString() ?? '1',
      profileImagePath: map['profile_image_path'],
    );
  }
}
