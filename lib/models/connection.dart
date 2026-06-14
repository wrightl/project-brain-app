/// A coach–user connection record from the API.
class Connection {
  final String id;
  final String userId;
  final String coachId;
  final String status;
  final String? userName;
  final String? coachName;
  final String? coachProfileId;
  final DateTime? requestedAt;
  final DateTime? respondedAt;

  const Connection({
    required this.id,
    required this.userId,
    required this.coachId,
    required this.status,
    this.userName,
    this.coachName,
    this.coachProfileId,
    this.requestedAt,
    this.respondedAt,
  });

  bool get isAccepted => status.toLowerCase() == 'accepted';

  bool get isPending => status.toLowerCase() == 'pending';

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['UserId']?.toString() ?? '',
      coachId: json['coachId']?.toString() ?? json['CoachId']?.toString() ?? '',
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      userName: json['userName']?.toString() ?? json['UserName']?.toString(),
      coachName: json['coachName']?.toString() ?? json['CoachName']?.toString(),
      coachProfileId: json['coachProfileId']?.toString() ??
          json['CoachProfileId']?.toString(),
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
    );
  }
}

/// Returns true when [value] looks like a GUID connection id.
bool isConnectionGuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
