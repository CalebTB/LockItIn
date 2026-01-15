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
      guestOfHonorId: json['guestOfHonorId'] as String? ?? json['guest_of_honor_id'] as String?,
      decoyTitle: json['decoyTitle'] as String? ?? json['decoy_title'] as String?,
      revealAt: (json['revealAt'] ?? json['reveal_at']) != null
          ? DateTime.parse((json['revealAt'] ?? json['reveal_at']) as String)
          : null,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => SurprisePartyTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      inOnItUserIds: (json['inOnItUserIds'] as List<dynamic>? ?? json['in_on_it_user_ids'] as List<dynamic>?)
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
    String? userId,
    String? description,
    String? servingSize,
    List<String>? dietaryInfo,
  }) {
    final newDish = PotluckDish(
      id: const Uuid().v4(),
      category: category,
      dishName: dishName,
      userId: userId,
      description: description,
      servingSize: servingSize,
      dietaryInfo: dietaryInfo,
      claimedAt: userId != null ? DateTime.now() : null,
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

  /// Claim a dish for a user
  PotluckTemplateModel claimDish(String dishId, String userId) {
    final updatedDishes = dishes.map((dish) {
      if (dish.id == dishId) {
        return PotluckDish(
          id: dish.id,
          category: dish.category,
          dishName: dish.dishName,
          userId: userId,
          description: dish.description,
          servingSize: dish.servingSize,
          dietaryInfo: dish.dietaryInfo,
          claimedAt: DateTime.now(),
        );
      }
      return dish;
    }).toList();

    return PotluckTemplateModel(
      maxDishesPerPerson: maxDishesPerPerson,
      allowDuplicates: allowDuplicates,
      dishes: updatedDishes,
    );
  }

  /// Unclaim a dish (make it available again)
  PotluckTemplateModel unclaimDish(String dishId) {
    final updatedDishes = dishes.map((dish) {
      if (dish.id == dishId) {
        return PotluckDish(
          id: dish.id,
          category: dish.category,
          dishName: dish.dishName,
          userId: null, // Unclaim
          description: dish.description,
          servingSize: dish.servingSize,
          dietaryInfo: dish.dietaryInfo,
          claimedAt: null, // Clear timestamp
        );
      }
      return dish;
    }).toList();

    return PotluckTemplateModel(
      maxDishesPerPerson: maxDishesPerPerson,
      allowDuplicates: allowDuplicates,
      dishes: updatedDishes,
    );
  }

  /// Get count of dishes signed up by a specific user
  int getUserDishCount(String userId) {
    return dishes.where((d) => d.userId == userId).length;
  }

  /// Check if user can add more dishes
  /// Returns true if unlimited (0) or user hasn't reached limit
  bool canUserAddDish(String userId) {
    if (maxDishesPerPerson == 0) return true; // Unlimited
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
///
/// BREAKING CHANGES (v0.4.0):
/// - userId: String to String? (nullable for unclaimed dishes)
/// - servingSize: int? to String? (flexible user input like "Serves 8-10")
/// - dietaryNotes: String? to dietaryInfo: List (structured dietary tags)
/// - Added description field for dish details
/// - Added claimedAt timestamp for tracking when dish was claimed
class PotluckDish {
  final String id;
  final String category; // 'mains', 'sides', 'desserts', 'drinks', 'appetizers'
  final String dishName;

  /// User ID of person who claimed this dish (null if unclaimed)
  final String? userId;

  /// Optional description/notes about the dish
  final String? description;

  /// Serving size as flexible string (e.g., "Serves 8-10", "Family size")
  final String? servingSize;

  /// Structured dietary information tags (e.g., ["vegetarian", "gluten-free"])
  final List<String> dietaryInfo;

  /// Timestamp when dish was claimed (null if unclaimed)
  final DateTime? claimedAt;

  PotluckDish({
    required this.id,
    required this.category,
    required this.dishName,
    this.userId,
    this.description,
    this.servingSize,
    List<String>? dietaryInfo,
    this.claimedAt,
  }) : dietaryInfo = dietaryInfo ?? [];

  /// Convenience getter to check if dish is claimed
  bool get isClaimed => userId != null;

  factory PotluckDish.fromJson(Map<String, dynamic> json) {
    return PotluckDish(
      id: json['id'] as String,
      category: json['category'] as String,
      dishName: json['dishName'] as String,
      userId: json['userId'] as String?,
      description: json['description'] as String?,
      servingSize: json['servingSize'] as String?,
      dietaryInfo: (json['dietaryInfo'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'dishName': dishName,
        'userId': userId,
        'description': description,
        'servingSize': servingSize,
        'dietaryInfo': dietaryInfo,
        'claimedAt': claimedAt?.toIso8601String(),
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
