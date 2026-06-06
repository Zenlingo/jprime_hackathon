import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sample_data.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Loads all data (speakers, sessions, tracks, config) in parallel
  /// and populates JPData statics.
  static Future<bool> loadAll() async {
    try {
      final results = await Future.wait([
        _db.collection('speakers').get(),
        _db.collection('sessions').get(),
        _db.collection('tracks').get(),
        _db.doc('config/conference').get(),
      ]);

      final speakersSnap = results[0] as QuerySnapshot;
      final sessionsSnap = results[1] as QuerySnapshot;
      final tracksSnap = results[2] as QuerySnapshot;
      final configSnap = results[3] as DocumentSnapshot;

      // Tracks
      if (tracksSnap.docs.isNotEmpty) {
        JPData.tracks = {
          for (final doc in tracksSnap.docs)
            doc.id: TrackData(
              id: doc.id,
              label: (doc.data() as Map<String, dynamic>)['label'] as String? ??
                  doc.id,
            ),
        };
      }

      // Config
      if (configSnap.exists) {
        final data = configSnap.data() as Map<String, dynamic>;
        JPData.totalDays = data['totalDays'] as int? ?? 1;
        final dates = data['conferenceDates'] as List<dynamic>?;
        if (dates != null) {
          JPData.conferenceDates =
              dates.map((d) => DateTime.parse(d as String)).toList()..sort();
        }
      }

      // Speakers
      JPData.speakers = {
        for (final doc in speakersSnap.docs)
          doc.id: SpeakerData.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id),
      };

      // Sessions
      JPData.sessions = sessionsSnap.docs
          .map((doc) => SessionData.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList()
        ..sort((a, b) {
          final dc = a.day.compareTo(b.day);
          if (dc != 0) return dc;
          return a.startMin.compareTo(b.startMin);
        });

      return true;
    } catch (e) {
      return false;
    }
  }
}
