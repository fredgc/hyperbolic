# Hyperbolic Geometry Drawing Tool Plan

This document outlines the strategic roadmap, architecture goals, and
milestones for the **Hyperbolic** Flutter project.

> **Note**: Active day-to-day tasks and issue tracking are managed dynamically
> using `~/bin/todo.py`. Run `~/bin/todo.py list` to view active tasks.

---

## Thoughts

We need to reduce the footprint of the top bar. It should have a basic set of
tools. I like the way each tool currently has a menu that lets you pick what
it's current tool is.

Maybe we can have a two layer menu system for the current tool so that only the
current tool is spelled out. I.e., if the current tool is select, the Point,
Line, Circle, and Constructor menus are collapsed like:
(Select v) (Pv) (Lv) (Ov) (Con v)

We can put the number constructor menu above the list of numbers. It would
include the "free number".


## Constructors: Design & Implementation Plan

### 1. Architectural Model & Taxonomy

A **Constructor** is an interactive, parameterized command that creates one or
more geometric objects (`SceneObject`) and their generating `Constraint` node
in the bipartite constraint graph.

Constructors are classified into two categories:

* **Primitive Constructors (Single-Constraint Generators)**: Directly
  construct an object driven by a dedicated `Constraint` node in the bipartite
  DAG (e.g., `PointObject` via `FreePointConstraint`, `LineObject` via
  `TwoPointLineConstraint`, `CircleObject` via `CircleRadiusConstraint`).

* **Compound / Macro Constructors (Multi-Constraint Generators)**: Synthesize
  high-level geometric constructions (e.g., perpendicular bisector,
  circumcircle) by executing a sequence of primitive constructions. Compound
  constructors wire intermediate objects and return primary output objects to
  the scene. They can either remain as dynamic subgraphs (where moving
  original points moves all intermediate and derived objects) or be collapsed
  into a composite constraint.

Constructors are grouped by their primary output type:

* **Points**: Free points, points on curves, intersections, midpoints.

* **Lines, Rays & Segments**: Full geodesics, segments, rays, angle lines,
  perpendiculars.

* **Circles**: Center and passing point, center and radius, compass transfer.

* **Numbers & Measurements**: Hyperbolic distances, angles, coordinates, free
  sliders.

* **Constructions (High School & Neutral Geometry)**: Perpendicular bisectors,
  angle bisectors, dropping perpendiculars, copying angles/segments, polygons.

### 2. User Interaction & Workflow Design

#### Multi-Step Selection State Machine

Constructors that require multiple inputs (e.g., two points for a line, or a
line and an external point for a perpendicular) follow a standardized state
machine:

1. **Activation**: Clicking a constructor tool in the toolbar (or selecting it
   from a group dropdown) activates the tool and enters step 1 of its
   selection sequence.

2. **Contextual Status & Prompt**: A banner or status line above the canvas
   displays prompt instructions (e.g., `"Select first point"`, `"Select
   line"`, `"Select distance or enter radius"`).

3. **Visual Affordances & Snapping**: Hovering over candidate objects
   highlights them with an outline or glow. If a constructor expects a point,
   clicking in empty canvas space can either instantly create a new
   `FreePoint` or snap to an existing point or intersection.

4. **Chaining & Nesting (Stacked Input Creation)**: If a constructor requires
   an input (e.g., a point) that does not yet exist, the user can seamlessly
   invoke a point constructor or click on an intersection to create that input
   inline without losing their place in the parent constructor sequence.

5. **Completion & Selection**: Once all inputs are satisfied, the output
   objects and constraint are committed to `SceneData`, added to
   `MyUndoManager` as a single undoable action, and automatically selected.

6. **Cancellation**: Pressing `Escape`, clicking the `Select` tool, or
   clicking a dedicated Cancel action cancels the active constructor and
   resets selection state.

#### Toolbar Organization & Progressive Disclosure

