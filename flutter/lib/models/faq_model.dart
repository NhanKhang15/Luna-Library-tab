import '../core/api_config.dart';

class FAQSourcePost {
  final int id;
  final String title;
  final String? thumbnailUrl;

  const FAQSourcePost({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });

  factory FAQSourcePost.fromJson(Map<String, dynamic> json) {
    return FAQSourcePost(
      id: json['id'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class FAQExpert {
  final int expertId;
  final String fullName;
  final String? specialization;

  const FAQExpert({
    required this.expertId,
    required this.fullName,
    this.specialization,
  });

  factory FAQExpert.fromJson(Map<String, dynamic> json) {
    return FAQExpert(
      expertId: json['expertId'] as int,
      fullName: json['fullName'] as String,
      specialization: json['specialization'] as String?,
    );
  }
}

class FAQRelatedVideo {
  final int id;
  final String title;
  final String? thumbnailUrl;

  const FAQRelatedVideo({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });

  factory FAQRelatedVideo.fromJson(Map<String, dynamic> json) {
    return FAQRelatedVideo(
      id: json['id'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class FAQTag {
  final int id;
  final String name;
  final String slug;

  const FAQTag({required this.id, required this.name, required this.slug});

  factory FAQTag.fromJson(Map<String, dynamic> json) {
    return FAQTag(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class FAQItem {
  final int id;
  final String category;
  final String question;
  final String answer;
  final List<FAQTag> tags;
  final FAQExpert? expert;
  final FAQSourcePost? sourcePost;
  final List<FAQRelatedVideo> relatedVideos;

  // UI state
  bool isExpanded;

  FAQItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.tags,
    this.expert,
    this.sourcePost,
    required this.relatedVideos,
    this.isExpanded = false,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as int,
      category: json['category'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => FAQTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expert: json['expert'] != null
          ? FAQExpert.fromJson(json['expert'] as Map<String, dynamic>)
          : null,
      sourcePost: json['sourcePost'] != null
          ? FAQSourcePost.fromJson(json['sourcePost'] as Map<String, dynamic>)
          : null,
      relatedVideos:
          (json['relatedVideos'] as List<dynamic>?)
              ?.map((e) => FAQRelatedVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper to construct full image URL
  String? getSourcePostImageUrl() {
    if (sourcePost?.thumbnailUrl == null) {
      return null;
    }
    if (sourcePost!.thumbnailUrl!.startsWith('http')) {
      return sourcePost!.thumbnailUrl;
    }
    return '${ApiConfig.baseUrl}${sourcePost!.thumbnailUrl}';
  }
}
