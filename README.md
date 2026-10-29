# Quick Invoice Maker — Flutter Starter

Offline-first invoice PDF generator. No login, backend, Firebase, or cloud database.

## Features
- Responsive Material 3 form
- Business and customer details
- Invoice number and date
- Add/remove invoice line items
- Automatic line totals and grand total
- PDF preview/print/save/share using the system print dialog
- Riverpod state management
- Calculation unit test
- Android and iOS platform folders

## Run
Install Flutter stable and Android Studio, then run:
```bash
flutter doctor
flutter pub get
flutter test
flutter analyze
flutter run
```

For iOS builds, use macOS with Xcode. If native platform files need to be regenerated for your installed Flutter version:
```bash
flutter create --platforms=android,ios .
```

## Release checks
Test on real devices and review the generated PDF before publishing. The iOS folder is starter scaffolding and should be regenerated/verified with Flutter and Xcode before App Store archive. This project has not been compiled in this environment because the Flutter SDK is unavailable here.
