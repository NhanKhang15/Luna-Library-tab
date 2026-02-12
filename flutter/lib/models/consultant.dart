/// Model representing a Consultant (Chuyên gia tư vấn)
class Consultant {
  final int id;
  final String name;
  final String title;
  final String? avatarUrl;
  final bool isVerified;
  final String primaryTag;
  final double rating;
  final int ratingCount;
  final int yearsExperience;
  final int consultationCount;
  final String bio;
  final List<String> specialties;
  final String priceInfo;

  const Consultant({
    required this.id,
    required this.name,
    required this.title,
    this.avatarUrl,
    this.isVerified = false,
    required this.primaryTag,
    required this.rating,
    required this.ratingCount,
    required this.yearsExperience,
    required this.consultationCount,
    required this.bio,
    required this.specialties,
    required this.priceInfo,
  });

  factory Consultant.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Consultant(
      id: parseInt(json['id']),
      name: (json['name'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      primaryTag: (json['primaryTag'] as String?) ?? '',
      rating: parseDouble(json['rating']),
      ratingCount: parseInt(json['ratingCount']),
      yearsExperience: parseInt(json['yearsExperience']),
      consultationCount: parseInt(json['consultationCount']),
      bio: (json['bio'] as String?) ?? '',
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : [],
      priceInfo: (json['priceInfo'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'primaryTag': primaryTag,
    'rating': rating,
    'ratingCount': ratingCount,
    'yearsExperience': yearsExperience,
    'consultationCount': consultationCount,
    'bio': bio,
    'specialties': specialties,
    'priceInfo': priceInfo,
  };

}

/// Model representing an expert review
class ExpertReview {
  final int reviewId;
  final int expertId;
  final int userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ExpertReview({
    required this.reviewId,
    required this.expertId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ExpertReview.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ExpertReview(
      reviewId: parseInt(json['reviewId']),
      expertId: parseInt(json['expertId']),
      userId: parseInt(json['userId']),
      rating: parseInt(json['rating']),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