* **Grouped Dropdown / Flyout Buttons**: To prevent toolbar clutter, the
  toolbar organizes constructors into five dropdown clusters: Points, Lines,
  Circles, Measurements, and Constructions. Each button displays the active
  constructor icon, with a dropdown arrow revealing alternative constructors
  in that family.

* **Progressive Disclosure via Tutorials**: New users start with a clean,
  focused default toolset (Free Point, Geodesic Line, Segment, Circle by
  Center+Point, Distance, Move Disk, Select). Advanced constructors
  (Perpendicular Bisector, Angle Bisector, Limiting Parallels, Inscribed
  Circle) are progressively unlocked as the user completes relevant tutorials,
  or can be toggled on all at once via a "Show All Tools" setting.

#### Object Naming, Styling & Number Ranges

* **Name Suggestion**: Default names follow mathematical conventions via
  `NameGuesser` (points: $A, B, C \dots$; lines: $L_1, L_2 \dots$; circles:
  $C_1, C_2 \dots$; angles: $\alpha, \beta, \theta$; distances: $d_1, d(A,
  B)$).

* **Color Inheritance**: New objects automatically adopt the currently
  selected palette color in the toolbar.

* **Number Range Configuration**: Every created `NumberObject` defaults to
  reasonable bounds based on its role:

  * Hyperbolic distance: $0 \le d < \infty$ (default range $[0, 5]$,
    editable).

  * Angle: $[0, \pi]$ or $[0, 2\pi]$ with radians/degrees toggle.

  * Free parameters: customizable minimum, maximum, and step size.

### 3. Detailed Constructor Catalog

#### A. Points

* **Free Point**:

  * *Inputs*: Screen click converted to Poincarédisk coordinates $(u_x, u_y)$.

  * *Outputs*: `PointObject` governed by `FreePointConstraint`.

* **Point on Line / Segment / Ray**:

  * *Inputs*: Target line $L$, initial click position near $L$.

  * *Outputs*: `PointObject` constrained by parameter $t \in \mathbb{R}$ on
    $L$.

* **Point on Circle**:

  * *Inputs*: Target circle $C$, initial click position near $C$.

  * *Outputs*: `PointObject` constrained by angle $\theta \in [0, 2\pi)$ on
    $C$.

* **Intersection Point(s)**:

  * *Inputs*: Two curves (Line-Line, Line-Circle, Circle-Circle).

  * *Outputs*: 1 or 2 `PointObject`s governed by `IntersectionConstraint`.

* **Midpoint**:

  * *Inputs*: Two points $A, B$ or segment $AB$.

  * *Outputs*: `PointObject` at hyperbolic midpoint $M$ such that $d(A, M) =
    d(M, B)$.

#### B. Lines, Rays & Segments

* **Line through Two Points**:

  * *Inputs*: Two points $A, B$.

  * *Outputs*: Complete geodesic `LineObject` extending to boundary circle.

* **Segment between Two Points**:

  * *Inputs*: Two points $A, B$.

  * *Outputs*: Bounded geodesic `LineObject` (`segment`) between $A$ and $B$.

* **Ray through Two Points**:

  * *Inputs*: Endpoint point $A$, direction point $B$.

  * *Outputs*: Semi-infinite geodesic `LineObject` (`ray`) starting at $A$
    through $B$ to boundary.

* **Line by Point and Angle**:

  * *Inputs*: Base line $L$, point $P \in L$, angle `NumberObject` $\theta$.

  * *Outputs*: Geodesic line through $P$ making angle $\theta$ with $L$.

* **Extend Segment to Line**:

  * *Inputs*: Segment or Ray.

  * *Outputs*: Full geodesic line through the segment's endpoints.

#### C. Circles

* **Circle by Center and Passing Point**:

  * *Inputs*: Center point $P$, boundary point $Q$.

  * *Outputs*: `CircleObject` with radius $d(P, Q)$.

