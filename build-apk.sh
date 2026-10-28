#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BT="$SDK/build-tools/35.0.0"
JAR="$SDK/platforms/android-35/android.jar"
mkdir -p build/classes build/dex dist
javac --release 8 -classpath "$JAR" -d build/classes app/src/main/java/com/stageclick/metronome/MainActivity.java
"$BT/aapt2" link -o build/base.apk -I "$JAR" --manifest app/src/main/AndroidManifest.xml --min-sdk-version 26 --target-sdk-version 35 --version-code 2 --version-name 1.1
"$BT/d8" --lib "$JAR" --output build/dex build/classes/com/stageclick/metronome/*.class
cp build/base.apk build/unsigned.apk
(cd build/dex && zip -q -u ../unsigned.apk classes.dex)
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk
if [ ! -f build/local.keystore ]; then
 keytool -genkeypair -keystore build/local.keystore -storepass android -keypass android -alias stageclick -dname 'CN=Stage Click Local' -keyalg RSA -keysize 2048 -validity 10000
fi
"$BT/apksigner" sign --ks build/local.keystore --ks-pass pass:android --key-pass pass:android --out dist/StageClick.apk build/aligned.apk
"$BT/apksigner" verify --verbose dist/StageClick.apk
