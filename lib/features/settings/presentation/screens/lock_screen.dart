import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/lock_helper.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlock;
  
  const LockScreen({super.key, this.onUnlock});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final local_auth.LocalAuthentication _localAuth = local_auth.LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _enteredPin = '';
  String _enteredPassword = '';
  bool _isAuthenticating = false;
  String? _errorMessage;
  LockType _lockType = LockType.none;
  bool _obscurePassword = true;
  bool _hasUnlocked = false; // Flag pour éviter les tentatives multiples

  @override
  void initState() {
    super.initState();
    _loadLockType();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLockType() async {
    final lockType = await LockHelper.getLockType();
    setState(() {
      _lockType = lockType;
    });

    if (lockType == LockType.biometric) {
      _checkBiometric();
    }
  }

  Future<void> _checkBiometric() async {
    // Ne pas déclencher si déjà déverrouillé ou en train d'authentifier
    if (_hasUnlocked || _isAuthenticating) return;
    
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (isAvailable && availableBiometrics.isNotEmpty && !_hasUnlocked) {
        // Essayer l'authentification biométrique automatiquement
        await _authenticateWithBiometric();
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _authenticateWithBiometric() async {
    // Éviter les tentatives multiples si déjà déverrouillé
    if (_hasUnlocked) return;
    
    try {
      setState(() {
        _isAuthenticating = true;
        _errorMessage = null;
      });

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Vérifiez votre identité pour accéder à l\'application',
        options: const local_auth.AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated && mounted && !_hasUnlocked) {
        // Authentification réussie
        setState(() {
          _isAuthenticating = false;
          _hasUnlocked = true; // Marquer comme déverrouillé
        });
        // Appeler le callback immédiatement
        widget.onUnlock?.call();
      } else {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Erreur d\'authentification biométrique';
      });
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onPinDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_hasUnlocked) return; // Éviter les tentatives multiples
    
    final isValid = await LockHelper.verifyLockValue(_enteredPin);
    if (isValid && mounted && !_hasUnlocked) {
      setState(() {
        _hasUnlocked = true; // Marquer comme déverrouillé
      });
      // Appeler le callback immédiatement
      widget.onUnlock?.call();
    } else {
      setState(() {
        _errorMessage = 'Code incorrect';
        _enteredPin = '';
      });
    }
  }

  Future<void> _verifyPassword() async {
    if (_hasUnlocked) return; // Éviter les tentatives multiples
    
    final isValid = await LockHelper.verifyLockValue(_enteredPassword);
    if (isValid && mounted && !_hasUnlocked) {
      setState(() {
        _hasUnlocked = true; // Marquer comme déverrouillé
      });
      // Appeler le callback immédiatement
      widget.onUnlock?.call();
    } else {
      setState(() {
        _errorMessage = 'Mot de passe incorrect';
        _enteredPassword = '';
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Empêcher de revenir en arrière
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Icône de verrouillage
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: AppColors.darkTextSecondary,
                  ),
                  const SizedBox(height: 24),
                  
                  // Titre
                  Text(
                    'Application verrouillée',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Sous-titre
                  Text(
                    'Vérifiez votre identité pour continuer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Indicateurs de PIN (seulement pour PIN)
                  if (_lockType == LockType.pin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
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
                            color: index < _enteredPin.length
                                ? AppColors.accentSecondary
                                : Colors.transparent,
                          ),
                        );
                      }),
                    ),
                  
                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Afficher selon le type de verrouillage
                  if (_lockType == LockType.biometric) ...[
                    // Bouton biométrique uniquement
                    FutureBuilder<bool>(
                      future: _localAuth.canCheckBiometrics,
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fingerprint, size: 48),
                                onPressed: _isAuthenticating
                                    ? null
                                    : _authenticateWithBiometric,
                                color: AppColors.accentSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Utiliser la biométrie',
                                style: TextStyle(
                                  color: AppColors.accentSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ] else if (_lockType == LockType.pin) ...[
                    // Clavier PIN
                    _buildPinKeyboard(),
                    // Option biométrique si disponible
                    FutureBuilder<bool>(
                      future: _localAuth.canCheckBiometrics,
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: _isAuthenticating
                                    ? null
                                    : _authenticateWithBiometric,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Utiliser la biométrie'),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ] else if (_lockType == LockType.password) ...[
                    // Champ de mot de passe
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
                      onChanged: (value) {
                        setState(() {
                          _enteredPassword = value;
                          _errorMessage = null;
                        });
                      },
                      onSubmitted: (_) => _verifyPassword(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _enteredPassword.isNotEmpty ? _verifyPassword : null,
                      child: const Text('Déverrouiller'),
                    ),
                    // Option biométrique si disponible
                    FutureBuilder<bool>(
                      future: _localAuth.canCheckBiometrics,
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _isAuthenticating
                                    ? null
                                    : _authenticateWithBiometric,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Utiliser la biométrie'),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
            const SizedBox(width: 80), // Espace pour centrer
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

