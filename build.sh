#!/bin/bash

PLATFORM_NAME=android
RELEASE_TYPE=apk
SYMBOLS_DIR=build/app/intermediates/merged_native_libs/release/out/lib

if [ "$1" = "ios" ]; then
  PLATFORM_NAME=ios
elif [ "$1" = "android" ]; then
  PLATFORM_NAME=android

    if [ "$2" = "release" ]; then
        RELEASE_TYPE=release
    elif [ "$2" = "apk" ]; then
        RELEASE_TYPE=apk
    else
        echo "Usage: $0 [ios|android] [release|apk]"
        exit 1
    fi
else
  echo "Usage: $0 [ios|android]"
  exit 1
fi

# check if this "const isDebug = true;" is in lib/common/constants.dart
# if found, exit with error
if grep -Fxq "const isDebug = true;" lib/common/constants.dart;  then
  echo "Error: lib/common/constants.dart contains 'isDebug = true;'"
  echo "Please replace it with 'isDebug = false;' then try again"
  exit 1
else
  echo "isDebug = true; not found in lib/common/constants.dart"
fi

echo "Update the build details"
./update_version.sh

# if PLATFORM_NAME is anrdoi run flutter build apk --release --obfuscate --split-debug-info=v1.0.1 else run  flutter build ios --release
if [ "$PLATFORM_NAME" = "android" ]; then
    if [ "$RELEASE_TYPE" = "release" ]; then
        echo "flutter build appbundle --release --obfuscate --split-debug-info=v1.0.1"
        flutter build appbundle --release --obfuscate --split-debug-info=v1.0.1
    else
        echo "flutter   apk --release --obfuscate --split-debug-info=quran-app/v1.0.1"
        flutter build apk --release --obfuscate --split-debug-info=v1.0.1
    fi

    # create symbol zip file
    cd $SYMBOLS_DIR;
    rm .DS_Store;
    zip -r symbols.zip .
    cp $SYMBOLS_DIR/symbols.zip build/app/outputs/bundle/release/;

    # if current os is macos, open build/app/outputs/bundle/release
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open build/app/outputs/bundle/release;
    else
        echo "open build/app/outputs/bundle/release";
    fi
else
    echo "flutter build ios --release"
    flutter build ios --release
    # if current os is macos, open build/ios/iphoneos
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open build/ios/iphoneos
    else
        echo "open build/ios/iphoneos"
    fi
fi
