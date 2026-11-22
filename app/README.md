# Application Mr. Shawarma (Flutter)

Trois applications dans un seul code :
- `lib/main.dart`         -> CLIENT
- `lib/main_livreur.dart` -> LIVREUR
- `lib/main_admin.dart`   -> ADMINISTRATEUR

Les APK sont construits automatiquement par GitHub (voir `../.github/workflows/build-apks.yml`
et `tools/prepare_android.py`). Guide complet : `../GUIDE_PUBLICATION.md`.

Test local dans le navigateur :
```powershell
flutter pub get
flutter run -d web-server --web-port 5050 -t lib\main.dart --dart-define=API_BASE=http://localhost:8001
```
