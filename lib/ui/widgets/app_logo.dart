import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:papuy/theme/catppuccin.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  static const double _darkMix = 0.12;
  static const double _lightMix = 0.22;

  static const String _shield =
      'M 5.0453582,6.0102893 C 4.7408615,6.476013 4.7408615,7.8603533 4.7408615,10.629073 v 1.363483 c 0,4.881755 3.419022,7.250852 5.5641785,8.256817 0.581892,0.272833 0.872821,0.409293 1.694959,0.409293 0.822139,0 1.113069,-0.13645 1.69493,-0.409295 2.145156,-1.005965 5.564209,-3.375064 5.564209,-8.256818 v -1.36348 c 0,-2.7687198 0,-4.1530601 -0.304482,-4.6187838 C 18.650178,5.5445658 17.437658,5.0990081 15.012622,4.2078833 L 14.550618,4.0381171 C 13.286479,3.5735925 12.654452,3.341334 11.999999,3.341334 c -0.654451,0 -1.28648,0.2322585 -2.5506013,0.6967793 L 8.9873851,4.2078796 C 6.5623568,5.0990043 5.3498469,5.5445618 5.0453582,6.0102855 Z';

  static const String _wing =
      '<path d="M12.35 11.5 C12.9 8.4 14.9 6.7 16.9 6.9 C18.5 7.1 18.8 8.8 18 10.3 C17.2 11.8 14.6 12.5 12.35 11.9 Z"/>'
      '<path d="M12.35 12.6 C14.6 12.3 17 12.9 16.9 14.8 C16.8 16.8 14.6 17.9 13.4 16.8 C12.6 16.0 12.35 14.4 12.35 12.6 Z"/>';

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _svg(Color glyph, Color tile) {
    final g = _hex(glyph);
    final t = _hex(tile);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<rect width="24" height="24" rx="6.16" fill="$t"/>'
        '<path d="$_shield" fill="$g"/>'
        '<g fill="$t">'
        '<g>$_wing</g>'
        '<g transform="translate(24 0) scale(-1 1)">$_wing</g>'
        '<rect x="11.62" y="8.9" width="0.76" height="7.4" rx="0.38"/>'
        '<path d="M11.8 8.9 C11.5 7.8 10.9 7.0 10.2 6.6 M12.2 8.9 C12.5 7.8 13.1 7.0 13.8 6.6" fill="none" stroke="$t" stroke-width="0.5" stroke-linecap="round"/>'
        '<circle cx="12" cy="12.2" r="3.05" fill="$g"/>'
        '<circle cx="12" cy="12.2" r="2.45" fill="$t"/>'
        '<path d="M11.2 10.95 L11.2 13.45 L13.35 12.2 Z" fill="$g" stroke="$g" stroke-width="0.5" stroke-linejoin="round"/>'
        '</g></svg>';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base =
        (dark ? CatppuccinPalette.mocha : CatppuccinPalette.latte).base;
    final tile = Color.lerp(base, scheme.primary, dark ? _darkMix : _lightMix)!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: SvgPicture.string(_svg(scheme.primary, tile)),
      ),
    );
  }
}
