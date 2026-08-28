# clean_bloc

A Flutter project generator for **Clean Architecture + BLoC**.

It scaffolds a complete, feature-first Flutter project from a configuration you
control — package name, Android `applicationId`, iOS bundle identifier, display
name, state management style and the exact set of packages — then keeps
generating features into it that match those choices.

Written in plain Dart with **zero dependencies**: it only uses `dart:io`, so it
runs (or compiles to a single binary) without fetching anything.

```bash
clean_bloc create shop_app --org com.acme --android-package com.acme.shop
```

## Install

```bash
git clone <this-repo> clean_bloc && cd clean_bloc
dart pub global activate --source path .
```

That puts a `clean_bloc` command on your PATH. Alternatives:

```bash
dart run bin/clean_bloc.dart <command>              # straight from the repo
dart compile exe bin/clean_bloc.dart -o clean_bloc  # standalone binary
```

Requires the Dart SDK ^3.5 (any Flutter install includes one). `flutter` must be
on the PATH for `create` to produce the native platform folders.

## Commands

| Command | What it does |
| --- | --- |
| `create [name]` | Scaffolds a project. Interactive unless `-y` or `--config`. |
| `feature <name>` | Adds a feature slice to an existing project and wires it up. |
| `rename` | Changes the Android package, iOS bundle id and display name. |
| `config [path]` | Writes a `clean_bloc.yaml` you can edit and reuse. |
| `packages` | Lists the packages the current configuration selects. |
| `help` | Full option reference. |

Common flags: `-y/--yes` (never prompt), `--dry-run`, `--force`,
`--no-flutter-create`, `--pub-get`.

## Initial setup

`clean_bloc create` walks through the whole setup interactively. Everything it
asks is also available as a flag:

```bash
clean_bloc create shop_app -y \
  --org com.acme \
  --display-name "Shop App" \
  --android-package com.acme.shop \
  --ios-bundle-id com.acme.shop \
  --platforms android,ios \
  --min-sdk 23 --ios-target 13.0 \
  --state bloc --locales en,ne
```

It runs `flutter create` for the chosen platforms, writes the architecture on
top, and rewrites every native identifier:

| Setting | Applied to |
| --- | --- |
| `--name` | pubspec `name`, every `package:` import |
| `--display-name` | `android:label`, `CFBundleDisplayName`, web title, `MaterialApp.title` |
| `--android-package` | `namespace`, `applicationId`, and the `MainActivity` package — the file is moved into its new directory |
| `--ios-bundle-id` | `PRODUCT_BUNDLE_IDENTIFIER` for Runner and RunnerTests, plus the macOS `AppInfo.xcconfig` |
| `--min-sdk` | `minSdk` in `android/app/build.gradle.kts` |
| `--ios-target` | `IPHONEOS_DEPLOYMENT_TARGET` and the Podfile platform |
| `--platforms` | which platform folders `flutter create` produces |

Android and iOS identifiers are independent, because Xcode rejects underscores
in bundle ids. By default `my_app` becomes `com.example.my_app` on Android and
`com.example.myApp` on iOS — the same convention `flutter create` uses.

To change them on an existing project later:

```bash
clean_bloc rename --android-package com.acme.market \
  --ios-bundle-id com.acme.market --display-name "Acme Market"
```

`rename` reads the current values out of the project first, so it also works on
projects this tool did not generate.

## Package selection

Modules decide which packages land in the pubspec — the generated project never
carries a dependency its code does not use. Disable any of them with
`--no-<name>`:

| Module | Packages | Adds |
| --- | --- | --- |
| `network` | `dio`, `pretty_dio_logger` | `ApiClient`, the interceptor stack, remote data sources |
| `connectivity` | `internet_connection_checker` | `NetworkInfo`, offline handling |
| `env` | `flutter_dotenv` | `.env` + `.env.example`, base-url wiring |
| `routing` | `go_router` | `AppRouter` with named routes |
| `localization` | `easy_localization`, `flutter_localizations`, `intl` | JSON translations per locale |
| `responsive` | `flutter_screenutil` | `ScreenUtilInit` with your design size |
| `theming` | — | `AppTheme` light/dark Material 3 |
| `logger` | `logger` | `AppLogger` wrapper |
| `prefs` | `shared_preferences` | local data sources, cache-on-failure |
| `secure_storage` | `flutter_secure_storage` | `SecureStorageService` + Dio auth interceptor |
| `firebase` | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | `PushNotificationService` |
| `flavors` | `flutter_flavorizr` | dev/stg/prod flavor config |
| `example_feature` | — | a complete worked feature |
| `tests` | — | unit tests for the generated blocs/cubits |

