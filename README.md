# Hyperbolic Drawing Tool

An interactive, cross-platform Flutter application for constructing,
visualizing, and exploring hyperbolic geometry diagrams in the Poincarédisk
model.

Built for both Web and Android, Hyperbolic provides straightedge-and-compass
constructions adapted to non-Euclidean space, backed by a bipartite constraint
graph and numerical inverse solver.

-------------------------------------------------------------------------------

## Documentation

Comprehensive documentation is available in the `doc/` directory:

- [doc/about.md](doc/about.md) : Project history, version notes, and author
  attribution.

- [doc/overview.md](doc/overview.md) : Mathematical principles of the Poincaré
  disk, hyperbolic distance, geodesics, and isometries.

- [doc/controls.md](doc/controls.md) : Guide to toolbar tools, modes, pan/zoom
  gestures, and shortcuts.

- [doc/objects.md](doc/objects.md) : Geometric entities including points,
  hyperbolic lines, rays, segments, and circles.

- [doc/files.md](doc/files.md) : Saving, loading, JSON schema, and Google Drive
  synchronization.

- [doc/privacy.md](doc/privacy.md) : Application privacy policy and local
  storage disclosure.

- [doc/terms.md](doc/terms.md) : Terms of service.

-------------------------------------------------------------------------------

## 1. Overview for Developers

This project is designed as a modular, extensible geometric drawing engine.
Developers interested in extending Hyperbolic, adding new geometric
constructions, or forking the codebase to create a new interactive drawing tool
will find a cleanly partitioned architecture separating geometric modeling,
constraint satisfaction, coordinate transforms, and UI rendering.

### Key Architectural Components

- **PoincaréDisk Canvas (`lib/scene/scene_view.dart`)**: Custom painter
  (`DiskPainter`) rendering geodesics (orthogonal circular arcs and diameters),
  hyperbolic circles, points, and selection highlights. Supports both Euclidean
  zoom/pan and hyperbolic translation via Möbius automorphisms
  ($z \mapsto \frac{z - a}{1 - \bar{a} z}$).

- **Bipartite Constraint Graph (`lib/constraints/`)**: Maintains an alternating
  directed acyclic graph of geometric/numeric scene objects (`PointObject`,
  `LineObject`, `CircleObject`, `NumberObject`) and constraint nodes
  (`FreePointConstraint`, `TwoPointLineConstraint`, `IntersectionConstraint`,
  etc.).

- **Topological Forward Evaluation & Inverse Solver**: Changes to ancestor
  parameters propagate forward in topological order. An inverse solver computes
  the Jacobian to allow direct dragging of derived or constrained objects while
  strictly respecting locked objects.

- **Split View & Numeric Parameters**: Adaptive split layout (`SplitterWidget`,
  `lib/splitter.dart`, `lib/widgets/number_panel.dart`) showing numeric
  parameters, hyperbolic distances, coordinates, and angles, paired with
  continuous sliders (`MySlider`).

- **File Storage & Cloud Sync**: Storage abstraction (`lib/file_manager.dart`,
  `lib/file_holder.dart`) supporting local file exports/imports, browser
  storage, clipboard JSON, and Google Drive REST API v3 sync.

- **Macro & Tutorial Engine (`lib/script/`, `lib/tutorial_widget.dart`)**:
  Markdown-driven interactive tutorial and macro system that guides users
  through step-by-step constructions and validates scene criteria in real time.

-------------------------------------------------------------------------------

## 2. Directory Structure

``` text
lib/
├── constraints/     # Bipartite constraint nodes & DAG solver
├── drive/           # Google Drive REST API integration & OAuth
├── objects/         # Scene objects (points, lines, circles, numbers)
├── scene/           # Canvas painter, scene data model, canvas controller
├── script/          # Interactive tutorial parser & criteria evaluator
├── widgets/         # App scaffold, toolbar, number panel, dialogs
├── edit.dart        # Undo/redo stack (MyUndoManager)
├── file_holder.dart # Storage driver abstractions
├── file_manager.dart# Document lifecycle and dirty-state tracking
├── transform.dart   # Poincaré metric, geodesics, circles & Möbius math
└── my_app.dart      # GoRouter routes and application entry configuration

doc/                 # User-facing Markdown documentation (compiled to HTML)
assets/              # Icons, styling, and bundled tutorial/help HTML
test/                # Comprehensive unit and widget test suite
```

-------------------------------------------------------------------------------

## 3. Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)

- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)

- `pandoc` (required for compiling markdown documentation into HTML assets)

### Forking and Cloning

1.  Fork the repository on GitHub to your account.

2.  Clone your fork locally:

    ``` bash
    git clone https://github.com/<your-username>/hyperbolic.git
    cd hyperbolic
    ```

3.  Install Flutter dependencies:

    ``` bash
    flutter pub get
    ```

4.  Compile documentation assets:

    ``` bash
    make docs
    ```

### Running Locally

To launch the web app in Chrome:

``` bash
./run-local-server.sh
```

Or directly via Flutter:

``` bash
flutter run -d chrome
```

### Running Tests

Run the full automated test suite:

``` bash
flutter test
```

Targeted test suites include:

- Math & transforms: `flutter test test/transform_test.dart`

- Constraint graph: `flutter test test/constraint_test.dart`

- Undo/redo engine: `flutter test test/undo_test.dart`

- File management: `flutter test test/local_file_test.dart`

- UI & canvas: `flutter test test/widget_test.dart`

-------------------------------------------------------------------------------

## 4. Build & Asset Automation

The project uses `make` to coordinate asset compilation, documentation builds,
and version updates:

- `make docs`: Compiles `doc/*.md` into `assets/*.html` and root documents into
  `assets/dev/*.html` via `pandoc`.

- `make ASSETS`: Regenerates icons, version metadata, and compiled HTML docs.

- `roll_build_number.sh`: Increments build number in `pubspec.yaml`.

- `roll_build_number.sh --release`: Increments release patch version and resets
  build number.

-------------------------------------------------------------------------------

## 5. Documentation & Mathematical References

- In-app user and developer guides are accessible from the **Help** menu.

- Comprehensive developer notes, math foundations, and coding guidelines are
  documented in [GEMINI.md](GEMINI.md) .

- Mathematical foundations of the Poincarédisk metric, geodesics, and
  hyperbolic circles are detailed in [doc/overview.md](doc/overview.md) .
