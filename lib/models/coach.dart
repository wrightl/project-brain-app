import 'package:projectbrain/core/logging/app_logger.dart';

class Coach {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? streetAddress;
  final String? addressLine2;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final List<String>? specialisms;
  final List<String>? qualifications;
  final List<String>? ageGroups;
  final bool? isOnline;
  final ConnectionStatus? connectionStatus;
  final DateTime? requestedAt;
  final String? requestedBy;
  final String? message;

  Coach({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.streetAddress,
    this.addressLine2,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
    this.specialisms,
    this.qualifications,
    this.ageGroups,
    this.isOnline,
    this.connectionStatus,
    this.requestedAt,
    this.requestedBy,
    this.message,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    logDebug('[Coach] Coach: $json');
    logDebug('[Coach] Connection status: ${json['connectionStatus']}');
    logDebug('[Coach] full name: ${json['fullName']}');

    return Coach(
      id: json['id'] ?? json['Id'] ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'],
      phone: json['phone'] ?? json['Phone'],
      streetAddress: json['streetAddress'] ?? json['StreetAddress'],
      addressLine2: json['addressLine2'] ?? json['AddressLine2'],
      city: json['city'] ?? json['City'],
      stateProvince: json['stateProvince'] ?? json['StateProvince'],
      postalCode: json['postalCode'] ?? json['PostalCode'],
      country: json['country'] ?? json['Country'],
      specialisms: json['specialisms'] != null
          ? List<String>.from(json['specialisms'] ?? [])
          : null,
      qualifications: json['qualifications'] != null
          ? List<String>.from(json['qualifications'] ?? [])
          : null,
      ageGroups: json['ageGroups'] != null
          ? List<String>.from(json['ageGroups'] ?? [])
          : null,
      isOnline: json['isOnline'] ?? json['IsOnline'],
      connectionStatus: json['connectionStatus'] != null ||
              json['ConnectionStatus'] != null
          ? ConnectionStatus.fromString(
              (json['connectionStatus'] ?? json['ConnectionStatus']).toString())
          : null,
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      requestedBy: json['requestedBy']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'streetAddress': streetAddress,
      'addressLine2': addressLine2,
      'city': city,
      'stateProvince': stateProvince,
      'postalCode': postalCode,
      'country': country,
      'specialisms': specialisms,
      'qualifications': qualifications,
      'ageGroups': ageGroups,
      'isOnline': isOnline,
      'connectionStatus': connectionStatus?.displayName,
      if (requestedAt != null) 'requestedAt': requestedAt!.toIso8601String(),
      if (requestedBy != null) 'requestedBy': requestedBy,
      if (message != null) 'message': message,
    };
  }
}

class CoachMessage {
  final String id;
  final String coachId;
  final String? text;
  final String? audioUrl;
  final String? fileUrl;
  final String? imageUrl;
  final String messageType; // 'text', 'audio', 'file', 'image'
  final bool isFromCoach;
  final DateTime createdAt;
  final String? status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? voiceNoteFileName;

  CoachMessage({
    required this.id,
    required this.coachId,
    this.text,
    this.audioUrl,
    this.fileUrl,
    this.imageUrl,
    required this.messageType,
    required this.isFromCoach,
    required this.createdAt,
    this.status,
    this.deliveredAt,
    this.readAt,
    this.voiceNoteFileName,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    final connectionId = json['connectionId']?.toString() ?? json['ConnectionId']?.toString();
    return CoachMessage(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      coachId: json['coachId']?.toString() ?? json['CoachId']?.toString() ?? connectionId ?? '',
      text: json['content']?.toString() ?? json['text']?.toString() ?? json['Text']?.toString(),
      audioUrl: json['voiceNoteUrl']?.toString() ?? json['audioUrl']?.toString() ?? json['AudioUrl']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? json['FileUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      messageType: json['messageType']?.toString() ?? json['MessageType']?.toString() ?? 'text',
      isFromCoach: json['isFromCoach'] == true || json['IsFromCoach'] == true,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: json['status']?.toString(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      voiceNoteFileName: json['voiceNoteFileName']?.toString() ?? json['VoiceNoteFileName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coachId': coachId,
      'text': text,
      'audioUrl': audioUrl,
      'fileUrl': fileUrl,
      'imageUrl': imageUrl,
      'messageType': messageType,
      'isFromCoach': isFromCoach,
      'createdAt': createdAt.toIso8601String(),
      if (status != null) 'status': status,
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (voiceNoteFileName != null) 'voiceNoteFileName': voiceNoteFileName,
    };
  }
}

/// Connection status enum for coach connections
enum ConnectionStatus {
  none,
  pending,
  connected;

  String get displayName {
    switch (this) {
      case ConnectionStatus.none:
        return 'Not Connected';
      case ConnectionStatus.pending:
        return 'Connection Pending';
      case ConnectionStatus.connected:
        return 'Connected';
    }
  }

  static ConnectionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'none':
      case 'not_connected':
        return ConnectionStatus.none;
      case 'pending':
      case 'requested':
        return ConnectionStatus.pending;
      case 'connected':
      case 'accepted':
        return ConnectionStatus.connected;
      default:
        return ConnectionStatus.none;
    }
  }
}
