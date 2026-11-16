import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transform.g.dart';

/// A point in the Poincaré Disk model of hyperbolic geometry.
///
/// The Poincaré Disk is defined as D = { z in C : |z| < 1 }.
/// Hyperbolic points are represented as complex numbers z = x + iy with |z| < 1.
@JsonSerializable()
class HyperbolicPoint {
  final double x;
  final double y;

  const HyperbolicPoint([this.x = 0.0, this.y = 0.0]);

  const HyperbolicPoint.origin() : x = 0.0, y = 0.0;

  HyperbolicPoint.fromPolar(double r, double theta)
    : x = r * math.cos(theta),
      y = r * math.sin(theta);

  HyperbolicPoint.fromOffset(Offset offset) : x = offset.dx, y = offset.dy;

  factory HyperbolicPoint.fromJson(Map<String, dynamic> json) =>
      _$HyperbolicPointFromJson(json);

  Map<String, dynamic> toJson() => _$HyperbolicPointToJson(this);

  /// Magnitude squared |z|^2 = x^2 + y^2.
  double get magnitudeSquared => x * x + y * y;

  /// Euclidean magnitude (norm) |z| = sqrt(x^2 + y^2).
  double get magnitude => math.sqrt(magnitudeSquared);

  /// Polar angle (argument) theta = atan2(y, x) in radians.
  double get arg => math.atan2(y, x);

  /// Whether this point lies strictly inside the open unit disk.
  bool get isInsideDisk => magnitudeSquared < 1.0;

  /// Whether this point lies inside the unit disk within numerical tolerance.
  bool isValid({double eps = 1e-9}) => magnitudeSquared < (1.0 - eps);

  /// Complex conjugate bar(z) = x - iy.
  HyperbolicPoint get conjugate => HyperbolicPoint(x, -y);

  /// Converts this point to a Flutter [Offset].
  Offset toOffset() => Offset(x, y);

  HyperbolicPoint operator +(HyperbolicPoint other) =>
      HyperbolicPoint(x + other.x, y + other.y);

  HyperbolicPoint operator -(HyperbolicPoint other) =>
      HyperbolicPoint(x - other.x, y - other.y);

  HyperbolicPoint operator -() => HyperbolicPoint(-x, -y);

  /// Scalar multiplication.
  HyperbolicPoint scale(double s) => HyperbolicPoint(x * s, y * s);

  /// Complex multiplication z1 * z2.
  HyperbolicPoint complexMul(HyperbolicPoint other) =>
      HyperbolicPoint(x * other.x - y * other.y, x * other.y + y * other.x);

  /// Complex division z1 / z2.
  HyperbolicPoint complexDiv(HyperbolicPoint other) {
    final double denom = other.magnitudeSquared;
    if (denom < 1e-15) {
      throw ArgumentError('Division by zero in complexDiv');
    }
    return HyperbolicPoint(
      (x * other.x + y * other.y) / denom,
      (y * other.x - x * other.y) / denom,
    );
  }

  /// 2D Dot product x1*x2 + y1*y2.
  double dot(HyperbolicPoint other) => x * other.x + y * other.y;

  /// 2D Cross product (determinant) x1*y2 - y1*x2.
  double cross(HyperbolicPoint other) => x * other.y - y * other.x;

  /// Euclidean distance to [other].
  double euclideanDistance(HyperbolicPoint other) {
    final double dx = x - other.x;
    final double dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Pseudo-hyperbolic distance t = |(u - v) / (1 - bar(u) v)| in [0, 1).
  double pseudoDistance(HyperbolicPoint other) {
    final double diffSq =
        (x - other.x) * (x - other.x) + (y - other.y) * (y - other.y);
    final double dotProd = dot(other);
    // |1 - bar(u)v|^2 = 1 - 2(u . v) + |u|^2 |v|^2
    final double denomSq =
        1.0 - 2.0 * dotProd + magnitudeSquared * other.magnitudeSquared;
    if (denomSq <= 0.0) return 1.0;
    final double tSq = diffSq / denomSq;
    if (tSq >= 1.0) return 1.0 - 1e-15;
    if (tSq <= 0.0) return 0.0;
    return math.sqrt(tSq);
  }

  /// Hyperbolic distance d(u, v) = 2 artanh(pseudoDistance).
  double hyperbolicDistance(HyperbolicPoint other) {
    final double t = pseudoDistance(other);
    if (t <= 0.0) return 0.0;
    if (t >= 1.0 - 1e-15) return 36.0; // clamp near boundary (~infinity)
    // 2 artanh(t) = ln((1 + t) / (1 - t))
    return math.log((1.0 + t) / (1.0 - t));
  }

  /// Inverts this point across the unit circle: P' = P / |P|^2.
  /// Returns null if this point is the origin.
  HyperbolicPoint? invertAcrossUnitCircle() {
    final double magSq = magnitudeSquared;
    if (magSq < 1e-12) return null;
    return HyperbolicPoint(x / magSq, y / magSq);
  }

  /// Returns unit vector in the direction of this point.
  HyperbolicPoint normalized() {
    final double mag = magnitude;
    if (mag < 1e-12) return const HyperbolicPoint.origin();
    return HyperbolicPoint(x / mag, y / mag);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HyperbolicPoint) return false;
    return (x - other.x).abs() < 1e-11 && (y - other.y).abs() < 1e-11;
  }

