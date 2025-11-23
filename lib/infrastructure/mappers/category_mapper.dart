import '../../domain/models/category.dart';
import '../db/drift_database.dart';
import 'package:drift/drift.dart';

/// Mapper pour convertir entre les modèles Drift et Domain pour les catégories
class CategoryMapper {
  /// Convertit un Category (Drift) en DomainCategory
  static DomainCategory toDomain(Category drift) {
    return DomainCategory(
      id: drift.id,
      name: drift.name,
      type: drift.type,
      color: drift.color,
      icon: drift.icon,
      isDefault: drift.isDefault,
    );
  }

  /// Convertit une liste de Category (Drift) en liste de DomainCategory
  static List<DomainCategory> toDomainList(List<Category> driftList) {
    return driftList.map(toDomain).toList();
  }

  /// Convertit un DomainCategory en CategoriesCompanion (Drift)
  static CategoriesCompanion toDrift(DomainCategory domain) {
    return CategoriesCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      type: Value(domain.type),
      color: Value(domain.color),
      icon: Value(domain.icon),
      isDefault: Value(domain.isDefault),
    );
  }
}

