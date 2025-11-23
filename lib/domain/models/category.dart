/// Modèle de domaine pour une catégorie
class DomainCategory {
  final int id;
  final String name;
  final String type; // 'expense' ou 'income'
  final String color; // code couleur hexadécimal
  final String icon; // identifiant d'icône
  final bool isDefault;

  DomainCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.isDefault,
  });

  DomainCategory copyWith({
    int? id,
    String? name,
    String? type,
    String? color,
    String? icon,
    bool? isDefault,
  }) {
    return DomainCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