  @override
  int get hashCode =>
      Object.hash((x * 1e7).roundToDouble(), (y * 1e7).roundToDouble());

  @override
  String toString() =>
      'HyperbolicPoint(${x.toStringAsFixed(5)}, ${y.toStringAsFixed(5)})';
}

/// Hyperbolic tangent tanh(x).
double tanh(double x) {
  if (x > 20.0) return 1.0;
  if (x < -20.0) return -1.0;
  final double e2x = math.exp(2.0 * x);
  return (e2x - 1.0) / (e2x + 1.0);
}

/// Inverse hyperbolic tangent artanh(x).
double artanh(double x) {
  if (x <= -1.0) return -36.0;
  if (x >= 1.0) return 36.0;
  return 0.5 * math.log((1.0 + x) / (1.0 - x));
}

/// Converts a Euclidean radius [r] from origin in D to hyperbolic distance rho.
double radiusToHyperbolicDistance(double r) {
  if (r <= 0.0) return 0.0;
  if (r >= 1.0 - 1e-15) return 36.0;
  return 2.0 * artanh(r);
}

/// Converts a hyperbolic distance [rho] to Euclidean radius r in D.
double hyperbolicDistanceToRadius(double rho) {
  if (rho <= 0.0) return 0.0;
  return tanh(rho / 2.0);
}

/// Computes the hyperbolic angle at vertex [b] between rays b -> a and b -> c.
///
/// Because Möbius disk automorphisms are conformal, this maps [b] to origin
/// and computes the Euclidean angle between the transformed points.
double angleBetween(HyperbolicPoint a, HyperbolicPoint b, HyperbolicPoint c) {
  final mobius = MobiusTransform.translationOnly(b);
  final aPrime = mobius.apply(a);
  final cPrime = mobius.apply(c);
  final double dot = aPrime.dot(cPrime);
  final double cross = aPrime.cross(cPrime);
  return math.atan2(cross, dot).abs();
}

/// Computes the hyperbolic area of triangle ABC using the Gauss-Bonnet theorem:
/// Area = pi - (angleA + angleB + angleC).
double hyperbolicTriangleArea(
  HyperbolicPoint a,
  HyperbolicPoint b,
  HyperbolicPoint c,
) {
  final double angleA = angleBetween(b, a, c);
  final double angleB = angleBetween(a, b, c);
  final double angleC = angleBetween(a, c, b);
  final double area = math.pi - (angleA + angleB + angleC);
  return area > 0.0 ? area : 0.0;
}

/// Möbius disk automorphism (isometry of the Poincaré disk):
///
/// M(z) = exp(i * theta) * (z - a) / (1 - bar(a) * z), where |a| < 1.
///
/// This transformation maps the Poincaré disk to itself bijectively,
/// preserves hyperbolic distances and conformal angles, and sends [translation]
/// to the origin.
@JsonSerializable()
class MobiusTransform {
  final HyperbolicPoint translation;
  final double rotation;

  const MobiusTransform({
    this.translation = const HyperbolicPoint.origin(),
    this.rotation = 0.0,
  });

  const MobiusTransform.identity()
    : translation = const HyperbolicPoint.origin(),
      rotation = 0.0;

  factory MobiusTransform.translationOnly(HyperbolicPoint a) =>
      MobiusTransform(translation: a, rotation: 0.0);

  factory MobiusTransform.rotationOnly(double theta) => MobiusTransform(
    translation: const HyperbolicPoint.origin(),
    rotation: theta,
  );

  factory MobiusTransform.fromJson(Map<String, dynamic> json) =>
      _$MobiusTransformFromJson(json);

  Map<String, dynamic> toJson() => _$MobiusTransformToJson(this);

  bool get isIdentity =>
      translation.magnitudeSquared < 1e-15 && rotation.abs() < 1e-15;

  /// Applies the transformation to point [z].
  HyperbolicPoint apply(HyperbolicPoint z) {
    if (isIdentity) return z;

    // (z - a)
    final double numX = z.x - translation.x;
    final double numY = z.y - translation.y;

    // 1 - bar(a) * z
    // bar(a) * z = (a.x * z.x + a.y * z.y) + i (a.x * z.y - a.y * z.x)
    final double denX = 1.0 - (translation.x * z.x + translation.y * z.y);
    final double denY = -(translation.x * z.y - translation.y * z.x);

    // w0 = (z - a) / (1 - bar(a) * z)
    final double denMagSq = denX * denX + denY * denY;
    if (denMagSq < 1e-15) return const HyperbolicPoint.origin();

    final double w0X = (numX * denX + numY * denY) / denMagSq;
    final double w0Y = (numY * denX - numX * denY) / denMagSq;

    if (rotation.abs() < 1e-15) {
      return HyperbolicPoint(w0X, w0Y);
    }

    // Rotate by theta: exp(i * theta)
    final double cosT = math.cos(rotation);
    final double sinT = math.sin(rotation);
    return HyperbolicPoint(w0X * cosT - w0Y * sinT, w0X * sinT + w0Y * cosT);
  }

