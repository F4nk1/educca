import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/promoter_user.dart';
import '../providers/auth_provider.dart';
import 'widgets/andean_widgets.dart';
import 'widgets/privacy_consent_dialog.dart';

/// Pantalla de registro M02 (Crear cuenta · Tema Andino EDUCCA Cusco)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController(text: '2000-01-01');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedSexo = 'M';
  PromoterCategory _selectedCategory = PromoterCategory.juvenil;
  bool _isAdultConfirmed = true;
  bool _privacyConsentAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isMinorEscolarBlocked {
    return _selectedCategory == PromoterCategory.escolar && !_isAdultConfirmed;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final adultMax = DateTime(now.year - 18, now.month, now.day);
    DateTime initial = DateTime(2000, 1, 1);
    if (_birthDateController.text.isNotEmpty) {
      try {
        final parsed = DateTime.parse(_birthDateController.text);
        if (parsed.isBefore(adultMax)) {
          initial = parsed;
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'FECHA DE NACIMIENTO (LPDP >= 18 AÑOS)',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AndeanColors.brand,
              onPrimary: Colors.white,
              onSurface: AndeanColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _birthDateController.text = formatted;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isMinorEscolarBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El registro de escolares menores de edad debe gestionarse a través de su institución educativa.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_privacyConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar el aviso de privacidad y consentimiento para continuar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final nombresInput = _nameController.text.trim();
    final apellidosInput = _lastNameController.text.trim();

    String nom = nombresInput;
    String ape = apellidosInput;
    if (ape.isEmpty) {
      final parts = nom.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        nom = parts[0];
        ape = parts.sublist(1).join(' ');
      } else {
        ape = nom;
      }
    }
    final fullName = ape.isNotEmpty && ape != nom ? '$nom $ape' : nom;

    final success = await auth.registerPromoter(
      fullName: fullName,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      promoterCategory: _selectedCategory.backendCode,
      isAdult: _selectedCategory == PromoterCategory.escolar ? _isAdultConfirmed : true,
      privacyConsentAccepted: _privacyConsentAccepted,
      dni: _dniController.text.trim(),
      nombres: nom,
      apellidos: ape,
      sexo: _selectedSexo,
      fechaNacimiento: _birthDateController.text.trim(),
      telefono: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta de promotor creada con éxito! Ahora puedes iniciar sesión.'),
          backgroundColor: AndeanColors.brand,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (auth.errorMessage != null) {
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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isCompact = screenHeight < 740;

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: Column(
        children: [
          // 1. Encabezado paisajístico andino
          AndeanHeader(
            title: 'EDUCCA Cusco',
            isCompact: isCompact,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              tooltip: 'Volver a iniciar sesión',
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: SvgPicture.asset(
              'assets/images/motivo_geometrico.svg',
              width: isCompact ? 18 : 22,
              height: isCompact ? 18 : 22,
            ),
          ),

          // 2. Formulario desplazable
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
                        // Tag de registro de promotor con guion terracota
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
                                'REGISTRO DE PROMOTOR',
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
                        SizedBox(height: isCompact ? 6 : 10),

                        // Títulos principales en Playfair Display
                        Text(
                          'Únete a la red',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isCompact ? 25 : 30,
                            fontWeight: FontWeight.bold,
                            color: AndeanColors.deep,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'EDUCCA',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isCompact ? 26 : 31,
                            fontStyle: FontStyle.italic,
                            color: AndeanColors.forest,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 6),

                        // Subtítulo oficial para tests y promotores
                        Text(
                          'Registro de Promotor EDUCCA',
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 12.5 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: AndeanColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Crea tu cuenta para participar en las actividades ambientales.',
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 11.5 : 12.5,
                            color: AndeanColors.muted,
                          ),
                        ),
                        SizedBox(height: isCompact ? 12 : 18),

                        // Selector de acceso (Crear cuenta seleccionado)
                        AndeanAccessSelector(
                          currentMode: AccessMode.register,
                          isCompact: isCompact,
                          onLoginTap: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(height: isCompact ? 14 : 20),

                        // Formulario de datos
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Campo 1: Documento de Identidad (DNI / CE)
                              Text(
                                'Documento de Identidad (DNI / CE)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('dniField'),
                                controller: _dniController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: '8 dígitos (DNI) o Carné Extranjería',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    size: 20,
                                    color: AndeanColors.forest,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tu DNI o documento';
                                  }
                                  final trimmed = value.trim();
                                  if (trimmed.length < 8 || trimmed.length > 15) {
                                    return 'Debe tener entre 8 y 15 caracteres';
                                  }
                                  if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(trimmed)) {
                                    return 'Solo números o letras sin espacios';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 2: Nombres
                              Text(
                                'Nombres',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('nameField'),
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Tus nombres',
                                  prefixIcon: SvgPicture.asset(
                                    'assets/images/icono_nombre.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tus nombres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 3: Apellidos
                              Text(
                                'Apellidos',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('lastNameField'),
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Tus apellidos',
                                  prefixIcon: SvgPicture.asset(
                                    'assets/images/icono_nombre.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if ((value == null || value.trim().isEmpty) &&
                                      !_nameController.text.trim().contains(' ')) {
                                    return 'Ingresa tus apellidos';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 4: Sexo
                              Text(
                                'Sexo',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildSexoSelector(),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 5: Fecha de Nacimiento
                              Text(
                                'Fecha de Nacimiento',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('birthDateField'),
                                controller: _birthDateController,
                                readOnly: true,
                                onTap: _selectBirthDate,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'AAAA-MM-DD (Mayor de 18 años)',
                                  prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: AndeanColors.forest,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.edit_calendar_outlined,
                                      size: 20,
                                      color: AndeanColors.forest,
                                    ),
                                    onPressed: _selectBirthDate,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Selecciona tu fecha de nacimiento';
                                  }
                                  try {
                                    final date = DateTime.parse(value.trim());
                                    final now = DateTime.now();
                                    int age = now.year - date.year;
                                    if (now.month < date.month ||
                                        (now.month == date.month && now.day < date.day)) {
                                      age--;
                                    }
                                    if (age < 18) {
                                      return 'Debes tener al menos 18 años (LPDP)';
                                    }
                                  } catch (_) {
                                    return 'Formato de fecha no válido (AAAA-MM-DD)';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 6: Teléfono / Celular (Opcional)
                              Text(
                                'Teléfono / Celular (Opcional)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('phoneField'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Ej. 984123456',
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                    color: AndeanColors.forest,
                                  ),
                                  isCompact: isCompact,
                                ),
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 7: Correo Electrónico
                              Text(
                                'Correo Electrónico',
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
                                  hintText: 'promotor@ejemplo.org',
                                  prefixIcon: SvgPicture.asset(
                                    'assets/images/icono_correo.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tu correo';
                                  }
                                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Formato de correo no válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 8: Contraseña
                              Text(
                                'Contraseña',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('passwordField'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Mínimo 8 caracteres',
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
                                    return 'Ingresa una contraseña';
                                  }
                                  if (value.length < 8) {
                                    return 'Debe tener al menos 8 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Campo 9: Confirmar Contraseña
                              Text(
                                'Confirmar Contraseña',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('confirmPasswordField'),
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AndeanColors.ink,
                                ),
                                decoration: andeanInputDecoration(
                                  hintText: 'Repite tu contraseña',
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
                                        _obscureConfirmPassword
                                            ? AndeanColors.muted
                                            : AndeanColors.brand,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  isCompact: isCompact,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isCompact ? 12 : 16),

                              // Selector de Categoría (Píldoras visuales de Figma)
                              Text(
                                'Tipo de promotor',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AndeanColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCategoryChips(),
                              const SizedBox(height: 10),

                              // DropdownButtonFormField integrado para accesibilidad y tests
                              DropdownButtonFormField<PromoterCategory>(
                                key: const Key('categoryDropdown'),
                                isExpanded: true,
                                value: _selectedCategory,
                                decoration: andeanInputDecoration(
                                  hintText: 'Categoría de Promotor',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    size: 20,
                                    color: AndeanColors.forest,
                                  ),
                                  isCompact: isCompact,
                                ),
                                items: PromoterCategory.values.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(
                                      cat.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AndeanColors.ink,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (cat) {
                                  if (cat != null) {
                                    setState(() {
                                      _selectedCategory = cat;
                                      if (cat != PromoterCategory.escolar) {
                                        _isAdultConfirmed = true;
                                      }
                                    });
                                  }
                                },
                              ),
                              SizedBox(height: isCompact ? 10 : 14),

                              // Control condicional de mayoría de edad para escolares
                              if (_selectedCategory == PromoterCategory.escolar) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    border: Border.all(color: const Color(0xFFFFE082)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            key: const Key('isAdultCheckbox'),
                                            value: _isAdultConfirmed,
                                            activeColor: AndeanColors.brand,
                                            onChanged: (val) {
                                              setState(() {
                                                _isAdultConfirmed = val ?? false;
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Declaro que tengo 18 años o más.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AndeanColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isMinorEscolarBlocked)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 4),
                                          child: Text(
                                            'El registro de promotores escolares menores de edad es gestionado directamente por su institución educativa o el coordinador EDUCCA. No es posible autorregistrarse como menor.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 10 : 14),
                              ],

                              // Casilla de Consentimiento Informado (RNF-01)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    key: const Key('consentCheckbox'),
                                    value: _privacyConsentAccepted,
                                    activeColor: AndeanColors.brand,
                                    onChanged: (val) {
                                      setState(() {
                                        _privacyConsentAccepted = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Acepto el ',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AndeanColors.ink,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => PrivacyConsentDialog.show(context),
                                            child: Text(
                                              'Aviso de Privacidad y Consentimiento',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AndeanColors.forest,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' para el uso puntual de mi ubicación al marcar asistencia.',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AndeanColors.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isCompact ? 16 : 22),

                              // Botón de Envío
                              SizedBox(
                                width: double.infinity,
                                height: isCompact ? 48 : 52,
                                child: ElevatedButton(
                                  key: const Key('registerButton'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AndeanColors.brand,
                                    disabledBackgroundColor: AndeanColors.line,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: (auth.isLoading ||
                                          _isMinorEscolarBlocked ||
                                          !_privacyConsentAccepted)
                                      ? null
                                      : _submit,
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
                                          'Registrarme como Promotor',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 18 : 24),

                        // Pie de página institucional
                        const Divider(
                          color: AndeanColors.line,
                          thickness: 1,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Datos protegidos · Uso institucional',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: AndeanColors.muted,
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
                        const SizedBox(height: 16),
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

  /// Selector andino de sexo (Masculino M / Femenino F)
  Widget _buildSexoSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('sexoM'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedSexo = 'M'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              decoration: BoxDecoration(
                color: _selectedSexo == 'M' ? AndeanColors.chipSelectedBg : AndeanColors.surface,
                border: Border.all(
                  color: _selectedSexo == 'M' ? AndeanColors.brand : AndeanColors.line,
                  width: _selectedSexo == 'M' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Masculino (M)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: _selectedSexo == 'M' ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedSexo == 'M' ? AndeanColors.forest : AndeanColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const Key('sexoF'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedSexo = 'F'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              decoration: BoxDecoration(
                color: _selectedSexo == 'F' ? AndeanColors.chipSelectedBg : AndeanColors.surface,
                border: Border.all(
                  color: _selectedSexo == 'F' ? AndeanColors.brand : AndeanColors.line,
                  width: _selectedSexo == 'F' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Femenino (F)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: _selectedSexo == 'F' ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedSexo == 'F' ? AndeanColors.forest : AndeanColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye las 3 píldoras visuales de categoría de Figma (Escolar, Juvenil, Comunitario)
  Widget _buildCategoryChips() {
    return Row(
      children: PromoterCategory.values.map((cat) {
        final isSelected = _selectedCategory == cat;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  if (cat != PromoterCategory.escolar) {
                    _isAdultConfirmed = true;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AndeanColors.chipSelectedBg : AndeanColors.surface,
                  border: Border.all(
                    color: isSelected ? AndeanColors.brand : AndeanColors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    cat.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AndeanColors.forest : AndeanColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