* **Circle by Center and Radius Number**:

  * *Inputs*: Center point $P$, `NumberObject` $\rho$.

  * *Outputs*: `CircleObject` with hyperbolic radius $\rho$.

* **Compass Circle (Transfer Distance)**:

  * *Inputs*: Segment $AB$ (or pair of points $A, B$), center point $P$.

  * *Outputs*: `CircleObject` centered at $P$ with hyperbolic radius equal to
    $d(A, B)$.

#### D. Numbers & Measurements

* **Free Slider Number**:

  * *Inputs*: Value, min, max (via dialog or default slider).

  * *Outputs*: Free `NumberObject` displayed in side panel.

* **Distance Measurement**:

  * *Inputs*: Two points $A, B$.

  * *Outputs*: `NumberObject` constrained to $d(A, B) =
    2\operatorname{artanh}\left|\frac{A - B}{1 - \bar{A}B}\right|$.

* **Angle Measurement**:

  * *Inputs*: Three points $A, B, C$ (vertex at $B$) or two intersecting
    lines.

  * *Outputs*: `NumberObject` constrained to conformal hyperbolic angle
    $\angle ABC$.

* **Point Coordinates**:

  * *Inputs*: Point $P$.

  * *Outputs*: Linked `NumberObject`s for $(x, y)$ or polar $(r, \theta)$.

#### E. High School Geometry Constructions (Neutral & Classical)

In hyperbolic geometry, all neutral geometry constructions (Euclid's Book I,
propositions 1–28) hold identically using straightedge and compass:

* **Perpendicular Bisector of Segment**:

  * *Inputs*: Segment $AB$ (or two points $A, B$).

  * *Construction*: Intersect two equal-radius circles centered at $A$ and
    $B$; draw geodesic line through intersection points.

  * *Outputs*: Midpoint $M$, perpendicular bisector line $L_\perp$.

* **Angle Bisector**:

  * *Inputs*: Angle $\angle ABC$ (three points or two intersecting lines).

  * *Construction*: Circle centered at $B$ finds equidistant points $P_1 \in
    BA, P_2 \in BC$; intersecting circles at $P_1, P_2$ yield point $Q$; line
    $BQ$ bisects $\angle ABC$.

  * *Outputs*: Bisector ray/line.

* **Perpendicular through Point on Line**:

  * *Inputs*: Line $L$, point $P \in L$.

  * *Outputs*: Geodesic line orthogonal to $L$ at $P$.

* **Perpendicular from External Point to Line (Drop Perpendicular)**:

  * *Inputs*: Line $L$, point $P \notin L$.

  * *Construction*: Circle centered at $P$ meets $L$ at two points;
    perpendicular bisector of those points passes through $P$ and is
    orthogonal to $L$.

  * *Outputs*: Orthogonal foot point $H \in L$, perpendicular line $PH$.

* **Copy Segment (Compass Transfer)**:

  * *Inputs*: Segment $AB$, target ray or line with origin $O$.

  * *Outputs*: Point $P$ on target ray such that $d(O, P) = d(A, B)$.

* **Copy Angle**:

  * *Inputs*: Angle $\angle ABC$, target ray with vertex $V$.

  * *Outputs*: Ray from $V$ forming an identical angle.

* **Equilateral Triangle**:

  * *Inputs*: Segment $AB$.

  * *Outputs*: Point $C$ (intersection of circles of radius $AB$ at $A$ and
    $B$) and triangle segments $AC, BC$.

* **Circumscribed Circle (Circumcenter)**:

  * *Inputs*: Three non-collinear points $A, B, C$.

  * *Outputs*: Circumcenter $O$ (intersection of perpendicular bisectors) and
    circumcircle passing through $A, B, C$ (when circumcenter exists in
    $\mathbb{D}$).

* **Inscribed Circle (Incenter)**:

  * *Inputs*: Triangle $A, B, C$.

  * *Outputs*: Incenter $I$ (intersection of angle bisectors) and incircle
    tangent to all three edges.

#### F. Hyperbolic-Specific Constructions

