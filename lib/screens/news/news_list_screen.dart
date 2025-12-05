import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/news_card.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/news_model.dart';

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return const Scaffold();
    }
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: firestore.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return const Center(child: Text('Belum ada berita.'));
          }
          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return NewsCard(
                title: news.title,
                author: news.authorName,
                excerpt: news.content,
                imageUrl: news.imageUrl,
                publishedAt: news.publishedAt,
                views: news.views,
                onTap: () {
                  // Navigate to news detail (not implemented)
                },
              );
            },
          );
        },
      ),
    );
  }
}
