import 'package:flutter/material.dart';

/// Design tokens for OFFGRID AI. Dark-first: charcoal surfaces, one green
/// accent, high-contrast text. Keep new colors here rather than inline.
abstract final class AppColors {
  static const background = Color(0xFF0B0D0C);
  static const surface = Color(0xFF151917);
  static const surfaceRaised = Color(0xFF1C211E);
  static const border = Color(0xFF262C28);

  /// Unfilled part of progress bars; must read clearly on [surface].
  static const track = Color(0xFF353D38);

  static const accent = Color(0xFF43D84A);
  static const accentMuted = Color(0xFF1F3A22);
  static const onAccent = Color(0xFF07140A);

  static const textPrimary = Color(0xFFF2F5F2);
  static const textSecondary = Color(0xFF9AA39C);
  static const textTertiary = Color(0xFF66706A);

  static const warning = Color(0xFFF2B33D);
  static const danger = Color(0xFFEF5B5B);

  static const topoLine = Color(0xFF242A26);

  /// USGS topographic map conventions, used only by the map legend so
  /// swatches match what the USGS Topo layer draws. Shown on [usgsPaper].
  static const usgsPaper = Color(0xFFF3F0E7);
  static const usgsContour = Color(0xFFC08A5C);
  static const usgsIndexContour = Color(0xFF8E5A2E);
  static const usgsWater = Color(0xFF3F8BD0);
  static const usgsWoodland = Color(0xFFB9DBA4);
  static const usgsHighway = Color(0xFFD9382C);
  static const usgsRoad = Color(0xFF7A7A7A);
  static const usgsTrail = Color(0xFF262626);
  static const usgsBuilding = Color(0xFF1C1C1C);
  static const usgsBoundary = Color(0xFF4A4A4A);
  static const usgsRelief = Color(0xFFA8A49B);
}
