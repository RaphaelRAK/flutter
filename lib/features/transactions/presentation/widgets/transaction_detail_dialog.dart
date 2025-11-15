import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionDetailDialog extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter l'édition
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter la suppression
                      Navigator.of(context).pop();
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
}

