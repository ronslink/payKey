# PayKey App Icon Specification

## Overview

This document provides detailed specifications for creating app icons for both Android and iOS platforms for the PayKey mobile application.

## Design Concept

**App Name**: PayKey
**Primary Color**: `#2196F3` (Material Blue)
**Icon Concept**: Key symbol combined with payment/finance elements

---

## Android Icon Requirements

### Adaptive Icon Structure

Android adaptive icons require:
1. **Background Layer** - Solid color or gradient (108dp x 108dp)
2. **Foreground Layer** - Vector graphic (108dp x 108dp)
3. **Mask** - System-provided by Android

#### Background Specification
- **Format**: XML drawable or PNG
- **Size**: 108dp x 108dp
- **Color**: `#2196F3` (primary blue) or slight gradient
- **Safe Zone**: Icon is masked to a 66dp diameter circle

#### Foreground Specification
- **Format**: Vector drawable (preferred) or PNG
- **Size**: 108dp x 108dp (108dp x 108dp viewport)
- **Content**: Key icon + PayKey text/symbol
- **Safe Zone**: Stay within 42dp - 66dp central area to avoid clipping
- **Color**: White (`#FFFFFF`)

### Legacy Launcher Icons (Pre-Android 8.0)

Required PNG sizes:

| Density | Size | Filename | Usage |
|---------|------|----------|-------|
| mdpi | 48x48 | ic_launcher.png | Low-end devices |
| hdpi | 72x72 | ic_launcher.png | Medium devices |
| xhdpi | 96x96 | ic_launcher.png | High-end devices |
| xxhdpi | 144x144 | ic_launcher.png | Very high-end |
| xxxhdpi | 192x192 | ic_launcher.png | Ultra high-end |

---

## iOS Icon Requirements

### App Icon Set (iOS 7+)

Required PNG sizes:

| Device | Size | Scale | Filename | Usage |
|--------|------|-------|----------|-------|
| iPhone | 20x20 | 2x | Icon-App-20x20@2x.png | Spotlight |
| iPhone | 20x20 | 3x | Icon-App-20x20@3x.png | Spotlight |
| iPhone | 29x29 | 1x | Icon-App-29x29@1x.png | Settings |
| iPhone | 29x29 | 2x | Icon-App-29x29@2x.png | Settings |
| iPhone | 29x29 | 3x | Icon-App-29x29@3x.png | Settings |
| iPhone | 40x40 | 2x | Icon-App-40x40@2x.png | Spotlight |
| iPhone | 40x40 | 3x | Icon-App-40x40@3x.png | Spotlight |
| iPhone | 60x60 | 2x | Icon-App-60x60@2x.png | Home screen |
| iPhone | 60x60 | 3x | Icon-App-60x60@3x.png | Home screen |
| iPad | 20x20 | 1x | Icon-App-20x20@1x.png | Spotlight |
| iPad | 20x20 | 2x | Icon-App-20x20@2x.png | Spotlight |
| iPad | 29x29 | 1x | Icon-App-29x29@1x.png | Settings |
| iPad | 29x29 | 2x | Icon-App-29x29@2x.png | Settings |
| iPad | 40x40 | 1x | Icon-App-40x40@1x.png | Spotlight |
| iPad | 40x40 | 2x | Icon-App-40x40@2x.png | Spotlight |
| iPad | 76x76 | 1x | Icon-App-76x76@1x.png | Home screen |
| iPad | 76x76 | 2x | Icon-App-76x76@2x.png | Home screen |
| iPad Pro | 83.5x83.5 | 2x | Icon-App-83.5x83.5@2x.png | Home screen |
| App Store | 1024x1024 | 1x | Icon-App-1024x1024@1x.png | App Store |

### iOS Icon Specifications

- **Format**: PNG (RGB or RGBA)
- **Color Space**: sRGB
- **No Transparency**: iOS icons should not have transparent areas
- **No Alpha Channel**: Remove alpha channel before export
- **Rounded Corners**: iOS automatically applies corner radius (do not add manually)
- **Max File Size**: 500KB recommended

---

## Design Guidelines

### Key Design Elements

1. **PayKey Logo**
   - Simple key shape
   - "P" letter integrated into key head
   - Clean, modern lines

2. **Color Palette**
   - Primary: `#2196F3` (Blue)
   - Secondary: `#1976D2` (Darker Blue)
   - Accent: `#FF9800` (Orange - optional)
   - Text: `#FFFFFF` (White for dark backgrounds)

3. **Style**
   - Flat design with subtle depth
   - Rounded corners on key elements
   - High contrast for visibility
   - Scalable vector-based design

### Do's and Don'ts

#### Do:
- ✅ Use simple, recognizable shapes
- ✅ Ensure good contrast between foreground and background
- ✅ Test at small sizes (29x29 for settings)
- ✅ Use consistent styling across platforms
- ✅ Include app name consideration for accessibility

#### Don't:
- ❌ Use too many details (lost at small sizes)
- ❌ Use text that's too small to read
- ❌ Use complex gradients (may not render well)
- ❌ Use white icons on light backgrounds
- ❌ Include app screenshots or UI elements

---

## File Naming Conventions

### Android
```
ic_launcher_background.xml    # Background drawable
ic_launcher_foreground.xml    # Foreground vector
launcher_icon.xml             # Adaptive icon config (v26+)
ic_launcher.png               # Legacy launcher (various densities)
```

### iOS
```
Icon-App-[size]@[scale].png   # All icon sizes
Contents.json                 # Icon set configuration
```

---

## Testing Checklist

### Android Testing
- [ ] Test on Android 8.0+ (adaptive icons)
- [ ] Test on Android 7.0 and below (legacy icons)
- [ ] Verify icon appears correctly in app launcher
- [ ] Check icon in Google Play Store listing
- [ ] Test on different density screens

### iOS Testing
- [ ] Test on iPhone and iPad devices
- [ ] Verify icon in SpringBoard (home screen)
- [ ] Check icon in App Store Connect
- [ ] Test in Settings app
- [ ] Verify Spotlight search icon

---

## Design Tools Recommendations

1. **Adobe Illustrator** - Vector design, export to multiple formats
2. **Figma** - Collaborative design, auto-export to PNG
3. **Sketch** - Native macOS app, excellent for iOS icons
4. **Inkscape** - Free vector editor
5. **Android Asset Studio** - Generate Android icons from templates
6. **MakeAppIcon** - Generate icons for all platforms

---

## Asset Delivery Checklist

Before submitting to the repository:

- [ ] Android adaptive icon (XML foreground + background)
- [ ] Android legacy icons (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] iOS icon set (all required sizes)
- [ ] iOS Contents.json updated
- [ ] App Store icon (1024x1024 PNG)
- [ ] All files properly named and organized
- [ ] Tested on both platforms

---

## Resources

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Android Adaptive Icons](https://developer.android.com/guide/topics/ui/look-and-feel/adaptive-icon)
- [Google Play Icon Design Guidelines](https://developer.android.com/docs/guidelines/design/icon-design)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-31
**Author**: Roo (AI Assistant)
