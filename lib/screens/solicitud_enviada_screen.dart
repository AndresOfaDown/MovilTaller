import 'package:flutter/material.dart';
import 'dart:async';

class SolicitudEnviadaScreen extends StatefulWidget {
  final String nombreTaller;
  final bool esTecnico;

  const SolicitudEnviadaScreen({
    Key? key,
    required this.nombreTaller,
    this.esTecnico = false,
  }) : super(key: key);

  @override
  State<SolicitudEnviadaScreen> createState() => _SolicitudEnviadaScreenState();
}

class _SolicitudEnviadaScreenState extends State<SolicitudEnviadaScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _fadeController;
  late Animation<double> _checkScale;
  late Animation<double> _fadeIn;
  Timer? _redirectTimer;
  int _countdown = 4;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start animations sequentially
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _fadeController.forward();
    });

    // Countdown + auto-redirect
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _navigateToServicios();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _navigateToServicios() {
    final tabIndex = widget.esTecnico ? 3 : 2;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: {'tabIndex': tabIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated check circle
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title and description
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    const Text(
                      '¡Solicitud Enviada!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1B1B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B6B6B),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Tu solicitud fue enviada con éxito a '),
                          TextSpan(
                            text: widget.nombreTaller,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF932D30),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Te notificaremos cuando el taller responda con una cotización.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Redirect info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF932D30).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: Color(0xFF932D30),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Redirigiendo a Servicios en $_countdown s',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF932D30),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _navigateToServicios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1B1B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ir a Mis Servicios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
