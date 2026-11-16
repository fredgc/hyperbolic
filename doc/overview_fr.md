---
title: Aperçu de la géométrie hyperbolique
---

L'outil de dessin hyperbolique est un canevas interactif pour construire et
explorer la géométrie hyperbolique dans le **modèle du disque de Poincaré**
($\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$).

Dans le disque de Poincaré, tous les postulats d'Euclide restent valables sauf
le postulat des parallèles :étant donnéune droite $L$ et un point extérieur $P
\notin L$, il existe une infinitéde droites distinctes passant par $P$ qui ne
coupent jamais $L$.

## 1. Le modèle du disque de Poincaré

* **Points** : Tous les points de l'espace hyperbolique correspondent aux
  points situésàl'intérieur du disque unitéouvert $|z| < 1$. Les points sur le
  cercle frontière $|z| = 1$ sont les pointsàl'infini (points idéaux $\partial
  \mathbb{D}$).

* **Droites (géodésiques)** : Les droites hyperboliques sont représentées par
  des arcs de cercle euclidiens orthogonaux ($90^\circ$) au cercle frontière,
  ainsi que par les diamètres euclidiens passant par l'origine.

* **Angles conformes** : Le disque de Poincaréest conforme : l'angle entre
  deux droites hyperboliques estégalàl'angle euclidien entre leurs vecteurs
  tangents au point d'intersection.

## 2. Distance et métrique hyperboliques

Àmesure que les points approchent de la frontière ($|z| \to 1$), les distances
hyperboliques croissent exponentiellement vers l'infini.

Pour deux points $u, v \in \mathbb{D}$ (nombres complexes $x + iy$), la
**distance hyperbolique** $d(u, v)$ est :

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

On utilise fréquemment la distance pseudohyperbolique $t = \tanh(d(u, v) / 2)
\in [0, 1)$ :

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

Pour un point situéàun rayon euclidien $r = |z|$ de l'origine :

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Le bord du disque se trouve doncàune distance infinie.

## 3. Cercles hyperboliques

Un **cercle hyperbolique** (lieu des points $Q \in \mathbb{D}$ situésàune
distance hyperbolique $\rho$ d'un centre $P \in \mathbb{D}$) est **un cercle
euclidien ordinaire** entièrement contenu dans le disque unité!

Cependant, sauf si $P$ estàl'origine, le **centre euclidien** $C_E$ du cercle
est décalévers l'origine par rapport au véritable **centre hyperbolique** $P$
en raison du gradient métrique.

Pour un centre $P$ ($p = |P|$) et un rayon $\rho$ ($t = \tanh(\rho / 2)$) :

* **Centre euclidien** :

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Rayon euclidien** :

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Constructions à la règle et au compas

Les constructions classiques s'adaptent naturellementàl'espace hyperbolique :

### Compas hyperbolique

* **Centre + point sur le cercle (compas pliable)** :Àpartir du centre $P$ et
  du point $Q$, on calcule $t = \left|\frac{P - Q}{1 - \bar{P}Q}\right|$, puis
  on trace le cercle euclidien de centre $C_E$ et de rayon $R_E$.

* **Centre + rayon (compas rigide)** : Avec un centre $P$ et un rayon
  numérique $\rho$ ou deux points $A, B$ définissant $\rho = d(A, B)$, on
  trace le cercle hyperbolique de centre $P$ avec ce rayon exact.

### Droite hyperbolique (règle)

Par deux points distincts $P, Q \in \mathbb{D}$, il passe une unique
géodésique hyperbolique :

* Si $P, Q$ et l'origine sont alignés ($P_x Q_y - P_y Q_x = 0$), la droite est
  le diamètre euclidien passant par $P$ et $Q$.

* Sinon, on calcule l'inverse de $P$ par rapport au cercle unité: $P' = P /
  |P|^2$. L'unique cercle euclidien passant par $P, Q, P'$ coupe le cercle
  unitéorthogonalement ($|C_L|^2 = R_L^2 + 1$). L'arc intérieur forme la
  droite hyperbolique.

## 5. Isométries et transformations de Möbius

L'espace hyperbolique est homogène : chaque point partage la même géométrie
locale. Les déplacements sont des automorphismes du disque (transformations de
Möbius) :

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

Ces transformations préservent les distances, les cercles et les angles.

## 6. Références et lectures complémentaires

* [Wikipédia : Disque de Poincaré](https://fr.wikipedia.org/wiki/Disque_de_Poincar%C3%A9)
  —Formules analytiques de métrique, cercles et géodésiques.

* [Wikipédia : Géométrie hyperbolique](https://fr.wikipedia.org/wiki/G%C3%A9om%C3%A9trie_hyperbolique)
  —Principes fondamentaux et propriétés des espaces hyperboliques.

* [NonEuclid : Informations interactives](https://www.cs.unm.edu/~joel/NonEuclid/)
  —Référence interactive pour les constructionsàla règle et au compas.
