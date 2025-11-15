import 'package:flutter/material.dart';

class CategoryIcons {
  // Mapping des noms de catégories vers des icônes Material
  static IconData getCategoryIcon(String categoryName, String? iconFromDb) {
    // Si on a une icône depuis la DB, on l'utilise
    if (iconFromDb != null && iconFromDb.isNotEmpty) {
      return _getIconFromString(iconFromDb);
    }

    final name = categoryName.toLowerCase();
    
    // Mapping des catégories par défaut
    if (name.contains('logement') || name.contains('maison') || name.contains('home')) {
      return Icons.home;
    } else if (name.contains('courses') || name.contains('shopping') || name.contains('achat')) {
      return Icons.shopping_cart;
    } else if (name.contains('restaurant') || name.contains('food') || name.contains('nourriture')) {
      return Icons.restaurant;
    } else if (name.contains('transport') || name.contains('voiture') || name.contains('car')) {
      return Icons.directions_car;
    } else if (name.contains('loisir') || name.contains('divertissement') || name.contains('entertainment')) {
      return Icons.sports_esports;
    } else if (name.contains('santé') || name.contains('health') || name.contains('médical')) {
      return Icons.local_hospital;
    } else if (name.contains('éducation') || name.contains('education') || name.contains('école')) {
      return Icons.school;
    } else if (name.contains('salaire') || name.contains('salary') || name.contains('travail')) {
      return Icons.work;
    } else if (name.contains('freelance') || name.contains('indépendant')) {
      return Icons.laptop;
    } else if (name.contains('investissement') || name.contains('investment')) {
      return Icons.trending_up;
    }
    
    return Icons.category;
  }

  // Mapping des services connus vers des icônes/logos
  static Widget? getServiceIcon(String? description) {
    if (description == null || description.isEmpty) return null;
    
    final desc = description.toUpperCase();
    
    // Services de streaming
    if (desc.contains('NETFLIX')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'N',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    } else if (desc.contains('SPOTIFY')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '♪',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      );
    } else if (desc.contains('DISNEY') || desc.contains('DISNEY+')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'D+',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else if (desc.contains('AMAZON PRIME') || desc.contains('PRIME VIDEO')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    } else if (desc.contains('APPLE') && (desc.contains('MUSIC') || desc.contains('TV'))) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.apple, color: Colors.white, size: 24),
        ),
      );
    } else if (desc.contains('YOUTUBE') || desc.contains('YOUTUBE PREMIUM')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_filled, color: Colors.white, size: 24),
        ),
      );
    } else if (desc.contains('UBER') || desc.contains('UBER EATS')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    } else if (desc.contains('DELIVEROO')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'D',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    } else if (desc.contains('MCDONALD') || desc.contains('MC DO')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'M',
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    } else if (desc.contains('STARBUCKS')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    }
    
    return null;
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}

