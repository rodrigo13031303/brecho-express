class BrechoSession {
  const BrechoSession({
    required this.accessToken,
    required this.sessionPublicId,
    required this.expiresAt,
    required this.accountPublicId,
  });

  factory BrechoSession.fromJson(Map<String, dynamic> json) {
    return BrechoSession(
      accessToken: json['accessToken'] as String,
      sessionPublicId: json['sessionPublicId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accountPublicId: json['accountPublicId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'sessionPublicId': sessionPublicId,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'accountPublicId': accountPublicId,
  };

  final String accessToken;
  final String sessionPublicId;
  final DateTime expiresAt;
  final String accountPublicId;

  bool isExpiredAt(DateTime instant) => !expiresAt.isAfter(instant);
}
