# Protocole ODD+D - modele multi-agents de la FVR dans le Ferlo

Version mise a jour le 5 septembre 2026. Cette version decrit le modele tel
qu'il est implemente dans `models/`, avec deux experiences independantes :
EXP Aedes et EXP Animal.

## 1. Introduction

Le modele simule la transmission de la fievre de la Vallee du Rift (FVR) dans
la zone pastorale Z3 de Barkedji, au Ferlo senegalais. Il suit dans l'espace
les humains, les animaux domestiques, les moustiques Aedes et Culex, les mares,
les campements et la vegetation.

Ce document suit le cadre ODD de Grimm et l'extension ODD+D de Muller et al.
Les mecanismes comportementaux detailles et leurs justifications sont decrits
dans [`processus_comportementaux.md`](processus_comportementaux.md).

## 2. Overview

### 2.1 Objectif

Le modele etudie :

- l'effet de l'eau, de la vegetation et de la dynamique des mares sur les vecteurs ;
- l'effet des deplacements des hotes sur les contacts hote-vecteur ;
- la propagation depuis un cas index Aedes ou animal ;
- les gites et zones presentant le plus fort risque local ;
- la persistance du virus dans les oeufs Aedes entre les saisons.

Trois grandeurs sont distinguees :

| Grandeur | Definition | Interpretation |
|---|---|---|
| R0 epidemiologique | `C/r`, avec `C = m.a^2.b.c.p^n / (-ln(p))` | transmission secondaire |
| R0 de capacite | `C/r`, avec `C = m.a^2.p^n / (-ln(p))` | potentiel de contact, sans b ni c |
| R0 vectoriel de gite | `rho(t,T).Lambda/mu` | production vectorielle locale |

La transmission verticale `rho_aedes` n'entre dans aucun de ces trois R0. Elle
sert a etudier le report du virus dans les oeufs quiescents.

### 2.2 Entites et etats

| Entite | Role |
|---|---|
| `humain` | mobilite, repas de sang et etats S/E/I/R |
| `animal` | abreuvement, paturage, transhumance et etats S/E/I/R |
| `vecteur` | moustique Aedes ou Culex, ponte, vol, piqure et EIP |
| `mare` | bilan hydrique, oeufs, cohortes et R0 local |
| `cohorte_larvaire` | developpement aquatique avec delai thermique |
| `campement` | ancrage spatial des humains et animaux |
| `vegetation` | biomasse et ressource fourragere |
| `zone_suivi` | observation spatiale sans retroaction dynamique |

Les hotes suivent `S -> E -> I -> R`. Les vecteurs suivent `S -> E -> I` et
restent infectieux jusqu'a leur mort.

### 2.3 Echelles

Deux echelles sont utilisees :

- `echelle_superindividu = 20` pour les humains et les animaux ;
- `echelle_si_vecteur = 2000` pour les vecteurs.

Les CSV et les displays d'effectifs affichent des **nombres d'agents**. Les
calculs internes de transmission et de R0 peuvent convertir ces agents en
individus reels, notamment pour le rapport vecteurs/hote `m`. Une sortie deja
en agents ne doit pas etre multipliee une seconde fois par une echelle.

### 2.4 Echelle spatiale et temporelle

La zone Z3 est chargee depuis `data/occsol/shp/zone3_entrainements.shp`. Son
emprise est d'environ 32 065 m x 30 410 m. Les processus avancent par cycles
journaliers. La periode standard est J152-J334, soit 183 jours. L'experience
Zone3 utilise par defaut J182-J242, soit 60 jours.

Les distances sont exprimees en metres : portee Aedes 620 m, portee Culex
550 m, et ZPOM de 100, 500 et 1000 m autour des mares.

### 2.5 Observations

`zone_suivi` enregistre les effectifs S/E/I/R, les vecteurs, les oeufs, les
nouvelles infections, les cas cumules et `jour_premiere_infection`. Les mares
enregistrent notamment `est_ensemble1`, `fermeture_500`, les hotes dans les
ZPOM, `R0_vectoriel` et les accumulateurs du R0 local.

## 3. Design concepts

### 3.1 Contact hote-vecteur

Le contact est simule geometriquement. Un vecteur ne prend un repas que si un
humain ou un animal se trouve dans sa portee. Le taux physiologique est
`a = 1/tau(T)`, module par l'humidite et le vent. La preference zoophile par
defaut vaut 0,98.

La competence depend de l'espece :

| Espece | `b` vecteur vers hote | `c` hote vers vecteur |
|---|---:|---:|
| Aedes | 0,23 | 0,57 |
| Culex | 0,11 | 0,28 |

Les piqures d'un groupe sont reparties entre les hotes accessibles. La
transmission directe humain-animal n'est pas modelisee.

