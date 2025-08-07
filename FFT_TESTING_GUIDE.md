# FFT Implementation Testing Guide

## Quick Testing in FrequencyFinder App

To test the different FFT implementations in the actual FrequencyFinder app, you can easily switch between them:

### Switch to ZenFFT (Original)
Add this line early in your app startup (e.g., in `FrequencyFinder.swift` or `AppDelegate.swift`):

```swift
import ZenPTrack

// Use original ZenFFT implementation
FFTConfiguration.defaultImplementation = .zen
```

### Switch to Accelerate (Optimized)
```swift
import ZenPTrack

// Use new Accelerate framework implementation (default)
FFTConfiguration.defaultImplementation = .accelerate
```

### Performance Monitoring
Enable performance logging to see comparison data:

```swift
import ZenPTrack

// Log performance comparison on first use
FFTConfiguration.enablePerformanceLogging = true
FFTConfiguration.logInitialBenchmark = true
```

## Testing Commands

### Run FFT Tests
```bash
cd Packages/MicrophonePitchDetector
swift run ffttest
```

### Build Verification
```bash
cd Packages/MicrophonePitchDetector  
swift build
```

## What to Look For

### ✅ Success Indicators
- App launches normally
- Audio processing works correctly
- No crashes or hangs
- Pitch detection accuracy maintained

### ⚠️ Potential Issues
- Audio latency changes
- Pitch detection becoming less accurate
- Memory usage changes
- Battery usage differences

## Performance Comparison

Test both implementations with:
1. **Reading Passage Analysis** - Compare f0 detection accuracy
2. **Real-time Tuner** - Check responsiveness and accuracy
3. **Long Sessions** - Monitor memory usage and stability

## Reverting Changes

If you encounter issues, simply change the configuration back:

```swift
// Revert to original implementation
FFTConfiguration.defaultImplementation = .zen
```

Or remove the configuration line entirely to use the default optimized version.

## Current Test Results

**Test Environment**: M1 Mac, Command Line
- ✅ Both implementations working correctly
- ✅ API compatibility maintained  
- ⚠️ Performance results mixed (needs real-world testing)

The implementations are functionally equivalent, so switching between them should be seamless for testing purposes.