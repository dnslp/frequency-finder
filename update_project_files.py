#!/usr/bin/env python3

import os
import shutil
from pathlib import Path

def create_file_mapping():
    """Create a mapping of old file paths to new file paths"""
    base_path = "/Users/davidnyman/Code/FrequencyFinder/FrequencyFinder"
    
    # Files that were moved to new locations
    file_mapping = {
        # App files
        "FrequencyFinder.swift": "App/FrequencyFinder.swift",
        "AppDelegate.swift": "App/AppDelegate.swift", 
        "TunerScreen.swift": "App/TunerScreen.swift",
        
        # Core Models
        "Models/Frequency.swift": "Core/Models/Audio/Frequency.swift",
        "Models/PitchTracker.swift": "Core/Models/Audio/PitchTracker.swift",
        "Models/Recorder.swift": "Core/Models/Audio/Recorder.swift",
        "Models/TunerData.swift": "Core/Models/Audio/TunerData.swift",
        "Models/ScaleNote.swift": "Core/Models/Music/ScaleNote.swift",
        "Models/NoteMatcher.swift": "Core/Models/Music/NoteMatcher.swift",
        "Models/ModifierPreference.swift": "Core/Models/Music/ModifierPreference.swift",
        "Models/UserProfile.swift": "Core/Models/User/UserProfile.swift",
        "Models/ReadingPassage.swift": "Core/Models/User/ReadingPassage.swift",
        "Models/SpotifyUserProfile.swift": "Core/Models/Spotify/SpotifyUserProfile.swift",
        "Models/StatisticsCalculator.swift": "Core/Utilities/StatisticsCalculator.swift",
        
        # Services  
        "UserProfileManager.swift": "Core/Services/User/UserProfileManager.swift",
        
        # Views
        "Views/TunerView.swift": "Features/Tuner/Views/TunerView.swift",
        "Views/ProfileView.swift": "Features/Profile/Views/ProfileView.swift",
        
        # ViewModels
        "ViewModels/ReadingPassageViewModel.swift": "Features/ReadingPassage/ViewModels/ReadingPassageViewModel.swift",
        "ViewModels/WebReadingPassageViewModel.swift": "Features/ReadingPassage/ViewModels/WebReadingPassageViewModel.swift",
        
        # Helpers
        "Helpers/Alignment.swift": "Supporting Files/Helpers/Alignment.swift",
        "Helpers/Color+MusicalDistance.swift": "Supporting Files/Helpers/Color+MusicalDistance.swift",
    }
    
    return file_mapping

def check_new_structure():
    """Verify the new file structure exists"""
    base_path = Path("/Users/davidnyman/Code/FrequencyFinder/FrequencyFinder")
    
    print("🔍 Checking new file structure...")
    
    key_files = [
        "App/FrequencyFinder.swift",
        "Core/Models/Spotify/SpotifyModels.swift", 
        "Core/Services/Spotify/SpotifyManager.swift",
        "Features/Spotify/Views/SpotifyView.swift"
    ]
    
    all_exist = True
    for file_path in key_files:
        full_path = base_path / file_path
        if full_path.exists():
            print(f"  ✅ {file_path}")
        else:
            print(f"  ❌ {file_path}")
            all_exist = False
            
    return all_exist

def main():
    print("🔧 FrequencyFinder Project Structure Checker")
    print("=" * 50)
    
    # Check if new structure exists
    if not check_new_structure():
        print("\n❌ New file structure is incomplete!")
        return
        
    print("\n✅ New file structure verified!")
    print("\n📋 MANUAL STEPS NEEDED:")
    print("1. Open Xcode")
    print("2. Delete any red/missing file references (Remove Reference Only)")
    print("3. Right-click project → 'Add Files to FrequencyFinder'") 
    print("4. Add these new folders:")
    print("   - App/")
    print("   - Core/")
    print("   - Features/")
    print("   - Supporting Files/")
    print("\n🎯 Your project should then build successfully!")
    print("\n💡 TIP: You can also use the new SpotifyView instead of PersistentSpotifyView")

if __name__ == "__main__":
    main()