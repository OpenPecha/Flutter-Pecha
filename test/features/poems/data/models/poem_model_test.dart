import 'package:flutter_pecha/features/poems/data/models/poem_model.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoemModel.fromJson', () {
    test('maps all fields from the API contract', () {
      final model = PoemModel.fromJson({
        'id': 'poem-1',
        'title': 'Song of the mountains',
        'content': 'For all those ailing in the world...',
        'author_name': 'Milarepa',
        'chapter_name': 'Songs of realization',
        'image_url': 'https://cdn.example.com/poem.jpg?sig=abc',
        'status': 'PUBLISHED',
        'published_at': '2026-01-01T00:00:00Z',
        'created_at': '2025-12-01T00:00:00Z',
        'updated_at': '2025-12-15T00:00:00Z',
      });

      expect(model.id, 'poem-1');
      expect(model.title, 'Song of the mountains');
      expect(model.content, 'For all those ailing in the world...');
      expect(model.authorName, 'Milarepa');
      expect(model.chapterName, 'Songs of realization');
      expect(model.imageUrl, 'https://cdn.example.com/poem.jpg?sig=abc');
      expect(model.status, 'PUBLISHED');
      expect(model.publishedAt, DateTime.parse('2026-01-01T00:00:00Z'));
      expect(model.createdAt, DateTime.parse('2025-12-01T00:00:00Z'));
      expect(model.updatedAt, DateTime.parse('2025-12-15T00:00:00Z'));
    });

    test('tolerates missing optional fields', () {
      final model = PoemModel.fromJson({
        'id': 'poem-2',
        'title': 'Untitled',
        'content': 'Content',
        'author_name': 'Anonymous',
      });

      expect(model.chapterName, isNull);
      expect(model.imageUrl, isNull);
      expect(model.publishedAt, isNull);
      expect(model.status, isNull);
    });

    test('defaults missing required strings to empty', () {
      final model = PoemModel.fromJson(const {});

      expect(model.id, '');
      expect(model.title, '');
      expect(model.content, '');
      expect(model.authorName, '');
    });
  });

  group('PoemModel.toEntity', () {
    test('maps PUBLISHED status', () {
      final model = PoemModel.fromJson({
        'id': 'poem-1',
        'title': 'T',
        'content': 'C',
        'author_name': 'A',
        'status': 'PUBLISHED',
      });

      expect(model.toEntity().status, PoemStatus.published);
    });

    test('maps unknown/missing status to draft', () {
      final model = PoemModel.fromJson({
        'id': 'poem-1',
        'title': 'T',
        'content': 'C',
        'author_name': 'A',
        'status': 'DRAFT',
      });

      expect(model.toEntity().status, PoemStatus.draft);

      final missing = PoemModel.fromJson({
        'id': 'poem-2',
        'title': 'T',
        'content': 'C',
        'author_name': 'A',
      });
      expect(missing.toEntity().status, PoemStatus.draft);
    });
  });
}
