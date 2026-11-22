#!/usr/bin/env python3
"""
Prépare le projet Android généré par `flutter create` :
  - 3 déclinaisons (client / livreur / admin) avec leur nom et leur identifiant
  - icônes + écran de démarrage (dossier android_overlay)
  - permissions (internet, localisation, notifications)
  - signature de release (android/key.properties) et desugaring
  - Firebase (seulement si android/app/google-services.json est présent)
Idempotent : peut être relancé sans risque.
"""
import pathlib, re, shutil, sys

APP = pathlib.Path(__file__).resolve().parent.parent
ANDROID = APP / 'android'
MAIN = ANDROID / 'app' / 'src' / 'main'
warnings = []

def read(p): return pathlib.Path(p).read_text(encoding='utf-8')
def write(p, s): pathlib.Path(p).write_text(s, encoding='utf-8', newline='\n')

# ---------------------------------------------------------------- Manifest
manifest = MAIN / 'AndroidManifest.xml'
m = read(manifest)
perms = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
]
missing = [p for p in perms if p not in m]
if missing:
    block = ''.join(f'    <uses-permission android:name="{p}"/>\n' for p in missing)
    m = re.sub(r'(\s*)<application\b', lambda x: '\n' + block + '    <application', m, count=1)
m = re.sub(r'(<application[^>]*?)android:label="[^"]*"', r'\1android:label="@string/app_name"', m, count=1, flags=re.S)
if '@string/app_name' not in m:
    warnings.append("android:label non remplacé dans AndroidManifest.xml")
write(manifest, m)

# ---------------------------------------------------------------- build.gradle.kts
gradle = ANDROID / 'app' / 'build.gradle.kts'
g = read(gradle)

if 'import java.util.Properties' not in g:
    g = 'import java.io.FileInputStream\nimport java.util.Properties\n\n' + g

if 'keystoreProperties' not in g:
    g = re.sub(r'(?m)^android\s*\{', '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''', g, count=1)

if 'productFlavors' not in g:
    g = re.sub(r'(?m)^android\s*\{\s*\n', '''android {
    buildFeatures {
        resValues = true
    }
    flavorDimensions += "app"
    productFlavors {
        create("client") {
            dimension = "app"
            applicationId = "com.mrshawarma.app"
            resValue("string", "app_name", "Mr. Shawarma")
        }
        create("livreur") {
            dimension = "app"
            applicationId = "com.mrshawarma.livreur"
            resValue("string", "app_name", "Mr. Shawarma Livreur")
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.mrshawarma.admin"
            resValue("string", "app_name", "Mr. Shawarma Admin")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

''', g, count=1)

if 'signingConfigs.getByName("release")' not in g:
    if 'signingConfig = signingConfigs.getByName("debug")' in g:
        g = g.replace('signingConfig = signingConfigs.getByName("debug")',
                      'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")')
    else:
        warnings.append("signingConfig de release introuvable : les APK seront signés avec la clé de debug")

if 'isCoreLibraryDesugaringEnabled' not in g:
    if re.search(r'compileOptions\s*\{', g):
        g = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
    else:
        warnings.append("compileOptions introuvable : desugaring non activé")
if 'coreLibraryDesugaring(' not in g:
    dep = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n'
    if re.search(r'(?m)^dependencies\s*\{', g):
        g = re.sub(r'(?m)^dependencies\s*\{\s*\n', 'dependencies {\n' + dep, g, count=1)
    else:
        g += '\ndependencies {\n' + dep + '}\n'

# Firebase : seulement si le fichier de configuration est fourni
if (ANDROID / 'app' / 'google-services.json').exists():
    if 'com.google.gms.google-services' not in g:
        g = re.sub(r'(?m)^plugins\s*\{\s*\n', 'plugins {\n    id("com.google.gms.google-services")\n', g, count=1)
    settings = ANDROID / 'settings.gradle.kts'
    s = read(settings)
    if 'com.google.gms.google-services' not in s:
        s = re.sub(r'(?m)^plugins\s*\{\s*\n', 'plugins {\n    id("com.google.gms.google-services") version "4.4.2" apply false\n', s, count=1)
        write(settings, s)
    print('Firebase : plugin google-services activé')

write(gradle, g)

# ---------------------------------------------------------------- Ressources (icônes, splash)
overlay = APP / 'android_overlay'
if overlay.exists():
    for src in overlay.iterdir():
        dst = ANDROID / 'app' / 'src' / src.name
        shutil.copytree(src, dst, dirs_exist_ok=True)
    print('Icônes et écran de démarrage copiés.')

if warnings:
    print('\nAVERTISSEMENTS :')
    for w in warnings: print(' -', w)
    sys.exit(0)
print('Android prêt.')
