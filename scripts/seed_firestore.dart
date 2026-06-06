// One-time script to seed Firestore with sample data.
// Run: dart run scripts/seed_firestore.dart
// Requires: firebase_core and cloud_firestore packages.

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  print('Seeding Firestore...');

  // --- Config ---
  await db.doc('config/conference').set({
    'name': 'jPrime 2025',
    'totalDays': 2,
    'conferenceDates': ['2025-06-03', '2025-06-04'],
  });
  print('  config/conference written');

  // --- Tracks ---
  final tracks = {
    'a': {'label': 'Hall A'},
    'b': {'label': 'Hall B'},
    'workshop': {'label': 'Workshop'},
  };
  for (final e in tracks.entries) {
    await db.doc('tracks/${e.key}').set(e.value);
  }
  print('  tracks written');

  // --- Speakers ---
  final speakers = {
    'venkat-subramaniam': {
      'name': 'Venkat Subramaniam',
      'role': 'Agile Developer, Inc.',
      'initials': 'VS',
      'gradientColors': [0xFF2D6CDF, 0xFF0E9C8C],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
    'trisha-gee': {
      'name': 'Trisha Gee',
      'role': 'Gradle',
      'initials': 'TG',
      'gradientColors': [0xFFFF5A3C, 0xFF6D4AED],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
    'sharat-chander': {
      'name': 'Sharat Chander',
      'role': 'Java Dev Relations',
      'initials': 'SC',
      'gradientColors': [0xFF0E9C8C, 0xFF2D6CDF],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
    'nicolai-parlog': {
      'name': 'Nicolai Parlog',
      'role': 'Java Champion',
      'initials': 'NP',
      'gradientColors': [0xFF6D4AED, 0xFF2D6CDF],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
    'mala-gupta': {
      'name': 'Mala Gupta',
      'role': 'Author, Manning',
      'initials': 'MG',
      'gradientColors': [0xFFC0712A, 0xFFFF5A3C],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
    'josh-long': {
      'name': 'Josh Long',
      'role': 'Spring Developer Advocate',
      'initials': 'JL',
      'gradientColors': [0xFF1E9E6A, 0xFF2D6CDF],
      'numericId': null,
      'imageUrl': null,
      'twitter': null,
      'bsky': null,
      'bio': null,
    },
  };
  for (final e in speakers.entries) {
    await db.doc('speakers/${e.key}').set(e.value);
  }
  print('  speakers written (${speakers.length})');

  // --- Sessions ---
  final sessions = {
    's1': {
      'title': 'Opening keynote: The AI agents are among us',
      'trackId': 'a',
      'room': 'Hall A',
      'start': '09:00',
      'end': '09:50',
      'level': 'All',
      'speakerId': 'trisha-gee',
      'speakerName': 'Trisha Gee',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'A fast tour of where agentic systems sit in the JVM ecosystem today — what is real, what is hype, and what it means for the way we build software this year.',
      'isBreak': false,
      'day': 1,
    },
    's2': {
      'title': 'Virtual threads, really: Project Loom in production',
      'trackId': 'a',
      'room': 'Hall A',
      'start': '10:00',
      'end': '10:50',
      'level': 'Intermediate',
      'speakerId': 'sharat-chander',
      'speakerName': 'Sharat Chander',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Loom brings virtual threads to the JVM, letting you write straightforward blocking code that scales to millions of concurrent tasks. We migrate a real Spring service and cover the gotchas you will hit in production — pinning, thread-locals, and observability.',
      'isBreak': false,
      'day': 1,
    },
    's3': {
      'title': 'Spring AI deep-dive',
      'trackId': 'b',
      'room': 'Hall B',
      'start': '10:00',
      'end': '10:50',
      'level': 'Intermediate',
      'speakerId': 'josh-long',
      'speakerName': 'Josh Long',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Wire LLMs, embeddings and vector stores into a Spring Boot app with the new Spring AI abstractions. Live coding, few slides.',
      'isBreak': false,
      'day': 1,
    },
    's4': {
      'title': 'Pattern matching & records, a deep-dive',
      'trackId': 'b',
      'room': 'Hall B',
      'start': '11:00',
      'end': '11:50',
      'level': 'Beginner',
      'speakerId': 'nicolai-parlog',
      'speakerName': 'Nicolai Parlog',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Records and pattern matching reshape how we model and branch over data. We build up from sealed types to exhaustive switches and deconstruction patterns.',
      'isBreak': false,
      'day': 1,
    },
    's5': {
      'title': 'GraalVM native images for fast startup',
      'trackId': 'a',
      'room': 'Hall A',
      'start': '11:00',
      'end': '11:50',
      'level': 'Advanced',
      'speakerId': 'venkat-subramaniam',
      'speakerName': 'Venkat Subramaniam',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Cut your cold-start to milliseconds. We cover reachability metadata, the closed-world assumption, and when native images are worth the trade-offs.',
      'isBreak': false,
      'day': 1,
    },
    's6': {
      'title': 'Hands-on: Testcontainers from zero',
      'trackId': 'workshop',
      'room': 'Workshop',
      'start': '11:00',
      'end': '12:30',
      'level': 'All',
      'speakerId': 'mala-gupta',
      'speakerName': 'Mala Gupta',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Bring a laptop. We spin up real databases, message brokers and your own services as disposable containers inside your test suite.',
      'isBreak': false,
      'day': 1,
    },
    's7': {
      'title': 'Lunch & hallway track',
      'trackId': 'a',
      'room': 'Chill',
      'start': '12:30',
      'end': '13:30',
      'level': 'All',
      'speakerId': null,
      'speakerName': null,
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract': '',
      'isBreak': true,
      'day': 1,
    },
    's8': {
      'title': 'Structured concurrency in practice',
      'trackId': 'a',
      'room': 'Hall A',
      'start': '13:30',
      'end': '14:20',
      'level': 'Intermediate',
      'speakerId': 'sharat-chander',
      'speakerName': 'Sharat Chander',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'Treat groups of related tasks as a single unit of work. Cleaner cancellation, clearer error handling, and no more leaked threads.',
      'isBreak': false,
      'day': 1,
    },
    's9': {
      'title': 'Kotlin coroutines for Java teams',
      'trackId': 'b',
      'room': 'Hall B',
      'start': '13:30',
      'end': '14:20',
      'level': 'Beginner',
      'speakerId': 'mala-gupta',
      'speakerName': 'Mala Gupta',
      'coSpeakerId': null,
      'coSpeakerName': null,
      'abstract':
          'A gentle on-ramp to coroutines for teams coming from a Java background, mapping familiar concepts to suspending functions.',
      'isBreak': false,
      'day': 1,
    },
  };
  for (final e in sessions.entries) {
    await db.doc('sessions/${e.key}').set(e.value);
  }
  print('  sessions written (${sessions.length})');

  print('Done! Firestore seeded successfully.');
}
