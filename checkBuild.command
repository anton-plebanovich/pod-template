#!/bin/bash

set -e

base_dir=$(dirname "$0")
cd "$base_dir"

echo ""

set -o pipefail && xcodebuild -workspace "Pods Project/${POD_NAME}.xcworkspace" -scheme "${POD_NAME}-Example" -configuration "Release" -sdk iphonesimulator12.2 | xcpretty

echo ""

xcodebuild -project "Carthage Project/${POD_NAME}.xcodeproj" -alltargets -sdk iphonesimulator12.1 | xcpretty

echo ""
echo "SUCCESS!"
echo ""