  /// Applies the inverse transformation to point [w].
  HyperbolicPoint inverse(HyperbolicPoint w) {
    if (isIdentity) return w;

    // First un-rotate by -theta:
    final double cosT = math.cos(rotation);
    final double sinT = math.sin(rotation);
    final double w0X = w.x * cosT + w.y * sinT;
    final double w0Y = -w.x * sinT + w.y * cosT;

    // Then apply M_{-a, 0}(w0) = (w0 + a) / (1 + bar(a) * w0)
    final double numX = w0X + translation.x;
    final double numY = w0Y + translation.y;

    // 1 + bar(a) * w0
    final double denX = 1.0 + (translation.x * w0X + translation.y * w0Y);
    final double denY = (translation.x * w0Y - translation.y * w0X);

    final double denMagSq = denX * denX + denY * denY;
    if (denMagSq < 1e-15) return const HyperbolicPoint.origin();

    return HyperbolicPoint(
      (numX * denX + numY * denY) / denMagSq,
      (numY * denX - numX * denY) / denMagSq,
    );
  }

  /// Composes this transformation with [other], returning this(other(z)).
  MobiusTransform compose(MobiusTransform other) {
    if (isIdentity) return other;
    if (other.isIdentity) return this;

    // We represent M as a matrix in SU(1, 1):
    // [ alpha, beta ]
    // [ bar(beta), bar(alpha) ]
    // with |alpha|^2 - |beta|^2 = 1.
    final (alpha1, beta1) = _toSU11();
    final (alpha2, beta2) = other._toSU11();

    // Matrix multiplication:
    // alpha = alpha1 * alpha2 + beta1 * bar(beta2)
    // beta = alpha1 * beta2 + beta1 * bar(alpha2)
    final (alphaR, alphaI) = _complexAdd(
      _complexMul(alpha1.$1, alpha1.$2, alpha2.$1, alpha2.$2),
      _complexMul(beta1.$1, beta1.$2, beta2.$1, -beta2.$2),
    );
    final (betaR, betaI) = _complexAdd(
      _complexMul(alpha1.$1, alpha1.$2, beta2.$1, beta2.$2),
      _complexMul(beta1.$1, beta1.$2, alpha2.$1, -alpha2.$2),
    );

    // Recover translation a and rotation theta:
    // a = -beta / alpha = -(beta * bar(alpha)) / |alpha|^2
    final double alphaMagSq = alphaR * alphaR + alphaI * alphaI;
    if (alphaMagSq < 1e-15) return const MobiusTransform.identity();

    final double aX = -(betaR * alphaR + betaI * alphaI) / alphaMagSq;
    final double aY = -(betaI * alphaR - betaR * alphaI) / alphaMagSq;

    // alpha / |alpha| = exp(i * theta / 2) -> theta = 2 * atan2(alphaI, alphaR)
    final double theta = 2.0 * math.atan2(alphaI, alphaR);

    return MobiusTransform(
      translation: HyperbolicPoint(aX, aY),
      rotation: theta,
    );
  }

  ((double, double), (double, double)) _toSU11() {
    final double gamma = 1.0 / math.sqrt(1.0 - translation.magnitudeSquared);
    final double halfTheta = rotation / 2.0;
    final double cosH = math.cos(halfTheta);
    final double sinH = math.sin(halfTheta);

    // alpha = gamma * exp(i * theta / 2)
    final double alphaR = gamma * cosH;
    final double alphaI = gamma * sinH;

    // beta = -a * gamma * exp(i * theta / 2)
    final double betaR = -gamma * (translation.x * cosH - translation.y * sinH);
    final double betaI = -gamma * (translation.x * sinH + translation.y * cosH);

    return ((alphaR, alphaI), (betaR, betaI));
  }

  static (double, double) _complexMul(
    double r1,
    double i1,
    double r2,
    double i2,
  ) {
    return (r1 * r2 - i1 * i2, r1 * i2 + i1 * r2);
  }

  static (double, double) _complexAdd(
    (double, double) c1,
    (double, double) c2,
  ) {
    return (c1.$1 + c2.$1, c1.$2 + c2.$2);
  }
}

/// A hyperbolic circle in the Poincaré disk.
///
/// Every hyperbolic circle with hyperbolic center P and hyperbolic radius rho
/// is also an ordinary Euclidean circle with Euclidean center [euclideanCenter]
/// and Euclidean radius [euclideanRadius].
class HyperbolicCircle {
  final HyperbolicPoint hyperbolicCenter;
  final double hyperbolicRadius;
  final HyperbolicPoint euclideanCenter;
  final double euclideanRadius;

  HyperbolicCircle({
    required this.hyperbolicCenter,
    required this.hyperbolicRadius,
  }) : euclideanCenter = _computeEuclideanCenter(
         hyperbolicCenter,
         hyperbolicRadius,
       ),
       euclideanRadius = _computeEuclideanRadius(
         hyperbolicCenter,
         hyperbolicRadius,
       );

