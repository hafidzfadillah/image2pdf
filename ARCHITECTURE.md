# Project Architecture

This document describes the project structure and architecture decisions.

## Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/                              # Core functionality
│   ├── constants/                     # App-wide constants
│   │   └── app_constants.dart
│   ├── theme/                         # Theme configuration
│   │   └── app_theme.dart
│   └── utils/                         # Utility functions
│       └── platform_utils.dart
│
├── features/                          # Feature-based modules
│   ├── camera/                        # Camera feature
│   │   ├── screens/
│   │   │   └── camera_screen.dart
│   │   └── widgets/
│   │       └── captured_image_list.dart
│   └── pdf/                           # PDF feature
│       └── screens/
│           └── preview_screen.dart
│
├── services/                          # Business logic services
│   ├── permission_service.dart        # Permission handling
│   ├── storage_service.dart           # File storage operations
│   └── pdf_service.dart               # PDF generation logic
│
└── widgets/                           # Shared/reusable widgets
    └── common/                        # Common widgets across features
```

## Architecture Principles

### 1. Feature-Based Organization
- Each feature is self-contained in its own folder
- Features can have their own screens, widgets, models, and services
- Easy to add new features without affecting existing code

### 2. Separation of Concerns
- **Core**: App-wide constants, theme, and utilities
- **Features**: Feature-specific UI and logic
- **Services**: Reusable business logic that can be used across features
- **Widgets**: Shared UI components

### 3. Scalability
- New features can be added by creating a new folder under `features/`
- Services can be extended or new ones added without breaking existing code
- Common widgets can be shared across features

## Adding a New Feature

To add a new feature:

1. Create a new folder under `features/`:
   ```
   lib/features/your_feature/
   ├── screens/
   ├── widgets/
   ├── models/        # Optional
   └── services/      # Optional (if feature-specific)
   ```

2. If the feature needs shared business logic, add it to `services/`

3. If the feature has reusable widgets, add them to `widgets/common/`

## Service Layer

Services handle business logic and are platform-agnostic where possible:

- **PermissionService**: Handles all permission requests
- **StorageService**: Handles file storage operations (abstracts platform differences)
- **PdfService**: Handles PDF generation and management

## Core Layer

The core layer contains app-wide configurations:

- **Constants**: All app-wide constants (file names, channel names, etc.)
- **Theme**: Theme configuration (light/dark themes)
- **Utils**: Utility functions (platform detection, etc.)

## Benefits of This Structure

1. **Easy to Navigate**: Clear separation makes it easy to find code
2. **Scalable**: New features don't clutter existing code
3. **Testable**: Services can be easily unit tested
4. **Maintainable**: Changes to one feature don't affect others
5. **Reusable**: Services and widgets can be shared across features

## Future Enhancements

Potential additions as the project grows:

- `lib/models/` - Shared data models
- `lib/repository/` - Data repositories (if adding backend)
- `lib/routes/` - Route configuration (if using named routes)
- `lib/state/` - State management (if using Provider, Riverpod, etc.)
- `lib/config/` - App configuration files

