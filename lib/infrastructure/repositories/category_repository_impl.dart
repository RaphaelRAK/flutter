import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../db/daos/categories_dao.dart';
import '../mappers/category_mapper.dart';
import 'package:drift/drift.dart';

/// Implémentation du repository de catégories utilisant Drift
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Future<List<DomainCategory>> getAllCategories() async {
    final categories = await _dao.getAllCategories();
    return CategoryMapper.toDomainList(categories);
  }

  @override
  Stream<List<DomainCategory>> watchAllCategories() {
    return _dao.watchAllCategories().map(CategoryMapper.toDomainList);
  }

  @override
  Future<List<DomainCategory>> getCategoriesByType(String type) async {
    final categories = await _dao.getCategoriesByType(type);
    return CategoryMapper.toDomainList(categories);
  }

  @override
  Future<DomainCategory?> getCategoryById(int id) async {
    final category = await _dao.getCategoryById(id);
    return category != null ? CategoryMapper.toDomain(category) : null;
  }

  @override
  Future<int> insertCategory(DomainCategory category) async {
    final companion = CategoryMapper.toDrift(category);
    final companionWithoutId = CategoriesCompanion(
      name: companion.name,
      type: companion.type,
      color: companion.color,
      icon: companion.icon,
      isDefault: companion.isDefault,
    );
    return await _dao.insertCategory(companionWithoutId);
  }

  @override
  Future<bool> updateCategory(DomainCategory category) async {
    final companion = CategoryMapper.toDrift(category);
    return await _dao.updateCategory(companion);
  }

  @override
  Future<int> deleteCategory(int id) async {
    return await _dao.deleteCategory(id);
  }
}