### 3.2 Decisions et mobilite

Les animaux cherchent prioritairement une mare en eau accessible, puis un
paturage et leur campement. La vitesse normale est 6 000 m/jour et la vitesse
de transhumance 15 000 m/jour. Les humains se deplacent entre campement, mares
et troupeaux selon leur reflex de mobilite.

### 3.3 Hydrologie

Le bilan des mares est fonde sur la surface en eau :

```text
dV/dt = P.A + Kr.Pe.Ac - L.A
Pe    = max(P - max(Gmax - Iap, 0), 0)
A(h)  = S0.(h/h0)^alpha
V(h)  = V0.(h/h0)^(alpha+1)
```

Les mares du lit principal et les mares hors lit utilisent des bassins versants
differents via `est_ensemble1`. En l'absence de couche explicite du lit du
Ferlo, cette appartenance est approchee par la surface de la mare.

### 3.4 Entomologie

Les Aedes pondent sur la berge exondee et les Culex sur l'eau libre. Les oeufs
Aedes infectes peuvent survivre a la saison seche. Les cohortes larvaires
introduisent un delai temperature-dependant entre ponte et emergence, avec
competition et capacite larvaire.

### 3.5 R0 et experiences

Le protocole comporte deux experiences independantes. Une simulation n'active
qu'un seul calcul R0 selon `type_experience`.

#### EXP A - R0 Aedes

- `type_experience = "Aedes"` ;
- un seul Aedes femelle infecte est le cas index ;
- tous les humains sont sains et susceptibles ;
- tous les animaux sont sains et susceptibles ;
- tous les Culex initiaux sont sains ;
- les oeufs initiaux infectes sont autorises selon le parametre de l'EXP A ;
- le R0 Aedes global et local est calcule sur J1-J21 ;
- la simulation continue ensuite jusqu'a sa duree complete.

#### EXP B - R0 Animal

- `type_experience = "Animal"` ;
- un seul animal infecte est le cas index ;
- tous les autres animaux sont sains et susceptibles ;
- tous les humains sont sains et susceptibles ;
- tous les Aedes et Culex initiaux sont sains ;
- le stock initial d'oeufs infectes est desactive ;
- le R0 Animal global et local est calcule sur J1-J10 ;
- la simulation continue ensuite jusqu'a sa duree complete.

Les accumulateurs et les reflex de cloture sont conditionnes par l'experience.
EXP A ne calcule donc pas le R0 Animal, et EXP B ne calcule pas le R0 Aedes.

Le R0 local est calcule gite par gite a la cloture de la fenetre active, puis
les accumulateurs des mares sont remis a zero. `r0_local.csv` peut contenir
plusieurs executions : la colonne `experience` doit separer les resultats
Aedes et Animal.

### 3.6 Ordre d'un cycle

1. lecture du climat et calcul des facteurs thermiques, d'humidite et de vent ;
2. mise a jour saisonniere ;
3. bilan hydrique des mares et historique de surface ;
4. eclosion des oeufs lors de la submersion ;
5. developpement et emergence des cohortes ;
6. ponte Aedes et Culex ;
7. deplacement des vecteurs ;
8. repas de sang et transmission ;
9. incubation extrinseque et transitions SEIR ;
10. mortalite des vecteurs ;
11. deplacement des hotes et abreuvement ;
12. accumulation des indicateurs et exports.

### 3.7 Stochasticite

Les deplacements, choix d'hotes, mortalites, transmissions et emergences sont
stochastiques. Les batchs utilisent `keep_seed: false`. Toute comparaison doit
conserver `simulation_id` et `experience`.

## 4. Details

### 4.1 Initialisation

L'initialisation charge le climat et les couches SIG, calibre l'emprise et les
rayons, construit mares, campements et zones de suivi, puis cree les hotes
sains. Elle applique ensuite la condition initiale de l'experience.

Les Culex de fond sont places sur des mares amorcees en eau, mais sont toujours
crees sains. Dans EXP A, l'Aedes index est place sur une mare de reference
forcee a sec afin de pondre au cycle 0. Dans EXP B, seul le premier animal est
passe a l'etat infectieux.

### 4.2 Donnees d'entree

- climat : `data/climat/Climat_2025.csv` ;
- occupation du sol et zones : `data/occsol/` ;
- mares, sol, vegetation et routes : shapefiles dans `data/` ;
- NDVI et NDWI : rasters et couches associees dans `data/`.

Les couches doivent etre compatibles avec les distances en metres. La couche
`zone3_entrainements` est en UTM 28N ; le referentiel des couches `occsol`
doit etre controle avant toute interpretation quantitative.

### 4.3 Observation et sorties

