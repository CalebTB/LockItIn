import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/utils/surprise_party_utils.dart';
import 'package:lockitin_app/data/models/event_model.dart';
import 'package:lockitin_app/data/models/event_template_model.dart';

void main() {
  group('SurprisePartyEventExtension', () {
    late DateTime testStartTime;
    late DateTime testEndTime;
    late DateTime testCreatedAt;

    setUp(() {
      testStartTime = DateTime(2026, 2, 14, 18, 0);
      testEndTime = DateTime(2026, 2, 14, 22, 0);
      testCreatedAt = DateTime(2026, 1, 14);
    });

    EventModel createTestEvent({
      String? userId = 'user123',
      EventTemplateModel? templateData,
    }) {
      return EventModel(
        id: 'event123',
        userId: userId!,
        title: 'Test Event',
        startTime: testStartTime,
        endTime: testEndTime,
        visibility: EventVisibility.sharedWithName,
        createdAt: testCreatedAt,
        templateData: templateData,
      );
    }

    SurprisePartyTemplateModel createSurpriseTemplate({
      String? guestOfHonorId = 'target123',
      List<String>? inOnItUserIds,
      String? decoyTitle,
    }) {
      return SurprisePartyTemplateModel(
        guestOfHonorId: guestOfHonorId!,
        decoyTitle: decoyTitle,
        revealAt: testStartTime,
        inOnItUserIds: inOnItUserIds ?? ['coordinator1', 'coordinator2'],
        tasks: const [],
      );
    }

    group('getUserRole', () {
      test('returns "neither" when no template data exists', () {
        final event = createTestEvent(templateData: null);
        expect(event.getUserRole('user123'), 'neither');
      });

      test('returns "neither" when currentUserId is null', () {
        final template = createSurpriseTemplate();
        final event = createTestEvent(templateData: template);
        expect(event.getUserRole(null), 'neither');
      });

      test('returns "target" when user is the guest of honor', () {
        final template = createSurpriseTemplate(guestOfHonorId: 'target123');
        final event = createTestEvent(templateData: template);
        expect(event.getUserRole('target123'), 'target');
      });

      test('returns "coordinator" when user is in the inOnIt list', () {
        final template = createSurpriseTemplate(
          inOnItUserIds: ['coordinator1', 'coordinator2'],
        );
        final event = createTestEvent(templateData: template);
        expect(event.getUserRole('coordinator1'), 'coordinator');
        expect(event.getUserRole('coordinator2'), 'coordinator');
      });

      test('returns "neither" when user is not target or coordinator', () {
        final template = createSurpriseTemplate(
          guestOfHonorId: 'target123',
          inOnItUserIds: ['coordinator1'],
        );
        final event = createTestEvent(templateData: template);
        expect(event.getUserRole('other_user'), 'neither');
      });
    });

    group('getDisplayTitle', () {
      test('returns real title when no template data exists', () {
        final event = createTestEvent(templateData: null);
        expect(event.getDisplayTitle('user123'), 'Test Event');
      });

      test('returns real title when user is coordinator', () {
        final template = createSurpriseTemplate(
          decoyTitle: 'Casual Dinner',
          inOnItUserIds: ['coordinator1'],
        );
        final event = createTestEvent(templateData: template);
        expect(event.getDisplayTitle('coordinator1'), 'Test Event');
      });

      test('returns decoy title when user is target and decoy exists', () {
        final template = createSurpriseTemplate(
          guestOfHonorId: 'target123',
          decoyTitle: 'Casual Dinner',
        );
        final event = createTestEvent(templateData: template);
        expect(event.getDisplayTitle('target123'), 'Casual Dinner');
      });

      test('returns real title when user is target but no decoy title', () {
        final template = createSurpriseTemplate(
          guestOfHonorId: 'target123',
          decoyTitle: null,
        );
        final event = createTestEvent(templateData: template);
        expect(event.getDisplayTitle('target123'), 'Test Event');
      });

      test('returns real title when user is neither target nor coordinator', () {
        final template = createSurpriseTemplate(
          guestOfHonorId: 'target123',
          decoyTitle: 'Casual Dinner',
          inOnItUserIds: ['coordinator1'],
        );
        final event = createTestEvent(templateData: template);
        expect(event.getDisplayTitle('other_user'), 'Test Event');
      });

      test('returns real title when currentUserId is null', () {
        final template = createSurpriseTemplate(decoyTitle: 'Casual Dinner');
        final event = createTestEvent(templateData: template);
        expect(event.getDisplayTitle(null), 'Test Event');
      });
    });

    group('isSurpriseParty', () {
      test('returns true when event has surprise party template', () {
        final template = createSurpriseTemplate();
        final event = createTestEvent(templateData: template);
        expect(event.isSurpriseParty, true);
      });

      test('returns false when event has no template', () {
        final event = createTestEvent(templateData: null);
        expect(event.isSurpriseParty, false);
      });

      test('returns false when event has different template type', () {
        final potluckTemplate = PotluckTemplateModel(
          dishes: const [],
          maxDishesPerPerson: 2,
        );
        final event = createTestEvent(templateData: potluckTemplate);
        expect(event.isSurpriseParty, false);
      });
    });
  });
}
