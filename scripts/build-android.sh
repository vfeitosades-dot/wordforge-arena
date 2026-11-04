#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ANDROID_SDK_ROOT:?Defina ANDROID_SDK_ROOT para o SDK Android}"
TOOLS="$ANDROID_SDK_ROOT/build-tools/35.0.0"
JAR="$ANDROID_SDK_ROOT/platforms/android-35/android.jar"
BUILD="$PWD/build/android"
mkdir -p "$BUILD/classes" "$BUILD/dex" "$BUILD/assets"
cp -R web/. "$BUILD/assets/"
"$TOOLS/aapt2" link -I "$JAR" --manifest android/app/src/main/AndroidManifest.xml -A "$BUILD/assets" -o "$BUILD/base.apk"
java -m jdk.compiler/com.sun.tools.javac.Main -source 8 -target 8 -bootclasspath "$JAR" -classpath "$JAR" -d "$BUILD/classes" android/app/src/main/java/com/wordforge/arena/MainActivity.java
mapfile -t CLASSES < <(find "$BUILD/classes" -name '*.class')
"$TOOLS/d8" --lib "$JAR" --min-api 26 --output "$BUILD/dex" "${CLASSES[@]}"
(cd "$BUILD/dex" && zip -q "$BUILD/base.apk" classes.dex)
"$TOOLS/zipalign" -f 4 "$BUILD/base.apk" "$BUILD/aligned.apk"
# Local distribution certificate. Keep the keystore for future updates; never commit it.
KEYSTORE="${WORDFORGE_KEYSTORE:-$PWD/build/wordforge.keystore}"
if [ ! -f "$KEYSTORE" ]; then
 keytool -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android -alias wordforge -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=WordForge Arena, O=WordForge, C=BR' >/dev/null 2>&1
fi
"$TOOLS/apksigner" sign --ks "$KEYSTORE" --ks-pass pass:android --ks-key-alias wordforge --out "$BUILD/WordForge-3D-Android.apk" "$BUILD/aligned.apk"
"$TOOLS/apksigner" verify --verbose "$BUILD/WordForge-3D-Android.apk"
