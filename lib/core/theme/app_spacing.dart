import 'package:flutter/material.dart';

/// Espaçamentos padrão reutilizáveis para evitar duplication
abstract final class AppSpacing {
  // Horizontal spacing
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  // Const SizedBox widgets pré-construídos (zero alocação)
  static const sizedBoxXs = SizedBox(width: xs, height: xs);
  static const sizedBoxSm = SizedBox(width: sm, height: sm);
  static const sizedBoxMd = SizedBox(width: md, height: md);
  static const sizedBoxLg = SizedBox(width: lg, height: lg);
  static const sizedBoxXl = SizedBox(width: xl, height: xl);
  static const sizedBoxXxl = SizedBox(width: xxl, height: xxl);
  static const sizedBoxXxxl = SizedBox(width: xxxl, height: xxxl);

  // Vertical spacing
  static const sizedBoxVerticalSm = SizedBox(height: sm);
  static const sizedBoxVerticalMd = SizedBox(height: md);
  static const sizedBoxVerticalLg = SizedBox(height: lg);
  static const sizedBoxVerticalXl = SizedBox(height: xl);
  static const sizedBoxVerticalXxl = SizedBox(height: xxl);

  // Horizontal spacing
  static const sizedBoxHorizontalSm = SizedBox(width: sm);
  static const sizedBoxHorizontalMd = SizedBox(width: md);
  static const sizedBoxHorizontalLg = SizedBox(width: lg);
}
