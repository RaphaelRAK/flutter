enum AccountType {
  bank('bank', 'Banque'),
  cash('cash', 'Espèces'),
  wallet('wallet', 'Portefeuille');

  final String value;
  final String label;

  const AccountType(this.value, this.label);
}

