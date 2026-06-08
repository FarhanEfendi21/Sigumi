# ══════════════════════════════════════════════════════════════
# SIGUMI — tflite_audio Patch Script
# ══════════════════════════════════════════════════════════════
# tflite_audio 0.3.0 is incompatible with modern Flutter/AGP 8.x+.
# This script patches the pub cache to fix:
# 1. Missing 'namespace' in build.gradle (required by AGP 8.x+)
# 2. 'package' attribute in AndroidManifest.xml (blocked by AGP 8.x+)
# 3. FlutterMain → FlutterInjector migration (removed in Flutter 3.x+)
# 4. loadModel() never returns result.success() — hangs Dart Future
#
# RUN THIS AFTER EVERY `flutter pub get` or `flutter clean`!
# Usage: .\patch_tflite_audio.ps1
# ══════════════════════════════════════════════════════════════

$basePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\tflite_audio-0.3.0\android"
$buildGradle = "$basePath\build.gradle"
$manifest = "$basePath\src\main\AndroidManifest.xml"
$pluginJava = "$basePath\src\main\java\flutter\tflite_audio\TfliteAudioPlugin.java"

Write-Host "=== Patching tflite_audio 0.3.0 ===" -ForegroundColor Cyan

# 1. Add namespace to build.gradle
Write-Host "[1/4] Adding namespace to build.gradle..." -ForegroundColor Yellow
$content = Get-Content $buildGradle -Raw
if ($content -notmatch "namespace") {
    $content = $content -replace "android \{`r?`n\s+compileSdkVersion 31", "android {`n    namespace 'flutter.tflite_audio'`n    compileSdkVersion 31"
    Set-Content $buildGradle $content -NoNewline
    Write-Host "      Done!" -ForegroundColor Green
} else {
    Write-Host "      Already patched." -ForegroundColor Gray
}

# 2. Remove package from AndroidManifest.xml
Write-Host "[2/4] Removing package from AndroidManifest.xml..." -ForegroundColor Yellow
Set-Content $manifest '<manifest xmlns:android="http://schemas.android.com/apk/res/android"></manifest>'
Write-Host "      Done!" -ForegroundColor Green

# 3. Fix FlutterMain → FlutterInjector
Write-Host "[3/4] Fixing FlutterMain → FlutterInjector..." -ForegroundColor Yellow
$java = Get-Content $pluginJava -Raw
$java = $java -replace 'import io\.flutter\.view\.FlutterMain;', 'import io.flutter.FlutterInjector;'
$java = $java -replace 'FlutterMain\.getLookupKeyForAsset', 'io.flutter.FlutterInjector.instance().flutterLoader().getLookupKeyForAsset'

# 4. Fix loadModel() hanging — add result.success(null)
Write-Host "[4/4] Fixing loadModel() hanging Future..." -ForegroundColor Yellow
if ($java -notmatch 'result\.success\(null\)') {
    $java = $java -replace '(loadModel\(\);\s+Log\.d\(LOG_TAG, "loadModel parameters: " \+ arguments\);)\s+break;', "`$1`n                result.success(null);`n                break;"
    Write-Host "      Done!" -ForegroundColor Green
} else {
    Write-Host "      Already patched." -ForegroundColor Gray
}

Set-Content $pluginJava $java -NoNewline

Write-Host "`n=== All patches applied! ===" -ForegroundColor Cyan
Write-Host "You can now run: flutter run" -ForegroundColor White
