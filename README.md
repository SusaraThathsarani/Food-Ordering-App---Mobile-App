# Food Order App

A Flutter mobile app for browsing food items, viewing details, and managing a cart.

## Prerequisites

- Flutter SDK (stable channel)
- Android Studio or VS Code with Flutter extensions
- A running backend API server (see `../food-item-backend`)

## Run The App

1. Install dependencies:

	 ```bash
	 flutter pub get
	 ```

2. Start a device or emulator.

3. Run the app:

	 ```bash
	 flutter run
	 ```

## Useful Commands

- Analyze code:

	```bash
	flutter analyze
	```

- Run tests:

	```bash
	flutter test
	```

## Project Structure

- `lib/main.dart`: app entry point
- `lib/pages/`: UI screens
- `lib/models/`: app data models
- `lib/providers/`: state management
- `assets/`, `images/`, `fonts/`: static resources

## Backend

The mobile app is designed to work with the Node.js backend in `../food-item-backend`.

Make sure the backend server is running and that API URLs used by the app match your local environment.
