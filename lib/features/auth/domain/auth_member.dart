class AuthMember {
  const AuthMember({
    required this.id,
    required this.email,
    required this.displayName,
    required this.profileImageUrl,
    required this.score,
  });

  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final int score;

  factory AuthMember.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final displayName = json['displayName'];
    final profileImageUrl = json['profileImageUrl'];
    final score = json['score'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('회원 ID가 올바르지 않습니다.');
    }
    if (email is! String || email.isEmpty) {
      throw const FormatException('회원 이메일이 올바르지 않습니다.');
    }
    if (displayName is! String || displayName.isEmpty) {
      throw const FormatException('회원 이름이 올바르지 않습니다.');
    }
    if (profileImageUrl != null && profileImageUrl is! String) {
      throw const FormatException('프로필 이미지 URL이 올바르지 않습니다.');
    }

    return AuthMember(
      id: id,
      email: email,
      displayName: displayName,
      profileImageUrl: profileImageUrl as String?,
      score: score is num ? score.toInt() : 0,
    );
  }
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class AuthSession {
  const AuthSession({required this.member, required this.tokens});

  final AuthMember member;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    if (member is! Map<String, dynamic> ||
        accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('인증 응답이 올바르지 않습니다.');
    }
    return AuthSession(
      member: AuthMember.fromJson(member),
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
    );
  }
}
