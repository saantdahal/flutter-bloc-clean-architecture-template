# Flutter BLoC Clean Architecture Template

A comprehensive Flutter project template implementing Clean Architecture with BLoC (Business Logic Component) pattern. This template provides a solid foundation for building scalable, maintainable, and testable Flutter applications.

## Architecture Overview

This template follows the principles of **Clean Architecture** as proposed by Robert C. Martin, combined with the **BLoC pattern** for state management. The architecture is divided into three main layers:

### Presentation Layer

- **BLoC**: Handles business logic and state management
- **Pages**: UI screens and navigation
- **Widgets**: Reusable UI components

### Domain Layer

- **Entities**: Core business objects
- **Use Cases**: Application-specific business rules
- **Repositories**: Abstract data interfaces

### Data Layer

- **Models**: Data transfer objects
- **Data Sources**: Concrete implementations for data retrieval
- **Repositories**: Data access implementations

## Project Structure

The template is **feature-first**: shared code lives under `core/`, and every
feature owns its full data/domain/presentation stack under `features/<name>/`.

```
lib
├── core
│   ├── error
│   │   └── failures.dart
│   ├── network
│   │   ├── network_info.dart
│   │   └── network_info_impl.dart
│   ├── router
│   │   └── app_router.dart
│   └── usecases
│       └── usecase.dart
├── features
│   └── example
│       ├── data
│       │   ├── datasources
│       │   │   ├── example_remote_datasource.dart
│       │   │   └── example_remote_datasource_impl.dart
│       │   ├── models
│       │   │   └── example_model.dart
│       │   └── repositories
│       │       └── example_repository_impl.dart
│       ├── domain
│       │   ├── entities
│       │   │   └── example_entity.dart
│       │   ├── repositories
│       │   │   └── example_repository.dart
│       │   └── usecases
│       │       └── get_examples.dart
│       └── presentation
│           ├── blocs
│           │   ├── example_bloc.dart
│           │   ├── example_event.dart
│           │   └── example_state.dart
│           ├── pages
│           │   └── home_page.dart
│           └── widgets
│               └── example_widget.dart
├── injection_container.dart
└── main.dart
```

To add a new feature, mirror the `example` folder under `features/<name>/`.

## Dependencies

### Core Dependencies

- **flutter_bloc**: ^9.1.1 - State management
- **equatable**: ^2.0.5 - Value equality
- **get_it**: ^7.7.0 - Dependency injection (manual registration in `lib/injection_container.dart`)
- **dartz**: ^0.10.1 - Functional programming utilities

### Networking & Data

- **dio**: ^5.7.0 - HTTP client
- **retrofit**: ^4.4.1 - Type-safe HTTP client
- **json_annotation**: ^4.8.1 - JSON serialization

### UI & Utilities

- **flutter_screenutil**: ^5.9.3 - Responsive UI
- **cached_network_image**: ^3.2.0 - Image caching
- **loading_animation_widget**: ^1.2.0 - Loading animations
- **flutter_svg**: ^2.2.1 - SVG support

### Localization & Navigation

- **easy_localization**: ^3.0.7 - Internationalization
- **go_router**: ^14.2.8 - Declarative routing

### Firebase & Notifications

- **firebase_core**: ^4.1.1 - Firebase core
- **firebase_messaging**: ^16.0.2 - Push notifications
- **flutter_local_notifications**: ^17.2.3 - Local notifications

### Security & Storage

- **flutter_secure_storage**: ^9.2.2 - Secure storage
- **shared_preferences**: ^2.3.2 - Local storage

### Development Dependencies

- **build_runner**: ^2.4.13 - Code generation
- **json_serializable**: ^6.8.0 - JSON code generation
- **injectable_generator**: ^2.6.2 - Dependency injection code generation
- **retrofit_generator**: ^9.1.2 - Retrofit code generation
- **mockito**: ^5.4.4 - Mocking for tests

## Getting Started

### Prerequisites

- Flutter SDK (^3.5.2)
- Dart SDK (^3.5.2)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/flutter-bloc-clean-architecture-template.git
   cd flutter-bloc-clean-architecture-template
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code**

   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Setup

