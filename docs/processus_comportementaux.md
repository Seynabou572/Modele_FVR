# Processus comportementaux du modèle FVR — mécanismes, sources et localisation dans le code

Ce document décrit **les processus comportementaux effectivement implémentés** dans le modèle,
la justification bibliographique de chacun, et l'endroit précis du code où il se trouve.

Il complète le [README](../README.md) : celui-ci décrit *quoi* fait le modèle, celui-ci explique
*pourquoi chaque comportement est écrit ainsi*.

Les numéros de ligne sont indicatifs (ils bougent avec le code) ; les **noms de `reflex` et
d'`action` sont stables** et constituent la référence fiable.

---

## Vue d'ensemble : la chaîne de contact hôte–vecteur

La transmission de la FVR ne dépend pas d'un seul paramètre mais d'une **chaîne de comportements**
qui doivent tous se produire pour qu'une infection ait lieu :

```
   [mare en eau]                          [campement]
        │                                      │
        │ ponte / éclosion                     │ abreuvement quotidien
        ▼                                      ▼
   émergence des vecteurs ──── vol de quête ──── rencontre ──── repas de sang
        │                       (620/550 m)                          │
        │                                                            │
        │                                          ┌─────────────────┴──────────────┐
        │                                          ▼                                ▼
        │                                 vecteur I → hôte S              hôte I → vecteur S
        │                                     (prob. b)                       (prob. c)
        ▼                                          │                                │
   incubation extrinsèque (EIP) ◄──────────────────┴────────────────────────────────┘
```

**Le maillon limitant est la rencontre.** Un vecteur ne peut piquer que ce qu'il atteint : sa portée
de vol est de quelques centaines de mètres, alors que les campements sont à 1–1,5 km des mares. Ce
sont donc les **déplacements des hôtes**, et non ceux des moustiques, qui déterminent l'essentiel du
contact — d'où l'importance du processus d'abreuvement décrit au §4.

---

## 1. Cycle gonotrophique et taux de piqûre

**Mécanisme biologique.** Une femelle prend un repas de sang, digère, développe ses œufs, pond, puis
recherche un nouvel hôte. La durée de ce cycle fixe la fréquence maximale de piqûre. En notation de
Ross-Macdonald, le taux de piqûre `a` vaut `1/τ`.

**Implémentation.** Un seul `reflex repas_sang`, exécuté pour **tous** les vecteurs quel que soit
leur état sanitaire. Une activation = **un** repas sur **un** hôte.

- Code : [`models/agents/vecteur.gaml`](../models/agents/vecteur.gaml) — `reflex repas_sang` (~l. 72)
- Durée du cycle : [`models/core/biologie_thermique.gaml`](../models/core/biologie_thermique.gaml) —
  `cycle_gonotrophique(T, type_v)` (~l. 76)

**Valeurs et source.** τ = 4 j (*Ae. vexans*), 3 j (*Cx. poicilipes*), mesurés à Barkédji
(**Ba et al. 2005**). Le modèle degré-jour est calé sur ces valeurs autour de 27–28 °C.

**Pourquoi ce choix.** Dans la version initiale, la piqûre était pilotée par deux paramètres
distincts (`proba_activite` et `sigma_v`) dont le produit valait 0,09/j, soit une piqûre tous les
11 jours — incompatible avec un cycle gonotrophique de 3–4 jours. Faire dériver `a` de `1/τ`
supprime ce double comptage et rattache le taux de piqûre à une grandeur mesurée sur le terrain.

---

## 2. Vol de quête et rencontre avec l'hôte

**Mécanisme biologique.** La femelle en quête ne reste pas à son gîte : elle se déplace activement,
guidée par le CO₂ et les odeurs, dans la limite de sa capacité de dispersion.

**Implémentation.** Au moment du repas, le vecteur cherche les hôtes dans un rayon égal à sa portée
de vol documentée ; s'il en trouve, il rejoint l'hôte choisi.

- Code : [`models/agents/vecteur.gaml`](../models/agents/vecteur.gaml) — `reflex repas_sang`,
  variable `portee`
