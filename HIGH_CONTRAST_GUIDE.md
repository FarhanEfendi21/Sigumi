# High Contrast Mode Implementation Guide

## Status Implementasi

✅ **Core Theme System**
- High contrast theme created in `lib/config/theme.dart`
- Theme switching logic in `lib/main.dart`
- State management via `VolcanoProvider.highContrast`
- Accessibility toggle UI in `lib/screens/accessibility/accessibility_screen.dart`

✅ **Helper Tools**
- Theme extension: `lib/config/theme_extensions.dart`
- Adaptive widgets: `lib/widgets/adaptive_container.dart`

## Cara Menggunakan Theme Extension

### 1. Import Extension
```dart
import 'package:sigumi/config/theme_extensions.dart';
```

### 2. Ganti Hardcoded Colors

**SEBELUM:**
```dart
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Color(0xFF1E1E2C)),
  ),
)
```

**SESUDAH:**
```dart
Container(
  color: context.bgPrimary,
  child: Text(
    'Hello',
    style: TextStyle(color: context.textPrimary),
  ),
)
```

### 3. Available Context Extensions

#### Background Colors
- `context.bgPrimary` - Main background (white → black)
- `context.bgSecondary` - Secondary background
- `context.bgSurface` - Card/surface background

#### Text Colors
- `context.textPrimary` - Primary text
- `context.textSecondary` - Secondary text
- `context.textTertiary` - Tertiary/hint text
- `context.textLabel` - Label text

#### Accent Colors
- `context.accentPrimary` - Primary accent (blue → yellow)
- `context.accentSecondary` - Secondary accent

#### Borders & Dividers
- `context.borderColor` - Border color
- `context.dividerColor` - Divider color
- `context.borderWidth` - Border width (1px → 2px)

#### Status Colors
- `context.statusColor(level)` - Volcano status (1-4)
- `context.successColor` - Success/green
- `context.warningColor` - Warning/orange
- `context.errorColor` - Error/red
- `context.infoColor` - Info/blue

#### Shadows & Overlays
- `context.cardShadow` - Card shadow (disabled in HC)
- `context.overlayLight(opacity)` - Light overlay
- `context.overlayDark(opacity)` - Dark overlay

### 4. Menggunakan Adaptive Widgets

```dart
import 'package:sigumi/widgets/adaptive_container.dart';

// Adaptive container
AdaptiveContainer(
  padding: EdgeInsets.all(16),
  child: Text('Content'),
)

// Adaptive card with tap
AdaptiveCard(
  onTap: () {},
  child: Text('Clickable card'),
)
```

## Screens yang Perlu Update

### ⚠️ Priority High (Banyak Hardcoded Colors)
- [ ] `lib/screens/visual/visual_merapi_screen.dart`
- [ ] `lib/screens/tourism/tourism_screen.dart`
- [ ] `lib/screens/tourism/tourism_detail_screen.dart`
- [ ] `lib/screens/report/report_screen.dart`
- [ ] `lib/screens/post_disaster/post_disaster_screen.dart`

### ⚠️ Priority Medium
- [ ] `lib/screens/settings/settings_screen.dart`
- [ ] `lib/screens/home/home_screen.dart`
- [x] `lib/screens/map/map_screen.dart` ✅
- [x] `lib/screens/chatbot/chatbot_screen.dart` ✅
- [ ] `lib/screens/news/news_detail_screen.dart`

### ⚠️ Priority Low
- [ ] `lib/screens/onboarding/onboarding_screen.dart`
- [ ] `lib/screens/auth/login_screen.dart`
- [ ] `lib/screens/auth/register_screen.dart`

## Pattern untuk Update

### 1. Container Backgrounds
```dart
// Before
Container(color: Colors.white)
Container(color: Color(0xFFF5F7FA))

// After
Container(color: context.bgPrimary)
Container(color: context.bgSecondary)
```

### 2. Text Styles
```dart
// Before
Text('Title', style: TextStyle(color: Color(0xFF1E1E2C)))
Text('Body', style: TextStyle(color: Color(0xFF6B6B78)))

// After
Text('Title', style: TextStyle(color: context.textPrimary))
Text('Body', style: TextStyle(color: context.textTertiary))
```

### 3. Borders
```dart
// Before
Border.all(color: Color(0xFFE5E7EB))

// After
Border.all(
  color: context.borderColor,
  width: context.borderWidth,
)
```

### 4. Shadows
```dart
// Before
boxShadow: [
  BoxShadow(
    color: Colors.black.withAlpha(10),
    blurRadius: 10,
  ),
]

// After
boxShadow: context.cardShadow
```

### 5. Status/Semantic Colors
```dart
// Before
color: Colors.green.shade600
color: Colors.red.shade600

// After
color: context.successColor
color: context.errorColor
```

### 6. Overlays
```dart
// Before
color: Colors.white.withAlpha(30)
color: Colors.black.withAlpha(50)

// After
color: context.overlayLight(0.3)
color: context.overlayDark(0.5)
```

## Testing Checklist

Setelah update screen, test dengan:

1. ✅ Toggle high contrast di Accessibility screen
2. ✅ Cek semua text readable (contrast ratio)
3. ✅ Cek borders visible (2px di HC mode)
4. ✅ Cek buttons/interactive elements jelas
5. ✅ Cek status colors (volcano levels, alerts)
6. ✅ Cek navigation (bottom nav, app bar)
7. ✅ Cek forms (input fields, dropdowns)

## WCAG Compliance

High contrast theme designed untuk WCAG AAA:
- Text contrast ratio: 21:1 (white on black)
- Interactive elements: 7:1 minimum
- Borders: 2px width untuk visibility
- No shadows (dapat mengurangi clarity)

## Notes

- Theme switch otomatis rebuild seluruh app via Provider
- Settings persist ke Supabase (sync across devices)
- Font size scaling independent dari high contrast
- Gradient backgrounds disabled di high contrast mode

## Special Implementation Notes

### Map Screen (Peta Risiko)
Halaman peta memiliki implementasi khusus untuk memastikan peta tetap jelas terlihat:

**Yang TIDAK diubah (tetap jelas):**
- ✅ OpenStreetMap tile layer (tetap menggunakan tile asli)
- ✅ Risk radius circles (zona bahaya tetap terlihat dengan warna status)
- ✅ Volcano markers (warna status tetap vibrant untuk visibility)
- ✅ User location marker (biru untuk GPS real, abu untuk simulasi)

**Yang diubah (adaptive):**
- ✅ Blur top bar background dan text
- ✅ Map control buttons (floating buttons kanan)
- ✅ Primary info card (status zona & jarak)
- ✅ Risk bottom sheet (draggable sheet bawah)
- ✅ GPS status badge
- ✅ Dialog volcano details (primary & secondary)
- ✅ Snackbar notifications

**Strategi:**
- Peta base layer tetap menggunakan OpenStreetMap standard tiles
- Overlay UI (cards, buttons, sheets) menggunakan theme extensions
- Marker colors tetap menggunakan semantic colors (merah, kuning, hijau) untuk status
- Border width dan shadows adaptive untuk visibility

Hasil: Peta tetap jelas dan readable di kedua mode, dengan UI overlay yang adaptive.
