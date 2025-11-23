import '../models/category.dart';

/// Interface du repository pour les catégories
abstract class CategoryRepository {
  Future<List<DomainCategory>> getAllCategories();
  Stream<List<DomainCategory>> watchAllCategories();
  Future<List<DomainCategory>> getCategoriesByType(String type);
  Future<DomainCategory?> getCategoryById(int id);
  Future<int> insertCategory(DomainCategory category);
  Future<bool> updateCategory(DomainCategory category);
  Future<int> deleteCategory(int id);
}