  factory HyperbolicCircle.fromPoints(
    HyperbolicPoint center,
    HyperbolicPoint pointOnCircle,
  ) {
    final double radius = center.hyperbolicDistance(pointOnCircle);
    return HyperbolicCircle(hyperbolicCenter: center, hyperbolicRadius: radius);
  }

  /// Constructs a hyperbolic circle from an existing Euclidean circle
  /// strictly contained within the unit disk (i.e. |center| + radius < 1).
  factory HyperbolicCircle.fromEuclidean(
    HyperbolicPoint euclideanCenter,
    double euclideanRadius,
  ) {
    final double c = euclideanCenter.magnitude;
    if (c + euclideanRadius >= 1.0) {
      throw ArgumentError(
        'Euclidean circle must be strictly inside the Poincaré unit disk',
      );
    }

    if (c < 1e-12) {
      final double rho = radiusToHyperbolicDistance(euclideanRadius);
      return HyperbolicCircle(
        hyperbolicCenter: const HyperbolicPoint.origin(),
        hyperbolicRadius: rho,
      );
    }

    final double r1 = c - euclideanRadius;
    final double r2 = c + euclideanRadius;
    final double rho1 = r1 >= 0
        ? radiusToHyperbolicDistance(r1)
        : -radiusToHyperbolicDistance(-r1);
    final double rho2 = radiusToHyperbolicDistance(r2);

    final double rhoCenter = (rho1 + rho2) / 2.0;
    final double rhoRadius = (rho2 - rho1) / 2.0;

    final double pMag = hyperbolicDistanceToRadius(rhoCenter.abs());
    final double sign = rhoCenter >= 0 ? 1.0 : -1.0;
    final unit = euclideanCenter.normalized();

    return HyperbolicCircle(
      hyperbolicCenter: unit.scale(pMag * sign),
      hyperbolicRadius: rhoRadius,
    );
  }

  static HyperbolicPoint _computeEuclideanCenter(
    HyperbolicPoint p,
    double rho,
  ) {
    final double t = tanh(rho / 2.0);
    final double pSq = p.magnitudeSquared;
    final double factor = (1.0 - t * t) / (1.0 - pSq * t * t);
    return p.scale(factor);
  }

  static double _computeEuclideanRadius(HyperbolicPoint p, double rho) {
    final double t = tanh(rho / 2.0);
    final double pSq = p.magnitudeSquared;
    return ((1.0 - pSq) * t) / (1.0 - pSq * t * t);
  }

  /// Whether the point [pt] lies on or inside this hyperbolic circle.
  bool contains(HyperbolicPoint pt, {double eps = 1e-9}) {
    return hyperbolicCenter.hyperbolicDistance(pt) <= hyperbolicRadius + eps;
  }

  /// Point on circle at hyperbolic direction [angle] from hyperbolic center.
  HyperbolicPoint pointAtAngle(double angle) {
    // Send hyperbolic center to origin, place point at radius t, and invert back:
    final double t = tanh(hyperbolicRadius / 2.0);
    final ptAtOrigin = HyperbolicPoint.fromPolar(t, angle);
    final mobius = MobiusTransform.translationOnly(hyperbolicCenter);
    return mobius.inverse(ptAtOrigin);
  }

  @override
  String toString() =>
      'HyperbolicCircle(center: $hyperbolicCenter, rho: ${hyperbolicRadius.toStringAsFixed(4)})';
}

/// A hyperbolic geodesic (line) in the Poincaré disk.
///
/// In the Poincaré disk, every geodesic is either:
/// 1. A diameter passing through the origin ([isDiameter] is true).
/// 2. A circular arc orthogonal to the boundary circle (|C_L|^2 = R_L^2 + 1).
class HyperbolicLine {
  final bool isDiameter;
  final HyperbolicPoint idealPoint1;
  final HyperbolicPoint idealPoint2;

  // Diameter properties:
  final double diameterAngle;
  final HyperbolicPoint direction;

  // Circular arc properties:
  final HyperbolicPoint euclideanCenter;
  final double euclideanRadius;
  final double startAngle;
  final double sweepAngle;

  const HyperbolicLine._diameter({
    required this.idealPoint1,
    required this.idealPoint2,
    required this.diameterAngle,
    required this.direction,
  }) : isDiameter = true,
       euclideanCenter = const HyperbolicPoint.origin(),
       euclideanRadius = double.infinity,
       startAngle = 0.0,
       sweepAngle = 0.0;

  const HyperbolicLine._circle({
    required this.idealPoint1,
    required this.idealPoint2,
    required this.euclideanCenter,
    required this.euclideanRadius,
    required this.startAngle,
    required this.sweepAngle,
  }) : isDiameter = false,
       diameterAngle = 0.0,
       direction = const HyperbolicPoint.origin();

