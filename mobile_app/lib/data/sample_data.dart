import 'package:flutter/material.dart';

class SpeakerData {
  final String name;
  final String role;
  final String initials;
  final LinearGradient gradient;
  final int? numericId;
  final String? twitter;
  final String? bsky;
  String? bio;

  String? get imageUrl =>
      numericId != null ? 'https://jprime.io/image/speaker/$numericId' : null;

  SpeakerData({
    required this.name,
    required this.role,
    required this.initials,
    required this.gradient,
    this.numericId,
    this.twitter,
    this.bsky,
    this.bio,
  });
}

class TrackData {
  final String id;
  final String label;

  const TrackData({required this.id, required this.label});
}

class SessionData {
  final String id;
  final String title;
  final String trackId;
  final String room;
  final String start;
  final String end;
  String level;
  final String? speakerId;
  final String? speakerName;
  final String? coSpeakerName;
  final String abstract_;
  final bool isBreak;
  final int day;

  SessionData({
    required this.id,
    required this.title,
    required this.trackId,
    required this.room,
    required this.start,
    required this.end,
    this.level = '',
    this.speakerId,
    this.speakerName,
    this.coSpeakerName,
    this.abstract_ = '',
    this.isBreak = false,
    this.day = 1,
  });

  int get startMin => toMin(start);
  int get endMin => toMin(end);

  static int toMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String statusAt(int nowMin) {
    if (nowMin >= endMin) return 'finished';
    if (nowMin >= startMin && nowMin < endMin) return 'live';
    return 'upcoming';
  }

  double progressAt(int nowMin) {
    final duration = endMin - startMin;
    if (duration <= 0) return 0;
    return ((nowMin - startMin) / duration).clamp(0.0, 1.0);
  }

  int minsLeftAt(int nowMin) => (endMin - nowMin).clamp(0, 999);
}

class SuggestionData {
  final String sessionId;
  final String why;

  const SuggestionData({required this.sessionId, required this.why});
}

class JPData {
  static const tracks = {
    'a': TrackData(id: 'a', label: 'Hall A'),
    'b': TrackData(id: 'b', label: 'Hall B'),
    'workshop': TrackData(id: 'workshop', label: 'Workshop'),
  };

  /// Number of conference days (updated from API).
  static int totalDays = 1;

  /// Actual conference dates (updated from API).
  static List<DateTime> conferenceDates = [];

