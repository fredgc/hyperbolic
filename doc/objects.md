---
title: Geometric Objects Guide
---

The Hyperbolic Drawing Tool models geometric entities and numeric parameters
within the Poincarédisk model $\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$.

## 1. Points

* **Free Points**: Select the **Point** tool and click anywhere inside the
  unit disk. Free points can be dragged anywhere inside the disk.

* **Constrained Points**: Points can be created as the intersection of two
  lines or circles using the **Intersection** tool.

* **Editing Points**: Click a point with the **Select** tool to display its
  properties bar. You can rename the point, change its color using the color
  picker, or toggle its lock state.

## 2. Geodesic Lines & Segments

* **Hyperbolic Lines**: Select the **Line** tool, then click two existing
  points (or click empty locations to create points). The geodesic line is
  drawn spanning across the disk orthogonally to the boundary circle.

* **Segments**: Select the **Segment** tool and click two endpoints to create
  a finite geodesic segment.

* **Style & Color**: Select any line or segment to rename it or customize its
  stroke color in the selected object properties bar.

## 3. Hyperbolic Circles

* **Creating Circles**: Select the **Circle** tool. Click the first point to
  serve as the hyperbolic center, then click a second point to set the radius.

* **Properties**: In the Poincarémodel, hyperbolic circles render as Euclidean
  circles whose center is offset toward the disk origin.

## 4. Number Objects & Measurements

* **Distance**: Select the **Distance** tool and click two points. A new
  number representing the hyperbolic distance is added to the parameter list.

* **Angle**: Select the **Angle** tool and click three points to measure the
  conformal hyperbolic angle.

* **Free Parameters**: In the Numbers panel, click **+** to add a free scalar
  parameter.

* **Slider Adjustment**: Click any number in the panel to activate the main
  interactive slider located beneath the canvas.
