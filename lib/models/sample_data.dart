import 'dart:math';
import 'package:flutter/material.dart';

class SpeakerData {
  final String name;
  final String role;
  final String initials;
  final LinearGradient gradient;
  final int? numericId;
  final String? imageUrl;
  final String? twitter;
  final String? bsky;
  String? bio;

  SpeakerData({
    required this.name,
    required this.role,
    required this.initials,
    required this.gradient,
    this.numericId,
    this.imageUrl,
    this.twitter,
    this.bsky,
    this.bio,
  });

  factory SpeakerData.fromFirestore(Map<String, dynamic> data, String docId) {
    final name = data['name'] as String? ?? docId;
    final gradientColors = (data['gradientColors'] as List<dynamic>?)
        ?.map((c) => Color(c as int))
        .toList();

    final colors = gradientColors != null && gradientColors.length >= 2
        ? gradientColors
        : _defaultGradientColors(name);

    return SpeakerData(
      name: name,
      role: data['role'] as String? ?? '',
      initials: data['initials'] as String? ?? _initials(name),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      numericId: data['numericId'] as int?,
      imageUrl: data['imageUrl'] as String?,
      twitter: data['twitter'] as String?,
      bsky: data['bsky'] as String?,
      bio: data['bio'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'role': role,
        'initials': initials,
        'gradientColors':
            gradient.colors.map((c) => c.toARGB32()).toList(),
        'numericId': numericId,
        'imageUrl': imageUrl,
        'twitter': twitter,
        'bsky': bsky,
        'bio': bio,
      };

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, min(2, name.length)).toUpperCase();
  }

  static List<Color> _defaultGradientColors(String name) {
    const palette = [
      Color(0xFF2D6CDF), Color(0xFF0E9C8C), Color(0xFFFF5A3C),
      Color(0xFF6D4AED), Color(0xFFC0712A), Color(0xFF1E9E6A),
      Color(0xFFD63384), Color(0xFF0DCAF0),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return [
      palette[hash % palette.length],
      palette[(hash ~/ palette.length + 3) % palette.length],
    ];
  }
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
  final String? coSpeakerId;
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
    this.coSpeakerId,
    this.coSpeakerName,
    this.abstract_ = '',
    this.isBreak = false,
    this.day = 1,
  });

  factory SessionData.fromFirestore(Map<String, dynamic> data, String docId) {
    return SessionData(
      id: docId,
      title: data['title'] as String? ?? 'TBA',
      trackId: data['trackId'] as String? ?? 'a',
      room: data['room'] as String? ?? '',
      start: data['start'] as String? ?? '00:00',
      end: data['end'] as String? ?? '00:00',
      level: data['level'] as String? ?? '',
      speakerId: data['speakerId'] as String?,
      speakerName: data['speakerName'] as String?,
      coSpeakerId: data['coSpeakerId'] as String?,
      coSpeakerName: data['coSpeakerName'] as String?,
      abstract_: data['abstract'] as String? ?? '',
      isBreak: data['isBreak'] as bool? ?? false,
      day: data['day'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'trackId': trackId,
        'room': room,
        'start': start,
        'end': end,
        'level': level,
        'speakerId': speakerId,
        'speakerName': speakerName,
        'coSpeakerId': coSpeakerId,
        'coSpeakerName': coSpeakerName,
        'abstract': abstract_,
        'isBreak': isBreak,
        'day': day,
      };

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
  static Map<String, TrackData> tracks = {
    'a': TrackData(id: 'a', label: 'Hall A'),
    'b': TrackData(id: 'b', label: 'Hall B'),
    'workshop': TrackData(id: 'workshop', label: 'Workshop'),
  };

  static int totalDays = 1;
  static List<DateTime> conferenceDates = [];
  static Map<String, SpeakerData> speakers = {};
  static List<SessionData> sessions = [];
  static List<SuggestionData> suggestions = [];

  static int dayForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (int i = 0; i < conferenceDates.length; i++) {
      if (conferenceDates[i] == d) return i + 1;
    }
    return 0;
  }

  static List<String> get rooms => sessions
      .where((s) => !s.isBreak)
      .map((s) => s.room)
      .toSet()
      .toList()
    ..sort();

  static SessionData? sessionById(String id) {
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
