#!/bin/bash

set -e

base_dir=$(dirname "$0")
cd "$base_dir"

echo ""

set -o pipefail && xcodebuild -workspace "Example/${POD_NAME}.xcworkspace" -scheme "${POD_NAME}-Example" -configuration "Release" -sdk iphonesimulator12.1 | xcpretty

echo ""

xcodebuild -project "CarthageSupport/${POD_NAME}.xcodeproj" -alltargets -sdk iphonesimulator12.1 | xcpretty

echo ""
echo "SUCCESS!"
echo ""
