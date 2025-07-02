#!/bin/bash

# Set debug bundle ID for development builds

if [ "$CONFIGURATION" = "Debug" ]; then
    echo "Setting debug bundle ID..."
    
    # Backup original Info.plist
    cp "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Info.plist" "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Info.plist.bak"
    
    # Replace bundle ID
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.k9i.ClaudeCodeMonitor.debug" "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Info.plist"
    
    # Replace app name
    /usr/libexec/PlistBuddy -c "Set :CFBundleName ClaudeCodeMonitor-Debug" "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ClaudeCodeMonitor-Debug" "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Info.plist"
    
    echo "Debug bundle ID set to: com.k9i.ClaudeCodeMonitor.debug"
fi