  /// Returns the 1-based conference day for the given date, or 0 if not a conference day.
  static int dayForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (int i = 0; i < conferenceDates.length; i++) {
      if (conferenceDates[i] == d) return i + 1;
    }
    return 0;
  }

  /// Unique room names derived from sessions.
  static List<String> get rooms => sessions
      .where((s) => !s.isBreak)
      .map((s) => s.room)
      .toSet()
      .toList()
    ..sort();

  static Map<String, SpeakerData> speakers = {
    'venkat': SpeakerData(
      name: 'Venkat Subramaniam',
      role: 'Agile Developer, Inc.',
      initials: 'VS',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D6CDF), Color(0xFF0E9C8C)],
      ),
    ),
    'trisha': SpeakerData(
      name: 'Trisha Gee',
      role: 'Gradle',
      initials: 'TG',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF5A3C), Color(0xFF6D4AED)],
      ),
    ),
    'sharat': SpeakerData(
      name: 'Sharat Chander',
      role: 'Java Dev Relations',
      initials: 'SC',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E9C8C), Color(0xFF2D6CDF)],
      ),
    ),
    'nicolai': SpeakerData(
      name: 'Nicolai Parlog',
      role: 'Java Champion',
      initials: 'NP',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6D4AED), Color(0xFF2D6CDF)],
      ),
    ),
    'mala': SpeakerData(
      name: 'Mala Gupta',
      role: 'Author, Manning',
      initials: 'MG',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC0712A), Color(0xFFFF5A3C)],
      ),
    ),
    'josh': SpeakerData(
      name: 'Josh Long',
      role: 'Spring Developer Advocate',
      initials: 'JL',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E9E6A), Color(0xFF2D6CDF)],
      ),
    ),
  };

  static List<SessionData> sessions = [
    SessionData(
      id: 's1',
      title: 'Opening keynote: The AI agents are among us',
      trackId: 'a',
      room: 'Hall A',
      start: '09:00',
      end: '09:50',
      level: 'All',
      speakerId: 'trisha',
      abstract_:
          'A fast tour of where agentic systems sit in the JVM ecosystem today \u2014 what is real, what is hype, and what it means for the way we build software this year.',
    ),
    SessionData(
      id: 's2',
      title: 'Virtual threads, really: Project Loom in production',
      trackId: 'a',
      room: 'Hall A',
      start: '10:00',
      end: '10:50',
      level: 'Intermediate',
      speakerId: 'sharat',
      abstract_:
          'Loom brings virtual threads to the JVM, letting you write straightforward blocking code that scales to millions of concurrent tasks. We migrate a real Spring service and cover the gotchas you will hit in production \u2014 pinning, thread-locals, and observability.',
    ),
    SessionData(
      id: 's3',
      title: 'Spring AI deep-dive',
      trackId: 'b',
      room: 'Room 4.1',
      start: '10:00',
      end: '10:50',
      level: 'Intermediate',
      speakerId: 'josh',
      abstract_:
          'Wire LLMs, embeddings and vector stores into a Spring Boot app with the new Spring AI abstractions. Live coding, few slides.',
    ),
    SessionData(
      id: 's4',
      title: 'Pattern matching & records, a deep-dive',
      trackId: 'b',
      room: 'Room 4.1',
      start: '11:00',
      end: '11:50',
      level: 'Beginner',
      speakerId: 'nicolai',
      abstract_:
          'Records and pattern matching reshape how we model and branch over data. We build up from sealed types to exhaustive switches and deconstruction patterns.',
    ),
    SessionData(
      id: 's5',
      title: 'GraalVM native images for fast startup',
      trackId: 'a',
      room: 'Hall A',
      start: '11:00',
      end: '11:50',
      level: 'Advanced',
      speakerId: 'venkat',
      abstract_:
          'Cut your cold-start to milliseconds. We cover reachability metadata, the closed-world assumption, and when native images are worth the trade-offs.',
    ),
    SessionData(
      id: 's6',
      title: 'Hands-on: Testcontainers from zero',
      trackId: 'workshop',
      room: 'Workshop Lab',
      start: '11:00',
      end: '12:30',
      level: 'All',
      speakerId: 'mala',
      abstract_:
          'Bring a laptop. We spin up real databases, message brokers and your own services as disposable containers inside your test suite.',
    ),
    SessionData(
      id: 's7',
      title: 'Lunch & hallway track',
      trackId: 'a',
      room: 'Atrium',
      start: '12:30',
      end: '13:30',
      level: 'All',
      isBreak: true,
    ),
    SessionData(
      id: 's8',
      title: 'Structured concurrency in practice',
      trackId: 'a',
      room: 'Hall A',
      start: '13:30',
      end: '14:20',
      level: 'Intermediate',
      speakerId: 'sharat',
      abstract_:
          'Treat groups of related tasks as a single unit of work. Cleaner cancellation, clearer error handling, and no more leaked threads.',
    ),
    SessionData(
      id: 's9',
      title: 'Kotlin coroutines for Java teams',
      trackId: 'b',
      room: 'Room 4.1',
      start: '13:30',
      end: '14:20',
      level: 'Beginner',
      speakerId: 'mala',
      abstract_:
          'A gentle on-ramp to coroutines for teams coming from a Java background, mapping familiar concepts to suspending functions.',
    ),
  ];

  static List<SuggestionData> suggestions = [
    SuggestionData(sessionId: 's4', why: 'Matches your Kotlin & Spring interests'),
    SuggestionData(sessionId: 's8', why: 'Popular with people who starred Loom'),
    SuggestionData(sessionId: 's3', why: 'Fills your 10:00 gap on Day 1'),
  ];

  static SessionData? sessionById(String id) {
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
