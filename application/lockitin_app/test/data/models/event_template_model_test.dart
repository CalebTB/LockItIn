import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/data/models/event_template_model.dart';

void main() {
  group('SurprisePartyTemplateModel', () {
    group('Constructor', () {
      test('should create SurprisePartyTemplateModel with default values', () {
        final template = SurprisePartyTemplateModel();

        expect(template.type, 'surprise_party');
        expect(template.name, 'Surprise Birthday Party');
        expect(template.emoji, '🎁');
        expect(template.guestOfHonorId, isNull);
        expect(template.decoyTitle, isNull);
        expect(template.revealAt, isNull);
        expect(template.tasks, isEmpty);
        expect(template.inOnItUserIds, isEmpty);
      });

      test('should create SurprisePartyTemplateModel with all fields', () {
        final revealDate = DateTime(2025, 6, 15, 19, 0);
        final template = SurprisePartyTemplateModel(
          guestOfHonorId: 'user-123',
          decoyTitle: 'Team Meeting',
          revealAt: revealDate,
          tasks: [
            SurprisePartyTask(
              id: 'task-1',
              title: 'Order cake',
              assignedTo: 'user-456',
              isCompleted: false,
            ),
          ],
          inOnItUserIds: ['user-456', 'user-789'],
        );

        expect(template.guestOfHonorId, 'user-123');
        expect(template.decoyTitle, 'Team Meeting');
        expect(template.revealAt, revealDate);
        expect(template.tasks.length, 1);
        expect(template.tasks[0].title, 'Order cake');
        expect(template.inOnItUserIds.length, 2);
      });
    });

    group('fromJson / toJson', () {
      test('should serialize and deserialize correctly', () {
        final originalTemplate = SurprisePartyTemplateModel(
          guestOfHonorId: 'user-123',
          decoyTitle: 'Team Meeting',
          tasks: [
            SurprisePartyTask(
              id: 'task-1',
              title: 'Order cake',
              assignedTo: 'user-456',
              isCompleted: false,
            ),
          ],
          inOnItUserIds: ['user-456'],
        );

        final json = originalTemplate.toJson();
        final deserializedTemplate =
            SurprisePartyTemplateModel.fromJson(json);

        expect(deserializedTemplate.type, originalTemplate.type);
        expect(deserializedTemplate.guestOfHonorId, originalTemplate.guestOfHonorId);
        expect(deserializedTemplate.decoyTitle, originalTemplate.decoyTitle);
        expect(deserializedTemplate.tasks.length, originalTemplate.tasks.length);
        expect(deserializedTemplate.tasks[0].title, originalTemplate.tasks[0].title);
        expect(deserializedTemplate.inOnItUserIds, originalTemplate.inOnItUserIds);
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'type': 'surprise_party',
          'guestOfHonorId': null,
          'decoyTitle': null,
          'revealAt': null,
          'tasks': null,
          'inOnItUserIds': null,
        };

        final template = SurprisePartyTemplateModel.fromJson(json);

        expect(template.guestOfHonorId, isNull);
        expect(template.decoyTitle, isNull);
        expect(template.revealAt, isNull);
        expect(template.tasks, isEmpty);
        expect(template.inOnItUserIds, isEmpty);
      });
    });

    group('Task Management', () {
      test('addTask should add new task to list', () {
        final template = SurprisePartyTemplateModel();
        final updatedTemplate = template.addTask(
          title: 'Decorate venue',
          assignedTo: 'user-456',
        );

        expect(updatedTemplate.tasks.length, 1);
        expect(updatedTemplate.tasks[0].title, 'Decorate venue');
        expect(updatedTemplate.tasks[0].assignedTo, 'user-456');
        expect(updatedTemplate.tasks[0].isCompleted, false);
        expect(updatedTemplate.tasks[0].id, isNotEmpty);
      });

      test('toggleTask should toggle completion status', () {
        final template = SurprisePartyTemplateModel(
          tasks: [
            SurprisePartyTask(
              id: 'task-1',
              title: 'Order cake',
              isCompleted: false,
            ),
          ],
        );

        final updatedTemplate = template.toggleTask('task-1');

        expect(updatedTemplate.tasks[0].isCompleted, true);

        final reToggledTemplate = updatedTemplate.toggleTask('task-1');
        expect(reToggledTemplate.tasks[0].isCompleted, false);
      });

      test('removeTask should remove task from list', () {
        final template = SurprisePartyTemplateModel(
          tasks: [
            SurprisePartyTask(id: 'task-1', title: 'Task 1', isCompleted: false),
            SurprisePartyTask(id: 'task-2', title: 'Task 2', isCompleted: false),
          ],
        );

        final updatedTemplate = template.removeTask('task-1');

        expect(updatedTemplate.tasks.length, 1);
        expect(updatedTemplate.tasks[0].id, 'task-2');
      });
    });

    group('Helper Methods', () {
      test('isUserInOnIt should return correct boolean', () {
        final template = SurprisePartyTemplateModel(
          inOnItUserIds: ['user-456', 'user-789'],
        );

        expect(template.isUserInOnIt('user-456'), true);
        expect(template.isUserInOnIt('user-999'), false);
      });

      test('incompleteTasks should return only incomplete tasks', () {
        final template = SurprisePartyTemplateModel(
          tasks: [
            SurprisePartyTask(id: 'task-1', title: 'Task 1', isCompleted: false),
            SurprisePartyTask(id: 'task-2', title: 'Task 2', isCompleted: true),
            SurprisePartyTask(id: 'task-3', title: 'Task 3', isCompleted: false),
          ],
        );

        final incompleteTasks = template.incompleteTasks;

        expect(incompleteTasks.length, 2);
        expect(incompleteTasks[0].id, 'task-1');
        expect(incompleteTasks[1].id, 'task-3');
      });

      test('completionPercentage should calculate correctly', () {
        final template = SurprisePartyTemplateModel(
          tasks: [
            SurprisePartyTask(id: 'task-1', title: 'Task 1', isCompleted: true),
            SurprisePartyTask(id: 'task-2', title: 'Task 2', isCompleted: true),
            SurprisePartyTask(id: 'task-3', title: 'Task 3', isCompleted: false),
            SurprisePartyTask(id: 'task-4', title: 'Task 4', isCompleted: false),
          ],
        );

        expect(template.completionPercentage, 0.5);
      });

      test('completionPercentage should return 0 for empty task list', () {
        final template = SurprisePartyTemplateModel();

        expect(template.completionPercentage, 0.0);
      });
    });
  });

  group('PotluckTemplateModel', () {
    group('Constructor', () {
      test('should create PotluckTemplateModel with default values', () {
        final template = PotluckTemplateModel();

        expect(template.type, 'potluck');
        expect(template.name, 'Potluck / Friendsgiving');
        expect(template.emoji, '🍽️');
        expect(template.maxDishesPerPerson, 2);
        expect(template.allowDuplicates, true);
        expect(template.dishes, isEmpty);
      });

      test('should create PotluckTemplateModel with custom settings', () {
        final template = PotluckTemplateModel(
          maxDishesPerPerson: 3,
          allowDuplicates: false,
          dishes: [
            PotluckDish(
              id: 'dish-1',
              category: 'mains',
              dishName: 'Turkey',
              userId: 'user-123',
            ),
          ],
        );

        expect(template.maxDishesPerPerson, 3);
        expect(template.allowDuplicates, false);
        expect(template.dishes.length, 1);
      });
    });

    group('fromJson / toJson', () {
      test('should serialize and deserialize correctly', () {
        final originalTemplate = PotluckTemplateModel(
          maxDishesPerPerson: 3,
          allowDuplicates: false,
          dishes: [
            PotluckDish(
              id: 'dish-1',
              category: 'mains',
              dishName: 'Turkey',
              userId: 'user-123',
              servingSize: 8,
              dietaryNotes: 'Contains nuts',
            ),
          ],
        );

        final json = originalTemplate.toJson();
        final deserializedTemplate = PotluckTemplateModel.fromJson(json);

        expect(deserializedTemplate.maxDishesPerPerson, originalTemplate.maxDishesPerPerson);
        expect(deserializedTemplate.allowDuplicates, originalTemplate.allowDuplicates);
        expect(deserializedTemplate.dishes.length, originalTemplate.dishes.length);
        expect(deserializedTemplate.dishes[0].dishName, originalTemplate.dishes[0].dishName);
      });
    });

    group('Dish Management', () {
      test('addDish should add new dish to list', () {
        final template = PotluckTemplateModel();
        final updatedTemplate = template.addDish(
          category: 'desserts',
          dishName: 'Pumpkin Pie',
          userId: 'user-456',
          servingSize: 6,
        );

        expect(updatedTemplate.dishes.length, 1);
        expect(updatedTemplate.dishes[0].dishName, 'Pumpkin Pie');
        expect(updatedTemplate.dishes[0].category, 'desserts');
        expect(updatedTemplate.dishes[0].servingSize, 6);
      });

      test('removeDish should remove dish from list', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'sides', dishName: 'Mashed Potatoes', userId: 'user-456'),
          ],
        );

        final updatedTemplate = template.removeDish('dish-1');

        expect(updatedTemplate.dishes.length, 1);
        expect(updatedTemplate.dishes[0].id, 'dish-2');
      });
    });

    group('Helper Methods', () {
      test('getUserDishCount should return correct count', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'sides', dishName: 'Stuffing', userId: 'user-123'),
            PotluckDish(id: 'dish-3', category: 'desserts', dishName: 'Pie', userId: 'user-456'),
          ],
        );

        expect(template.getUserDishCount('user-123'), 2);
        expect(template.getUserDishCount('user-456'), 1);
        expect(template.getUserDishCount('user-999'), 0);
      });

      test('canUserAddDish should respect maxDishesPerPerson', () {
        final template = PotluckTemplateModel(
          maxDishesPerPerson: 2,
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'sides', dishName: 'Stuffing', userId: 'user-123'),
          ],
        );

        expect(template.canUserAddDish('user-123'), false);
        expect(template.canUserAddDish('user-456'), true);
      });

      test('isDishNameTaken should check for duplicates case-insensitively', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
          ],
        );

        expect(template.isDishNameTaken('Turkey'), true);
        expect(template.isDishNameTaken('turkey'), true);
        expect(template.isDishNameTaken('TURKEY'), true);
        expect(template.isDishNameTaken('Ham'), false);
      });

      test('getDishesByCategory should filter correctly', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'sides', dishName: 'Stuffing', userId: 'user-456'),
            PotluckDish(id: 'dish-3', category: 'mains', dishName: 'Ham', userId: 'user-789'),
          ],
        );

        final mains = template.getDishesByCategory('mains');
        expect(mains.length, 2);
        expect(mains[0].dishName, 'Turkey');
        expect(mains[1].dishName, 'Ham');
      });

      test('getUserDishes should filter by user', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'sides', dishName: 'Stuffing', userId: 'user-123'),
            PotluckDish(id: 'dish-3', category: 'desserts', dishName: 'Pie', userId: 'user-456'),
          ],
        );

        final userDishes = template.getUserDishes('user-123');
        expect(userDishes.length, 2);
        expect(userDishes[0].dishName, 'Turkey');
        expect(userDishes[1].dishName, 'Stuffing');
      });

      test('getCategoryCounts should return correct counts', () {
        final template = PotluckTemplateModel(
          dishes: [
            PotluckDish(id: 'dish-1', category: 'mains', dishName: 'Turkey', userId: 'user-123'),
            PotluckDish(id: 'dish-2', category: 'mains', dishName: 'Ham', userId: 'user-456'),
            PotluckDish(id: 'dish-3', category: 'sides', dishName: 'Stuffing', userId: 'user-789'),
            PotluckDish(id: 'dish-4', category: 'desserts', dishName: 'Pie', userId: 'user-999'),
          ],
        );

        final counts = template.getCategoryCounts();
        expect(counts['mains'], 2);
        expect(counts['sides'], 1);
        expect(counts['desserts'], 1);
        expect(counts['drinks'], isNull);
      });
    });
  });

  group('EventTemplateModel Factory', () {
    test('should create SurprisePartyTemplateModel from JSON', () {
      final json = {
        'type': 'surprise_party',
        'guestOfHonorId': 'user-123',
      };

      final template = EventTemplateModel.fromJson(json);

      expect(template, isA<SurprisePartyTemplateModel>());
      expect(template.type, 'surprise_party');
      expect((template as SurprisePartyTemplateModel).guestOfHonorId, 'user-123');
    });

    test('should create PotluckTemplateModel from JSON', () {
      final json = {
        'type': 'potluck',
        'maxDishesPerPerson': 3,
      };

      final template = EventTemplateModel.fromJson(json);

      expect(template, isA<PotluckTemplateModel>());
      expect(template.type, 'potluck');
      expect((template as PotluckTemplateModel).maxDishesPerPerson, 3);
    });

    test('should create CustomTemplateModel from JSON with custom_ prefix', () {
      final json = {
        'type': 'custom_my_template',
        'schemaId': 'schema-123',
        'customFields': {'name': 'My Custom Template'},
      };

      final template = EventTemplateModel.fromJson(json);

      expect(template, isA<CustomTemplateModel>());
      expect(template.type, 'custom_schema-123');
    });

    test('should throw ArgumentError for null type', () {
      final json = <String, dynamic>{};

      expect(
        () => EventTemplateModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for unknown type', () {
      final json = {
        'type': 'unknown_template',
      };

      expect(
        () => EventTemplateModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SurprisePartyTask', () {
    test('should create task with required fields', () {
      final task = SurprisePartyTask(
        id: 'task-1',
        title: 'Order cake',
        isCompleted: false,
      );

      expect(task.id, 'task-1');
      expect(task.title, 'Order cake');
      expect(task.assignedTo, isNull);
      expect(task.isCompleted, false);
    });

    test('copyWith should update fields correctly', () {
      final task = SurprisePartyTask(
        id: 'task-1',
        title: 'Order cake',
        isCompleted: false,
      );

      final updatedTask = task.copyWith(
        title: 'Order fancy cake',
        assignedTo: 'user-456',
        isCompleted: true,
      );

      expect(updatedTask.id, 'task-1'); // ID should not change
      expect(updatedTask.title, 'Order fancy cake');
      expect(updatedTask.assignedTo, 'user-456');
      expect(updatedTask.isCompleted, true);
    });

    test('fromJson / toJson should work correctly', () {
      final task = SurprisePartyTask(
        id: 'task-1',
        title: 'Order cake',
        assignedTo: 'user-456',
        isCompleted: true,
      );

      final json = task.toJson();
      final deserializedTask = SurprisePartyTask.fromJson(json);

      expect(deserializedTask.id, task.id);
      expect(deserializedTask.title, task.title);
      expect(deserializedTask.assignedTo, task.assignedTo);
      expect(deserializedTask.isCompleted, task.isCompleted);
    });
  });

  group('PotluckDish', () {
    test('should create dish with required fields', () {
      final dish = PotluckDish(
        id: 'dish-1',
        category: 'mains',
        dishName: 'Turkey',
        userId: 'user-123',
      );

      expect(dish.id, 'dish-1');
      expect(dish.category, 'mains');
      expect(dish.dishName, 'Turkey');
      expect(dish.userId, 'user-123');
      expect(dish.servingSize, isNull);
      expect(dish.dietaryNotes, isNull);
    });

    test('fromJson / toJson should work correctly', () {
      final dish = PotluckDish(
        id: 'dish-1',
        category: 'desserts',
        dishName: 'Pumpkin Pie',
        userId: 'user-456',
        servingSize: 8,
        dietaryNotes: 'Contains nuts',
      );

      final json = dish.toJson();
      final deserializedDish = PotluckDish.fromJson(json);

      expect(deserializedDish.id, dish.id);
      expect(deserializedDish.category, dish.category);
      expect(deserializedDish.dishName, dish.dishName);
      expect(deserializedDish.userId, dish.userId);
      expect(deserializedDish.servingSize, dish.servingSize);
      expect(deserializedDish.dietaryNotes, dish.dietaryNotes);
    });
  });
}
