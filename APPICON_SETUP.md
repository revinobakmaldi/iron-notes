# App Icon Setup

The AppIcon.svg and AppIcon-Tinted.svg files contain app icon designs for IronNotes.

## Icon Design

### Primary Icon (AppIcon.svg)
- **Theme**: Dark theme with blue accent (matching app color scheme)
- **Symbol**: Dumbbell representing fitness and strength training
- **Colors**:
  - Background: Black (#000000)
  - Primary: Blue (#2196F3)
  - Secondary: Darker Blue (#1976D2)

### Tinted Icon (AppIcon-Tinted.svg)
- **Theme**: Monochrome/black-white design for system tinting
- **Use**: Settings, Spotlight, Notifications, Widgets
- **Colors**:
  - Primary: White (#ffffff)
  - Secondary: Black (#000000)
- **Note**: iOS will automatically tint this icon based on context (system theme, app accent color)

## Converting SVG to Required Sizes

To use this icon in your iOS app, you need to convert it to PNG format in multiple sizes:

### Required Sizes:
- 1024x1024 (App Store icon)
- 180x180 (iPhone @3x)
- 167x167 (iPad Pro @2x)
- 152x152 (iPad @2x)
- 120x120 (iPhone @3x)
- 87x87 (iPhone @3x)
- 80x80 (iPad @2x, iPhone @2x)
- 76x76 (iPad @1x)
- 60x60 (iPhone @2x)
- 58x58 (iPhone @2x)
- 40x40 (iPad @1x)
- 29x29 (iPhone @1x, @2x, @3x)
- 20x20 (iPad @1x, @2x)

### Conversion Options:

#### Option 1: Online Tool
1. Visit https://makeappicon.com/
2. Upload AppIcon.svg
3. Download the complete icon set
4. Extract and place in Xcode project

#### Option 2: macOS Terminal
```bash
# Install ImageMagick if not already installed
brew install imagemagick

# Convert SVG to all required sizes
sips -z 1024 1024 AppIcon.svg --out AppIcon_1024x1024.png
sips -z 180 180 AppIcon.svg --out AppIcon_180x180.png
sips -z 167 167 AppIcon.svg --out AppIcon_167x167.png
sips -z 152 152 AppIcon.svg --out AppIcon_152x152.png
sips -z 120 120 AppIcon.svg --out AppIcon_120x120.png
sips -z 87 87 AppIcon.svg --out AppIcon_87x87.png
sips -z 80 80 AppIcon.svg --out AppIcon_80x80.png
sips -z 76 76 AppIcon.svg --out AppIcon_76x76.png
sips -z 60 60 AppIcon.svg --out AppIcon_60x60.png
sips -z 58 58 AppIcon.svg --out AppIcon_58x58.png
sips -z 40 40 AppIcon.svg --out AppIcon_40x40.png
sips -z 29 29 AppIcon.svg --out AppIcon_29x29.png
sips -z 20 20 AppIcon.svg --out AppIcon_20x20.png
```

#### Option 3: Image Editor
1. Open AppIcon.svg in Sketch, Figma, or Adobe Illustrator
2. Export to PNG in all required sizes
3. Or use Preview app (macOS):
   - Open AppIcon.svg in Preview
   - File > Export
   - Select different dimensions and save

## Adding to Xcode Project

1. Open your Xcode project
2. Navigate to `IronNotes/Assets.xcassets/AppIcon.appiconset`
3. Drag and drop PNG files into corresponding slots in the Assets catalog
4. For iOS 18+, the tinted version will be automatically generated from the primary icon
5. For earlier iOS versions, you can optionally add the tinted icon manually
6. Or manually edit `Contents.json` in AppIcon.appiconset directory

### Example Contents.json (iOS 18+ - Auto Tint):
```json
{
  "images" : [
    {
      "filename" : "1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### Example Contents.json (with manual tinted icon):
```json
{
  "images" : [
    {
      "filename" : "1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "light"
        }
      ],
      "filename" : "1024-tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```
```json
{
  "images" : [
    {
      "filename" : "1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "filename" : "180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    // ... add all other sizes
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

## Using AppIconSet Generator (Recommended)

The easiest way is to use an appiconset generator:
1. Download "AppIconSet Generator" from Mac App Store (free)
2. Drag AppIcon.svg onto the app
3. It will generate all sizes and create the appiconset automatically
4. Drag the generated appiconset into your Xcode project

## Testing the Icon

After adding the icon:
1. Clean build folder (Cmd+Shift+K)
2. Build and run the app
3. Check the home screen for the new icon
4. For App Store preview, go to Product > Archive > Distribute App