- Paramètres : `portee_vol_aedes_m`, `portee_vol_culex_m` dans
  [`models/core/parametres_globaux.gaml`](../models/core/parametres_globaux.gaml)

**Valeurs et source.** 620 m (*Ae. vexans*) et 550 m (*Cx. poicilipes*), distances maximales de
dispersion mesurées par capture-marquage-recapture à Barkédji (**Ba et al. 2005**), cohérentes avec
la décroissance d'abondance observée jusqu'à ~850 m des mares (**Talla et al. 2016**).

**Pourquoi ce choix.** Sans vol de quête, le vecteur devait attendre qu'un hôte passe à quelques
dizaines de mètres de son gîte : les rencontres étaient quasi nulles et le taux de piqûre mesuré
s'effondrait à zéro. Les distances sont exprimées **en mètres** et non en fraction de la zone, ce
qui les rend directement comparables à la littérature.

---

## 3. Choix de l'hôte : zoophilie

**Mécanisme biologique.** *Ae. vexans arabiensis* du Ferlo est fortement zoophile : il pique
préférentiellement les mammifères domestiques, très rarement l'humain.

**Implémentation.** Quand les deux types d'hôtes sont à portée, le repas est pris sur un animal avec
la probabilité `preference_zoophilie`.

- Code : [`models/agents/vecteur.gaml`](../models/agents/vecteur.gaml) — variable `sur_animal` dans
  `reflex repas_sang`

**Valeur et source.** 0,98. **Diallo et al. 2019** : sur 156 repas mixtes analysés dans le Ferlo,
**2 seulement (1,28 %) impliquaient un humain** ; les rapports de préférence (*forage ratio*)
donnent 46,8 pour le cheval et 5,2 pour les bovins, contre < 1 pour l'humain.

**Conséquence pour le modèle.** L'humain est un cul-de-sac épidémiologique dans cette
paramétrisation : il est très peu piqué. C'est conforme au fait que la voie dominante d'infection
humaine pour la FVR n'est pas la piqûre mais le contact direct avec les tissus animaux — voie qui
**n'est pas modélisée ici** (voir §10).

---

## 4. Abreuvement quotidien du bétail *(processus central du contact)*

**Mécanisme biologique.** Dans le système pastoral sahélien, le bétail boit **tous les jours** en
saison chaude et accepte de parcourir plusieurs kilomètres pour le faire. Les mares temporaires du
Ferlo sont simultanément :

- le **gîte larvaire** des deux vecteurs de la FVR,
- le **lieu de repos** des adultes,
- et la **ressource en eau** des troupeaux et des familles.

C'est cette superposition qui fait des mares le foyer de la transmission.

**Implémentation.** Chaque jour, un animal qui a une mare en eau dans son rayon de déplacement s'y
rend, quelle que soit la saison. Ce comportement passe **avant** la recherche de pâturage et le
retour au campement dans l'arbre de décision ; seule la transhumance le devance.

- Code : [`models/agents/animal.gaml`](../models/agents/animal.gaml) — `reflex deplacement`, bloc
  commenté `ABREUVEMENT QUOTIDIEN` (~l. 60)
- Équivalent humain (puisage domestique) :
  [`models/agents/humain.gaml`](../models/agents/humain.gaml) — `reflex se_deplacer` (~l. 34)
- Paramètres : `distance_abreuvement_max`, `vitesse_hote_normal`

**Valeurs et sources.**

| Grandeur | Valeur | Source |
|---|---|---|
| Fréquence d'abreuvement | quotidienne (saison chaude) | FAO, systèmes pastoraux sahéliens |
| Distance pâturage → point d'eau | 6–10 km (bovins), 3–5 km (petits ruminants) | FAO |
| Déplacement journalier retenu | 6 000 m | idem |
| Distance campement → mare | 100 m – 3 km ; 80 % à 1–1,5 km du lit du Ferlo | **Chevalier et al. 2013** |

