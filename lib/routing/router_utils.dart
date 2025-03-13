enum AppRoute { textSavePdf, writeSavePdf }

extension AppPageExtention on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.textSavePdf:
        return '/textSavePdf';
      case AppRoute.writeSavePdf:
        return '/writeSavePdf';
    }
  }
}
