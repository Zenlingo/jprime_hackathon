import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Question {
  final String id;
  final String sessionId;
  final String text;
  final String authorName;
  final String deviceId;
  final DateTime timestamp;
  final int upvotes;
  final List<String> upvotedBy;

  Question({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.authorName,
    required this.deviceId,
    required this.timestamp,
    required this.upvotes,
    required this.upvotedBy,
  });

  factory Question.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      sessionId: d['sessionId'] ?? '',
      text: d['text'] ?? '',
      authorName: d['authorName'] ?? 'Anonymous',
      deviceId: d['deviceId'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotes: d['upvotes'] ?? 0,
      upvotedBy: List<String>.from(d['upvotedBy'] ?? []),
    );
  }
}

class QAService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'questions';

  static Stream<List<Question>> questionsStream(String sessionId) {
    return _db
        .collection(_collection)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('upvotes', descending: true)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Question.fromDoc).toList());
  }

  static Future<void> postQuestion(
    String sessionId,
    String text,
    String authorName,
    String deviceId,
  ) async {
    await _db.collection(_collection).add({
      'sessionId': sessionId,
      'text': text,
      'authorName': authorName.isNotEmpty ? authorName : 'Anonymous',
      'deviceId': deviceId,
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'upvotedBy': <String>[],
    });
  }

  static Future<void> toggleUpvote(String questionId, String deviceId) async {
    final ref = _db.collection(_collection).doc(questionId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final upvotedBy = List<String>.from(snap['upvotedBy'] ?? []);
      if (upvotedBy.contains(deviceId)) {
        upvotedBy.remove(deviceId);
        tx.update(ref, {
          'upvotedBy': upvotedBy,
          'upvotes': FieldValue.increment(-1),
        });
      } else {
        upvotedBy.add(deviceId);
        tx.update(ref, {
          'upvotedBy': upvotedBy,
          'upvotes': FieldValue.increment(1),
        });
      }
    });
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    return id;
  }
}