* **Limiting Parallel Line (Asymptotic Geodesic)**:

  * *Inputs*: Line $L$, external point $P \notin L$, direction (left/right).

  * *Construction*: Find ideal endpoint $\Omega \in \partial \mathbb{D}$ of
    $L$; draw geodesic line through $P$ and $\Omega$.

  * *Outputs*: Limiting parallel line meeting $L$ at infinity.

* **Common Perpendicular of Ultraparallel Lines**:

  * *Inputs*: Two ultraparallel (non-intersecting, non-asymptotic) lines $L_1,
    L_2$.

  * *Construction*: Determine the unique geodesic orthogonal to both lines.

  * *Outputs*: Orthogonal geodesic line and the two foot points of shortest
    distance.

* **Ideal Triangle**:

  * *Inputs*: Three ideal boundary points $\Omega_1, \Omega_2, \Omega_3 \in
    \partial \mathbb{D}$.

  * *Outputs*: Three bounding geodesic lines, forming a triangle with angle
    sum $0$.

* **Lambert & Saccheri Quadrilaterals**:

  * *Inputs*: Base segment $AB$, height $h$.

  * *Outputs*: Quadrilateral with right angles at $A$ and $B$, equal legs $AD
    = BC = h$, and acute summit angles at $C$ and $D$.

## Infrastructure

We'll need to include file handling and Google Drive interaction, which has
not been set up yet. We'll use Flutter and Firebase to publish the app.

Early development will focus on setting up all the Flutter/Firebase config
files, adapting the working infrastructure from `../spacetime`. Note that
`setup.sh` has already been updated to point to the `fredgc-hyperbolic`
Firebase project console. This project does not yet exist.

We'll also create a new `icon.xcf` and copy the version rolling
(`roll_build_number.sh`), icon export (`export-icons.py`), and build scripts
(`Makefile`, `json-builder.sh`, `run-local-*.sh`, `log_server.py`) from
`../spacetime`.

## UI & Viewport Navigation

The main drawing canvas will render the Poincaréunit disk with points, lines,
line segments/rays, and circles drawn on it.

* **Viewport Navigation**: The canvas will support both:

  * **Euclidean Zoom & Pan**: Allows inspecting fine details near the unit
    disk boundary where hyperbolic objects crowd together in Euclidean space.

  * **Hyperbolic Translation (Möbius Isometry Mode)**: Applies disk
    automorphisms $z \mapsto e^{i\theta}\frac{z - a}{1 - \bar{a}z}$ to
    smoothly shift which point of the hyperbolic plane is at the center of the
    unit disk while preserving all hyperbolic distances and angles.

* **Number Objects Panel**: There will be a scrollable list of `Number`
  objects. Depending on the aspect ratio of the window (using
  `SplitterWidget`), the list will be positioned below the disk
  (portrait/narrow) or to the right of the disk (landscape/wide).

## Objects

As in `spacetime`, most objects can have names, colors, visibility, and locked
states.

* **Geometric Objects** (drawn on the main canvas):

  * **Point**: A point $z \in \mathbb{D}$ inside the open unit disk.

  * **Line / Segment / Ray**: A hyperbolic geodesic (orthogonal circular arc
    or diameter), rendered as a full line across the disk, a segment between
    two points, or a ray.

  * **Circle**: A hyperbolic circle with hyperbolic center $P$ and hyperbolic
    radius $\rho$.

* **Number Objects** (displayed in the side/bottom list):

  * Represent real numbers (coordinates, hyperbolic distances/radii, angles,
    or free parameters).

  * When editing a `Number` object, an interactive slider (`MySlider`) lets
    the user smoothly adjust its value and animate it over a range.

* **Locking**: Objects can be locked so their values/positions cannot be
  adjusted by direct manipulation or by the constraint solver.

