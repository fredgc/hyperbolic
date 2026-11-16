---
title: Visão Geral da Geometria Hiperbólica
---

A Ferramenta de Desenho Hiperbólicoéuma tela interativa para construir e
explorar a geometria hiperbólica no **modelo do Disco de Poincaré**
($\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$).

No disco de Poincaré, todos os postulados neutros de Euclides são válidos,
exceto o postulado das paralelas: dada uma reta $L$ e um ponto externo $P
\notin L$, existem infinitas retas distintas passando por $P$ que nunca se
cruzam com $L$.

## 1. O Modelo do Disco de Poincaré

* **Pontos**: Todos os pontos no espaço hiperbólico correspondem a pontos
  dentro do disco unitário aberto $|z| < 1$. Pontos no círculo limite unitário
  $|z| = 1$ são pontos no infinito (fronteira ideal $\partial \mathbb{D}$).

* **Retas (Geodésicas)**: As retas hiperbólicas são representadas por arcos de
  circunferência euclidianos que interceptam o círculo unitário emângulos
  retos ($90^\circ$), além dos diâmetros euclidianos que passam pela origem.

* **Ângulos Conformes**: O disco de Poincarééconforme: oângulo entre duas
  retas hiperbólicaséigual aoângulo euclidiano entre seus vetores tangentes no
  ponto de interseção.

## 2. Distância e Métrica Hiperbólica

Àmedida que os pontos se aproximam da fronteira ($|z| \to 1$), as distâncias
hiperbólicas crescem exponencialmente atéo infinito.

Para quaisquer dois pontos $u, v \in \mathbb{D}$ (números complexos $x + iy$),
a **distância hiperbólica** $d(u, v)$é:

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

Geralmenteéconveniente utilizar a distância pseudohiperbólica $t = \tanh(d(u,
v) / 2) \in [0, 1)$:

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

Para um ponto a um raio euclidiano $r = |z|$ da origem:

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Como a métrica se expande próximoàborda, a fronteira estáinfinitamente
distante.

## 3. Círculos Hiperbólicos

Um **círculo hiperbólico** (lugar geométrico de todos os pontos $Q \in
\mathbb{D}$ a uma distância hiperbólica $\rho$ de um centro $P \in
\mathbb{D}$)é**um círculo euclidiano comum** totalmente contido no disco
unitário!

No entanto, a menos que $P$ esteja na origem, o **centro euclidiano** $C_E$ do
círculoédeslocado em direçãoàorigem em relação ao verdadeiro **centro
hiperbólico** $P$.

Dado o centro hiperbólico $P$ ($p = |P|$) e o raio $\rho$ ($t = \tanh(\rho /
2)$):

* **Centro euclidiano**:

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Raio euclidiano**:

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Construções com Régua e Compasso

Construções clássicas adaptam-se naturalmente ao plano hiperbólico:

### Compasso Hiperbólico

* **Centro + Ponto no Círculo**: Com o centro $P$ e o ponto $Q$, calcula-se $t
  = \left|\frac{P - Q}{1 - \bar{P}Q}\right|$ e traça-se o círculo euclidiano
  com centro $C_E$ e raio $R_E$.

* **Centro + Raio**: Com o centro $P$ e raio numérico $\rho$ (ou dois pontos
  de referência $A, B$), constrói-se o círculo hiperbólico centrado em $P$ com
  esse raio exato.

### Reta Hiperbólica (Régua)

Por quaisquer dois pontos distintos $P, Q \in \mathbb{D}$, passa umaúnica
geodésica:

* Se $P, Q$ e a origem forem colineares, a retaéo diâmetro euclidiano.

* Caso contrário, reflete-se $P$ através do círculo unitário por inversão: $P'
  = P / |P|^2$. O círculo euclidianoúnico por $P, Q, P'$ intercepta o círculo
  unitário ortogonalmente. O arco interior forma a reta hiperbólica.

## 5. Isometrias e Transformações de Möbius

O espaço hiperbólicoéhomogêneo: cada ponto possui geometria local idêntica.
Translações e rotações são representadas por automorfismos do disco:

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

Essas transformações preservam distâncias hiperbólicas, círculos eângulos.

## 6. Referências e Leituras Adicionais

* [Wikipédia: Modelo do disco de Poincaré](https://pt.wikipedia.org/wiki/Disco_de_Poincar%C3%A9)
  —Fórmulas analíticas de distância, retas e círculos.

* [NonEuclid: Informações Interativas](https://www.cs.unm.edu/~joel/NonEuclid/)
  —Referência clássica interativa para construções com régua e compasso.
