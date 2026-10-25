@echo off
REM 真机测试 APK 一键构建：把服务地址打包进 APK
REM 用法：build-apk.bat <电脑局域网IP>   （不传参数时用 10.194.191.79）
REM 手机与电脑需在同一 WiFi；构建完成后 APK 自动拷到桌面

set IP=%1
if "%IP%"=="" set IP=10.194.191.79

echo 构建中（API=%IP%）...
docker run --rm -v "%cd%:/app" -v flutter_pubcache:/root/.pub-cache -v flutter_pubcache:/sdks/flutter/.pub-cache -v flutter_gradle:/root/.gradle -w /app ghcr.io/cirruslabs/flutter:3.24.5 sh -c "flutter pub get >/dev/null 2>&1 && flutter build apk --debug --dart-define=API_BASE_URL=http://%IP%:8080 --dart-define=WS_URL=ws://%IP%:8080/ws"

if exist "build\app\outputs\flutter-apk\app-debug.apk" (
  copy /y "build\app\outputs\flutter-apk\app-debug.apk" "%USERPROFILE%\Desktop\机器报修-debug.apk" >nul
  echo 完成：桌面\机器报修-debug.apk
) else (
  echo 构建失败，请查看上方日志
)