Add or pin anything else:

```bash
clean_bloc create app --add "freezed_annotation:^2.4.4" \
  --add-dev "bloc_test:^9.1.7" --pin "dio:^5.7.0"
```

Preview the resolution before generating:

```bash
clean_bloc packages [--config clean_bloc.yaml]
```

## Repeatable configuration

```bash
clean_bloc config clean_bloc.yaml    # write a config file
# edit it
clean_bloc create --config clean_bloc.yaml -y
```

```yaml
project:
  name: shop_app
  display_name: "Shop App"
  org: com.acme
  version: 1.0.0+1

platforms:
  targets: [android, ios]
  android:
    package: com.acme.shop
    min_sdk_version: 23
  ios:
    bundle_id: com.acme.shop
    deployment_target: "13.0"

architecture:
  state_management: bloc      # bloc | cubit

app:
  base_url: https://api.acme.com
  design_width: 375
  design_height: 812

locales: [en, ne]

modules:
  network: true
  firebase: false
  # ...

dependencies:
  overrides:
    dio: ^5.7.0
  extra:
    freezed_annotation: ^2.4.4
```

`create` also drops a `clean_bloc.yaml` into the generated project, so
`clean_bloc feature` later reads it and keeps new slices consistent. Without
that file it infers the settings from `pubspec.yaml` and the existing folders.

## Adding features

Run inside a generated project:

```bash
clean_bloc feature product
clean_bloc feature cart --state cubit --no-local
```

Each run writes the full slice:

```
lib/features/product
├── data
│   ├── datasources    product_remote_data_source(_impl).dart
│   │                  product_local_data_source(_impl).dart
│   ├── models         product_model.dart
│   └── repositories   product_repository_impl.dart
├── domain
│   ├── entities       product_entity.dart
│   ├── repositories   product_repository.dart
│   └── usecases       get_products.dart
└── presentation
    ├── bloc           product_bloc / _event / _state.dart
    ├── pages          product_page.dart
    └── widgets        product_list_item.dart
test/features/product/product_bloc_test.dart
```

…and wires it in: registrations into `injection_container.dart`, the provider
into `app.dart`, the route into `app_router.dart`, and keys into every
translation file. Wiring is anchored on `// clean_bloc:` marker comments and is
idempotent — re-running skips existing files and never inserts a registration
twice.

Options: `--state bloc|cubit`, `--no-remote`, `--no-local`, `--no-page`,
`--no-tests`, `--no-wire`, `--path <dir>`.

## Generated architecture

```
lib
├── app.dart                 MaterialApp shell
├── main.dart                bootstrap (l10n, .env, Firebase, Bloc.observer, DI)
├── injection_container.dart get_it registrations, layered
├── core
│   ├── bloc                 AppBlocObserver
│   ├── constants            app + endpoint constants
│   ├── error                AppException hierarchy, Failure hierarchy
│   ├── network
│   │   ├── api_client.dart  Dio factory
│   │   ├── api_endpoints.dart
│   │   ├── network_info.dart
│   │   └── interceptors     auth / error / retry / headers
│   ├── notifications        push notifications
│   ├── router               go_router, blocs scoped per route
│   ├── storage              secure storage
│   ├── theme                light / dark themes
│   ├── usecases             UseCase contract
│   └── utils                logger
└── features
    └── <feature>
        ├── data             models, remote + local data sources, repository impl
        ├── domain           entities, repository contract, use cases
        └── presentation     bloc/cubit, pages, widgets
```

### The rules the generated code follows

**Dependencies point inward.** `presentation → domain ← data`. The domain layer
imports nothing from the other two; the repository *contract* lives in `domain`
and its implementation in `data`.