* **Constraints (Bipartite Object/Constraint Graph)**:

  * Every object is generated or governed by a `Constraint`, forming an
    alternating (red/black) bipartite graph of `Drawable`/`Number` objects and
    `Constraint` nodes:

    * **Free / Parameter Constraints**: Free point $(x, y)$ or polar $(r,
      \theta)$ driven by two `Number` objects; point constrained to lie on a
      line or circle at parameter $t$.

    * **Line Constraints**: Line/segment/ray through two points $P_1, P_2$.

    * **Angle Constraint**: A line through a point $P$ on another line $L$
      that forms an angle with $L$ whose measure is specified by a `Number`
      object (note: because the Poincarédisk model is conformal, hyperbolic
      angles equal the Euclidean angles between tangent vectors at $P$).

    * **Circle Constraints**: Circle from center $P$ and point $Q$ on circle;
      circle from center $P$ and `Number` radius $\rho$ (or distance $d(A, B)$
      between two points).

    * **Intersection Constraints**: Intersection point(s) of two lines, a line
      and a circle, or two circles.

    * **Measurement / Coordinate Constraints**: `Number` constrained to be the
      hyperbolic distance $d(P, Q)$, hyperbolic angle $\angle ABC$, or disk
      coordinates $(x, y, r, \theta)$ of a point.

## Constraint Solver

When the user selects and drags an object (or adjusts a `Number` slider):

1. **Downward Propagation (Forward Evaluation)**: Changes to ancestor inputs
   automatically recompute all descendant constraints and objects in
   topological order.

2. **Upward Propagation (Numerical Inverse Solver)**: If the user drags a
   derived object (such as the intersection of two lines or a point on a
   circle) whose inputs are not locked, the solver traverses upward to
   identify unlocked ancestor parameters and takes a damped least-squares /
   gradient descent step (using the Jacobian of the dragged object's position
   with respect to unlocked ancestor parameters) so the dragged object follows
   the user's cursor while keeping the entire constraint graph satisfied.

## Macro / Tutorials

There will be a macro system unified with the tutorial system
(`lib/script.dart` and `lib/tutorial_widget.dart` from `spacetime`). When a
user runs a macro, it executes a sequence of steps, pausing to prompt the user
to select or place required input objects.

For example, to construct a line perpendicular to a given line $L$ through a
point $P$:

1. Find/place two points $A, B$ on the line $L$.

2. Construct two circles centered at $A$ and $B$ passing through $P$ (or two
   equal-radius circles from $P$ intersecting $L$ at $A, B$ and then
   equal-radius circles around $A$ and $B$).

3. Find the intersection points of those two circles.

4. Construct the hyperbolic line through those intersection points.

## TODO / Next Steps

### Phase 1: Project Initialization & Infrastructure Copy

- [x] Research Poincarédisk math, compass/circle equivalents, and reference
      links (documented in Overview above).

- [x] Create default Flutter project (`org.gchouse.hyperbolic`) and configure
      Firebase project (`fredgc-hyperbolic`), Android SHA-1/SHA-256
      fingerprints, and Web/Android OAuth client IDs
      (`lib/firebase_options.dart`, `android/app/google-services.json`,
      `firebase.json`, `.firebaserc`).

- [x] After `../spacetime` code cleanup/refactoring is complete, copy core
      project scaffolding from `../spacetime` (preserving `fredgc-hyperbolic`
      OAuth client ID
      `1098767857767-r9arrbbj58rdgm0aubck8brhcs5acdae.apps.googleusercontent.com`
      in `web/index.html`):

  - Config & build files: `pubspec.yaml`, `analysis_options.yaml`,
    `.gitignore`, `.gitallowed`, `Makefile`, `roll_build_number.sh`,
    `json-builder.sh`, `export-icons.py`, `log_server.py`,
    `run-local-server.sh`, `run-local-release.sh`.

  - Web & Firebase files: `web/`, `package.json`, `html_tweak/`.

  - Reusable `lib/` modules: `main.dart`, `my_app.dart`, `navigation.dart`,
    `file_manager.dart`, `file_holder.dart`, `local_file.dart`,
    `recent_file.dart`, `drive.dart`, `upload.dart`, `edit.dart`,
    `settings.dart`, `color.dart`, `name.dart`, `printer.dart`, `worker.dart`,
    `splitter.dart`, `slider.dart`, `animate.dart`, `help.dart`, `menus.dart`,
    `sign_in_button*.dart`, `js_*.dart`, `webview_*.dart`.

