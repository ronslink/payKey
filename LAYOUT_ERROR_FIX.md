# Layout Error Fix - RenderShrinkWrappingViewport

## Problem
When opening the payroll review page, the console showed multiple errors:
```
RenderShrinkWrappingViewport does not support returning intrinsic dimensions.
Cannot hit test a render box that has never been laid out.
Assertion failed: mouse_tracker.dart:199:12
```

## Root Cause
The error was caused by using `IntrinsicHeight` with a `ListView` that has `shrinkWrap: true`. 

### The Problematic Code:
```dart
body: LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(  // ❌ Problem starts here
          child: Column(
            children: [
              // ... other widgets ...
              _buildRecordsSection(),  // Contains ListView with shrinkWrap: true
            ],
          ),
        ),
      ),
    );
  },
)
```

Inside `_buildRecordsSection()`:
```dart
ListView.separated(
  shrinkWrap: true,  // ❌ This + IntrinsicHeight = ERROR
  physics: const NeverScrollableScrollPhysics(),
  // ...
)
```

## Why This Causes Errors

`IntrinsicHeight` tries to calculate the natural height of its children by asking them for their intrinsic dimensions. However, `ListView` with `shrinkWrap: true` creates a `RenderShrinkWrappingViewport`, which **cannot** provide intrinsic dimensions because it doesn't know its size until it's laid out.

This creates a circular dependency:
1. `IntrinsicHeight` asks: "How tall are you?"
2. `ListView` responds: "I don't know until you lay me out"
3. `IntrinsicHeight` says: "But I need to know to lay you out!"
4. 💥 **Error!**

## Solution

Remove the `IntrinsicHeight` and `ConstrainedBox` wrappers. They weren't necessary because:
- `SingleChildScrollView` already handles scrolling
- `Column` with `shrinkWrap: true` ListView works fine without `IntrinsicHeight`

### Fixed Code:
```dart
body: LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(  // ✅ Direct Column, no wrappers
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_statistics != null) _buildSummarySection(),
          const SizedBox(height: 24),
          _buildRecordsSection(),  // ListView works fine now
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  },
)
```

## Changes Made

**File**: `mobile/lib/features/payroll/presentation/pages/payroll_review_page.dart`

**Removed**:
- `ConstrainedBox` wrapper
- `IntrinsicHeight` wrapper

**Kept**:
- `LayoutBuilder` (for responsive design)
- `SingleChildScrollView` (for scrolling)
- `Column` (for vertical layout)
- `ListView` with `shrinkWrap: true` (works fine without IntrinsicHeight)

## Benefits

1. ✅ **No More Layout Errors**: Removed the circular dependency
2. ✅ **Better Performance**: Less widget nesting
3. ✅ **Simpler Code**: Fewer unnecessary wrappers
4. ✅ **Same Visual Result**: Page looks identical

## Testing

The page should now:
- ✅ Load without console errors
- ✅ Display all sections correctly
- ✅ Scroll smoothly
- ✅ Handle mouse/touch events properly

## Common Flutter Layout Rules

**❌ Don't Do This:**
```dart
IntrinsicHeight(
  child: Column(
    children: [
      ListView(shrinkWrap: true),  // ERROR!
    ],
  ),
)
```

**✅ Do This Instead:**
```dart
Column(
  children: [
    ListView(shrinkWrap: true),  // Works fine
  ],
)
```

Or if you need intrinsic sizing:
```dart
IntrinsicHeight(
  child: Column(
    children: [
      // Use widgets that support intrinsic dimensions
      Text('...'),
      Container(height: 100),
      // NOT ListView, GridView, or other viewports
    ],
  ),
)
```

## Status
✅ **FIXED** - The payroll review page now loads without layout errors!
