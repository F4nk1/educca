import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'widgets/andean_widgets.dart';
import 'widgets/privacy_consent_dialog.dart';
import 'widgets/server_config_dialog.dart';

/// Pantalla de inicio de sesión M01 (Acceso · Tema Andino EDUCCA Cusco)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<AppConfig>();
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isCompact = screenHeight < 720;

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: Column(
        children: [
          // 1. Encabezado paisajístico andino
          AndeanHeader(
            title: 'EDUCCA Cusco',
            isCompact: isCompact,
            trailing: IconButton(
              icon: const Icon(Icons.settings_ethernet, color: Colors.white, size: 20),
              tooltip: 'Configurar servidor / Modo Demo',
              onPressed: () => ServerConfigDialog.show(context, config),
            ),
          ),

          // 2. Banner de Modo Demostración si está activo
          if (config.isDemoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              color: Colors.amber.shade800,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'MODO DEMOSTRACIÓN — DATOS SIMULADOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Contenido desplazable del formulario
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isCompact ? 10 : 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tag de identidad institucional municipal con guion terracota
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 2,
                              color: AndeanColors.terracotta,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'IDENTIDAD INSTITUCIONAL MUNICIPAL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.terracotta,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 8 : 12),

                        // Saludos principales en Playfair Display
                        Text(
                          'Allin hamuy,',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isCompact ? 26 : 31,
                            fontWeight: FontWeight.bold,
                            color: AndeanColors.deep,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'bienvenido',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isCompact ? 26 : 31,
                            fontStyle: FontStyle.italic,
                            color: AndeanColors.forest,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),

                        // Subtítulo del promotor ambiental
                        Text(
                          'Portal del Promotor Ambiental',
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 12.5 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: AndeanColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Accede con tu correo y contraseña para continuar.',
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 12 : 13,
                            color: AndeanColors.muted,
                          ),
                        ),
                        SizedBox(height: isCompact ? 14 : 22),

                        // Selector de acceso tipo pestaña (Ingresar seleccionado)
                        AndeanAccessSelector(
                          currentMode: AccessMode.login,
                          isCompact: isCompact,
                          onRegisterTap: auth.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => const RegisterScreen(),
                                    ),
                                  );
                                },
                        ),
                        SizedBox(height: isCompact ? 14 : 22),

                        // Formulario de credenciales
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Etiqueta e Input: Correo electrónico
                              Text(
                                'Correo electrónico',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('emailField'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'nombre@correo.com',
                                  prefixIcon: SvgPicture.asset(
                                    'assets/images/icono_correo.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Formato de correo no válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 12 : 16),

                              // Etiqueta, enlace '¿La olvidaste?' e Input: Contraseña
                              Row(
                                children: [
                                  Text(
                                    'Contraseña',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AndeanColors.ink,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Para recuperar tu contraseña, comunícate con la coordinación de EDUCCA Cusco.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '¿La olvidaste?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AndeanColors.forest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('passwordField'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Tu contraseña',
                                  prefixIcon: SvgPicture.asset(
                                    'assets/images/icono_clave.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: SvgPicture.asset(
                                      'assets/images/icono_ver_clave.svg',
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                        _obscurePassword
                                            ? AndeanColors.muted
                                            : AndeanColors.brand,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 18 : 24),

                              // Botón de acción principal 'Ingresar'
                              SizedBox(
                                width: double.infinity,
                                height: isCompact ? 48 : 52,
                                child: ElevatedButton(
                                  key: const Key('loginButton'),
                                  onPressed: auth.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AndeanColors.brand,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Ingresar',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: isCompact ? 10 : 12),

                              // Botón secundario para acceso directo a Datos Simulados
                              SizedBox(
                                width: double.infinity,
                                height: isCompact ? 44 : 48,
                                child: OutlinedButton.icon(
                                  key: const Key('demoModeQuickButton'),
                                  icon: const Icon(Icons.science_outlined, size: 18, color: AndeanColors.forest),
                                  label: Text(
                                    config.isDemoMode
                                        ? 'Ingresar con Datos Simulados'
                                        : 'Modo Demostración (Datos Simulados)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AndeanColors.forest,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AndeanColors.forest, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: auth.isLoading
                                      ? null
                                      : () async {
                                          if (!config.isDemoMode) {
                                            await config.setDemoMode(true);
                                          }
                                          _emailController.text = 'sayri.promotor@educca.gob.pe';
                                          _passwordController.text = 'demo1234';
                                          _submit();
                                        },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 18 : 26),

                        // Separador y pie de privacidad
                        const Divider(
                          color: AndeanColors.line,
                          thickness: 1,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => PrivacyConsentDialog.show(context),
                                child: Text(
                                  'Privacidad y protección de datos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AndeanColors.forest,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cusco, Perú',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AndeanColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Servidor: ${config.baseUrl}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF8C9B93),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