  /// Constructs the unique geodesic through points [p1] and [p2].
  factory HyperbolicLine.fromPoints(HyperbolicPoint p1, HyperbolicPoint p2) {
    if (p1 == p2) {
      throw ArgumentError('Points p1 and p2 must be distinct to define a line');
    }

    // Check collinearity with origin (p1 x p2 == 0):
    final double crossOrigin = p1.cross(p2);
    if (crossOrigin.abs() < 1e-11 ||
        p1.magnitudeSquared < 1e-12 ||
        p2.magnitudeSquared < 1e-12) {
      // Diameter geodesic
      HyperbolicPoint dir;
      if (p1.magnitudeSquared > 1e-12) {
        dir = p1.normalized();
      } else if (p2.magnitudeSquared > 1e-12) {
        dir = p2.normalized();
      } else {
        dir = (p2 - p1).normalized();
      }
      final double angle = math.atan2(dir.y, dir.x);
      return HyperbolicLine._diameter(
        idealPoint1: dir,
        idealPoint2: -dir,
        diameterAngle: angle,
        direction: dir,
      );
    }

    // Invert p1 across unit circle: p1' = p1 / |p1|^2
    final p1Prime = p1.invertAcrossUnitCircle()!;

    // Find Euclidean circle through p1, p2, and p1Prime:
    final (center, radius) = _circleFrom3Points(p1, p2, p1Prime);

    // Compute ideal points and arc sweep inside the disk:
    final (ideal1, ideal2, start, sweep) = _arcParameters(center, radius);

    return HyperbolicLine._circle(
      idealPoint1: ideal1,
      idealPoint2: ideal2,
      euclideanCenter: center,
      euclideanRadius: radius,
      startAngle: start,
      sweepAngle: sweep,
    );
  }

  /// Constructs the unique geodesic through point [p] with tangent angle [angle].
  factory HyperbolicLine.fromPointAndAngle(HyperbolicPoint p, double angle) {
    final tangent = HyperbolicPoint(math.cos(angle), math.sin(angle));

    // Collinear with origin test: p x tangent == 0
    final double crossOrigin = p.cross(tangent);
    if (crossOrigin.abs() < 1e-11 || p.magnitudeSquared < 1e-12) {
      return HyperbolicLine._diameter(
        idealPoint1: tangent,
        idealPoint2: -tangent,
        diameterAngle: angle,
        direction: tangent,
      );
    }

    // Normal to tangent:
    final normal = HyperbolicPoint(-tangent.y, tangent.x);
    // lambda = (1 - |p|^2) / (2 * (p . normal))
    final double pDotN = p.dot(normal);
    final double lambda = (1.0 - p.magnitudeSquared) / (2.0 * pDotN);
    final center = p + normal.scale(lambda);
    final double radius = lambda.abs();

    final (ideal1, ideal2, start, sweep) = _arcParameters(center, radius);

    return HyperbolicLine._circle(
      idealPoint1: ideal1,
      idealPoint2: ideal2,
      euclideanCenter: center,
      euclideanRadius: radius,
      startAngle: start,
      sweepAngle: sweep,
    );
  }

  static (HyperbolicPoint, double) _circleFrom3Points(
    HyperbolicPoint a,
    HyperbolicPoint b,
    HyperbolicPoint c,
  ) {
    final double d =
        2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
    if (d.abs() < 1e-12) {
      throw StateError('Collinear points encountered in _circleFrom3Points');
    }
    final double aSq = a.magnitudeSquared;
    final double bSq = b.magnitudeSquared;
    final double cSq = c.magnitudeSquared;

    final double cx =
        (aSq * (b.y - c.y) + bSq * (c.y - a.y) + cSq * (a.y - b.y)) / d;
    final double cy =
        (aSq * (c.x - b.x) + bSq * (a.x - c.x) + cSq * (b.x - a.x)) / d;
    final center = HyperbolicPoint(cx, cy);
    final double radius = a.euclideanDistance(center);
    return (center, radius);
  }

  static (HyperbolicPoint, HyperbolicPoint, double, double) _arcParameters(
    HyperbolicPoint center,
    double radius,
  ) {
    final double d = center.magnitude;
    final double phi = center.arg;

    // Ideal points on unit circle:
    final double deltaPsi = math.acos(1.0 / d);
    final ideal1 = HyperbolicPoint.fromPolar(1.0, phi - deltaPsi);
    final ideal2 = HyperbolicPoint.fromPolar(1.0, phi + deltaPsi);

    // Angles from center to ideal points:
    final double deltaAlpha = math.asin(1.0 / d);
    final double start = (phi + math.pi) - deltaAlpha;
    final double sweep = 2.0 * deltaAlpha;

    return (ideal1, ideal2, start, sweep);
  }

  /// Whether [pt] lies on this geodesic within tolerance [eps].
  bool containsPoint(HyperbolicPoint pt, {double eps = 1e-6}) {
    if (!pt.isInsideDisk) return false;
    if (isDiameter) {
      return pt.cross(direction).abs() < eps;
    } else {
      return (pt.euclideanDistance(euclideanCenter) - euclideanRadius).abs() <
          eps;
    }
  }

