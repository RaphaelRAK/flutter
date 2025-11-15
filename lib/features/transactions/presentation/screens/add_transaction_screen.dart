import 'package:flutter/material.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle opération'),
      ),
      body: const Center(
        child: Text('Formulaire d\'ajout de transaction (à implémenter)'),
      ),
    );
  }
}

