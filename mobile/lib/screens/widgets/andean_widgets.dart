import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color oficiales extraídos del diseño Figma EDUCCA Cusco (M01 a M08)
class AndeanColors {
  AndeanColors._();

  static const Color cream = Color(0xFFFAF6ED);
  static const Color surface = Color(0xFFFFFDF8);
  static const Color soft = Color(0xFFEEEADF);
  static const Color line = Color(0xFFDCD2C1);
  static const Color brand = Color(0xFF176B53);
  static const Color forest = Color(0xFF15563F);
  static const Color deep = Color(0xFF153B2F);
  static const Color ink = Color(0xFF22372D);
  static const Color muted = Color(0xFF66776D);
  static const Color terracotta = Color(0xFFC66C3F);
  static const Color headerDark = Color(0xFF214B3B);
  static const Color headerOverlay = Color(0x420C2C21);
  static const Color chipSelectedBg = Color(0xFFE4F1EB);
}

/// Encabezado paisajístico andino compacto con motivo geométrico y banda ornamental
class AndeanHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool isCompact;

  const AndeanHeader({
    super.key,
    this.title = 'EDUCCA Cusco',
    this.leading,
    this.trailing,
    bool isCompact = false,
    bool? compact,
  }) : isCompact = compact ?? isCompact;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final baseHeight = isCompact ? 100.0 : 145.0;
    final headerHeight = baseHeight + topPadding;

    return Container(
      height: headerHeight,
      width: double.infinity,
      color: AndeanColors.headerDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ilustración vectorial del paisaje andino
          SvgPicture.asset(
            'assets/images/paisaje_andino.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: headerHeight,
          ),

          // Capa de contraste semi-transparente
          Container(
            color: AndeanColors.headerOverlay,
          ),

          // Barra superior con leading/motivo, título y trailing/acciones
          Positioned(
            top: topPadding + (isCompact ? 4 : 10),
            left: 16,
            right: 8,
            child: Row(
              children: [
                leading ??
                    SvgPicture.asset(
                      'assets/images/motivo_geometrico.svg',
                      width: isCompact ? 18 : 22,
                      height: isCompact ? 18 : 22,
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isCompact ? 17 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),

          // Banda ornamental andina en el borde inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: isCompact ? 12 : 16,
            child: SvgPicture.asset(
              'assets/images/banda_ornamental.svg',
              fit: BoxFit.fill,
              width: double.infinity,
              height: isCompact ? 12 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de modo de acceso (Ingresar vs Crear cuenta)
enum AccessMode { login, register }

class AndeanAccessSelector extends StatelessWidget {
  final AccessMode currentMode;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;
  final bool isCompact;

  const AndeanAccessSelector({
    super.key,
    required this.currentMode,
    this.onLoginTap,
    this.onRegisterTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = currentMode == AccessMode.login;

    return Container(
      height: isCompact ? 46 : 52,
      decoration: BoxDecoration(
        color: AndeanColors.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLoginTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isLogin ? AndeanColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Ingresar',
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: isLogin ? AndeanColors.brand : AndeanColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onRegisterTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isLogin ? AndeanColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Crear cuenta',
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: !isLogin ? AndeanColors.brand : AndeanColors.muted,
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

/// Decoración estándar para campos de texto con tema andino
InputDecoration andeanInputDecoration({
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isCompact = false,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AndeanColors.muted,
    ),
    filled: true,
    fillColor: AndeanColors.surface,
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: prefixIcon,
          )
        : null,
    prefixIconConstraints: const BoxConstraints(
      minWidth: 48,
      minHeight: 24,
    ),
    suffixIcon: suffixIcon,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: isCompact ? 12 : 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AndeanColors.line, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AndeanColors.line, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AndeanColors.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
    ),
  );
}

/// Botón con tema andino EDUCCA (Primario verde / Secundario verde suave)
class AndeanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isCompact;

  const AndeanButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isCompact ? 46 : 52,
      child: isSecondary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AndeanColors.chipSelectedBg,
                foregroundColor: AndeanColors.brand,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AndeanColors.brand,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AndeanColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

/// Banner indicador de Modo Demostración activo
class AndeanDemoBanner extends StatelessWidget {
  const AndeanDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Barra de navegación inferior andina (Figma 1:155)
class AndeanBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AndeanBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 60 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AndeanColors.cream,
        border: Border(
          top: BorderSide(color: AndeanColors.line, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'Inicio', 'assets/images/icono_nav_inicio.svg'),
          _buildNavItem(1, 'Talleres', 'assets/images/icono_nav_talleres.svg'),
          _buildNavItem(2, 'Asistencias', 'assets/images/icono_nav_asistencias.svg'),
          _buildNavItem(3, 'Perfil', 'assets/images/icono_nav_perfil.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconPath) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 25,
              width: 42,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F3ED) : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isSelected ? AndeanColors.brand : AndeanColors.muted,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AndeanColors.brand : AndeanColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
