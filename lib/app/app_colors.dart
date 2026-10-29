import 'package:flutter/material.dart';

abstract final class AppColors {
  static const blue1 = Color(0xFF3c2d89);
  static const blue2 = Color(0xFF007bff);
  static const blue3 = Color(0xFF3a38a1);
  static const blue4 = Color(0xFF3366ff);
  static const blue5 = Color(0xFF2196F3);
  static const blue6 = Color(0xFF2f80ed);
  static const blue7 = Color(0xFF3984fe);
  static const blue8 = Color(0xFFd0daff);
  static const blue9 = Color(0xff000080);
  static const blue10 = Color(0xff3c8dbc);
  static const blue11 = Color(0xff0354a6);
  static const white1 = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFF2F2F2);
  static const grey2 = Color(0xFF4D4D4D);
  static const grey4 = Color(0xFF778ca2);
  static const grey5 = Color(0xFFd2d6de);
  static const grey3 = Color(0xFFA4A4A4);
  static const grey6 = Color(0xFF868e96);
  static const grey7 = Color(0xFF666666);
  static const grey8 = Color(0xFFfbfbfb);
  static const grey9 = Color(0xFFe3e6ea);
  static const grey10 = Color(0xFFf1f3f4);
  static const grey11 = Color(0xFFdfe1e4);
  static const grey12 = Color(0xFFf8f9fa);
  static const grey13 = Color(0xFF5f6367);
  static const grey14 = Color(0xFFced4da);
  static const grey15 = Color(0xFF999999);
  static const grey16 = Color(0xFF555555);
  static const grey17 = Color(0xFFf8f9fb);
  static const grey18 = Color(0xFF9A9A9A);
  static const whiteTransparent = Color(
    0x4DFFFFFF,
  ); // Figma rgba(255, 255, 255, 0.3)
  static const blackTransparent = Color(0x4D000000);
  static const red1 = Color(0xFFE74C3C);
  static const red2 = Color(0xFFf9dee4);
  static const red3 = Color(0xFFff0000);
  static const red4 = Color(0xFFdc3545);
  static const red5 = Color(0xFFd73925);
  static const black1 = Color(0xFF495057);
  static const black2 = Color(0xFF1a202e);
  static const black3 = Color(0xFF333333);
  static const black4 = Color(0xFF3a4150);
  static const black5 = Color(0xFF212529);
  static const black6 = Color(0xFF000000);
  static const green1 = Color(0xFF27ae60);
  static const green2 = Color(0x3327AE60);
  static const green3 = Color(0xFF28a745);
  static const green4 = Color(0xFF00a65a);
  static const brown1 = Color(0xFFcebb1a);
  static const brown2 = Color(0xFFefebd1);
  static const brown3 = Color(0xFFffe6d0);
  static const brown4 = Color(0xFFf27201);
  static const orange1 = Color(0xFFfffcf0);
  static const orange2 = Color(0xFFdc7609);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.blue1,
    onPrimary: AppColors.white1,
    secondary: AppColors.black2,
    onSecondary: AppColors.white1,
    surface: AppColors.white1,
    onSurface: AppColors.black1,
    error: Color(0xffb00020),
    onError: Colors.white,
    tertiary: AppColors.grey4,
    secondaryContainer: AppColors.blue3,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.white1,
    onPrimary: AppColors.blue1,
    secondary: AppColors.white1,
    onSecondary: AppColors.blue1,
    surface: AppColors.blue1,
    onSurface: Colors.white,
    error: Colors.black,
    onError: AppColors.red1,
  );
}