  /// Unit tangent vector along this geodesic at point [pt].
  HyperbolicPoint tangentAt(HyperbolicPoint pt) {
    if (isDiameter) {
      return direction;
    }
    final toPoint = pt - euclideanCenter;
    return HyperbolicPoint(-toPoint.y, toPoint.x).normalized();
  }

  /// Unit normal vector to this geodesic at point [pt].
  HyperbolicPoint normalAt(HyperbolicPoint pt) {
    final t = tangentAt(pt);
    return HyperbolicPoint(-t.y, t.x);
  }

  /// Orthogonal hyperbolic projection of point [p] onto this geodesic.
  HyperbolicPoint projectPoint(HyperbolicPoint p) {
    if (containsPoint(p)) return p;

    // Pick two reference points on this line:
    HyperbolicPoint p1, p2;
    if (isDiameter) {
      p1 = const HyperbolicPoint.origin();
      p2 = direction.scale(0.5);
    } else {
      // Point closest to origin:
      final double d = euclideanCenter.magnitude;
      final double rClosest = d - euclideanRadius;
      p1 = euclideanCenter.normalized().scale(rClosest);
      // Another point on the arc:
      p2 = HyperbolicPoint(
        euclideanCenter.x +
            euclideanRadius * math.cos(startAngle + sweepAngle * 0.25),
        euclideanCenter.y +
            euclideanRadius * math.sin(startAngle + sweepAngle * 0.25),
      );
    }

    // Map this line to the positive x-axis using Mobius transformation:
    // 1. Translate p1 to origin
    final m1 = MobiusTransform.translationOnly(p1);
    final p2Transformed = m1.apply(p2);
    // 2. Rotate so p2 lies on positive real axis
    final double rot = -p2Transformed.arg;
    final mobius = MobiusTransform(translation: p1, rotation: rot);

    // In this frame, this line is the real axis (y = 0)
    final pPrime = mobius.apply(p);
    final double xP = pPrime.x;
    final double yP = pPrime.y;

    HyperbolicPoint fPrime;
    if (xP.abs() < 1e-12) {
      fPrime = const HyperbolicPoint.origin();
    } else {
      final double c = (xP * xP + yP * yP + 1.0) / (2.0 * xP);
      final double sign = c >= 0.0 ? 1.0 : -1.0;
      final double r = math.sqrt(c * c - 1.0);
      final double xF = c - sign * r;
      fPrime = HyperbolicPoint(xF, 0.0);
    }

    // Map back to original coordinate frame:
    return mobius.inverse(fPrime);
  }

  /// Constructs the unique geodesic perpendicular to this line passing through [pt].
  HyperbolicLine perpendicularAt(HyperbolicPoint pt) {
    final foot = containsPoint(pt) ? pt : projectPoint(pt);
    final normal = normalAt(foot);
    final double angle = math.atan2(normal.y, normal.x);
    return HyperbolicLine.fromPointAndAngle(foot, angle);
  }

  @override
  String toString() => isDiameter
      ? 'HyperbolicLine.diameter(angle: ${diameterAngle.toStringAsFixed(4)})'
      : 'HyperbolicLine.circle(center: $euclideanCenter, R: ${euclideanRadius.toStringAsFixed(4)})';
}

/// A finite geodesic segment between endpoints [p1] and [p2].
class HyperbolicSegment {
  final HyperbolicPoint p1;
  final HyperbolicPoint p2;
  late final HyperbolicLine line;

  HyperbolicSegment(this.p1, this.p2) {
    line = HyperbolicLine.fromPoints(p1, p2);
  }

  double get length => p1.hyperbolicDistance(p2);

  /// Hyperbolic midpoint M such that d(p1, M) == d(M, p2) == length / 2.
  HyperbolicPoint get midpoint => pointAtFraction(0.5);

  /// Point at fractional distance [fraction] in [0, 1] from [p1] to [p2].
  HyperbolicPoint pointAtFraction(double fraction) {
    if (fraction <= 0.0) return p1;
    if (fraction >= 1.0) return p2;

    // Send p1 to origin:
    final mobius = MobiusTransform.translationOnly(p1);
    final p2Transformed = mobius.apply(p2);

    final double totalRho = radiusToHyperbolicDistance(p2Transformed.magnitude);
    final double targetRho = totalRho * fraction;
    final double targetRadius = hyperbolicDistanceToRadius(targetRho);

    final targetTransformed = p2Transformed.normalized().scale(targetRadius);
    return mobius.inverse(targetTransformed);
  }

  /// Whether point [pt] lies on this segment.
  bool containsPoint(HyperbolicPoint pt, {double eps = 1e-6}) {
    if (!line.containsPoint(pt, eps: eps)) return false;
    final double dTotal = length;
    final double d1 = p1.hyperbolicDistance(pt);
    final double d2 = pt.hyperbolicDistance(p2);
    return (d1 + d2 - dTotal).abs() < eps;
  }
}

/// A geodesic ray starting at [start] and extending through [through] to infinity.
class HyperbolicRay {
  final HyperbolicPoint start;
  final HyperbolicPoint through;
  late final HyperbolicLine line;
  late final HyperbolicPoint idealPoint;

