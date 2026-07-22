# Component Library: Localink Mobile App
Version 2.0.0 • Widget Specifications

This document outlines the catalog of reusable, premium widgets that construct the Localink application. All components inherit tokens from `DESIGN_SYSTEM.md` and use `'Material Symbols Rounded'` for icons.

---

## 1. Action Components (Buttons & FAB)

### A. AppButton
Standard primary/secondary CTA action button.
```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.icon,
  });
}
```
*   **Aesthetic specs:** Rounded pill contour (`radius-xl`), primary color fill (`color-primary`) or border line (`color-primary`), bold text (`font-button`). Contains a centered progress spinner if `isLoading` is active.

### B. AppIconButton
Circle tap button for headers and controls.
```dart
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });
}
```

---

## 2. Data Entry & Form Inputs

### A. AppTextField
Unified text input field replacing duplicate decoration schemes.
```dart
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });
}
```

### B. AppPhoneField
Phone input containing country selector.
```dart
class AppPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCode;
  final List<Map<String, String>> countryCodes;
  final ValueChanged<String> onCountryChanged;
  final String? Function(String?)? validator;

  const AppPhoneField({
    super.key,
    required this.controller,
    required this.selectedCode,
    required this.countryCodes,
    required this.onCountryChanged,
    this.validator,
  });
}
```

### C. AppDropdownField<T>
Minimal, styled dropdown button.
```dart
class AppDropdownField<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool isLoading;

  const AppDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isLoading = false,
  });
}
```

---

## 3. Navigation Containers

### A. AppAppBar
Unified screen header containing leading navigate icons and page titles.
```dart
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLeading;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
```

### B. AppBottomNavBar
Floating bar shell with rounded edges hosting tab views.
```dart
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavBarItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });
}

class AppNavBarItem {
  final IconData icon;
  final String label;
  const AppNavBarItem({required this.icon, required this.label});
}
```

---

## 4. Cards & Visual Boards

### A. AppBusinessCard
Minimal card listing business items.
```dart
class AppBusinessCard extends StatelessWidget {
  final String name;
  final String? category;
  final double rating;
  final int reviews;
  final String city;
  final String? photoUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const AppBusinessCard({
    super.key,
    required this.name,
    this.category,
    required this.rating,
    required this.reviews,
    required this.city,
    this.photoUrl,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });
}
```

### B. AppMetricsCard
Visually clean metric blocks displaying numbers and labels for business analytics.
```dart
class AppMetricsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppMetricsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = const Color(0xFFFF6600),
  });
}
```

---

## 5. Overlay dialogs & Sheets

### A. AppDialog
Standard prompt box dialog overlay.
```dart
class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });
}
```

### B. AppBottomSheet
Top-rounded modal container for filtering, closure forms, or voice search settings.
```dart
class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
}
```

---

## 6. Feedback & Interactive State Indicators

### A. AppShimmerLoader
Shimmer card simulator to act as a placeholder.
```dart
class AppShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });
}
```

### B. AppStateWidget
Consolidated status container rendering empty, error, or success feedback views.
```dart
enum AppStateType { empty, error, success }

class AppStateWidget extends StatelessWidget {
  final AppStateType type;
  final String title;
  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const AppStateWidget({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    this.buttonLabel,
    this.onButtonPressed,
  });
}
```
