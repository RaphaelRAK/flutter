import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../../core/utils/helpers/lock_helper.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/navigation/main_bottom_nav_bar.dart';

class LockSetupScreen extends ConsumerStatefulWidget {
  const LockSetupScreen({super.key});

  @override
  ConsumerState<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends ConsumerState<LockSetupScreen> {
  final local_auth.LocalAuthentication _localAuth = local_auth.LocalAuthentication();
  LockType? _selectedType;
  bool _isCheckingBiometric = false;
  bool _biometricAvailable = false;
  List<local_auth.BiometricType> _availableBiometrics = [];

  // Pour la configuration du PIN
  String _pinStep = 'enter'; // 'enter' ou 'confirm'
  String _enteredPin = '';
  String _confirmPin = '';

  // Pour la configuration du mot de passe
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadCurrentLockType();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _isCheckingBiometric = true;
    });

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (isAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        setState(() {
          _biometricAvailable = true;
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      // Ignorer les erreurs
    } finally {
      setState(() {
        _isCheckingBiometric = false;
      });
    }
  }

  Future<void> _loadCurrentLockType() async {
    final currentType = await LockHelper.getLockType();
    setState(() {
      _selectedType = currentType;
    });
  }

  String _getBiometricName() {
    if (_availableBiometrics.contains(local_auth.BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(local_auth.BiometricType.fingerprint)) {
      return 'Empreinte digitale';
    } else if (_availableBiometrics.contains(local_auth.BiometricType.strong)) {
      return 'Biométrie';
    }
    return 'Biométrie';
  }

  Future<void> _setupBiometric() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Configurez la biométrie pour sécuriser votre application',
        options: const local_auth.AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await LockHelper.setLockType(LockType.biometric);
        await ref.read(settingsDaoProvider).updateSettings(
          SettingsCompanion(
            id: Value(1),
            biometricLockEnabled: Value(true),
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verrouillage biométrique activé')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_pinStep == 'enter') {
      if (_enteredPin.length < 4) {
        setState(() {
          _enteredPin += digit;
        });

        if (_enteredPin.length == 4) {
          setState(() {
            _pinStep = 'confirm';
          });
        }
      }
    } else if (_pinStep == 'confirm') {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
        });

        if (_confirmPin.length == 4) {
          _confirmPinSetup();
        }
      }
    }
  }

  void _onPinDelete() {
    if (_pinStep == 'confirm' && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      });
    } else if (_pinStep == 'enter' && _enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _confirmPinSetup() async {
    if (_enteredPin == _confirmPin) {
      await LockHelper.setLockHash(_enteredPin);
      await LockHelper.setLockType(LockType.pin);
      await ref.read(settingsDaoProvider).updateSettings(
        SettingsCompanion(
          id: Value(1),
          biometricLockEnabled: Value(true),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code PIN configuré')),
        );
        context.pop();
      }
    } else {
      setState(() {
        _enteredPin = '';
        _confirmPin = '';
        _pinStep = 'enter';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les codes ne correspondent pas')),
        );
      }
    }
  }

  Future<void> _setupPassword() async {
    if (_passwordController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 4 caractères')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    await LockHelper.setLockHash(_passwordController.text);
    await LockHelper.setLockType(LockType.password);
    await ref.read(settingsDaoProvider).updateSettings(
      SettingsCompanion(
        id: Value(1),
        biometricLockEnabled: Value(true),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe configuré')),
      );
      context.pop();
    }
  }

  Future<void> _disableLock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le verrouillage'),
        content: const Text('Êtes-vous sûr de vouloir désactiver le verrouillage ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Désactiver', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LockHelper.clearLock();
      await ref.read(settingsDaoProvider).updateSettings(
        SettingsCompanion(
          id: Value(1),
          biometricLockEnabled: Value(false),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verrouillage désactivé')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du verrouillage'),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Options de verrouillage
          if (_selectedType == null || _selectedType == LockType.none) ...[
            _buildOptionCard(
              icon: Icons.pin,
              title: 'Code PIN',
              subtitle: 'Utilisez un code à 4 chiffres',
              onTap: () => setState(() => _selectedType = LockType.pin),
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              icon: Icons.lock,
              title: 'Mot de passe',
              subtitle: 'Utilisez un mot de passe personnalisé',
              onTap: () => setState(() => _selectedType = LockType.password),
            ),
            const SizedBox(height: 12),
            if (_biometricAvailable)
              _buildOptionCard(
                icon: Icons.fingerprint,
                title: _getBiometricName(),
                subtitle: 'Utilisez la biométrie de votre appareil',
                onTap: _setupBiometric,
              ),
          ] else ...[
            // Configuration du PIN
            if (_selectedType == LockType.pin) _buildPinSetup(),
            // Configuration du mot de passe
            if (_selectedType == LockType.password) _buildPasswordSetup(),
            // Désactiver
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.red),
                title: const Text('Désactiver le verrouillage'),
                subtitle: const Text('Supprimer la protection'),
                onTap: _disableLock,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPinSetup() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _pinStep == 'enter' ? 'Entrez votre code PIN' : 'Confirmez votre code PIN',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                // Indicateurs de PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final currentPin = _pinStep == 'enter' ? _enteredPin : _confirmPin;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkTextSecondary,
                          width: 2,
                        ),
                        color: index < currentPin.length
                            ? AppColors.accentSecondary
                            : Colors.transparent,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Clavier PIN
                _buildPinKeyboard(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = null;
              _enteredPin = '';
              _confirmPin = '';
              _pinStep = 'enter';
            });
          },
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _buildPasswordSetup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _setupPassword,
              child: const Text('Configurer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinKeyboard() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPinButton('1'),
            const SizedBox(width: 16),
            _buildPinButton('2'),
            const SizedBox(width: 16),
            _buildPinButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPinButton('4'),
            const SizedBox(width: 16),
            _buildPinButton('5'),
            const SizedBox(width: 16),
            _buildPinButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPinButton('7'),
            const SizedBox(width: 16),
            _buildPinButton('8'),
            const SizedBox(width: 16),
            _buildPinButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            _buildPinButton('0'),
            const SizedBox(width: 16),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildPinButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPinDigitPressed(digit),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.darkTextSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPinDelete,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.darkTextSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }
}