  HyperbolicRay(this.start, this.through) {
    line = HyperbolicLine.fromPoints(start, through);
    // Identify which ideal point the ray heads towards:
    final d1 = through.euclideanDistance(line.idealPoint1);
    final d2 = through.euclideanDistance(line.idealPoint2);
    idealPoint = d1 < d2 ? line.idealPoint1 : line.idealPoint2;
  }
}

/// Intersects two hyperbolic lines.
///
/// In hyperbolic geometry, two distinct lines intersect in at most one point
/// inside the Poincaré disk. If they intersect on the boundary circle, they are
/// limiting parallel. If they do not intersect, they are ultraparallel.
List<HyperbolicPoint> intersectLineLine(HyperbolicLine l1, HyperbolicLine l2) {
  // Case 1: Both are diameters
  if (l1.isDiameter && l2.isDiameter) {
    final double cross = l1.direction.cross(l2.direction);
    if (cross.abs() < 1e-11) {
      // Parallel or identical diameters
      return const [];
    }
    // All distinct diameters intersect at the origin
    return [const HyperbolicPoint.origin()];
  }

  // Case 2: One diameter and one circle
  if (l1.isDiameter || l2.isDiameter) {
    final diameter = l1.isDiameter ? l1 : l2;
    final circle = l1.isDiameter ? l2 : l1;

    final v = diameter.direction;
    final c = circle.euclideanCenter;
    final double vDotC = v.dot(c);

    // Quadratic: t^2 - 2 (v . c) t + 1 = 0
    final double disc = vDotC * vDotC - 1.0;
    if (disc <= 0.0) return const [];

    final double sqrtDisc = math.sqrt(disc);
    final double sign = vDotC >= 0 ? 1.0 : -1.0;
    final double t = vDotC - sign * sqrtDisc;
    final pt = v.scale(t);

    if (pt.isInsideDisk) {
      return [pt];
    }
    return const [];
  }

  // Case 3: Both are circles
  return _intersectCirclesInsideDisk(
    l1.euclideanCenter,
    l1.euclideanRadius,
    l2.euclideanCenter,
    l2.euclideanRadius,
  );
}

/// Intersects a hyperbolic line and a hyperbolic circle.
///
/// Yields 0, 1 (tangent), or 2 points inside the Poincaré disk.
List<HyperbolicPoint> intersectLineCircle(
  HyperbolicLine line,
  HyperbolicCircle circle,
) {
  if (line.isDiameter) {
    final v = line.direction;
    final c = circle.euclideanCenter;
    final double r = circle.euclideanRadius;

    // Line: P(t) = t * v
    // |t * v - c|^2 = r^2 -> t^2 - 2(v . c) t + (|c|^2 - r^2) = 0
    final double b = -2.0 * v.dot(c);
    final double cConst = c.magnitudeSquared - r * r;
    final double disc = b * b - 4.0 * cConst;

    if (disc < -1e-12) return const [];
    if (disc.abs() <= 1e-12) {
      final double t = -b / 2.0;
      final pt = v.scale(t);
      return pt.isInsideDisk ? [pt] : const [];
    }

    final double sqrtDisc = math.sqrt(disc);
    final double t1 = (-b - sqrtDisc) / 2.0;
    final double t2 = (-b + sqrtDisc) / 2.0;

    final results = <HyperbolicPoint>[];
    final pt1 = v.scale(t1);
    final pt2 = v.scale(t2);
    if (pt1.isInsideDisk) results.add(pt1);
    if (pt2.isInsideDisk) results.add(pt2);
    return results;
  } else {
    return _intersectCirclesInsideDisk(
      line.euclideanCenter,
      line.euclideanRadius,
      circle.euclideanCenter,
      circle.euclideanRadius,
    );
  }
}

/// Intersects two hyperbolic circles.
///
/// Yields 0, 1, or 2 points inside the Poincaré disk.
List<HyperbolicPoint> intersectCircleCircle(
  HyperbolicCircle c1,
  HyperbolicCircle c2,
) {
  return _intersectCirclesInsideDisk(
    c1.euclideanCenter,
    c1.euclideanRadius,
    c2.euclideanCenter,
    c2.euclideanRadius,
  );
}

List<HyperbolicPoint> _intersectCirclesInsideDisk(
  HyperbolicPoint c1,
  double r1,
  HyperbolicPoint c2,
  double r2,
) {
  final double d = c1.euclideanDistance(c2);
  if (d < 1e-12 || d > r1 + r2 || d < (r1 - r2).abs()) {
    return const [];
  }

  // Distance from c1 to radical line:
  final double a = (d * d - r2 * r2 + r1 * r1) / (2.0 * d);
  final double hSq = r1 * r1 - a * a;
  if (hSq < -1e-12) return const [];

  final double h = hSq > 0.0 ? math.sqrt(hSq) : 0.0;
  final p0 = c1 + (c2 - c1).scale(a / d);
  final normal = HyperbolicPoint(-(c2.y - c1.y) / d, (c2.x - c1.x) / d);

  final results = <HyperbolicPoint>[];
  if (h < 1e-12) {
    if (p0.isInsideDisk) results.add(p0);
    return results;
  }

  final sol1 = p0 + normal.scale(h);
  final sol2 = p0 - normal.scale(h);

  if (sol1.isInsideDisk) results.add(sol1);
  if (sol2.isInsideDisk) results.add(sol2);
  return results;
}

