#!/bin/bash
# Copy app icon to build output

if [ -f "${SRCROOT}/AppIcon.icns" ]; then
    echo "Copying AppIcon.icns to ${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
    cp "${SRCROOT}/AppIcon.icns" "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
fi