- [x] Rename package from `spacetime` to `hyperbolic` in `pubspec.yaml`,
      update `mime_type` to `application/hyperbolic` in `lib/drive.dart`, and
      update package imports across `lib/` and `test/`.

- [x] Create new `icon.xcf` for Hyperbolic and generate web/Android icons.

- [ ] Revisit Google Cloud Console OAuth Verification Center & Audience
      settings
      (`https://console.cloud.google.com/auth/overview?project=fredgc-hyperbolic`)
      to complete app verification (or test-user configuration) for the
      `https://www.googleapis.com/auth/drive` scope once the app is ready.

### Phase 2: Hyperbolic Math & Coordinate Transform (`lib/transform.dart`)

- [x] Implement `HyperbolicPoint` / complex disk arithmetic inside
      $\mathbb{D}$:

  - Hyperbolic distance $d(u, v)$ and pseudo-distance $t = \tanh(d/2)$.

  - Möbius transformation $z \mapsto e^{i\theta}\frac{z - a}{1 - \bar{a}z}$
    for hyperbolic translation/rotation of the disk.

  - Geodesic (line) calculation from two points, or from a point $P$ on a line
    $L$ at a specified angle $\alpha$ (returning either a diameter or an
    orthogonal Euclidean circle center $C_L$, radius $R_L$, and start/sweep
    angles).

  - Hyperbolic circle conversion between `(hyperbolicCenter,
    hyperbolicRadius)` and `(euclideanCenter, euclideanRadius)`.

  - Intersection solvers (line-line, line-circle, circle-circle) inside the
    unit disk.

- [x] Update `CoordinateTransform` to map between Hyperbolic Disk coordinates,
      Möbius-transformed view coordinates, and Screen pixel coordinates.

- [x] Write unit tests in `test/transform_test.dart` verifying distances,
      isometries, orthogonal circles, hyperbolic circle centers, and
      intersections.

### Phase 3: Objects, Bipartite Constraint Graph & Solver

- [x] Design `SceneObject` base class (`PointObject`, `LineObject`,
      `CircleObject`, `NumberObject`) with `name`, `color`, `locked`, and
      parent `Constraint` reference.

- [x] Design `Constraint` base class and concrete constraint types (free
      point, point on object, line through two points, line at angle `Number`
      through a point on a line, circle by center+point, circle by
      center+radius, intersections, distance/coordinate numbers) with JSON
      serialization.

- [x] Implement topological forward evaluation and the numerical inverse
      solver for dragging constrained objects while respecting locked objects.

- [x] Write unit tests for constraint satisfaction, locking, and inverse drag
      updates.

### Phase 4: Canvas Rendering & Number List UI

- [x] Implement `DiskPainter` (`CustomPainter`) to draw the Poincarédisk
      boundary, hyperbolic lines/segments, hyperbolic circles, points, labels,
      and selection highlights.

- [x] Build the responsive layout (`SplitterWidget`) pairing the Poincarédisk
      canvas with the scrollable `NumberObject` list and animated sliders.

- [x] Add interactive construction tools in the toolbar (Create Point, Line,
      Angle Line, Circle, Intersection, Number/Measurement, Lock/Unlock).

- [x] Implement and verify file loading and saving for both local storage and
      Google Drive (with `application/hyperbolic` MIME type).

### Phase 5: Implement Tutorials and Macros

#### Proposed Standard Tutorials (For User Review)

