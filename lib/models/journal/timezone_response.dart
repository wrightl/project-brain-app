/// Response from GET /users/me/timezone.
class TimezoneResponse {
  final String? timezone;

  TimezoneResponse({this.timezone});

  factory TimezoneResponse.fromJson(Map<String, dynamic> json) {
    return TimezoneResponse(
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timezone != null) 'timezone': timezone,
    };
  }
}