/// Viewport coordinate transformation between:
/// 1. Hyperbolic Disk coordinates: z in D (|z| < 1).
/// 2. Möbius View coordinates: w = M(z) in D (|w| < 1).
/// 3. Screen pixel coordinates: Offset on the canvas.
class CoordinateTransform {
  Size size;
  Offset pan;
  double zoom;
  MobiusTransform mobius;

  CoordinateTransform({
    this.size = const Size(800.0, 600.0),
    this.pan = Offset.zero,
    this.zoom = 1.0,
    this.mobius = const MobiusTransform.identity(),
  });

  /// Center of the Poincaré disk in screen pixel coordinates.
  Offset get screenCenter =>
      Offset(size.width / 2.0 + pan.dx, size.height / 2.0 + pan.dy);

  /// Radius of the boundary circle on screen at zoom = 1.0.
  double get baseRadius => math.min(size.width, size.height) * 0.45;

  /// Radius of the boundary circle on screen at current [zoom].
  double get screenRadius => baseRadius * zoom;

  // Coordinate mappings:

  /// Maps Hyperbolic Disk coordinates to Möbius View coordinates: w = M(z).
  HyperbolicPoint diskToView(HyperbolicPoint p) => mobius.apply(p);

  /// Maps Möbius View coordinates back to Hyperbolic Disk coordinates: z = M^-1(w).
  HyperbolicPoint viewToDisk(HyperbolicPoint w) => mobius.inverse(w);

  /// Maps Möbius View coordinates to Screen pixels.
  Offset viewToScreen(HyperbolicPoint w) {
    return Offset(
      screenCenter.dx + w.x * screenRadius,
      screenCenter.dy - w.y * screenRadius,
    );
  }

  /// Maps Screen pixels to Möbius View coordinates.
  HyperbolicPoint screenToView(Offset screen) {
    return HyperbolicPoint(
      (screen.dx - screenCenter.dx) / screenRadius,
      (screenCenter.dy - screen.dy) / screenRadius,
    );
  }

  /// Maps Hyperbolic Disk coordinates directly to Screen pixels.
  Offset diskToScreen(HyperbolicPoint p) => viewToScreen(diskToView(p));

  /// Maps Screen pixels directly to Hyperbolic Disk coordinates.
  HyperbolicPoint screenToDisk(Offset screen) =>
      viewToDisk(screenToView(screen));

  /// Converts a disk delta to screen delta.
  Offset diskDeltaToScreen(Offset delta) =>
      Offset(delta.dx * screenRadius, -delta.dy * screenRadius);

  /// Converts a screen delta to disk delta.
  Offset screenDeltaToDisk(Offset delta) =>
      Offset(delta.dx / screenRadius, -delta.dy / screenRadius);

  /// Translates the hyperbolic plane so that [diskTarget] moves to the center of the disk.
  void translateDiskCenter(HyperbolicPoint diskTarget) {
    mobius = MobiusTransform.translationOnly(diskTarget);
  }

  /// Zooms in or out centered at [focalPoint] on screen.
  void zoomAt(Offset focalPoint, double factor) {
    final newZoom = (zoom * factor).clamp(0.1, 1000.0);
    // Adjust pan so focalPoint stays fixed in view space:
    final viewBefore = screenToView(focalPoint);
    zoom = newZoom;
    final screenAfter = viewToScreen(viewBefore);
    pan += (focalPoint - screenAfter);
  }

  /// Pans the Euclidean view by [delta] screen pixels.
  void panBy(Offset delta) {
    pan += delta;
  }

  /// Resets zoom and pan to defaults.
  void resetView() {
    pan = Offset.zero;
    zoom = 1.0;
  }

  /// Resets both Euclidean view and Möbius isometry to default origin.
  void resetAll() {
    resetView();
    mobius = const MobiusTransform.identity();
  }

  Map<String, dynamic> toJson() => {
    'pan': {'dx': pan.dx, 'dy': pan.dy},
    'zoom': zoom,
    'mobius': mobius.toJson(),
  };

  void loadFromJson(Map<String, dynamic> json) {
    if (json.containsKey('pan')) {
      final panMap = json['pan'] as Map<String, dynamic>;
      pan = Offset(
        (panMap['dx'] as num).toDouble(),
        (panMap['dy'] as num).toDouble(),
      );
    }
    if (json.containsKey('zoom')) {
      zoom = (json['zoom'] as num).toDouble();
    }
    if (json.containsKey('mobius')) {
      mobius = MobiusTransform.fromJson(json['mobius'] as Map<String, dynamic>);
    }
  }

  @override
  String toString() =>
      'CoordinateTransform(zoom: ${zoom.toStringAsFixed(2)}, pan: $pan, mobius: ${mobius.isIdentity ? "id" : mobius.translation})';
}
