class RatingSummary {
  final num averageRating;
  final num ratingCount;
  final num? yourScore;

  const RatingSummary({
    this.averageRating = 0,
    this.ratingCount = 0,
    this.yourScore,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
        averageRating: json['averageRating'] is num ? json['averageRating'] as num : 0,
        ratingCount: json['ratingCount'] is num ? json['ratingCount'] as num : 0,
        yourScore: json['yourScore'] is num ? json['yourScore'] as num : null,
      );
}
