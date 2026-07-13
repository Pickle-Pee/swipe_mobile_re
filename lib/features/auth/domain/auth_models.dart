class SendCodeRequest {
  const SendCodeRequest(this.phoneNumber);

  final String phoneNumber;

  Map<String, dynamic> toQueryParameters() => {'phone_number': phoneNumber};
}

class SendCodeResponse {
  const SendCodeResponse({this.demoVerificationCode});

  final String? demoVerificationCode;

  factory SendCodeResponse.fromJson(Map<String, dynamic> json) {
    final code = json['verification_code'];
    return SendCodeResponse(
      demoVerificationCode: code is String && code.isNotEmpty ? code : null,
    );
  }
}

enum AccountStatus { newUser, existingUser }

class CheckCodeRequest {
  const CheckCodeRequest({
    required this.phoneNumber,
    required this.verificationCode,
  });

  final String phoneNumber;
  final String verificationCode;

  Map<String, dynamic> toQueryParameters() => {
    'phone_number': phoneNumber,
    'verification_code': verificationCode,
  };
}

class LoginRequest {
  const LoginRequest({required this.phoneNumber, required this.code});

  final String phoneNumber;
  final String code;

  Map<String, dynamic> toQueryParameters() => {
    'phone_number': phoneNumber,
    'code': code,
  };
}

class RegisterRequest {
  const RegisterRequest({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.cityName,
    this.additionalFields = const {},
  });

  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String cityName;
  final Map<String, dynamic> additionalFields;

  Map<String, dynamic> toJson() => {
    ...additionalFields,
    'phone_number': phoneNumber,
    'first_name': firstName,
    'last_name': lastName,
    'date_of_birth': dateOfBirth,
    'gender': gender,
    'city_name': cityName,
  };
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('Authentication response has no tokens');
    }
    return AuthSession(accessToken: accessToken, refreshToken: refreshToken);
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    this.phoneNumber,
    this.firstName,
    this.lastName,
  });

  final int id;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('whoami response has no user id');
    }
    return AuthUser(
      id: id,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}
