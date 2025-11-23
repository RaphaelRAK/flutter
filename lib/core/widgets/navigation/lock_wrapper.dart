import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../infrastructure/db/database_provider.dart';
import '../../../features/settings/presentation/screens/lock_screen.dart';
import '../../utils/helpers/lock_helper.dart';
import '../../theme/app_theme.dart';

class LockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const LockWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends ConsumerState<LockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isChecking = true;
  DateTime? _lastBackgroundTime;
  final Key _lockKey = UniqueKey();
  bool _justUnlocked = false; // Flag pour éviter le reverrouillage immédiat

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'app passe en arrière-plan, enregistrer le temps
      _lastBackgroundTime = DateTime.now();
      // Réinitialiser le flag de déverrouillage
      _justUnlocked = false;
    } else if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan, vérifier le verrouillage
      // Mais ne pas reverrouiller si on vient juste de déverrouiller
      if (!_justUnlocked) {
        _checkLockOnResume();
      }
    }
  }

  Future<void> _checkLockStatus() async {
    try {
      final isLockEnabled = await LockHelper.isLockEnabled();
      setState(() {
        _isLocked = isLockEnabled;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _checkLockOnResume() async {
    try {
      final isLockEnabled = await LockHelper.isLockEnabled();
      if (isLockEnabled && mounted) {
        // Vérifier si l'app était en arrière-plan depuis plus de quelques secondes
        // Pour l'instant, on verrouille toujours au retour au premier plan
        setState(() {
          _isLocked = true;
        });
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  void _onUnlock() {
    if (mounted) {
      setState(() {
        _isLocked = false;
        _justUnlocked = true; // Marquer qu'on vient de déverrouiller
      });
      // Réinitialiser le flag après 2 secondes pour permettre le verrouillage futur
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _justUnlocked = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Si verrouillé, afficher l'écran de verrouillage
    if (_isLocked) {
      return MaterialApp(
        key: _lockKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: LockScreen(onUnlock: _onUnlock),
      );
    }

    // Sinon, afficher l'application normale
    return widget.child;
  }
}

