import 'package:uuid/uuid.dart';

// ==================== Abstract Base Class ====================

/// Abstract class (not sealed) for event templates
/// Allows future CustomTemplateModel extension for user-generated templates (v1.1+)
abstract class EventTemplateModel {
  final String type;
  final String name;
  final String? emoji;

  EventTemplateModel({
    required this.type,
    required this.name,
    this.emoji,
  });

  /// Factory constructor for polymorphic deserialization
  /// This is the key to extensibility - adding new templates just requires:
  /// 1. Create new class extending EventTemplateModel
  /// 2. Add case to switch expression
  factory EventTemplateModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    if (type == null) {
      throw ArgumentError('Template type is required');
    }

    return switch (type) {
      'surprise_party' => SurprisePartyTemplateModel.fromJson(json),
      'potluck' => PotluckTemplateModel.fromJson(json),
      // Future: User-generated templates (v1.1+)
      String customType when customType.startsWith('custom_') =>
        CustomTemplateModel.fromJson(json),
      _ => throw ArgumentError('Unknown template type: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

// ==================== Surprise Party Template ====================

/// Surprise Birthday Party template with task management and member exclusion
/// Implements Issues #68-70
class SurprisePartyTemplateModel extends EventTemplateModel {
  /// The user ID of the guest of honor (event is hidden from them)
  final String? guestOfHonorId;

  /// The fake event title shown to the guest of honor
  final String? decoyTitle;

  /// When to reveal the surprise (auto-reveal after this time)
  final DateTime? revealAt;

  /// Task list stored as JSONB array
  final List<SurprisePartyTask> tasks;

  /// User IDs who are "in on it" (can see the real event)
  final List<String> inOnItUserIds;

  SurprisePartyTemplateModel({
    this.guestOfHonorId,
    this.decoyTitle,
    this.revealAt,
    this.tasks = const [],
    this.inOnItUserIds = const [],
  }) : super(
          type: 'surprise_party',
          name: 'Surprise Birthday Party',
          emoji: '🎁',
        );

  factory SurprisePartyTemplateModel.fromJson(Map<String, dynamic> json) {
    return SurprisePartyTemplateModel(
      guestOfHonorId: json['guestOfHonorId'] as String?,
      decoyTitle: json['decoyTitle'] as String?,
      revealAt: json['revealAt'] != null
          ? DateTime.parse(json['revealAt'] as String)
          : null,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => SurprisePartyTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      inOnItUserIds: (json['inOnItUserIds'] as List<dynamic>?)
              ?.map((id) => id as String)
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'guestOfHonorId': guestOfHonorId,
        'decoyTitle': decoyTitle,
        'revealAt': revealAt?.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'inOnItUserIds': inOnItUserIds,
      };

  // ==================== Helper Methods ====================
  // Behavior on model, not service layer (Rails-style)

  /// Add a new task to the task list
  SurprisePartyTemplateModel addTask({
    required String title,
    String? assignedTo,
  }) {
    final newTask = SurprisePartyTask(
      id: const Uuid().v4(),
      title: title,
      assignedTo: assignedTo,
      isCompleted: false,
    );

    return SurprisePartyTemplateModel(
      guestOfHonorId: guestOfHonorId,
      decoyTitle: decoyTitle,
      revealAt: revealAt,
      tasks: [...tasks, newTask],
      inOnItUserIds: inOnItUserIds,
    );
  }

  /// Toggle task completion status
  SurprisePartyTemplateModel toggleTask(String taskId) {
    final updatedTasks = tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();

    return SurprisePartyTemplateModel(
      guestOfHonorId: guestOfHonorId,
      decoyTitle: decoyTitle,
      revealAt: revealAt,
      tasks: updatedTasks,
      inOnItUserIds: inOnItUserIds,
    );
  }

  /// Remove a task from the list
  SurprisePartyTemplateModel removeTask(String taskId) {
    return SurprisePartyTemplateModel(
      guestOfHonorId: guestOfHonorId,
      decoyTitle: decoyTitle,
      revealAt: revealAt,
      tasks: tasks.where((t) => t.id != taskId).toList(),
      inOnItUserIds: inOnItUserIds,
    );
  }

  /// Check if a user is "in on it" (can see the real event)
  bool isUserInOnIt(String userId) => inOnItUserIds.contains(userId);

  /// Get incomplete tasks
  List<SurprisePartyTask> get incompleteTasks =>
      tasks.where((t) => !t.isCompleted).toList();

  /// Get completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }
}

/// Task data class for Surprise Party template
/// Stored in JSONB array (not separate table)
class SurprisePartyTask {
  final String id;
  final String title;
  final String? assignedTo;
  final bool isCompleted;

  SurprisePartyTask({
    required this.id,
    required this.title,
    this.assignedTo,
    required this.isCompleted,
  });

  factory SurprisePartyTask.fromJson(Map<String, dynamic> json) {
    return SurprisePartyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      assignedTo: json['assignedTo'] as String?,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'assignedTo': assignedTo,
        'isCompleted': isCompleted,
      };

  /// Creates a copy with updated fields
  /// Note: id is immutable and cannot be changed
  SurprisePartyTask copyWith({
    String? title,
    String? assignedTo,
    bool? isCompleted,
  }) {
    return SurprisePartyTask(
      id: id,
      title: title ?? this.title,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// ==================== Potluck Template ====================

/// Potluck / Friendsgiving template with dish signup coordination
/// Implements Issues #71-72
class PotluckTemplateModel extends EventTemplateModel {
  /// Maximum dishes one person can sign up for
  final int maxDishesPerPerson;

  /// Whether to allow duplicate dishes
  final bool allowDuplicates;

  /// Dish signups stored as JSONB array
  final List<PotluckDish> dishes;

  PotluckTemplateModel({
    this.maxDishesPerPerson = 2,
    this.allowDuplicates = true,
    this.dishes = const [],
  }) : super(
          type: 'potluck',
          name: 'Potluck / Friendsgiving',
          emoji: '🍽️',
        );

  factory PotluckTemplateModel.fromJson(Map<String, dynamic> json) {
    return PotluckTemplateModel(
      maxDishesPerPerson: json['maxDishesPerPerson'] as int? ?? 2,
      allowDuplicates: json['allowDuplicates'] as bool? ?? true,
      dishes: (json['dishes'] as List<dynamic>?)
              ?.map((d) => PotluckDish.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'maxDishesPerPerson': maxDishesPerPerson,
        'allowDuplicates': allowDuplicates,
        'dishes': dishes.map((d) => d.toJson()).toList(),
      };

  // ==================== Helper Methods ====================

  /// Add a dish signup
  PotluckTemplateModel addDish({
    required String category,
    required String dishName,
    required String userId,
    int? servingSize,
    String? dietaryNotes,
  }) {
    final newDish = PotluckDish(
      id: const Uuid().v4(),
      category: category,
      dishName: dishName,
      userId: userId,
      servingSize: servingSize,
      dietaryNotes: dietaryNotes,
    );

    return PotluckTemplateModel(
      maxDishesPerPerson: maxDishesPerPerson,
      allowDuplicates: allowDuplicates,
      dishes: [...dishes, newDish],
    );
  }

  /// Remove a dish signup
  PotluckTemplateModel removeDish(String dishId) {
    return PotluckTemplateModel(
      maxDishesPerPerson: maxDishesPerPerson,
      allowDuplicates: allowDuplicates,
      dishes: dishes.where((d) => d.id != dishId).toList(),
    );
  }

  /// Get count of dishes signed up by a specific user
  int getUserDishCount(String userId) {
    return dishes.where((d) => d.userId == userId).length;
  }

  /// Check if user can add more dishes
  bool canUserAddDish(String userId) {
    return getUserDishCount(userId) < maxDishesPerPerson;
  }

  /// Check if a dish name is already taken
  bool isDishNameTaken(String dishName) {
    return dishes
        .any((d) => d.dishName.toLowerCase() == dishName.toLowerCase());
  }

  /// Get dishes by category
  List<PotluckDish> getDishesByCategory(String category) {
    return dishes.where((d) => d.category == category).toList();
  }

  /// Get dishes signed up by a specific user
  List<PotluckDish> getUserDishes(String userId) {
    return dishes.where((d) => d.userId == userId).toList();
  }

  /// Get all unique categories with dish counts
  Map<String, int> getCategoryCounts() {
    final counts = <String, int>{};
    for (final dish in dishes) {
      counts[dish.category] = (counts[dish.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Standard dish categories
  static const List<String> standardCategories = [
    'mains',
    'sides',
    'desserts',
    'drinks',
    'appetizers',
  ];
}

/// Dish data class for Potluck template
/// Stored in JSONB array (not separate table)
class PotluckDish {
  final String id;
  final String category; // 'mains', 'sides', 'desserts', 'drinks', 'appetizers'
  final String dishName;
  final String userId;
  final int? servingSize;
  final String? dietaryNotes;

  PotluckDish({
    required this.id,
    required this.category,
    required this.dishName,
    required this.userId,
    this.servingSize,
    this.dietaryNotes,
  });

  factory PotluckDish.fromJson(Map<String, dynamic> json) {
    return PotluckDish(
      id: json['id'] as String,
      category: json['category'] as String,
      dishName: json['dishName'] as String,
      userId: json['userId'] as String,
      servingSize: json['servingSize'] as int?,
      dietaryNotes: json['dietaryNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'dishName': dishName,
        'userId': userId,
        'servingSize': servingSize,
        'dietaryNotes': dietaryNotes,
      };
}

// ==================== Future: Custom Template (v1.1+) ====================

/// User-generated template from template marketplace
/// This demonstrates why factory pattern matters - we can add this later
/// without refactoring the existing code
class CustomTemplateModel extends EventTemplateModel {
  /// Reference to user_templates table (future feature)
  final String schemaId;

  /// Custom fields defined by template creator
  final Map<String, dynamic> customFields;

  CustomTemplateModel({
    required this.schemaId,
    required this.customFields,
  }) : super(
          type: 'custom_$schemaId',
          name: customFields['name'] as String? ?? 'Custom Template',
          emoji: customFields['emoji'] as String?,
        );

  factory CustomTemplateModel.fromJson(Map<String, dynamic> json) {
    return CustomTemplateModel(
      schemaId: json['schemaId'] as String,
      customFields:
          json['customFields'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'schemaId': schemaId,
        'customFields': customFields,
      };
}