**Pourquoi ce processus a changé les résultats.** L'ancien réglage donnait
`vitesse_hote_normal = unite_z3 × 0,0004`, soit **≈ 13 m par jour** sur une zone de 32 km : un
troupeau aurait mis plus de 100 jours pour rejoindre une mare à 1,5 km. Le bétail était de fait
immobile, ne rencontrait jamais les vecteurs, et le taux de piqûre `a` restait un ordre de grandeur
sous sa borne physiologique. Ramener la mobilité à sa valeur documentée et rendre l'abreuvement
quotidien rétablit le mécanisme de contact réel du système.

**Effet mesuré** (run de 75 jours, données réelles) : le taux de piqûre `a` passe de 0,057-0,067 à
0,061-0,083, et le R₀ de pic de saison des pluies de 0,39 à **0,53**.

**Ce que ce processus ne suffit pas à combler.** `a` reste très en dessous de sa borne
physiologique 1/τ ≈ 0,25-0,33. La cause est spatiale : la **production vectorielle est répartie sur
les ~250 mares de la zone**, alors que la **présence des hôtes se concentre sur les mares proches
des campements**. Les vecteurs émergeant des mares inoccupées ne piquent jamais et tirent la moyenne
vers le bas. Le R₀ calculé est donc une moyenne spatiale, à ne pas confondre avec les R₀ locaux
cartographiés dans la littérature (Durand et al. 2020).

---

## 5. Ponte et réservoir d'œufs quiescents

**Mécanisme biologique.** *Ae. vexans* pond sur le **sol humide exondé** en bordure de mare, pas sur
l'eau libre. Ses œufs résistent à la dessiccation et passent la saison sèche dans le sol ; ils
éclosent de façon synchrone à la remise en eau. *Cx. poicilipes* pond au contraire **sur l'eau
libre**.

**Implémentation.**

- Ponte *Aedes* sur mare **asséchée** (`m.volume_eau = 0`) : `reflex ponte_aedes`
  ([`vecteur.gaml`](../models/agents/vecteur.gaml), ~l. 159)
- Ponte *Culex* sur mare **en eau** : `reflex ponte_culex` (~l. 184)
- Stock d'œufs quiescents et survie journalière : `reflex survie_oeufs_quiescents`
  ([`mare.gaml`](../models/environnement/mare.gaml), ~l. 108)
- Déclenchement de l'éclosion : `reflex eclosion_aedes` (~l. 119)

**Source.** **Talla et al. 2016** : *Ae. vexans* « passe la saison défavorable sous forme d'œufs
desséchés résistants qui éclosent de façon synchrone lors de la mise en eau des mares » ;
*Cx. poicilipes* « passe la saison sèche sous forme de femelles nullipares fécondées ».

**Deux corrections apportées à ce processus.**

1. **Toutes les femelles pondent.** Auparavant seules les femelles *infectées* pondaient, ce qui
   rendait la population d'*Aedes* dépendante de la présence du virus — l'inverse de la réalité.
   Désormais la ponte est universelle ; seule la fraction `rho_aedes` d'œufs infectés dépend de
   l'état sanitaire de la mère.
2. **La condition d'éclosion était inopérante.** L'ancien code exigeait
   `jours_sans_pluie >= Td_aedes` *le jour même de la pluie*, alors que ce compteur venait d'être
   remis à zéro par le reflex précédent : l'éclosion des *Aedes* ne pouvait jamais se déclencher.
   Le modèle mémorise maintenant la durée du dernier épisode sec **achevé**
   (`duree_secheresse_prec`, `reflex compter_jours_secs`), et l'éclosion se déclenche à la remise en
   eau si cette sécheresse a été suffisante — ce qui correspond au mécanisme réel (quiescence par
   dessiccation, éclosion par inondation).

---

## 6. Développement aquatique avec délai

**Mécanisme biologique.** Entre la ponte et l'adulte volant s'écoulent plusieurs jours de
développement œuf → larve → nymphe, dont la durée dépend de la température. Ce délai est ce qui
produit le **décalage entre le pic de pluie et le pic d'abondance vectorielle**.