**Errors change shape at the boundary.** Data sources throw typed
`AppException`s (`ServerException`, `UnauthorizedException`,
`RequestTimeoutException`, `CacheException`, …). Repositories catch them and
return `Either<Failure, T>` via `Failure.from(error)`. Nothing above the
repository ever catches an exception.

**Blocs are pure presentation logic.** They call use cases and emit states —
no Dio, no SharedPreferences, no `BuildContext`. States are `sealed` classes, so
the UI's `switch` is exhaustive and a new state is a compile error until it is
handled.

**Events are transformed, not queued blindly.**

```dart
on<LoadProducts>(_onLoad, transformer: droppable());     // ignore double taps
on<RefreshProducts>(_onRefresh, transformer: restartable()); // supersede
```

**Blocs live exactly as long as their screen.** With routing enabled, each route
creates its bloc from the service locator and disposes it on pop:

```dart
GoRoute(
  path: ProductPage.routePath,
  builder: (context, state) => BlocProvider(
    create: (_) => sl<ProductBloc>()..add(const LoadProducts()),
    child: const ProductPage(),
  ),
),
```

**`AppBlocObserver`** logs every event, transition and unhandled bloc error in
one place, installed in `main` before `runApp`.

### The interceptor stack

`ApiClient.create` composes them in order — outbound top to bottom, inbound
bottom to top:

| Interceptor | Responsibility |
| --- | --- |
| `HeadersInterceptor` | `Accept-Language` from the app's locale, plus any static headers |
| `AuthInterceptor` | attaches the bearer token; on a 401 refreshes once and replays the request. Extends `QueuedInterceptor`, so parallel 401s trigger a single refresh instead of a stampede |
| `RetryInterceptor` | linear backoff for timeouts, dropped connections and 5xx — only on `GET`/`HEAD`/`OPTIONS`, so a `POST` is never sent twice |
| `ErrorInterceptor` | maps `DioException` onto the app's `AppException` types, reading `message` / `errors` out of the response body |
| `PrettyDioLogger` | debug builds only (behind an `assert`), last so it sees everything |

The refresh call uses a second, interceptor-free `Dio` registered under
`instanceName: refreshClient`, so a failing refresh cannot recurse.

### Dependency injection

`injection_container.dart` registers in dependency order — external packages,
then core services, then one block per feature:

```dart
Future<void> init() async {
  await _registerExternal();  // SharedPreferences, SecureStorage, connectivity
  _registerCore();            // NetworkInfo, Dio + its interceptors
  _registerFeatures();        // bloc -> use cases -> repository -> data sources
}
```

Blocs are `registerFactory` (a fresh instance per screen); everything below
them is a lazy singleton. `clean_bloc feature` appends a new block at the
`// clean_bloc:registrations` marker.

## Offline behaviour

With both `network` and `prefs` enabled, repositories cache every successful
remote read and fall back to that cache when the request fails or the device is
offline — so a failed refresh shows stale data plus a snackbar rather than an
error screen.

## How it works

| Path | Role |
| --- | --- |
| [bin/clean_bloc.dart](bin/clean_bloc.dart) | CLI: argument parsing, prompts, command dispatch |
| [lib/src/config.dart](lib/src/config.dart) | `ProjectConfig` / `FeatureConfig`, validation, YAML I/O |
| [lib/src/packages.dart](lib/src/packages.dart) | module → pub package registry |
| [lib/src/engine.dart](lib/src/engine.dart) | mustache-style renderer (`{{var}}`, `{{#flag}}`) |
| [lib/src/templates/](lib/src/templates/) | project and feature templates |
| [lib/src/project_generator.dart](lib/src/project_generator.dart) | runs `flutter create`, writes the project |
| [lib/src/feature_generator.dart](lib/src/feature_generator.dart) | writes a feature slice and wires it in |
| [lib/src/native.dart](lib/src/native.dart) | rewrites Android/iOS/macOS/web/Linux identifiers |
| [lib/src/detect.dart](lib/src/detect.dart) | recovers the configuration of an existing project |
| [lib/src/writer.dart](lib/src/writer.dart) | file writing, `--dry-run`/`--force`, marker patching |

Templates are embedded as raw Dart strings, so a compiled `clean_bloc` binary is
fully self-contained.

## License

See [LICENSE](LICENSE).