1. Copy `.env.example` to `.env` and configure your environment variables:

   ```bash
   cp .env.example .env
   ```

   ```env
   API_BASE_URL=https://jsonplaceholder.typicode.com
   ```

   `.env` is loaded on startup via `flutter_dotenv` (see `lib/main.dart`) and
   `API_BASE_URL` is used to configure the shared `Dio` client's base URL in
   `lib/injection_container.dart`. `.env` is gitignored — only `.env.example`
   is committed.

2. For Firebase integration:
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

## Usage

### Adding a New Feature

1. **Create Entity** (Domain Layer)

   ```dart
   class NewEntity extends Equatable {
     final String id;
     final String name;

     const NewEntity({required this.id, required this.name});

     @override
     List<Object> get props => [id, name];
   }
   ```

2. **Create Repository Interface** (Domain Layer)

   ```dart
   abstract class NewRepository {
     Future<Either<Failure, List<NewEntity>>> getNews();
   }
   ```

3. **Implement Use Case** (Domain Layer)

   ```dart
   class GetNews implements UseCase<List<NewEntity>, NoParams> {
     final NewRepository repository;

     GetNews(this.repository);

     @override
     Future<Either<Failure, List<NewEntity>>> call(NoParams params) {
       return repository.getNews();
     }
   }
   ```

4. **Create BLoC** (Presentation Layer)

   ```dart
   class NewBloc extends Bloc<NewEvent, NewState> {
     final GetNews getNews;

     NewBloc({required this.getNews}) : super(NewInitial()) {
       on<GetNewsEvent>((event, emit) async {
         emit(NewLoading());
         final result = await getNews(NoParams());
         result.fold(
           (failure) => emit(NewError()),
           (news) => emit(NewLoaded(news)),
         );
       });
     }
   }
   ```

5. **Register Dependencies**
   Add to `lib/injection_container/injection_container.dart`:
   ```dart
   sl.registerFactory(() => NewBloc(getNews: sl()));
   sl.registerLazySingleton(() => GetNews(sl()));
   // ... other registrations
   ```

### State Management

The template uses BLoC pattern for state management. Each feature has its own BLoC with events and states:

- **Events**: User actions or system events
- **States**: UI states (loading, loaded, error)
- **BLoC**: Business logic and state transitions

### Networking

Uses Dio for HTTP requests with Retrofit for type-safe API calls. The shared
`Dio` instance is registered once in `lib/injection_container.dart` with its
`baseUrl` read from `.env` and a `PrettyDioLogger` interceptor attached, so
data sources issue relative requests:

```dart
final response = await dio.get('/posts');
```

For a type-safe API layer, define a Retrofit interface:

```dart
@RestApi()
abstract class ApiService {
  @GET("/posts")
  Future<List<PostModel>> getPosts();
}
```

### Routing

Uses `go_router` for declarative navigation. Routes are declared in
`lib/core/router/app_router.dart` and consumed by `MaterialApp.router` in
`lib/main.dart`:

```dart
GoRoute(
  path: '/',
  name: 'home',
  builder: (context, state) => const HomePage(),
),
```

### Localization

Supports multiple languages using easy_localization, initialized in
`lib/main.dart` with `en`/`ne` as the supported locales:

```dart
Text('press_button_to_load'.tr()), // Uses translation keys
```

Add translation keys to `assets/translations/en.json` and
`assets/translations/ne.json`.

### Responsive UI

Uses `flutter_screenutil` for responsive sizing. `main.dart` wraps the app in
a `ScreenUtilInit`, after which `.w`, `.h`, `.sp`, etc. extensions are
available on `num` throughout the app.

## Testing

Run tests:

```bash
flutter test
```

Run integration tests:

```bash
flutter test integration_test/
```

## Scripts

- `flutter pub run build_runner build` - Generate code
- `flutter pub run build_runner watch` - Watch for changes and regenerate
- `flutter pub run flutter_launcher_icons` - Generate app icons

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Reso Coder](https://resocoder.com/) for Clean Architecture tutorials
- [Flutter BLoC](https://bloclibrary.dev/) for state management
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) by Robert C. Martin
