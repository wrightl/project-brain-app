/// Request body for PUT /strategies/{id}/rating.
class UpdateCopingStrategyRatingRequest {
  final int rating;

  UpdateCopingStrategyRatingRequest({required this.rating});

  Map<String, dynamic> toJson() {
    return {'rating': rating};
  }
}
