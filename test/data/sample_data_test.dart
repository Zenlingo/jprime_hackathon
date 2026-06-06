import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/sample_data.dart';

void main() {
  group('SessionData.toMin', () {
    test('converts "09:00" to 540', () {
      expect(SessionData.toMin('09:00'), 540);
    });

    test('converts "13:30" to 810', () {
      expect(SessionData.toMin('13:30'), 810);
    });

    test('converts "00:00" to 0', () {
      expect(SessionData.toMin('00:00'), 0);
    });

    test('converts "23:59" to 1439', () {
      expect(SessionData.toMin('23:59'), 1439);
    });
  });

  group('SessionData.startMin / endMin', () {
    test('returns correct minute values', () {
      final session = SessionData(
        id: 't1',
        title: 'Test',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:50',
      );
      expect(session.startMin, 600);
      expect(session.endMin, 650);
    });
  });

  group('SessionData.statusAt', () {
    late SessionData session;

    setUp(() {
      session = SessionData(
        id: 't1',
        title: 'Test',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:50',
      );
    });

    test('returns "upcoming" before session starts', () {
      expect(session.statusAt(599), 'upcoming');
      expect(session.statusAt(540), 'upcoming');
    });

    test('returns "live" at session start', () {
      expect(session.statusAt(600), 'live');
    });

    test('returns "live" during session', () {
      expect(session.statusAt(625), 'live');
      expect(session.statusAt(649), 'live');
    });

    test('returns "finished" at session end', () {
      expect(session.statusAt(650), 'finished');
    });

    test('returns "finished" after session end', () {
      expect(session.statusAt(700), 'finished');
    });
  });

  group('SessionData.progressAt', () {
    late SessionData session;

    setUp(() {
      // 10:00 (600) to 10:50 (650), duration = 50 min
      session = SessionData(
        id: 't1',
        title: 'Test',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:50',
      );
    });

    test('returns 0.0 before session starts', () {
      expect(session.progressAt(500), 0.0);
    });

    test('returns 0.0 at session start', () {
      expect(session.progressAt(600), 0.0);
    });

    test('returns 0.5 at midpoint', () {
      expect(session.progressAt(625), 0.5);
    });

    test('returns 1.0 at session end', () {
      expect(session.progressAt(650), 1.0);
    });

    test('clamps to 1.0 after session end', () {
      expect(session.progressAt(700), 1.0);
    });

    test('returns 0 when duration is zero', () {
      final zeroSession = SessionData(
        id: 'z',
        title: 'Zero',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:00',
      );
      expect(zeroSession.progressAt(600), 0.0);
    });
  });

  group('SessionData.minsLeftAt', () {
    late SessionData session;

    setUp(() {
      session = SessionData(
        id: 't1',
        title: 'Test',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:50',
      );
    });

    test('returns full duration before start', () {
      expect(session.minsLeftAt(600), 50);
    });

    test('returns remaining minutes during session', () {
      expect(session.minsLeftAt(630), 20);
    });

    test('returns 0 at session end', () {
      expect(session.minsLeftAt(650), 0);
    });

    test('clamps to 0 after session end', () {
      expect(session.minsLeftAt(700), 0);
    });
  });

  group('SessionData defaults', () {
    test('has correct defaults for optional fields', () {
      final session = SessionData(
        id: 't1',
        title: 'Test',
        trackId: 'a',
        room: 'Hall A',
        start: '10:00',
        end: '10:50',
      );
      expect(session.level, '');
      expect(session.speakerId, isNull);
      expect(session.speakerName, isNull);
      expect(session.coSpeakerName, isNull);
      expect(session.abstract_, '');
      expect(session.isBreak, false);
      expect(session.day, 1);
    });
  });

  group('SpeakerData', () {
    test('imageUrl is built from numericId', () {
      final speaker = SpeakerData(
        name: 'Test',
        role: 'Dev',
        initials: 'T',
        gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
        numericId: 42,
      );
      expect(speaker.imageUrl, 'https://jprime.io/image/speaker/42');
    });

    test('imageUrl is null when numericId is null', () {
      final speaker = SpeakerData(
        name: 'Test',
        role: 'Dev',
        initials: 'T',
        gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
      );
      expect(speaker.imageUrl, isNull);
    });
  });

  group('JPData', () {
    test('tracks contains a, b, workshop', () {
      expect(JPData.tracks.keys, containsAll(['a', 'b', 'workshop']));
      expect(JPData.tracks['a']!.label, 'Hall A');
      expect(JPData.tracks['b']!.label, 'Hall B');
      expect(JPData.tracks['workshop']!.label, 'Workshop');
    });

    test('sessionById returns session for valid id', () {
      final session = JPData.sessionById('s1');
      expect(session, isNotNull);
      expect(session!.title, contains('Opening keynote'));
    });

    test('sessionById returns null for invalid id', () {
      expect(JPData.sessionById('nonexistent'), isNull);
    });

    test('rooms returns sorted unique non-break rooms', () {
      final rooms = JPData.rooms;
      expect(rooms, isNotEmpty);
      // Should not include break room "Chill"
      for (final room in rooms) {
        expect(room, isNot('Chill'));
      }
      // Should be sorted
      for (int i = 1; i < rooms.length; i++) {
        expect(rooms[i].compareTo(rooms[i - 1]) >= 0, isTrue);
      }
    });

    test('speakers map is not empty', () {
      expect(JPData.speakers, isNotEmpty);
    });

    test('sessions list is not empty', () {
      expect(JPData.sessions, isNotEmpty);
    });

    group('dayForDate', () {
      test('returns 0 when no conference dates set', () {
        final original = JPData.conferenceDates;
        JPData.conferenceDates = [];
        expect(JPData.dayForDate(DateTime(2025, 6, 4)), 0);
        JPData.conferenceDates = original;
      });

      test('returns correct day for matching dates', () {
        JPData.conferenceDates = [
          DateTime(2025, 6, 4),
          DateTime(2025, 6, 5),
        ];
        expect(JPData.dayForDate(DateTime(2025, 6, 4)), 1);
        expect(JPData.dayForDate(DateTime(2025, 6, 5)), 2);
        expect(JPData.dayForDate(DateTime(2025, 6, 6)), 0);
        JPData.conferenceDates = [];
      });
    });

    test('break sessions have isBreak = true', () {
      final breaks = JPData.sessions.where((s) => s.isBreak);
      expect(breaks, isNotEmpty);
      for (final b in breaks) {
        expect(b.isBreak, isTrue);
      }
    });
  });
}
