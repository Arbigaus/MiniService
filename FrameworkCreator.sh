#!/bin/bash

SchemeName=MiniService
DerivedDataPath="~/Library/Developer/Xcode/DerivedData/"

echo "Cleaning build folder if exist"
rm -rf build/
echo "Build folder removed"

echo "Starting the archive proccess"

xcodebuild archive -scheme $SchemeName -destination "generic/platform=iOS" -archivePath ./build/$SchemeName-iOS.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES 
xcodebuild archive -scheme $SchemeName -destination "generic/platform=iOS Simulator" -archivePath ./build/$SchemeName-iOSSimulator.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES 
xcodebuild archive -scheme $SchemeName -destination "generic/platform=macOS" -archivePath ./build/$SchemeName-macOS.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES 

echo "Starting to create the xcframework"
xcodebuild -create-xcframework \
    -framework ./build/$SchemeName-iOS.xcarchive/Products/usr/local/lib/MiniService.framework \
    -framework ./build/$SchemeName-iOSSimulator.xcarchive/Products/usr/local/lib/MiniService.framework \
    -framework ./build/$SchemeName-macOS.xcarchive/Products/usr/local/lib/MiniService.framework \
    -output ./$SchemeName.xcframework

echo "Removing the build folder"
rm -rf build/
echo "Build folder removed"