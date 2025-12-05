import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Profile CRUD ---

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Read user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- News CRUD ---

  // Create news
  Future<void> createNews(NewsModel news) async {
    try {
      await _firestore.collection('news').doc(news.id).set(news.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Read all news
  Future<List<NewsModel>> getAllNews() async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => NewsModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get news by author
  Future<List<NewsModel>> getNewsByAuthor(String authorId) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .where('authorId', isEqualTo: authorId)
          .orderBy('publishedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => NewsModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get single news
  Future<NewsModel?> getNews(String newsId) async {
    try {
      final doc = await _firestore.collection('news').doc(newsId).get();
      if (doc.exists) {
        return NewsModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update news
  Future<void> updateNews(String newsId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('news').doc(newsId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete news
  Future<void> deleteNews(String newsId) async {
    try {
      await _firestore.collection('news').doc(newsId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Stream to listen for news changes
  Stream<List<NewsModel>> getNewsStream() {
    return _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => NewsModel.fromJson(doc.data()))
                .toList();
          } catch (e) {
            debugPrint('Error parsing news: $e');
            return <NewsModel>[];
          }
        })
        .handleError((Object e) {
          debugPrint('Error in news stream: $e');
          return <NewsModel>[];
        })
        .cast<List<NewsModel>>();
  }

  // Stream to listen for user's news
  Stream<List<NewsModel>> getUserNewsStream(String authorId) {
    return _firestore
        .collection('news')
        .where('authorId', isEqualTo: authorId)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => NewsModel.fromJson(doc.data()))
                .toList();
          } catch (e) {
            debugPrint('Error parsing user news: $e');
            return <NewsModel>[];
          }
        })
        .handleError((Object e) {
          debugPrint('Error in user news stream: $e');
          return <NewsModel>[];
        })
        .cast<List<NewsModel>>();
  }

  // Seed sample news data (for development)
  Future<void> seedSampleNews() async {
    try {
      final now = DateTime.now();
      final sampleNews = [
        NewsModel(
          id: 'news_1',
          title: 'Flutter 3.16 Diluncurkan dengan Fitur Baru',
          content:
              'Flutter terbaru menghadirkan peningkatan performa hingga 40% dan dukungan Material Design 3 yang lebih lengkap. Fitur baru termasuk impeller rendering engine yang lebih cepat dan tooling yang ditingkatkan.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Flutter+3.16',
          publishedAt: now.subtract(const Duration(hours: 2)),
          views: 1250,
        ),
        NewsModel(
          id: 'news_2',
          title: 'Firebase Realtime Database Mencapai 1 Juta Query/Detik',
          content:
              'Google mengumumkan peningkatan kapasitas Firebase Realtime Database hingga 1 juta query per detik. Ini merupakan milestone penting untuk aplikasi real-time yang membutuhkan skalabilitas tinggi.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Firebase+Update',
          publishedAt: now.subtract(const Duration(hours: 5)),
          views: 892,
        ),
        NewsModel(
          id: 'news_3',
          title: 'Dart 3.2 Hadir dengan Null Safety yang Lebih Baik',
          content:
              'Versi terbaru Dart membawa perbaikan signifikan pada sistem null safety. Developer dapat menulis kode yang lebih aman dengan kemudahan yang lebih tinggi. Kompatibilitas mundur tetap terjaga untuk proyek yang ada.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Dart+3.2',
          publishedAt: now.subtract(const Duration(hours: 8)),
          views: 654,
        ),
        NewsModel(
          id: 'news_4',
          title: 'Kebijakan Baru: Aplikasi Flutter Wajib Gunakan Material Design 3',
          content:
              'Tim Flutter mengumumkan bahwa mulai tahun depan, semua aplikasi baru harus menggunakan Material Design 3. Ini adalah langkah untuk memastikan konsistensi dan pengalaman pengguna yang lebih baik di ekosistem Flutter.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Material+Design+3',
          publishedAt: now.subtract(const Duration(hours: 12)),
          views: 2341,
        ),
        NewsModel(
          id: 'news_5',
          title: 'Konferensi Flutter Indonesia 2025 Dibuka Pendaftaran',
          content:
              'Konferensi Flutter Indonesia 2025 kini membuka pendaftaran untuk pembicara dan peserta. Acara akan diadakan di Jakarta selama 3 hari dengan menghadirkan pembicara internasional dan lokal terkemuka.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Flutter+Indonesia',
          publishedAt: now.subtract(const Duration(hours: 15)),
          views: 1876,
        ),
        NewsModel(
          id: 'news_6',
          title: 'Integrasi Firebase dengan Riverpod Kini Lebih Mudah',
          content:
              'Library baru memudahkan integrasi Firebase dengan state management Riverpod. Fitur baru termasuk caching otomatis, error handling yang lebih baik, dan sinkronisasi real-time yang efisien.',
          authorId: 'system',
          authorName: 'Admin Portal',
          imageUrl:
              'https://via.placeholder.com/400x200?text=Riverpod+Firebase',
          publishedAt: now.subtract(const Duration(hours: 18)),
          views: 743,
        ),
      ];

      // Create all news documents
      for (final news in sampleNews) {
        await _firestore.collection('news').doc(news.id).set(news.toJson());
      }

      debugPrint('Sample news seeded successfully!');
    } catch (e) {
      debugPrint('Error seeding sample news: $e');
      rethrow;
    }
  }
}
