---
title: Hyperbolic Overview
---

The Hyperbolic Drawing Tool is an interactive canvas for constructing and
exploring hyperbolic geometry within the **PoincaréDisk model** ($\mathbb{D} =
\{z \in \mathbb{C} : |z| < 1\}$).

In the Poincarédisk, all of neutral geometry (Euclid's postulates without the
parallel postulate) holds, while the parallel postulate fails: given a line
$L$ and an external point $P \notin L$, there are infinitely many distinct
lines through $P$ that never meet $L$.

## 1. The Poincaré Disk Model

* **Points**: All points in hyperbolic space correspond to points inside the
  open unit disk $|z| < 1$. Points on the unit boundary circle $|z| = 1$ are
  points at infinity (ideal boundary points $\partial \mathbb{D}$).

* **Lines (Geodesics)**: Hyperbolic straight lines are represented by
  Euclidean circular arcs that intersect the unit circle at right angles
  ($90^\circ$), as well as Euclidean diameters passing through the origin.

* **Conformal Angles**: The Poincarédisk is conformal: the angle between two
  hyperbolic lines equals the Euclidean angle between their tangent vectors at
  the intersection point.

## 2. Hyperbolic Distance & Metric

As points approach the boundary of the unit disk ($|z| \to 1$), hyperbolic
distances grow exponentially toward infinity.

For any two points $u, v \in \mathbb{D}$ (treated as complex numbers $x +
iy$), the **hyperbolic distance** $d(u, v)$ is:

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

It is often convenient to work with the pseudo-hyperbolic distance $t =
\tanh(d(u, v) / 2) \in [0, 1)$, which has the simple algebraic form:

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

For a point at Euclidean radius $r = |z|$ from the origin:

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Because distance expands near the boundary circle, the edge of the disk is
infinitely far away.

## 3. Hyperbolic Circles

A **hyperbolic circle** (the locus of all points $Q \in \mathbb{D}$ at
hyperbolic distance $\rho$ from a hyperbolic center $P \in \mathbb{D}$) is
**an ordinary Euclidean circle** contained strictly inside the unit disk!

However, unless $P$ is at the origin, the **Euclidean center** $C_E$ of that
circle is shifted toward the origin relative to the true **hyperbolic center**
$P$ because of the metric gradient across the disk.

Specifically, given hyperbolic center $P$ with $p = |P|$ and hyperbolic radius
$\rho$ with $t = \tanh(\rho / 2)$:

* **Euclidean center**:

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Euclidean radius**:

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Straightedge and Compass Constructions

Classical straightedge-and-compass constructions adapt naturally to hyperbolic
geometry:

### Hyperbolic Compass

* **Center + Point on Circle (Collapsible Compass)**: Given hyperbolic center
  $P$ and passing point $Q$, compute $t = \left|\frac{P - Q}{1 -
  \bar{P}Q}\right|$, then render the Euclidean circle with center $C_E$ and
  radius $R_E$.

* **Center + Radius / Transfer Distance (Non-collapsible Compass)**: Given
  hyperbolic center $P$ and either a numeric radius $\rho$ or two reference
  points $A, B$ defining radius $\rho = d(A, B)$, construct the hyperbolic
  circle centered at $P$ with that exact hyperbolic radius.

### Hyperbolic Line (Straightedge)

Through any two distinct points $P, Q \in \mathbb{D}$, there is a unique
hyperbolic geodesic:

* If $P, Q$, and the origin are collinear ($P_x Q_y - P_y Q_x = 0$), the line
  is the Euclidean diameter passing through $P$ and $Q$.

* Otherwise, reflect $P$ across the unit circle via circle inversion to obtain
  $P' = P / |P|^2$. The unique Euclidean circle through $P, Q$, and $P'$
  intersects the unit circle orthogonally ($|C_L|^2 = R_L^2 + 1$). The arc
  inside $\mathbb{D}$ forms the hyperbolic line, and the arc between $P$ and
  $Q$ forms the hyperbolic segment.

## 5. Isometries & Möbius Transformations

Hyperbolic space is homogeneous: every point has identical local geometry.
Translations and rotations are represented by disk automorphisms (Möbius
transformations):

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

These transformations preserve hyperbolic distances, circles, and conformal
angles, allowing any point in the disk to be smoothly translated to the center
for inspection without metric distortion.

## 6. References & Further Reading

* [Wikipedia: Poincaré disk model](https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model)
  —Analytic formulas for distance, circles, lines, and constructions.

* [Wikipedia: Constructions in hyperbolic geometry](https://en.wikipedia.org/wiki/Constructions_in_hyperbolic_geometry)
  —Straightedge and compass constructions in hyperbolic space.

* [Wikipedia: Circle inversion](https://en.wikipedia.org/wiki/Inversive_geometry#Circle_inversion)
  —Orthogonal circle construction via circle inversion.

* [NonEuclid Interactive Poincaré Disk Info](https://www.cs.unm.edu/~joel/NonEuclid/)
  —Classical interactive reference for hyperbolic straightedge and compass
  constructions.
