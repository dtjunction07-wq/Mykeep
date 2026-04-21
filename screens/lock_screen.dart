import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockMode { setup, verify, change }

class LockScreen extends StatefulWidget {
  final LockMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const LockScreen({
    Key? key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  String _oldPin = '';
  bool _isConfirming = false;
  bool _isEnteringOld = false;
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    if (widget.mode == LockMode.change) {
      _isEnteringOld = true;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == LockMode.setup) {
      return _isConfirming ? 'Confirm PIN' : 'Set PIN';
    } else if (widget.mode == LockMode.change) {
      if (_isEnteringOld) return 'Enter Current PIN';
      return _isConfirming ? 'Confirm New PIN' : 'Enter New PIN';
    }
    return 'Enter PIN';
  }

  String get _currentInput {
    if (widget.mode == LockMode.change && _isEnteringOld) return _oldPin;
    if (_isConfirming) return _confirmPin;
    return _pin;
  }

  void _addDigit(String digit) {
    setState(() {
      _errorMessage = '';
      if (widget.mode == LockMode.change && _isEnteringOld) {
        if (_oldPin.length < 4) _oldPin += digit;
        if (_oldPin.length == 4) _verifyOldPin();
      } else if (_isConfirming) {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _verifyConfirm();
      } else {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) _onPinComplete();
      }
    });
  }

  void _removeDigit() {
    setState(() {
      _errorMessage = '';
      if (widget.mode == LockMode.change && _isEnteringOld) {
        if (_oldPin.isNotEmpty) _oldPin = _oldPin.substring(0, _oldPin.length - 1);
      } else if (_isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verifyOldPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('lock_pin') ?? '';
    await Future.delayed(const Duration(milliseconds: 150));
    if (_oldPin == savedPin) {
      setState(() {
        _isEnteringOld = false;
        _oldPin = '';
      });
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _oldPin = '';
        _errorMessage = 'Incorrect PIN';
      });
    }
  }

  void _onPinComplete() {
    if (widget.mode == LockMode.setup || widget.mode == LockMode.change) {
      setState(() => _isConfirming = true);
    } else {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('lock_pin') ?? '';
    await Future.delayed(const Duration(milliseconds: 150));
    if (_pin == savedPin) {
      widget.onSuccess();
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _errorMessage = 'Incorrect PIN';
      });
    }
  }

  Future<void> _verifyConfirm() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_pin == _confirmPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lock_pin', _pin);
      widget.onSuccess();
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
        _errorMessage = 'PINs do not match. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF9E6);
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final dotActive = const Color(0xFFFFD700);
    final dotInactive = isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  if (widget.onCancel != null)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                      onPressed: widget.onCancel,
                    ),
                ],
              ),
            ),
            const Spacer(),
            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: dotActive.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, color: dotActive, size: 36),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              _title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 32),
            // PIN dots with shake
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value * (_shakeController.value < 0.5 ? 1 : -1), 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _currentInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: filled ? 18 : 14,
                    height: filled ? 18 : 14,
                    decoration: BoxDecoration(
                      color: filled ? dotActive : dotInactive,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Error message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _errorMessage.isNotEmpty
                  ? Text(
                      _errorMessage,
                      key: ValueKey(_errorMessage),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    )
                  : const SizedBox(height: 18),
            ),
            const Spacer(),
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3'], textColor),
                  const SizedBox(height: 16),
                  _buildRow(['4', '5', '6'], textColor),
                  const SizedBox(height: 16),
                  _buildRow(['7', '8', '9'], textColor),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEmptyKey(),
                      _buildKey('0', textColor),
                      _buildBackspace(textColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(d, textColor)).toList(),
    );
  }

  Widget _buildKey(String digit, Color textColor) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2C)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: textColor,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace(Color textColor) {
    return GestureDetector(
      onTap: _removeDigit,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(Icons.backspace_outlined, color: textColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyKey() {
    return const SizedBox(width: 72, height: 72);
  }
}
