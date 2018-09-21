#!/bin/sh

PROJECT_PATH="${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="${PROJECT_NAME}"
PRODUCT_NAME="${PROJECT_NAME}"
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal


## Build Device and Simulator versions
xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME_NAME}" -configuration ${CONFIGURATION} BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" -sdk iphoneos ONLY_ACTIVE_ARCH=NO clean build
xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME_NAME}" -configuration ${CONFIGURATION} BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO clean build


## Make sure the output folder for the universal framework exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}/"


## Copy the framework structure (from iphoneos build) to the universal folder
## This will include all device architectures and swiftmodules
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"


## Copy Swift modules (from iphonesimulator build) to the copied framework directory
## This copies over the swiftmodules for the simulator
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/." "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule"


## Create universal binary file using lipo and place the combined executable in the universal framework directory
## Generates the executable with both simulator and device architectures. Places the file in the universal output folder where we've consolidated the swiftmodules we need.
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}"


## Retrieve CFBundleShortVersion from generated framework
SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${UNIVERSAL_OUTPUTFOLDER}/${PRODUCT_NAME}.framework/Info.plist")


## Generate local path to store built framework
COPY_DIR="${PROJECT_DIR}/Binaries/${SHORT_VERSION}/iOS"


## Convenience step to copy the framework to the project's directory
rm -rf "${COPY_DIR}"
mkdir -p "${COPY_DIR}"
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${PRODUCT_NAME}.framework" "${COPY_DIR}"
