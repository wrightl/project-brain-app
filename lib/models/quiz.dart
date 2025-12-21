class Quiz {
  final String id;
  final String title;
  final String description;
  final List<QuizQuestion>? questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? json['Id'] ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      questions: json['questions'] != null
          ? (json['questions'] as List<dynamic>)
              .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions?.map((q) => q.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Question input types
enum QuestionInputType {
  text,
  number,
  email,
  date,
  choice, // Single choice (radio buttons)
  multipleChoice, // Multiple choice (checkboxes)
  scale, // Likert scale or rating
  textarea,
  tel,
  url;

  static QuestionInputType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return QuestionInputType.text;
      case 'number':
        return QuestionInputType.number;
      case 'email':
        return QuestionInputType.email;
      case 'date':
        return QuestionInputType.date;
      case 'choice':
      case 'single_choice':
      case 'radio':
        return QuestionInputType.choice;
      case 'multiple_choice':
      case 'multiplechoice':
      case 'checkbox':
        return QuestionInputType.multipleChoice;
      case 'scale':
      case 'rating':
      case 'likert':
        return QuestionInputType.scale;
      case 'textarea':
        return QuestionInputType.textarea;
      case 'tel':
      case 'phone':
        return QuestionInputType.tel;
      case 'url':
        return QuestionInputType.url;
      default:
        return QuestionInputType.text;
    }
  }
}

class QuizQuestion {
  final String id;
  final String label;
  final QuestionInputType inputType;
  final bool mandatory;
  final bool visible;
  final num? minValue;
  final num? maxValue;
  final List<String>? choices; // For choice and multipleChoice types
  final String? placeholder;
  final String? hint;

  QuizQuestion({
    required this.id,
    required this.label,
    required this.inputType,
    this.mandatory = false,
    this.visible = true,
    this.minValue,
    this.maxValue,
    this.choices,
    this.placeholder,
    this.hint,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? json['Id'] ?? '',
      label: json['label'] ?? json['Label'] ?? '',
      inputType: json['inputType'] != null
          ? QuestionInputType.fromString(json['inputType'].toString())
          : QuestionInputType.text,
      mandatory: json['mandatory'] ?? json['Mandatory'] ?? false,
      visible: json['visible'] ?? json['Visible'] ?? true,
      minValue: json['minValue'] != null
          ? num.tryParse(json['minValue'].toString())
          : json['minValue'] as num?,
      maxValue: json['maxValue'] != null
          ? num.tryParse(json['maxValue'].toString())
          : json['maxValue'] as num?,
      choices: json['choices'] != null
          ? List<String>.from(json['choices'] ?? json['Choices'] ?? [])
          : null,
      placeholder: json['placeholder'] ?? json['Placeholder'],
      hint: json['hint'] ?? json['Hint'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'inputType': inputType.name,
      'mandatory': mandatory,
      'visible': visible,
      'minValue': minValue,
      'maxValue': maxValue,
      'choices': choices,
      'placeholder': placeholder,
      'hint': hint,
    };
  }
}

class QuizInsights {
  final String summary;
  final List<String> keyInsights;
  final DateTime? lastUpdated;

  QuizInsights({
    required this.summary,
    required this.keyInsights,
    this.lastUpdated,
  });

  factory QuizInsights.fromJson(Map<String, dynamic> json) {
    return QuizInsights(
      summary: json['summary'] ?? json['Summary'] ?? '',
      keyInsights: json['keyInsights'] != null
          ? List<String>.from(json['keyInsights'] ?? json['KeyInsights'] ?? [])
          : [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyInsights': keyInsights,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

class QuizResponse {
  final String id;
  final String quizId;
  final String userId;
  final String? quizTitle; // Optional title from API
  final Map<String, dynamic> answers;
  final num? score;
  final DateTime completedAt;
  final DateTime? createdAt;

  QuizResponse({
    required this.id,
    required this.quizId,
    required this.userId,
    this.quizTitle,
    required this.answers,
    this.score,
    required this.completedAt,
    this.createdAt,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      id: json['id'] ?? json['Id'] ?? '',
      quizId: json['quizId'] ?? json['QuizId'] ?? '',
      userId: json['userId'] ?? json['UserId'] ?? '',
      quizTitle: json['quizTitle'] ?? json['QuizTitle'],
      answers: json['answers'] != null
          ? Map<String, dynamic>.from(json['answers'] ?? json['Answers'] ?? {})
          : {},
      score: json['score'] != null
          ? num.tryParse(json['score'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'quizTitle': quizTitle,
      'answers': answers,
      'score': score,
      'completedAt': completedAt.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

