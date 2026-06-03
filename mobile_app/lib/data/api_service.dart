import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'sample_data.dart';

class JPrimeApi {
  static const String baseUrl = 'https://jprime.io';
  static const List<String> defaultHalls = ['Hall A', 'Hall B', 'Workshops'];

  /// Speaker directory: normalized name → scraped data.
  /// Populated by [loadSpeakers].
  static final Map<String, _ScrapedSpeaker> _speakerDirectory = {};

  /// Fetches sessions from all halls and populates JPData.
  static Future<bool> loadSchedule() async {
    try {
      final allRaw = <Map<String, dynamic>>[];
      final seenIds = <int>{};

      for (final hall in defaultHalls) {
        try {
          final body = await _get('$baseUrl/pwa/findSessionsByHall',
              queryParams: {'hallName': hall});
          if (body == null) continue;

          final List<dynamic> data = json.decode(body);
          for (final item in data) {
            final id = item['id'] as int;
            if (seenIds.contains(id)) continue;
            seenIds.add(id);
            allRaw.add({
              ...(item as Map<String, dynamic>),
              '_queriedHall': hall,
            });
          }
        } catch (_) {}
      }

      if (allRaw.isEmpty) return false;

      // Determine conference days from unique dates
      final dates = allRaw
          .map((item) => DateTime.parse(item['startTime'] as String))
          .map((dt) => DateTime(dt.year, dt.month, dt.day))
          .toSet()
          .toList()
        ..sort();

      final speakers = <String, SpeakerData>{};
      final sessions = <SessionData>[];

      for (final item in allRaw) {
        final startTime = DateTime.parse(item['startTime'] as String);
        final endTime = DateTime.parse(item['endTime'] as String);
        final hallName =
            (item['hallName'] as String?) ?? (item['_queriedHall'] as String);
        final lectorName = item['lectorName'] as String?;
        final coLectorName = item['coLectorName'] as String?;
        final title = (item['title'] as String?) ?? 'TBA';
        final description = (item['talkDescription'] as String?) ?? '';

        final trackId = _hallToTrack(hallName);

        final sessionDate =
            DateTime(startTime.year, startTime.month, startTime.day);
        final day = dates.indexOf(sessionDate) + 1;

        String? speakerId;
        if (lectorName != null && lectorName.isNotEmpty) {
          speakerId = _slugify(lectorName);
          speakers.putIfAbsent(
              speakerId, () => _buildSpeaker(lectorName));
        }
        if (coLectorName != null && coLectorName.isNotEmpty) {
          final coId = _slugify(coLectorName);
          speakers.putIfAbsent(
              coId, () => _buildSpeaker(coLectorName));
        }

        final isBreak = lectorName == null && description.isEmpty;

        sessions.add(SessionData(
          id: item['id'].toString(),
          title: title,
          trackId: trackId,
          room: hallName,
          start: _formatTime(startTime),
          end: _formatTime(endTime),
          level: '',
          speakerId: speakerId,
          speakerName: lectorName,
          coSpeakerName: coLectorName,
          abstract_: description,
          isBreak: isBreak,
          day: day,
        ));
      }

      sessions.sort((a, b) {
        final dc = a.day.compareTo(b.day);
        if (dc != 0) return dc;
        return a.startMin.compareTo(b.startMin);
      });

      JPData.sessions = sessions;
      JPData.speakers = speakers;
      JPData.suggestions = [];
      JPData.totalDays = dates.length.clamp(1, 3);
      JPData.conferenceDates = dates;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Scrapes /speakers HTML page to get IDs, headlines, twitter handles.
  /// Then enriches JPData.speakers with this data.
  static Future<void> loadSpeakers() async {
    try {
      final html = await _get('$baseUrl/speakers');
      if (html == null) return;

      // Extract speaker entries: image ID + name + headline in sequence
      final entryRegex = RegExp(
        r'src="/image/speaker/(\d+)"(.*?)<h3><a href="/speaker/\d+">(.+?)</a></h3>\s*<p>(.*?)</p>',
        dotAll: true,
      );
      final twitterRegex = RegExp(r'href="https://x\.com/([^"]+)"');
      final bskyRegex =
          RegExp(r'href="https://bsky\.app/profile/([^"]+)"');

      for (final match in entryRegex.allMatches(html)) {
        final numericId = int.parse(match.group(1)!);
        final betweenText = match.group(2)!; // text between img and h3
        final rawName = match
            .group(3)!
            .replaceAll('&nbsp;', ' ')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim();
        final headline = match
            .group(4)!
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim();

        final twitterMatch = twitterRegex.firstMatch(betweenText);
        final bskyMatch = bskyRegex.firstMatch(betweenText);

        final normalized = _normalizeName(rawName);
        _speakerDirectory[normalized] = _ScrapedSpeaker(
          numericId: numericId,
          name: rawName,
          headline: headline,
          twitter: twitterMatch?.group(1),
          bsky: bskyMatch?.group(1),
        );
      }

      // Enrich existing JPData.speakers with scraped data
      for (final entry in JPData.speakers.entries) {
        final sp = entry.value;
        final scraped = _findScrapedSpeaker(sp.name);
        if (scraped != null) {
          JPData.speakers[entry.key] = SpeakerData(
            name: sp.name,
            role: scraped.headline.isNotEmpty ? scraped.headline : sp.role,
            initials: sp.initials,
            gradient: sp.gradient,
            numericId: scraped.numericId,
            twitter: scraped.twitter,
            bsky: scraped.bsky,
          );
        }
      }
    } catch (_) {}
  }

  /// Scrapes talk levels from /agenda/{id} pages in parallel.
  static Future<void> loadLevels() async {
    try {
      final sessions =
          JPData.sessions.where((s) => !s.isBreak && s.level.isEmpty).toList();
      if (sessions.isEmpty) return;

      final levelRegex = RegExp(
        r'<b>Talk Level:</b>\s*(?:<br\s*/?>)?\s*(BEGINNER|INTERMEDIATE|ADVANCED)',
        caseSensitive: false,
      );

      // Fetch up to 10 at a time to avoid overwhelming the server
      const batchSize = 10;
      for (int i = 0; i < sessions.length; i += batchSize) {
        final batch = sessions.skip(i).take(batchSize);
        await Future.wait(batch.map((s) async {
          try {
            final html = await _get('$baseUrl/agenda/${s.id}');
            if (html == null) return;
            final match = levelRegex.firstMatch(html);
            if (match != null) {
              s.level = _normalizeLevel(match.group(1));
            }
          } catch (_) {}
        }));
      }
    } catch (_) {}
  }

  /// Lazy-loads speaker bio from /speaker/{id} page.
  static Future<String?> fetchSpeakerBio(int numericId) async {
    try {
      final html = await _get('$baseUrl/speaker/$numericId');
      if (html == null) return null;

      final bioRegex = RegExp(
        r'<div class="entry-content">\s*<p>(.*?)</p>',
        dotAll: true,
      );
      final match = bioRegex.firstMatch(html);
      if (match == null) return null;

      return match
          .group(1)!
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('\r\n', '\n')
          .trim();
    } catch (_) {
      return null;
    }
  }

  // --- Helpers ---

  static Future<String?> _get(String url,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        client.close();
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      client.close();
      return body;
    } catch (_) {
      return null;
    }
  }

  static _ScrapedSpeaker? _findScrapedSpeaker(String name) {
    final normalized = _normalizeName(name);
    if (_speakerDirectory.containsKey(normalized)) {
      return _speakerDirectory[normalized];
    }
    // Fuzzy match: try matching by last name
    final lastName = name.trim().split(RegExp(r'\s+')).last.toLowerCase();
    for (final entry in _speakerDirectory.entries) {
      if (entry.key.endsWith(lastName)) return entry.value;
    }
    return null;
  }

  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '')
        .trim();
  }

  static String _normalizeLevel(String? raw) {
    if (raw == null) return '';
    switch (raw.toUpperCase()) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
        return 'Advanced';
      default:
        return '';
    }
  }

  static String _hallToTrack(String hallName) {
    final lower = hallName.toLowerCase();
    if (lower.contains('hall a') || lower.contains('alpha')) return 'a';
    if (lower.contains('hall b') || lower.contains('beta')) return 'b';
    if (lower.contains('workshop')) return 'workshop';
    return 'a';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static SpeakerData _buildSpeaker(String name) {
    final scraped = _findScrapedSpeaker(name);
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, min(2, name.length)).toUpperCase();

    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    const palette = [
      Color(0xFF2D6CDF),
      Color(0xFF0E9C8C),
      Color(0xFFFF5A3C),
      Color(0xFF6D4AED),
      Color(0xFFC0712A),
      Color(0xFF1E9E6A),
      Color(0xFFD63384),
      Color(0xFF0DCAF0),
    ];

    final c1 = palette[hash % palette.length];
    final c2 = palette[(hash ~/ palette.length + 3) % palette.length];

    return SpeakerData(
      name: name,
      role: scraped?.headline ?? '',
      initials: initials,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1, c2],
      ),
      numericId: scraped?.numericId,
      twitter: scraped?.twitter,
      bsky: scraped?.bsky,
    );
  }
}

class _ScrapedSpeaker {
  final int numericId;
  final String name;
  final String headline;
  final String? twitter;
  final String? bsky;

  _ScrapedSpeaker({
    required this.numericId,
    required this.name,
    required this.headline,
    this.twitter,
    this.bsky,
  });
}
