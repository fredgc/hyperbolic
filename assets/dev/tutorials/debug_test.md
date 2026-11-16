# Debug Tutorial Feature Test

A test tutorial placed in assets/dev/tutorials to verify debug tutorial
discovery, inline object loading, and interactive tool/canvas directives.

## 1. Setup & Inline Objects

Verify the setup directive resets the scene and loads initial hyperbolic
objects (Point A at the origin, Point B at (0.4, 0.3), and geodesic line AB).
Click Continue.

> reset
> setup: point(name="A", x=0.0, y=0.0), point(name="B", x=0.4, y=0.3), line(name="AB", p1="A", p2="B"), number(name="N1", value=1.5)
> ok

## 2. Switch to Point Tool

Select the Point tool from the toolbar chip strip.

> tool = point

## 3. Add a Point on the Canvas

Click the flashing target near (-0.3, 0.2) inside the Poincarédisk to place
Point C.

> add = point(name="C", x=-0.3, y=0.2)

## 4. Select an Object

Switch the tool to Select and click on Point A to select it.

> select = A

## 5. Drag an Object

Drag Point A towards (0.2, 0.1). Dependent geodesic line AB will update
dynamically!

> drag = A(x=0.2, y=0.1, tol=0.2)

## 6. Adjust a Number Slider

In the parameter list, adjust the slider for N1 to 2.50.

> slider = N1(val=2.5, tol=0.2)

## 7. Hyperbolic Translation (Möbius Isometry)

Switch to the Move Disk tool to experience Poincarédisk translation.

> tool = moveDisk

## 8. Test Completed

All core tutorial directives (scene reset, multi-object setup, tool switching,
canvas addition, selection, dragging, slider adjustments, and continue
actions) are functioning properly!

> ok
