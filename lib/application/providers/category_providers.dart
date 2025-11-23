import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../use_cases/categories/get_categories_use_case.dart';
import '../../domain/models/category.dart';
import 'repository_providers.dart';

/// Providers pour les use cases de catégories
final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return GetCategoriesUseCase(repository);
});

/// Provider pour le stream de toutes les catégories
final categoriesStreamProvider = StreamProvider<List<DomainCategory>>((ref) {
  final useCase = ref.watch(getCategoriesUseCaseProvider);
  return useCase();
});

