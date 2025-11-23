import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../use_cases/accounts/get_accounts_use_case.dart';
import '../use_cases/accounts/add_account_use_case.dart';
import '../use_cases/accounts/update_account_use_case.dart';
import '../use_cases/accounts/delete_account_use_case.dart';
import '../use_cases/accounts/calculate_net_worth_use_case.dart';
import '../../domain/models/account.dart';
import 'repository_providers.dart';

/// Providers pour les use cases de comptes
final getAccountsUseCaseProvider = Provider<GetAccountsUseCase>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return GetAccountsUseCase(repository);
});

final addAccountUseCaseProvider = Provider<AddAccountUseCase>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AddAccountUseCase(repository);
});

final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return UpdateAccountUseCase(repository);
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return DeleteAccountUseCase(repository);
});

final calculateNetWorthUseCaseProvider = Provider<CalculateNetWorthUseCase>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return CalculateNetWorthUseCase(repository);
});

/// Provider pour le stream de tous les comptes
final accountsStreamProvider = StreamProvider<List<DomainAccount>>((ref) {
  final useCase = ref.watch(getAccountsUseCaseProvider);
  return useCase();
});

/// Provider pour les comptes par catégorie
final assetAccountsStreamProvider = StreamProvider<List<DomainAccount>>((ref) {
  final useCase = ref.watch(getAccountsUseCaseProvider);
  return useCase.getByCategory('asset');
});

final liabilityAccountsStreamProvider = StreamProvider<List<DomainAccount>>((ref) {
  final useCase = ref.watch(getAccountsUseCaseProvider);
  return useCase.getByCategory('liability');
});

/// Providers pour les totaux
final totalAssetsProvider = FutureProvider<double>((ref) {
  final useCase = ref.watch(calculateNetWorthUseCaseProvider);
  return useCase.getTotalAssets();
});

final totalLiabilitiesProvider = FutureProvider<double>((ref) {
  final useCase = ref.watch(calculateNetWorthUseCaseProvider);
  return useCase.getTotalLiabilities();
});

final netWorthProvider = FutureProvider<double>((ref) {
  final useCase = ref.watch(calculateNetWorthUseCaseProvider);
  return useCase();
});

