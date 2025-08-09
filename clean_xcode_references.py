#!/usr/bin/env python3

import re
import shutil
from pathlib import Path

def clean_xcode_references():
    """Remove references to deleted Old* files from Xcode project"""
    
    project_file = Path("/Users/davidnyman/Code/FrequencyFinder/FrequencyFinder.xcodeproj/project.pbxproj")
    
    if not project_file.exists():
        print("❌ project.pbxproj not found!")
        return False
    
    # Create backup
    backup_file = project_file.with_suffix('.pbxproj.backup')
    shutil.copy2(project_file, backup_file)
    print(f"📦 Created backup: {backup_file}")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Files to remove references for
    old_files = [
        'OldEnhancedSpotifyManager.swift',
        'OldUnifiedSpotifyManager.swift', 
        'OldPersistentSpotifyView.swift',
        'OldSpotifyManager.swift',
        'OldSimpleSpotifyManager.swift'
    ]
    
    # Remove file references
    original_length = len(content)
    
    for old_file in old_files:
        # Remove build file entries
        content = re.sub(rf'.*{re.escape(old_file)}.*in Sources.*\n', '', content)
        # Remove file reference entries  
        content = re.sub(rf'.*{re.escape(old_file)}.*\n', '', content)
        # Remove from build phases
        content = re.sub(rf'.*{re.escape(old_file)}.*Sources.*\n', '', content)
    
    if len(content) != original_length:
        # Write the cleaned content
        with open(project_file, 'w') as f:
            f.write(content)
        print(f"✅ Cleaned {original_length - len(content)} characters of old references")
        print("🎯 Now clean build folder in Xcode (⌘+Shift+K) and build (⌘+B)")
        return True
    else:
        print("ℹ️  No old file references found in project file")
        return False

if __name__ == "__main__":
    print("🔧 Xcode Project Reference Cleaner")
    print("=" * 40)
    clean_xcode_references()