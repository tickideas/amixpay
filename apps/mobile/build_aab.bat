@echo off
set NDK_BIN=C:\Users\mcjam\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin
set PATH=%NDK_BIN%;%PATH%
echo NDK bin added to PATH
echo Building AAB...
flutter build appbundle --release
echo Done. Exit code: %ERRORLEVEL%
