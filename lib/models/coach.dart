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
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] ?? json['Id'] ?? '',
      coachId: json['coachId'] ?? json['CoachId'] ?? '',
      text: json['text'] ?? json['Text'],
      audioUrl: json['audioUrl'] ?? json['AudioUrl'],
      fileUrl: json['fileUrl'] ?? json['FileUrl'],
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      messageType: json['messageType'] ?? json['MessageType'] ?? 'text',
      isFromCoach: json['isFromCoach'] ?? json['IsFromCoach'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