1. **`01_welcome_to_poincare.md` - Welcome to the PoincaréDisk**

   - **Concepts**: The unit disk $\mathbb{D} = \{z \in \mathbb{C} : |z| <
     1\}$, boundary circle at infinity $\partial \mathbb{D}$, and geodesic
     lines (circular arcs orthogonal to the boundary circle and Euclidean
     diameters).

   - **Activities**: Place points, draw geodesic lines and segments, and
     inspect orthogonal intersections with the boundary circle.

   - **Takeaway**: Hyperbolic lines appear curved to Euclidean eyes, but
     inside hyperbolic space they represent straight, shortest-path geodesics.

2. **`02_exponential_distance.md` - Distance & The Edge of the Universe**

   - **Concepts**: The hyperbolic distance metric $d(u, v) = 2
     \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$ and
     exponential metric expansion near the boundary circle.

   - **Activities**: Measure distances with the Distance measurement tool,
     drag points closer to the boundary, and adjust numeric sliders.

   - **Takeaway**: The boundary circle is infinitely far away; an infinite
     universe is represented faithfully inside a finite drawing.

3. **`03_mobius_translations.md` - Hyperbolic Translations & Homogeneity**

   - **Concepts**: Möbius disk automorphisms $z \mapsto \frac{z - a}{1 -
     \bar{a}z}$. Hyperbolic space is homogeneous: every point has identical
     geometry.

   - **Activities**: Use the **Move Disk** tool to translate an off-center
     cluster to the origin; observe the preservation of hyperbolic lengths and
     conformal angles.

   - **Takeaway**: Apparent boundary distortion is an artifact of Euclidean
     projection; any point can be centered and viewed without distortion.

4. **`04_hyperbolic_circles.md` - Circles with Shifted Centers**

   - **Concepts**: Hyperbolic circles are Euclidean circles, but the Euclidean
     center $C_E$ is shifted closer to the origin than the true hyperbolic
     center $P$: $C_E = \frac{1 - t^2}{1 - p^2 t^2} P$.

   - **Activities**: Construct hyperbolic circles by center and radius,
     compare hyperbolic vs Euclidean radius, and translate the center to the
     origin to observe $C_E$ and $P$ align.

   - **Takeaway**: The metric gradient shifts the Euclidean center while the
     hyperbolic radius remains constant in all directions.

5. **`05_parallel_postulate.md` - The Failure of Euclid's Fifth Postulate**

   - **Concepts**: The core difference between Euclidean and hyperbolic
     geometry. Through a point $P \notin L$, there are infinitely many
     non-intersecting lines.

   - **Activities**: Given line $L$ and point $P$, construct the two limiting
     parallels (asymptotic rays meeting $L$ at the boundary circle) and the
     fan of divergent ultraparallel lines between them.

   - **Takeaway**: Directly experiencing the non-Euclidean property that
     launched modern geometry.

6. **`06_triangles_and_defect.md` - Triangles & The Angle Defect**

   - **Concepts**: The angle sum in hyperbolic triangles is strictly less than
     $180^\circ$ ($\sum \alpha < \pi$). Area is directly proportional to the
     angle defect: $\text{Area} = \pi - (\alpha + \beta + \gamma)$.

   - **Activities**: Construct a triangle $ABC$, measure the three angles with
     the Angle tool, drag vertices to vary the triangle's size, and construct
     an ideal triangle with all vertices on the boundary circle ($\sum \alpha
     = 0$).

   - **Takeaway**: There are no similar triangles of different sizes in
     hyperbolic geometry; scale determines shape and area.

7. **`07_perpendicular_bisector.md` - Classical Compass Constructions**

   - **Concepts**: Classical straightedge-and-compass constructions in
     hyperbolic geometry using intersecting circles.

   - **Activities**: Construct the perpendicular bisector and midpoint of a
     segment $AB$ by intersecting equal-radius hyperbolic circles centered at
     $A$ and $B$.

   - **Takeaway**: Neutral geometry constructions from Euclid's Book I hold
     without modification in hyperbolic space.

