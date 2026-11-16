---
title: Hiperbolinės geometrijos apžvalga
---

Hiperbolinės geometrijos braižymoįrankis yra interaktyvi drobėhiperbolinei
geometrijai tyrinėti **Poincarédisko modelyje** ($\mathbb{D} = \{z \in
\mathbb{C} : |z| < 1\}$).

Poincarédiske galioja visi neutralios geometrijos teiginiai (Euklido
postulatai be lygiagretumo postulato), tačiau lygiagretumo postulatas
negalioja: bet kuriai tiesei $L$ ir taškui $P \notin L$ egzistuoja be galo
daug skirtingųtiesiųper $P$, kurios niekada nekerta $L$.

## 1. Poincaré disko modelis

* **Taškai**: visi hiperbolinės erdvės taškai atitinka taškus atviro
  vienetinio disko viduje $|z| < 1$. Vienetinio apskritimo taškai $|z| = 1$
  yra begalybės taškai (ribiniai taškai $\partial \mathbb{D}$).

* **Tiesės (geodezės)**: hiperbolinės tiesės atvaizduojamos Euklido lankais,
  kurie vienetinįapskritimąkerta stačiu kampu ($90^\circ$), taip pat Euklido
  skersmenimis, einančiais per centrą.

* **Konformumas**: Poincarémodelis yra konforminis (išlaiko kampus): kampas
  tarp dviejųhiperboliniųtiesiųlygus Euklido kampui tarp jųliestiniųsankirtos
  taške.

## 2. Hiperbolinis atstumas ir metrika

Artėjant prie vienetinio disko ribos ($|z| \to 1$), hiperboliniai atstumai
eksponentiškai auga iki begalybės.

Dviejųtaškų$u, v \in \mathbb{D}$ (kompleksiniųskaičių$x + iy$) **hiperbolinis
atstumas** $d(u, v)$ yra:

$$d(u, v) = \operatorname{arcosh}\left(1 + \frac{2|u - v|^2}{(1 - |u|^2)(1 - |v|^2)}\right) = 2 \operatorname{artanh}\left|\frac{u - v}{1 - \bar{u}v}\right|$$

Dažnai patogu naudoti pseudohiperbolinįatstumą$t = \tanh(d(u, v) / 2) \in [0,
1)$:

$$t = \left|\frac{u - v}{1 - \bar{u}v}\right|$$

Taškui, esančiam Euklido atstumu $r = |z|$ nuo centro:

$$\rho = \ln\left(\frac{1+r}{1-r}\right) = 2\operatorname{artanh}(r) \iff r = \tanh(\rho / 2)$$

Disko kraštas yra be galo toli.

## 3. Hiperboliniai apskritimai

**Hiperbolinis apskritimas** (visųtaškų$Q \in \mathbb{D}$ aibė, nutolusių
hiperboliniu atstumu $\rho$ nuo centro $P \in \mathbb{D}$) yra **įprastas
Euklido apskritimas**, esantis disko viduje!

Tačiau, nebent $P$ yra centre, to apskritimo **Euklido centras** $C_E$ yra
pasislinkęs disko centro link, palyginti su tikruoju **hiperboliniu centru**
$P$.

Hiperboliniam centrui $P$ ($p = |P|$) ir spinduliui $\rho$ ($t = \tanh(\rho /
2)$):

* **Euklido centras**:

  $$C_E = \frac{1 - t^2}{1 - p^2 t^2} P$$

* **Euklido spindulys**:

  $$R_E = \frac{(1 - p^2) t}{1 - p^2 t^2}$$

## 4. Braižymas liniuote ir skriestuvu

Klasikiniai braižymo būdai natūraliai pritaikomi hiperbolinėje erdvėje:

### Hiperbolinis skriestuvas

* **Centras ir taškas apskritime**: turint centrą$P$ ir tašką$Q$,
  apskaičiuojamas $t = \left|\frac{P - Q}{1 - \bar{P}Q}\right|$, tada
  nubrėžiamas Euklido apskritimas su centru $C_E$ ir spinduliu $R_E$.

* **Centras ir spindulys**: turint centrą$P$ ir spindulį$\rho$ (arba taškus
  $A, B$), brėžiamas hiperbolinis apskritimas nurodytu spinduliu.

### Hiperbolinė tiesė (liniuotė)

Per du taškus $P, Q \in \mathbb{D}$ eina viena hiperbolinėgeodezė:

* Jei $P, Q$ ir centras yra vienoje tiesėje, tiesėyra Euklido skersmuo.

* Priešingu atveju atliekama inversija vienetiniame apskritime: $P' = P /
  |P|^2$. Vienintelis Euklido apskritimas per $P, Q, P'$ kerta vienetinį
  apskritimąstatmenai.

## 5. Izometrijos ir Möbius transformacijos

Hiperbolinėerdvėyra vienalytė: kiekvienas taškas pasižymi vienoda vietine
geometrija. Judėjimai yra disko automorfizmai (Möbius transformacijos):

$$z \mapsto e^{i\theta} \frac{z - a}{1 - \bar{a} z}, \quad |a| < 1, \; \theta \in \mathbb{R}$$

Šios transformacijos išlaiko hiperbolinius atstumus, apskritimus ir kampus.

## 6. Nuorodos

* [Vikipedija: Poincaré disko modelis](https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model)
  —analitinės atstumų, apskritimųir tiesiųformulės.

* [NonEuclid interaktyvus šaltinis](https://www.cs.unm.edu/~joel/NonEuclid/)—
  klasikiniai hiperbolinio braižymo pavyzdžiai.
