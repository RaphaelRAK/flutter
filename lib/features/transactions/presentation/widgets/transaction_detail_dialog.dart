import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionDetailDialog extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';

    Color amountColor;
    IconData iconData;
    String prefix = '';

    if (isExpense) {
      amountColor = AppColors.expense;
      iconData = Icons.arrow_downward;
      prefix = '-';
    } else if (isIncome) {
      amountColor = AppColors.income;
      iconData = Icons.arrow_upward;
      prefix = '+';
    } else {
      amountColor = AppColors.transfer;
      iconData = Icons.swap_horiz;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails de la transaction',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Montant
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: amountColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$prefix${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.type == 'expense'
                          ? 'Dépense'
                          : transaction.type == 'income'
                              ? 'Revenu'
                              : 'Transfert',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Informations
            _buildDetailRow(
              'Date',
              DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
                  .format(transaction.date),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Description',
              transaction.description ?? 'Aucune description',
              Icons.description,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Compte ID',
              transaction.accountId.toString(),
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Catégorie ID',
              transaction.categoryId.toString(),
              Icons.category,
            ),
            const SizedBox(height: 12),
            // Images
            if (transaction.images != null && transaction.images!.isNotEmpty)
              _buildImagesSection(context, transaction.images!),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Naviguer vers l'écran d'édition
                      context.push('/edit-transaction', extra: transaction);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Demander confirmation
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer la transaction'),
                          content: const Text(
                            'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final transactionsDao = ref.read(transactionsDaoProvider);
                          await transactionsDao.deleteTransaction(transaction.id);
                          
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Fermer le dialogue de détails
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction supprimée avec succès'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de la suppression: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.darkTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(BuildContext context, String imagesString) {
    final imagePaths = imagesString.split(',').where((path) => path.trim().isNotEmpty).toList();
    
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 20, color: AppColors.darkTextSecondary),
            const SizedBox(width: 12),
            Text(
              'Photos / Reçus',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final imagePath = imagePaths[index].trim();
              final file = File(imagePath);
              
              return GestureDetector(
                onTap: () {
                  // Afficher l'image en plein écran
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              child: Image.file(
                                file,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkTextSecondary.withOpacity(0.2)),
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