**Implémentation.** Une espèce dédiée porte les immatures d'un même gîte, pondus le même jour, avec
le même statut infectieux. Elle progresse d'une fraction `1/durée(T)` par jour et n'émerge qu'à
maturité ; l'assèchement du gîte tue la cohorte entière.

- Code : [`models/environnement/cohorte_larvaire.gaml`](../models/environnement/cohorte_larvaire.gaml)
  — `reflex cycle_larvaire` (~l. 31), `action emerger` (~l. 58)
- Durée : `duree_dev_larvaire(T, type_v)` dans
  [`biologie_thermique.gaml`](../models/core/biologie_thermique.gaml) (~l. 66)

**Valeurs et source.** *Ae. vexans* : développement larvaire complet en **moins de 10 jours**
(**Talla et al. 2016**) → calé à ~8 j à 28 °C. *Cx. poicilipes* est plus lent, ce qui est cohérent
avec son pic d'abondance **tardif** dans la saison, alors qu'*Ae. vexans* domine au début
(**Talla et al. 2014**).

**Régulation densité-dépendante.** La survie larvaire est réduite par la compétition selon une forme
de Beverton-Holt, avec une capacité de charge proportionnelle à la surface en eau du gîte
(`Emax_culex`, en individus/m²). Sans ce terme, la production larvaire est illimitée et la
population vectorielle finit bornée par le plafond technique `max_vecteurs` — auquel cas le rapport
vecteurs/hôte `m` du R₀ mesure ce plafond et non la biologie.

**Avant cette correction**, `phi^T` et `gamma^T` étaient appliqués **en une seule fois** : un œuf
devenait adulte le jour même, et le modèle ne pouvait produire aucun décalage saisonnier.

---

## 7. Incubation extrinsèque (EIP)

**Mécanisme biologique.** Après un repas infectant, le virus doit se répliquer et gagner les
glandes salivaires avant que la femelle ne devienne infectante. Cette durée est fortement
dépendante de la température.

**Implémentation.** Avancement fractionnaire `avancement_eip += 1/EIP(T)` par jour, ce qui reste
correct lorsque la température varie **pendant** l'incubation.

- Code : [`models/agents/vecteur.gaml`](../models/agents/vecteur.gaml) —
  `reflex incubation_extrinseque` (~l. 142)
- Durée : `eip_jours(T)` dans [`biologie_thermique.gaml`](../models/core/biologie_thermique.gaml)
  (~l. 58)

**Valeur et source.** EIP moyenne de **10,5 jours à 28 °C** (**Turell et al.**), soit 147 °C·j
au-dessus d'un seuil de développement de 14 °C. *Ae. vexans* transmet le RVFV à partir de ~14 jours
post-infection.

**Correction apportée.** Le paramètre `T_aedes` servait simultanément de durée de phase œuf **et**
d'EIP de l'adulte : l'EIP simulée valait 7 j alors que celle utilisée dans le R₀ valait 10 j. Les
deux grandeurs sont désormais distinctes et l'EIP est la même dans la dynamique et dans la métrique.

---

## 8. Mortalité et longévité des adultes

**Mécanisme biologique.** La survie journalière conditionne la probabilité qu'une femelle vive
assez longtemps pour devenir infectante — c'est le terme `p^n` du R₀, le plus sensible de la
formule.

**Implémentation.** Mortalité de base propre à l'espèce, majorée par le stress hydrique (air sec) et
le stress thermique ; plafond d'âge distinct par espèce.

- Code : [`models/agents/vecteur.gaml`](../models/agents/vecteur.gaml) — `reflex mourir` (~l. 196)
- Fonction : `mortalite_adulte_journaliere(T, RH, type_v)` dans
  [`biologie_thermique.gaml`](../models/core/biologie_thermique.gaml) (~l. 87)

**Valeurs et source (Ba et al. 2005, Barkédji).**

| | *Ae. vexans* | *Cx. poicilipes* |
|---|---|---|
| Survie journalière (parité) | 0,94 | 0,94 |
| Survie journalière (capture-marquage-recapture) | 0,91–0,96 | 0,70–0,79 |
| Longévité maximale calculée | 26 j | 15 j |

