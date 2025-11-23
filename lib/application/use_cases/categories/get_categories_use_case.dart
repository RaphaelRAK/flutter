import '../../../domain/models/category.dart';
import '../../../domain/repositories/category_repository.dart';

/// Use case pour récupérer les catégories
class GetCategoriesUseCase {
  final CategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  /// Récupère toutes les catégories en stream
  Stream<List<DomainCategory>> call() {
    return _repository.watchAllCategories();
  }

  /// Récupère toutes les catégories (une fois)
  Future<List<DomainCategory>> getAll() {
    return _repository.getAllCategories();
  }

  /// Récupère les catégories par type
  Future<List<DomainCategory>> getByType(String type) {
    return _repository.getCategoriesByType(type);
  }

  /// Récupère une catégorie par ID
  Future<DomainCategory?> getById(int id) {
    return _repository.getCategoryById(id);
  }
}