8. **`08_saccheri_quadrilaterals.md` - Saccheri & Lambert Quadrilaterals**

   - **Concepts**: Quadrilaterals with right angles and equal legs whose
     summit angles are strictly acute ($< 90^\circ$).

   - **Activities**: Construct a Saccheri quadrilateral, measure summit
     angles, and observe how the summit curve diverges from a geodesic.

   - **Takeaway**: Retracing the historical investigations of Omar Khayyam,
     Saccheri, and Lambert.

#### Architecture Tasks

- [ ] Adapt the script engine (`lib/script/tutorial_step.dart`,
      `tutorial_parser.dart`, `tutorial_controller.dart`, and
      `lib/tutorial_widget.dart`) to support hyperbolic objects, constraints,
      tool selection, point placement, dragging, and sliders.

- [ ] Create debug tutorial (`assets/dev/tutorials/debug_test.md`) testing
      directives: `reset`, `setup`, `object`, `tool`, `add`, `select`, `drag`,
      `slider`, and `ok`.

- [ ] Connect `generate_tutorials.py` and register the tutorial overlay card
      in `AppWidget`.

- [ ] Implement reusable construction macros that pause for user selection of
      inputs (perpendiculars, angle bisectors, midpoints, ultraparallels).

- [ ] Author standard interactive tutorials in `assets/tutorials/`.

- [ ] Write unit and widget tests (`test/tutorial_test.dart`) verifying
      directive satisfaction and tutorial card interactions.

### For first release

- announce tool and update main page.

- update dns entry for gchouse.org

- Don't forget to update Google Drive API integration after we've published
  the first release. i.e. -- upload icons and stuff.

---

## Visual & Accessibility Verification Checklist

Perform these manual checks across supported locales (`en`, `es`, `de`, `fr`,
`ja`, `lt`, `pt`, `zh`) on mobile and desktop viewports:

* **PoincaréDisk Canvas & Tools**:

  * [ ] Verify the unit boundary circle, points, lines, segments, and circles
        render smoothly with accurate color swatches in light and dark themes.

  * [ ] Verify the **Move Disk** (Möbius translation) gesture drags the disk
        smoothly without boundary deformation or visual stutter.

  * [ ] Verify the **Pan/Zoom** and **Reset View** tools correctly reset the
        origin and scale.

* **Selected Object Properties Bar**:

  * [ ] Select an object and verify the top properties banner displays the
        localized object type, inline name editor, color swatch, and lock
        button.

  * [ ] Check that name editing dialogs and color pickers do not cause
        horizontal overflows on mobile viewports.

* **Numbers Panel & Dedicated Slider**:

  * [ ] Click a numeric parameter in the Numbers panel and confirm the bottom
        slider activates with the parameter name and current value.

  * [ ] Drag the slider thumb and verify dependent geometric constructions
        update smoothly in real time.

* **Interactive Tutorials & Documentation**:

  * [ ] Open Tutorial 01 ("Introduction") and verify titles and instructions
        load in the active language (`de`, `es`, `fr`, `ja`, `lt`, `pt`,
        `zh`).

  * [ ] Open Help dialog and verify all four extended guides load correctly:

    * `overview.html`: Poincarédisk model and metric theory.

    * `controls.html`: Controls and gestures guide.

    * `objects.html`: Geometric objects guide.

    * `files.html`: File management guide.

* **Language Menu & Settings**:

  * [ ] Switch to each language from the top bar language menu and confirm all
        UI labels, toolbars, and help tabs update immediately.

  * [ ] Switch to **Auto** and verify the app reverts cleanly to the system
        default locale.

* **Touch Targets & Screen Readers**:

  * [ ] Verify that toolbar icon buttons and color chips have at least 48x48
        dp tap padding on touch devices.

  * [ ] Enable TalkBack (Android) or VoiceOver (iOS/macOS) and confirm screen
        reader announcements when selecting tools and toggling object locks.