**Choix de l'estimateur — point sensible.** Le modèle retient la **parité** pour les deux espèces.
C'est l'estimateur usuel de la capacité vectorielle, et la CMR sous-estime la survie car
l'émigration hors de la zone de recapture y est comptée comme une mortalité. L'enjeu est important :
en retenant 0,77 pour *Culex*, **moins de 2 % des femelles survivent à l'EIP** et la transmission
s'annule numériquement. Ce choix doit être explicité dans toute présentation des résultats.

Seules les morts **biologiques** alimentent l'estimation de `p` ; la purge appliquée au plafond
`max_vecteurs` est un artefact de performance et en est exclue.

---

## 9. Progression SEIR chez les hôtes

**Implémentation.**

- [`models/agents/animal.gaml`](../models/agents/animal.gaml) — `reflex transition_etat` (~l. 93),
  avec mortalité possible en fin de phase infectieuse (`delta_c`)
- [`models/agents/humain.gaml`](../models/agents/humain.gaml) — `reflex transition_etat` (~l. 67)

**Valeurs et sources.**

| Paramètre | Valeur | Source |
|---|---|---|
| Incubation (ruminants) | 2 j | WOAH : 12–72 h chez les adultes, 12–72 h chez les nouveau-nés |
| Durée d'infection / virémie | 4 j | Infections expérimentales : pic de virémie à J2, détectable 3–5 j |

**Note.** Le Code sanitaire de la WOAH retient une « période infectieuse » réglementaire de 14 jours,
qui est une marge de sécurité sanitaire et non la durée biologique de la virémie : le modèle utilise
cette dernière.

**Condition corporelle et transhumance.** L'indice `NEC` diminue quand l'eau ou la biomasse
fourragère manquent et déclenche la transhumance sous un seuil
([`animal.gaml`](../models/agents/animal.gaml) — `reflex mise_a_jour_NEC`, `reflex deplacement`).

---

## 10. Ce qui n'est **pas** modélisé

Ces absences sont volontaires et doivent être rappelées à la lecture des résultats.

- **Transmission directe animal → humain** (abattage, mise bas, avortement, lait cru). C'est la
  **voie dominante d'infection humaine** pour la FVR. Combinée à une zoophilie de 0,98, son absence
  fait que le modèle sous-estime structurellement le risque humain.
- **Transmission verticale non confirmée chez l'espèce modélisée.** `rho_aedes = 0,02` est dans la
  fourchette 0–8,5 % de la littérature, mais la transmission transovarienne **n'a jamais été
  démontrée expérimentalement chez *Ae. vexans***, y compris au Sénégal ; seul *Culex tarsalis* en
  offre une démonstration préliminaire. Le virus a été détecté chez des mâles et femelles capturés
  sur le terrain, ce qui reste un argument indirect. **C'est le mécanisme central de l'expérience
  « Aedes ».**
- **Hétérogénéité du bétail** (petits ruminants vs bovins vs camelins) et **avortements**, alors que
  les avortements sont le principal signal de surveillance vétérinaire de la FVR.
- **Cycle jour/nuit.** Un pas de temps vaut un jour ; le modèle ne distingue pas la position du
  troupeau au crépuscule (moment de la piqûre) de sa position diurne.
- **Immunité inter-annuelle** : les hôtes redémarrent tous susceptibles à chaque simulation.

---

## 11. Comment ces processus alimentent le R₀

La formule de Ross-Macdonald agrège les processus ci-dessus :

```
R₀ = m · a² · b · c · pⁿ / (−ln p · r)
```

| Terme | Processus qui le produit | Section |
|---|---|---|
| `m` | densité vectorielle issue du développement aquatique et de la mortalité | §6, §8 |
| `a` | cycle gonotrophique **et** réussite de la rencontre (vol de quête + abreuvement) | §1, §2, §4 |
| `b`, `c` | compétence vectorielle par espèce | tableau ci-dessous |
| `p` | survie journalière mesurée dans la simulation | §8 |
| `n` | incubation extrinsèque thermo-dépendante | §7 |
| `r` | durée de virémie de l'hôte | §9 |

