import 'package:projectbrain/core/logging/app_logger.dart';

/// Subscription tier enum
enum SubscriptionTier {
  free,
  pro,
  ultimate;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.ultimate:
        return 'Ultimate';
    }
  }

  static SubscriptionTier fromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'pro':
        return SubscriptionTier.pro;
      case 'ultimate':
        return SubscriptionTier.ultimate;
      default:
        return SubscriptionTier.free;
    }
  }
}

/// Subscription status enum
enum SubscriptionStatus {
  active,
  trialing,
  canceled,
  expired;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.trialing:
        return 'Trial';
      case SubscriptionStatus.canceled:
        return 'Canceled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  static SubscriptionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

/// Subscription model
class Subscription {
  final String id;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? canceledAt;
  final String userType;

  Subscription({
    required this.id,
    required this.tier,
    required this.status,
    this.trialEndsAt,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.canceledAt,
    required this.userType,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    logDebug('[Subscription] Parsing subscription: $json');

    return Subscription(
      id: json['id'] ?? json['Id'] ?? '',
      tier: SubscriptionTier.fromString(
        (json['tier'] ?? json['Tier'] ?? 'free').toString(),
      ),
      status: SubscriptionStatus.fromString(
        (json['status'] ?? json['Status'] ?? 'expired').toString(),
      ),
      trialEndsAt: json['trialEndsAt'] != null || json['TrialEndsAt'] != null
          ? DateTime.parse(
              (json['trialEndsAt'] ?? json['TrialEndsAt']).toString())
          : null,
      currentPeriodStart: json['currentPeriodStart'] != null ||
              json['currentPeriodStart'] != null
          ? DateTime.parse(
              (json['currentPeriodStart'] ?? json['CurrentPeriodStart'])
                  .toString())
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null ||
              json['CurrentPeriodEnd'] != null
          ? DateTime.parse(
              (json['currentPeriodEnd'] ?? json['CurrentPeriodEnd']).toString())
          : null,
      canceledAt: json['canceledAt'] != null || json['CanceledAt'] != null
          ? DateTime.parse(
              (json['canceledAt'] ?? json['CanceledAt']).toString())
          : null,
      userType: json['userType'] ?? json['UserType'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier.displayName,
      'status': status.displayName,
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'currentPeriodStart': currentPeriodStart?.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'userType': userType,
    };
  }

  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;
  bool get isTrialing => status == SubscriptionStatus.trialing;
  bool get isCanceled => status == SubscriptionStatus.canceled;
  bool get isExpired => status == SubscriptionStatus.expired;
}

/// Usage statistics model
class UsageStats {
  final AIQueriesUsage aiQueries;
  final CoachMessagesUsage coachMessages;
  final FileStorageUsage fileStorage;
  final ResearchReportsUsage researchReports;

  UsageStats({
    required this.aiQueries,
    required this.coachMessages,
    required this.fileStorage,
    required this.researchReports,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    logDebug('[UsageStats] Parsing usage stats: $json');

    return UsageStats(
      aiQueries: AIQueriesUsage.fromJson(
        json['aiQueries'] ?? json['AiQueries'] ?? {},
      ),
      coachMessages: CoachMessagesUsage.fromJson(
        json['coachMessages'] ?? json['CoachMessages'] ?? {},
      ),
      fileStorage: FileStorageUsage.fromJson(
        json['fileStorage'] ?? json['FileStorage'] ?? {},
      ),
      researchReports: ResearchReportsUsage.fromJson(
        json['researchReports'] ?? json['ResearchReports'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiQueries': aiQueries.toJson(),
      'coachMessages': coachMessages.toJson(),
      'fileStorage': fileStorage.toJson(),
      'researchReports': researchReports.toJson(),
    };
  }
}

class AIQueriesUsage {
  final int daily;
  final int monthly;

  AIQueriesUsage({
    required this.daily,
    required this.monthly,
  });

  factory AIQueriesUsage.fromJson(Map<String, dynamic> json) {
    return AIQueriesUsage(
      daily: json['daily'] ?? json['Daily'] ?? 0,
      monthly: json['monthly'] ?? json['Monthly'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily,
      'monthly': monthly,
    };
  }
}

class CoachMessagesUsage {
  final int monthly;

  CoachMessagesUsage({
    required this.monthly,
  });

  factory CoachMessagesUsage.fromJson(Map<String, dynamic> json) {
    return CoachMessagesUsage(
      monthly: json['monthly'] ?? json['Monthly'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly': monthly,
    };
  }
}

class FileStorageUsage {
  final int bytes;
  final double megabytes;

  FileStorageUsage({
    required this.bytes,
    required this.megabytes,
  });

  factory FileStorageUsage.fromJson(Map<String, dynamic> json) {
    return FileStorageUsage(
      bytes: json['bytes'] ?? json['Bytes'] ?? 0,
      megabytes: (json['megabytes'] ?? json['Megabytes'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bytes': bytes,
      'megabytes': megabytes,
    };
  }
}

class ResearchReportsUsage {
  final int monthly;

  ResearchReportsUsage({
    required this.monthly,
  });

  factory ResearchReportsUsage.fromJson(Map<String, dynamic> json) {
    return ResearchReportsUsage(
      monthly: json['monthly'] ?? json['Monthly'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly': monthly,
    };
  }
}

/// Tier information model
class TierInfo {
  final SubscriptionTier tier;
  final String userType;

  TierInfo({
    required this.tier,
    required this.userType,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      tier: SubscriptionTier.fromString(
        (json['tier'] ?? json['Tier'] ?? 'free').toString(),
      ),
      userType: json['userType'] ?? json['UserType'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.displayName,
      'userType': userType,
    };
  }
}