| Fichier | Grain | Contenu |
|---|---|---|
| `journalier.csv` | simulation x cycle | climat, distances et hotes accessibles |
| `populations.csv` | simulation x cycle | effectifs humains et animaux par etat, en agents |
| `moustiques.csv` | simulation x cycle | Aedes/Culex par etat, en agents |
| `r0_vectoriel.csv` | simulation x experience | R0 global et capacite |
| `r0_local.csv` | gite x fenetre | R0 local, R0 vectoriel et ZPOM |
| `zones_epidemio.csv` | zone x pas d'export | etats, infections et dates d'apparition |
| `zones_environnement.csv` | zone x pas d'export | eau, NDVI, NDWI et climat |
| `transmissions.csv` | evenement | espece hote, vecteur, jour et zone |
| `validation.csv` | simulation | pluie, pics, co-abondance et R0 de protocole |

Les CSV sont initialises avec une seule entete lorsque `simulation_id = 1`.
Les fichiers issus d'anciennes executions doivent etre regeneres ou nettoyes
avant analyse.

La carte distingue les formes suivantes : animaux en cercle, humains en carre,
Aedes en triangle et Culex en cercle violet. Les mares sont en bleu clair, leur
surface en eau en bleu fonce, les campements en marron fonce et la vegetation
en vert fonce. Le display `Climat` contient quatre graphes : pluie,
temperature, humidite et vent. Les displays SEIR humains et animaux sont
separes.

### 4.4 Validation

La validation compare les hauteurs d'eau au critere de Nash lorsque les
observations sont disponibles. Elle suit aussi les pics Aedes et Culex, leur
decalage et leur co-abondance.

Le champ `forcage_hors_enveloppe` signale un climat incompatible avec
l'enveloppe de calibration du Ferlo. Tant que le cumul et les intensites de
pluie ne sont pas valides, les resultats hydrologiques, entomologiques et les
R0 doivent etre consideres comme exploratoires.

### 4.5 Limites connues

1. La serie climatique et les projections doivent etre validees avant le calage.
2. Le lit du Ferlo est approche par la taille des mares.
3. Les bassins versants sont des parametres de travail, non des mesures directes.
4. La transmission verticale est incertaine pour *Ae. vexans*.
5. Le R0 global est une moyenne spatiale ; le R0 local est plus pertinent pour
   comparer les gites.
6. Les sorties en agents ne sont pas des estimations directes des populations
   reelles sans application explicite des echelles.
7. La transmission directe par contact avec un animal infecte n'est pas modelisee.
8. Une simulation couvre une saison ou une fenetre experimentale ; elle ne
   remplace pas une validation pluriannuelle.

### 4.6 Implementation

Le point d'entree est [`models/main.gaml`](../models/main.gaml). Les modules
principaux sont :

- [`core/initialisation.gaml`](../models/core/initialisation.gaml) ;
- [`core/r0_vectoriel.gaml`](../models/core/r0_vectoriel.gaml) ;
- [`core/exports_csv.gaml`](../models/core/exports_csv.gaml) ;
- [`environnement/mare.gaml`](../models/environnement/mare.gaml) ;
- [`environnement/zone_suivi.gaml`](../models/environnement/zone_suivi.gaml) ;
- [`agents/vecteur.gaml`](../models/agents/vecteur.gaml) ;
- [`experiments/experiment_gui_aedes.gaml`](../models/experiments/experiment_gui_aedes.gaml) ;
- [`experiments/experiment_gui_animal.gaml`](../models/experiments/experiment_gui_animal.gaml) ;
- [`experiments/experiment_zone3.gaml`](../models/experiments/experiment_zone3.gaml).

Les experiences batch sont definies dans
[`experiment_batch.gaml`](../models/experiments/experiment_batch.gaml) et
`experiment_zone3.gaml`. Les diagnostics syntaxiques GAML sont valides ; un
run GAMA reste necessaire pour verifier les trajectoires et les valeurs
numeriques.

## 5. References principales

- Ba et al. (2005), bioecologie d'*Aedes vexans* et *Culex poicilipes* au Senegal.
- Diallo et al. (2016), competence vectorielle des vecteurs senegalais.
- Diallo et al. (2019), comportements de repas dans le Ferlo.
- Soti et al. (2010), hydrologie des mares du Ferlo.
- Soti et al. (2012), hydrologie, moustiques et emergence de la FVR.
- Talla et al. (2014, 2016), dynamique des vecteurs et cartographie du risque.
- Vignolles et al. (2009), zones potentiellement occupees par les Aedes.
- Porphyre, Bicout et Sabatier (2005), production vectorielle des gites.
- Chitnis, Hyman et Manore (2013), transmission verticale et R0.
- Cecilia et al. (2022), revue des modeles de transmission de la FVR.
- Muller et al. (2013), extension ODD+D pour les modeles multi-agents.