Code : [`models/core/r0_vectoriel.gaml`](../models/core/r0_vectoriel.gaml) — `composante_C` (~l. 81),
`mettre_a_jour_b_c_moyens` (~l. 93), `reflex accumuler_fenetre_R0` (~l. 209).

**Compétence vectorielle** (souches et populations sénégalaises, **Diallo et al. 2016**) :

| | *Ae. vexans* | *Cx. poicilipes* |
|---|---|---|
| `b` — transmission vecteur → hôte / piqûre | 0,23 (mesuré 13,3–33,3 %) | 0,11 (11,1 %) |
| `c` — transmission hôte → vecteur / piqûre | 0,57 (mesuré 30–85 %) | 0,28 (8,3–46,7 %) |

Ces taux dépendent de **l'espèce de moustique**, pas du type d'hôte : c'est ainsi qu'ils sont
mesurés en laboratoire. Le modèle les porte donc sur le vecteur.

**Sensibilité.** `R₀ ∝ a²` : un taux de piqûre deux fois trop faible divise le R₀ par quatre. C'est
pourquoi les processus de rencontre (§2 et §4) pèsent davantage sur le résultat que la plupart des
paramètres physiologiques.

---

## Bibliographie

- **Ba Y., Diallo D., Kebe C.M.F., Dia I., Diallo M.** (2005). *Aspects of bioecology of two Rift
  Valley fever virus vectors in Senegal (West Africa): Aedes vexans and Culex poicilipes.*
  Journal of Medical Entomology 42(5):739-750.
  → cycle gonotrophique, survie, longévité, dispersion.
- **Diallo D. et al.** (2016). *Vector competence of Aedes vexans (Meigen), Culex poicilipes
  (Theobald) and Cx. quinquefasciatus Say from Senegal for West and East African lineages of Rift
  Valley fever virus.* Parasites & Vectors.
  → probabilités de transmission `b` et `c`.
- **Diallo D. et al.** (2019). *Host-feeding patterns of Aedes (Aedimorphus) vexans arabiensis, a
  Rift Valley Fever virus vector in the Ferlo pastoral ecosystem of Senegal.* PLoS One 14(4).
  → zoophilie.
- **Talla C. et al.** (2016). *Modelling hotspots of the two dominant Rift Valley fever vectors
  (Aedes vexans and Culex poicilipes) in Barkédji, Sénégal.* Parasites & Vectors 9:111.
  → écologie des deux espèces, dispersion, développement larvaire, rôle des mares.
- **Talla C. et al.** (2014). *Statistical modeling of the abundance of vectors of West African
  Rift Valley fever in Barkédji, Senegal.* PLoS One 9(12):e114047.
  → dynamique saisonnière comparée des deux espèces.
- **Chevalier V. et al.** (2013). *Identifying landscape features associated with Rift Valley fever
  virus transmission, Ferlo region, Senegal, using very high spatial resolution satellite imagery.*
  International Journal of Health Geographics 12:10.
  → distance campement–mare, rôle des mares dans la transmission.
- **Ancey V. et al.** (2014). *How do pastoral families combine livestock herds with other
  livelihood security means to survive? The case of the Ferlo area in Senegal.* Pastoralism 4:3.
  → taille et structure des troupeaux par campement.
- **Turell M.J. et al.** *Effect of extrinsic incubation temperature on the ability of mosquitoes to
  transmit Rift Valley fever virus.*
  → EIP en fonction de la température.
- **FAO.** *Interrelations between the components of the system (man, water, livestock, rangeland).*
  → fréquence d'abreuvement et distances parcourues par le bétail sahélien.
- **WOAH.** Fiche technique et Code sanitaire pour les animaux terrestres — fièvre de la Vallée du
  Rift. → incubation et période infectieuse.
- **Durand B. et al.** (2020). *It's risky to wander in September: modelling the epidemic potential
  of Rift Valley fever in a Sahelian setting.* Epidemics.
  → cadre de comparaison pour le R₀ dans le Ferlo.
