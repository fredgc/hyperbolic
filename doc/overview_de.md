---
title: Hyperbolische Geometrie im Überblick
---

Das hyperbolische Zeichenwerkzeug ist eine interaktive Arbeitsfläche zur
Konstruktion und Erkundung der hyperbolischen Geometrie im **Poincaré-
Kreisscheibenmodell** ($\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$).

In der Poincaré-Scheibe gilt die gesamte absolute Geometrie (Euklids Postulate
ohne das Parallelenpostulat), während das Parallelenpostulat verletzt ist: Zu
jeder Geraden $L$ und jedemäußeren Punkt $P \notin L$ gibt es unendlich viele
verschiedene Geraden durch $P$, die $L$ niemals schneiden.

## 1. Das Poincaré-Kreisscheibenmodell

* **Punkte**: Alle Punkte des hyperbolischen Raumes entsprechen Punkten im
  offenen Einheitskreis $|z| < 1$. Punkte auf dem Randkreis $|z| = 1$ sind
  Punkte im Unendlichen (ideale Randpunkte $\partial \mathbb{D}$).

* **Geraden (Geodäten)**: Hyperbolische Geraden werden durch euklidische
  Kreisbögen dargestellt, die den Randkreis orthogonal ($90^\circ$) schneiden,
  sowie durch euklidische Durchmesser durch den Ursprung.

* **Konforme Winkel**: Das Poincaré-Modell ist winkeltreu (konform): Der
  Winkel zwischen zwei hyperbolischen Geraden entspricht dem euklidischen
  Winkel zwischen ihren Tangentenvektoren im Schnittpunkt.

## 2. Hyperbolischer Abstand & Metrik

Nähern sich Punkte dem Rand der Einheitskreisscheibe ($|z| \to 1$), wachsen
hyperbolische Abstände exponentiell gegen unendlich.

Für zwei beliebige Punkte $u, v \in \mathbb{D}$ (als komplexe Zahlen $x + iy$)
beträgt der **hyperbolische Abstand** $d(u, v)$:

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

Häufig ist die pseudohyperbolische Distanz $t = \tanh(d(u, v) / 2) \in [0, 1)$
zweckmäßig, die die einfache algebraische Form besitzt:

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

Für einen Punkt im euklidischen Abstand $r = |z|$ vom Ursprung gilt:

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Da sich Abstände zum Randkreis hin dehnen, liegt der Rand unendlich weit
entfernt.

## 3. Hyperbolische Kreise

Ein **hyperbolischer Kreis** (die Menge aller Punkte $Q \in \mathbb{D}$ mit
hyperbolischem Abstand $\rho$ zu einem Zentrum $P \in \mathbb{D}$) ist **ein
gewöhnlicher euklidischer Kreis**, der vollständig in der Scheibe liegt!

Sofern $P$ nicht im Ursprung liegt, ist der **euklidische Mittelpunkt** $C_E$
des Kreises relativ zum echten **hyperbolischen Mittelpunkt** $P$ durch den
metrischen Gradienten zum Ursprung hin verschoben:

* **Euklidischer Mittelpunkt**:

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Euklidischer Radius**:

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Konstruktionen mit Zirkel und Lineal

Klassische Konstruktionenübertragen sich auf die hyperbolische Geometrie:

### Hyperbolischer Zirkel

* **Mittelpunkt + Punkt auf Kreis (kollabierender Zirkel)**: Aus dem Zentrum
  $P$ und Randpunkt $Q$ wird $t = \left|\frac{P - Q}{1 - \bar{P}Q}\right|$
  berechnet und der euklidische Kreis mit $C_E$ und $R_E$ gezeichnet.

* **Mittelpunkt + Radius / Distanzübertrag**: Mit Zentrum $P$ und Radius
  $\rho$ oder zwei Referenzpunkten $A, B$ mit $\rho = d(A, B)$ wird der
  hyperbolische Kreis um $P$ mit genau diesem Radius konstruiert.

### Hyperbolische Gerade (Lineal)

Durch zwei verschiedene Punkte $P, Q \in \mathbb{D}$ verläuft genau eine
hyperbolische Geodäte:

* Liegen $P, Q$ und der Ursprung auf einer Linie ($P_x Q_y - P_y Q_x = 0$),
  ist die Gerade der euklidische Durchmesser durch $P$ und $Q$.

* Andernfalls wird $P$ durch Kreisspiegelung an der Einheitskreisscheibe
  gespiegelt ($P' = P / |P|^2$). Der eindeutige Kreis durch $P, Q, P'$
  schneidet den Einheitskreis orthogonal ($|C_L|^2 = R_L^2 + 1$). Der Bogen in
  $\mathbb{D}$ bildet die hyperbolische Gerade.

## 5. Isometrien & Möbius-Transformationen

Der hyperbolische Raum ist homogen: Jeder Punkt besitzt dieselbe lokale
Geometrie. Verschiebungen und Drehungen sind Scheibenautomorphismen
(Möbius-Transformationen):

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

Diese Transformationen erhalten hyperbolische Abstände, Kreise und Winkel.

## 6. Referenzen & Weiterführendes

* [Wikipedia: Poincaré-Kreisscheiben-Modell](https://de.wikipedia.org/wiki/Poincar%C3%A9-Kreisscheiben-Modell)
  —Analytische Formeln für Metrik, Kreise und Geraden.

* [Wikipedia: Nichteuklidische Geometrie](https://de.wikipedia.org/wiki/Nichteuklidische_Geometrie)
  —Grundlagen und historische Entwicklung.

* [NonEuclid Interaktive Info](https://www.cs.unm.edu/~joel/NonEuclid/)—
  Klassische interaktive Referenz für Zirkel-und-Lineal-Konstruktionen.
