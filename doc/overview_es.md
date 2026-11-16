---
title: Visión General de Hyperbolic
---

La Herramienta de Dibujo Hiperbólico es un lienzo interactivo para construir y
explorar la geometría hiperbólica dentro del **modelo del Disco de Poincaré**
($\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$).

En el disco de Poincarése cumple toda la geometría neutra (los postulados de
Euclides sin el postulado de las paralelas), mientras que el postulado de las
paralelas no se cumple: dada una línea $L$ y un punto exterior $P \notin L$,
existen infinitas líneas distintas que pasan por $P$ y nunca intersecan a $L$.

## 1. El Modelo del Disco de Poincaré

* **Puntos**: Todos los puntos en el espacio hiperbólico corresponden a puntos
  dentro del disco unitario abierto $|z| < 1$. Los puntos en el círculo límite
  unitario $|z| = 1$ son puntos en el infinito (puntos ideales del límite
  $\partial \mathbb{D}$).

* **Líneas (Geodésicas)**: Las líneas rectas hiperbólicas están representadas
  por arcos circulares euclidianos que intersecan al círculo unitario en
  ángulos rectos ($90^\circ$), asícomo por diámetros euclidianos que pasan por
  el origen.

* **Ángulos Conformes**: El disco de Poincarées conforme: elángulo entre dos
  líneas hiperbólicas es igual alángulo euclidiano entre sus vectores
  tangentes en el punto de intersección.

## 2. Distancia y Métrica Hiperbólica

A medida que los puntos se aproximan al límite del disco unitario ($|z| \to
1$), las distancias hiperbólicas crecen exponencialmente hacia el infinito.

Para cualesquiera dos puntos $u, v \in \mathbb{D}$ (tratados como números
complejos $x + iy$), la **distancia hiperbólica** $d(u, v)$ es:

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

A menudo es conveniente trabajar con la distancia pseudohiperbólica $t =
\tanh(d(u, v) / 2) \in [0, 1)$, que tiene la forma algebraica simple:

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

Para un punto a una distancia euclidiana $r = |z|$ del origen:

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Debido a que la distancia se expande cerca del círculo límite, el borde del
disco se encuentra infinitamente lejos.

## 3. Círculos Hiperbólicos

Un **círculo hiperbólico** (el lugar geométrico de todos los puntos $Q \in
\mathbb{D}$ a una distancia hiperbólica $\rho$ de un centro hiperbólico $P \in
\mathbb{D}$)¡es **un círculo euclidiano ordinario** contenido estrictamente
dentro del disco unitario!

Sin embargo, a menos que $P$ estéen el origen, el **centro euclidiano** $C_E$
de ese círculo se desplaza hacia el origen con respecto al verdadero **centro
hiperbólico** $P$ debido al gradiente métrico en el disco.

Específicamente, dado un centro hiperbólico $P$ con $p = |P|$ y un radio
hiperbólico $\rho$ con $t = \tanh(\rho / 2)$:

* **Centro euclidiano**:

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Radio euclidiano**:

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Construcciones con Regla y Compás

Las construcciones clásicas con regla y compás se adaptan naturalmente a la
geometría hiperbólica:

### Compás Hiperbólico

* **Centro + Punto en el Círculo (Compás Colapsable)**: Dado el centro
  hiperbólico $P$ y el punto de paso $Q$, se calcula $t = \left|\frac{P - Q}{1 - \bar{P}Q}\right|$, luego se representa el círculo euclidiano con centro
  $C_E$ y radio $R_E$.

* **Centro + Radio / Transferencia de Distancia (Compás No Colapsable)**: Dado
  el centro hiperbólico $P$ y un radio numérico $\rho$ o dos puntos de
  referencia $A, B$ que definen el radio $\rho = d(A, B)$, se construye el
  círculo hiperbólico centrado en $P$ con ese radio hiperbólico exacto.

### Línea Hiperbólica (Regla)

Por cualesquiera dos puntos distintos $P, Q \in \mathbb{D}$, pasa unaúnica
geodésica hiperbólica:

* Si $P, Q$ y el origen son colineales ($P_x Q_y - P_y Q_x = 0$), la línea es
  el diámetro euclidiano que pasa por $P$ y $Q$.

* En caso contrario, se refleja $P$ respecto al círculo unitario mediante
  inversión circular para obtener $P' = P / |P|^2$. Elúnico círculo euclidiano
  que pasa por $P, Q$ y $P'$ interseca al círculo unitario ortogonalmente
  ($|C_L|^2 = R_L^2 + 1$). El arco interior de $\mathbb{D}$ forma la línea
  hiperbólica, y el arco entre $P$ y $Q$ forma el segmento hiperbólico.

## 5. Isometrías y Transformaciones de Möbius

El espacio hiperbólico es homogéneo: cada punto tiene una geometría local
idéntica. Las traslaciones y rotaciones están representadas por automorfismos
del disco (transformaciones de Möbius):

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

Estas transformaciones conservan distancias hiperbólicas, círculos yángulos
conformes, permitiendo trasladar suavemente cualquier punto del disco al
centro para inspección sin distorsión métrica.

## 6. Referencias y Lecturas Adicionales

* [Wikipedia: Modelo del disco de Poincaré](https://es.wikipedia.org/wiki/Modelo_del_disco_de_Poincar%C3%A9)
  —Fórmulas analíticas para distancia, círculos, líneas y construcciones.

* [Wikipedia: Geometría hiperbólica](https://es.wikipedia.org/wiki/Geometr%C3%ADa_hiperb%C3%B3lica)
  —Conceptos y construcciones en el espacio hiperbólico.

* [Wikipedia: Inversión respecto a una circunferencia](https://es.wikipedia.org/wiki/Inversi%C3%B3n_respecto_a_una_circunferencia)
  —Construcción de círculos ortogonales mediante inversión circular.

* [Información interactiva del disco de Poincaré en NonEuclid](https://www.cs.unm.edu/~joel/NonEuclid/)
  —Referencia interactiva clásica para construcciones hiperbólicas con regla y
  compás.
