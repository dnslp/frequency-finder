#!/bin/bash

# Script to help fix Xcode project references after file reorganization
# This creates a backup and provides guidance for manual fixes

echo "🔧 FrequencyFinder - Xcode Project Reference Fixer"
echo "=================================================="

PROJECT_DIR="/Users/davidnyman/Code/FrequencyFinder"
XCODE_PROJECT="$PROJECT_DIR/FrequencyFinder.xcodeproj/project.pbxproj"

# Create backup
echo "📦 Creating backup of project.pbxproj..."
cp "$XCODE_PROJECT" "$XCODE_PROJECT.backup.$(date +%Y%m%d_%H%M%S)"

echo "✅ Backup created successfully!"
echo ""
echo "🎯 RECOMMENDED APPROACH:"
echo "1. Open Xcode"
echo "2. Look for red/missing files in the Navigator"
echo "3. Right-click each → 'Delete' → 'Remove Reference Only'"
echo "4. Right-click project root → 'Add Files to FrequencyFinder'"
echo "5. Add the new organized folders:"
echo "   - App/"
echo "   - Core/"
echo "   - Features/" 
echo "   - Supporting Files/"
echo ""
echo "📁 NEW STRUCTURE CREATED:"
echo "✓ App/ (FrequencyFinder.swift, AppDelegate.swift, TunerScreen.swift)"
echo "✓ Core/Models/ (Audio/, Music/, Spotify/, User/)"
echo "✓ Core/Services/ (Spotify/, User/)"  
echo "✓ Features/ (Tuner/, ReadingPassage/, Profile/, Spotify/)"
echo "✓ Supporting Files/ (Helpers/, Views/)"
echo ""
echo "🔄 After adding files, your project should build successfully!"
echo "💡 The old files are preserved with 'Old' prefixes for reference"