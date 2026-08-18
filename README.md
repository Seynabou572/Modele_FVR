# Modèle FVR — Zone Z3, Barkedji (Sénégal)

Modèle multi-agents GAMA de la Fièvre de la Vallée du Rift (FVR / Rift Valley Fever) sur la zone
pastorale Z3 de Barkedji, pour la saison des pluies 2025 (jour de l'année 152 → 334, soit
183 jours simulés).

## 1. Ce que simule le modèle

Trois populations interagissent dans l'espace :

- **Humains** — se déplacent entre campement, mares et troupeaux ; compartiments **S → E → I → R**.
- **Animaux** (bétail) — pâturent, font la transhumance saisonnière, ont une condition corporelle
  (NEC) qui pilote leurs déplacements ; compartiments **S → E → I → R** (avec mortalité possible en I).
- **Vecteurs** — moustiques *Aedes* et *Culex* — piquent, transmettent le virus, pondent ;
  compartiments **S → E → I** (pas de R : les vecteurs infectés le restent).

La transmission passe uniquement par les vecteurs (pas de contact direct humain/animal). Le moteur
scientifique central est le calcul du **R₀ vectoriel** (formule de Ross-Macdonald), recalculé
toutes les 10 jours simulés, séparément pour *Aedes* seul et pour tous les vecteurs confondus.

Le mécanisme épidémiologique clé de la FVR modélisé ici est la **transmission verticale** (ou
transovarienne) chez *Aedes* : une femelle infectée pond des œufs eux-mêmes infectés
(`rho_aedes`), qui peuvent survivre à la saison sèche dans le sol d'une mare asséchée et éclore
en moustiques déjà infectés dès le retour des pluies — c'est ce mécanisme qui permet au virus de
« redémarrer » chaque saison des pluies sans hôte infecté préexistant.

> **Détail des processus comportementaux** — mécanismes biologiques implémentés, justification
> bibliographique de chacun et localisation dans le code :
> [`docs/processus_comportementaux.md`](docs/processus_comportementaux.md).

## 2. Architecture du projet

```
Modele_FVR/
├── models/
│   ├── main.gaml                 # point d'entrée : assemble tous les modules ci-dessous
│   ├── core/                     # logique globale (pas d'agents spatiaux)
│   │   ├── donnees_chemins.gaml      # chemins vers data/, géométrie du monde (shape, zone_z3)
│   │   ├── parametres_globaux.gaml   # tous les paramètres/constantes (déclarations pures)
│   │   ├── climat.gaml               # chargement du CSV climat + reflex journalier + facteurs
│   │   ├── biologie_thermique.gaml   # durées dépendantes de T (EIP, larves, cycle gonotrophique)
│   │   ├── saisons_occsol.gaml       # calendrier des 3 saisons, (re)génération mares/campements
│   │   ├── dynamique_population.gaml # agrégation SEIR, naissances animaux, recrutement Culex
│   │   ├── r0_vectoriel.gaml         # calcul du R₀ (Ross-Macdonald) par fenêtre de 10 jours
│   │   ├── exports_csv.gaml          # chemins des CSV de sortie + tous les reflex d'export
│   │   └── initialisation.gaml       # le bloc init : orchestre tout le bootstrap
│   ├── environnement/            # espèces non mobiles (paysage)
│   │   ├── occsol_polygone.gaml, zone_eau_binaire.gaml, sol.gaml,
│   │   │   vegetation.gaml, route.gaml, campement.gaml, mare.gaml
│   │   └── cohorte_larvaire.gaml     # stade aquatique avec délai de développement
│   ├── agents/                   # espèces mobiles
│   │   ├── hote.gaml (parent commun humain/animal), humain.gaml, animal.gaml, vecteur.gaml
│   └── experiments/
│       ├── experiment_gui_aedes.gaml   # expérience GUI, cas index = Aedes (EXP A)
│       ├── experiment_gui_animal.gaml  # expérience GUI, cas index = Animal (EXP B)
│       └── experiment_batch.gaml       # 4 expériences batch (3 et 1000 répétitions)
├── docs/
│   └── processus_comportementaux.md  # mécanismes, sources, renvois au code
├── data/                         # données SIG/climat — voir data/README.md
└── outputs/                      # CSV générés par les simulations (ignorés par git)
```

Chaque fichier `.gaml` sous `models/` déclare son propre `model <Nom>` (obligatoire en GAML pour
qu'un fichier soit importable) **et déclare ses propres `import`**. C'est ce qui permet d'ouvrir
n'importe quel fichier seul dans l'éditeur GAMA sans erreur de variable non résolue ; GAML tolère
les imports croisés (mare ↔ vecteur, humain ↔ animal). `main.gaml` reste le point d'entrée qui
assemble le tout en un seul modèle `ModeleFVRBarkedjiZ3`.

> **Attention aux chemins relatifs.** GAMA ne les résout pas de la même façon selon le sens :
> la **lecture** (`file("...")`) est relative au fichier qui déclare le chemin
> (`models/core/` → `../../data/`), tandis que l'**écriture** (`save ... to:`) est relative au
> fichier d'entrée (`models/main.gaml` → `../outputs/`). Déplacer `main.gaml` casserait les
> chemins de sortie.

## 3. Déroulement d'une simulation

1. **`init`** (`core/initialisation.gaml`) :
   - calibre les échelles spatiales (vitesses, rayons de détection/piqûre) à partir de la taille
     de la zone Z3 ;
   - calcule les paramètres fixes du R₀ (`p_survie_vect`, `r_hote`, ...) ;
   - charge le CSV climatique (`charger_climat`, `core/climat.gaml`) ;
   - crée les routes, sols, végétation à partir des shapefiles ;
   - détermine la saison de départ et construit mares/campements/fond de carte
     (`mettre_a_jour_occsol_saisonnier`, `core/saisons_occsol.gaml`) ;
   - crée les humains et animaux (en super-individus) répartis sur les campements ;
   - selon l'expérience (`type_experience`), place le **cas index** — voir §4 ;
   - construit le graphe routier et initialise les fichiers CSV de sortie.
2. **Chaque cycle** (1 jour simulé) : mise à jour du climat, éventuel changement de saison
   (reconstruction des mares/campements), déplacement des hôtes et vecteurs, piqûres et
   transmissions, pontes, émergences de moustiques depuis les mares, exports CSV.
3. **Toutes les 10 jours** : calcul et export du R₀ de la fenêtre (`calculer_et_exporter_R0`).
4. **`reflex stop`** (à `cycle >= duree_simulation - 1`) : calcule le R₀ moyen sur toute la
   simulation, écrit le résumé, met la simulation en pause.

## 4. Les deux expériences

Le modèle a un seul mécanisme de transmission ; ce qui change entre les deux expériences GUI,
c'est **où démarre l'épidémie** :

- **"FVR Z3 — Expérience Aedes"** (`type_experience = "Aedes"`) : une mare est forcée à sec, une
  femelle *Aedes* adulte infectée y est placée comme cas index ; elle pondra dès le jour 0 des
  œufs infectés (transmission verticale). C'est le scénario où la maladie *réémerge* uniquement
  via le réservoir vectoriel, sans hôte infecté au départ.
- **"FVR Z3 — Expérience Animal"** (`type_experience = "Animal"`) : un animal est infecté dès le
  départ (cas index B), en plus d'un Aedes index sur une mare sèche. C'est le scénario où
  l'épidémie part d'un hôte infecté.

Dans les deux cas, 100 *Culex* sont initialisés sur les mares disponibles (5 % déjà infectés) via
`initialiser_culex_100`.

Les expériences **batch** (`experiments/experiment_batch.gaml`) répètent l'une ou l'autre
expérience 3 ou 1000 fois avec des graines aléatoires différentes (`keep_seed: false`), pour
obtenir une distribution du R₀ plutôt qu'une seule trajectoire.

## 5. Paramètres principaux

Regroupés par thème dans `core/parametres_globaux.gaml` ; les plus utiles à explorer sont exposés
comme `parameter` dans les expériences GUI (catégorie **Fonctionnalités** pour les bascules) :

| Paramètre | Rôle |
|---|---|
| `type_experience` | `"Aedes"` ou `"Animal"` — où démarre le cas index |
| `utiliser_ndwi_binaire` | Active un masque d'eau binaire pour forcer l'assèchement des mares hors zone d'eau (désactivé par défaut, shapefile requis — voir §7) |
| `export_detail` | Active/désactive l'écriture des CSV détaillés à chaque cycle |
| `echelle_superindividu` | Individus réels par agent **hôte** (défaut 20) |
| `echelle_si_vecteur` | Individus réels par agent **vecteur** (défaut 500) — voir §6 |
| `lambda_aedes`, `rho_aedes` | Fécondité et taux de transmission verticale des Aedes |
| `b_aedes`, `b_culex`, `c_aedes`, `c_culex` | Probabilités de transmission **par piqûre**, par espèce de vecteur (voir §6) |
| `tau_aedes`, `preference_zoophilie` | Cycle gonotrophique (le taux de piqûre vaut 1/tau) et part des repas pris sur le bétail |
| `delta_c` | Létalité de l'infection chez l'animal |
| `max_vecteurs` | Plafond de population vectorielle (limite mémoire/performance) |

## 6. Calibration et sources

Les paramètres biologiques sont calés autant que possible sur des études conduites
**à Barkédji même ou dans le Ferlo**, et à défaut sur la littérature RVF générale. Les valeurs
propres au site priment sur les valeurs génériques.

### Vecteurs — bioécologie (Barkédji)

| Paramètre | Valeur | Source |
|---|---|---|
| Cycle gonotrophique *Ae. vexans* | 4 j | Ba et al. 2005 |
| Cycle gonotrophique *Cx. poicilipes* | 3 j | Ba et al. 2005 |
| Survie journalière (parité) | 0,94 pour les deux espèces | Ba et al. 2005 |
| Longévité maximale | 26 j (*Aedes*) / 15 j (*Culex*) | Ba et al. 2005 |
| Dispersion maximale depuis le gîte | 620 m (*Aedes*) / 550 m (*Culex*) | Ba et al. 2005 ; Talla et al. 2016 |
| Développement larvaire | < 10 j (*Aedes*) ; plus lent chez *Culex* | Talla et al. 2016 |

> La survie journalière est le paramètre le plus sensible du R₀, via le terme `p^n`. Ba et al.
> donnent deux estimateurs : la **parité** (0,94 pour les deux espèces) et la
> **capture-marquage-recapture** (0,91–0,96 pour *Aedes*, 0,70–0,79 pour *Culex*). Le modèle
> retient la parité, estimateur usuel de la capacité vectorielle — la CMR sous-estime la survie
> car l'émigration hors zone de recapture y est comptée comme une mortalité. Avec 0,77 pour
> *Culex*, moins de 2 % des femelles survivent à l'EIP et la transmission s'annule.

### Vecteurs — compétence (souches et populations sénégalaises)

| Paramètre | *Ae. vexans* | *Cx. poicilipes* | Source |
|---|---|---|---|
| `b` — transmission vecteur → hôte / piqûre | 0,23 (mesuré 13,3–33,3 %) | 0,11 (11,1 %) | Diallo et al. 2016 |
| `c` — transmission hôte → vecteur / piqûre | 0,57 (mesuré 30–85 %) | 0,28 (8,3–46,7 %) | Diallo et al. 2016 |
| EIP à 28 °C | 10,5 j | 10,5 j | Turell et al. |

### Comportement de piqûre

| Paramètre | Valeur | Source |
|---|---|---|
| Préférence zoophile | 0,98 | Diallo et al. 2019 : seuls 1,28 % des repas mixtes impliquaient un humain |

### Hôtes

| Paramètre | Valeur | Source |
|---|---|---|
| Incubation (ruminants) | 2 j (12–72 h) | WOAH |
| Durée d'infection / virémie | 4 j (pic à J2, 3–5 j) | Infections expérimentales agneaux/veaux |
| Densité par campement | ~67 animaux, ~13 personnes | Ancey et al. 2014 : < 50 bovins + < 50 ovins par campement |

### Échelles super-individus : pourquoi deux valeurs

Un moustique est plusieurs ordres de grandeur plus nombreux qu'un ruminant. Avec une échelle
commune aux hôtes et aux vecteurs, représenter une densité vectorielle réaliste demanderait des
millions d'agents : en pratique la population vectorielle butait sur `max_vecteurs`, et le
rapport `m` du R₀ mesurait ce plafond technique plutôt que la biologie.

Le modèle utilise donc **deux échelles** : `echelle_superindividu` (hôtes) et
`echelle_si_vecteur` (vecteurs). Le `m` du R₀ est calculé en **individus réels**, en
repondérant par les deux échelles. Conséquence pratique : vérifier dans
`controle_memoire.csv` que la colonne `vecteurs` reste nettement sous `max_vecteurs` — sinon
`m` est de nouveau tronqué et il faut augmenter `echelle_si_vecteur`.

### Non calibré — à traiter avec prudence

- **Transmission verticale (`rho_aedes` = 0,02).** La littérature situe le taux transovarien RVFV
  entre 0 et 8,5 %, mais **elle n'a jamais été démontrée expérimentalement chez *Ae. vexans***,
  y compris au Sénégal ; seul *Culex tarsalis* en offre une démonstration préliminaire. Le virus
  a bien été détecté chez des mâles et femelles capturés sur le terrain, ce qui reste un
  argument indirect. **C'est le mécanisme central de l'expérience « Aedes » : ses résultats
  reposent donc sur une hypothèse non confirmée pour cette espèce.**
- **Capacité de charge larvaire (`Emax_culex`).** Le maximum physiologique de 7 000 ind/m² cité
  dans la littérature ne régule jamais la population dans ce paysage ; la valeur de travail est
  choisie pour que la compétition larvaire soit effective, pas sourcée.
- Les coefficients degrés-jours de `core/biologie_thermique.gaml` sont calés sur les durées
  ci-dessus à une température de référence, pas ajustés sur des séries expérimentales.

### Références

- Ba Y. et al. (2005). *Aspects of bioecology of two Rift Valley fever virus vectors in Senegal
  (West Africa): Aedes vexans and Culex poicilipes.* J Med Entomol 42(5):739-750.
- Diallo D. et al. (2016). *Vector competence of Aedes vexans, Culex poicilipes and Cx.
  quinquefasciatus from Senegal for West and East African lineages of Rift Valley fever virus.*
  Parasites & Vectors.
- Diallo D. et al. (2019). *Host-feeding patterns of Aedes (Aedimorphus) vexans arabiensis, a
  Rift Valley Fever virus vector in the Ferlo pastoral ecosystem of Senegal.* PLoS One 14(4).
- Talla C. et al. (2016). *Modelling hotspots of the two dominant Rift Valley fever vectors
  (Aedes vexans and Culex poicilipes) in Barkédji, Sénégal.* Parasites & Vectors 9:111.
- Talla C. et al. (2014). *Statistical modeling of the abundance of vectors of West African Rift
  Valley fever in Barkédji, Senegal.* PLoS One 9(12):e114047.
- Ancey V. et al. (2014). *How do pastoral families combine livestock herds with other livelihood
  security means to survive? The case of the Ferlo area in Senegal.* Pastoralism 4:3.
- Durand B. et al. (2020). *It's risky to wander in September: modelling the epidemic potential
  of Rift Valley fever in a Sahelian setting.* Epidemics.
- Cavalerie L. et al. (2019). *Rift Valley fever: an open-source transmission dynamics simulation
  model.* PLoS One 14(1):e0209929.
- WOAH — fiche technique et Code sanitaire pour les animaux terrestres, fièvre de la Vallée du Rift.

## 7. Données (`data/`)

Voir [`data/README.md`](data/README.md) pour l'arborescence exacte attendue (rasters/shapefiles
d'occupation du sol, NDVI, NDWI par saison, sol, végétation, routes, climat).

Le modèle ne gère actuellement que **3 saisons** : Ceedu (jours 1–181), Nduungu (182–304),
Dabbuunde (305–365) — voir `calculer_saison` dans `core/saisons_occsol.gaml`. Un 4ᵉ jeu de
données saisonnier ("Deminaree") existe dans `data/_non_utilise/` mais n'est pas référencé par
le modèle.

La fonctionnalité NDWI binaire (`utiliser_ndwi_binaire`) est câblée dans le code mais désactivée
tant que `data/occsol/eau_binaire/eau_binaire_z3.shp` n'est pas fourni (voir
`models/core/donnees_chemins.gaml` et `models/core/initialisation.gaml`, actuellement commentés).

## 8. Sorties (`outputs/`)

Un seul jeu de CSV partagé par toutes les simulations d'un batch (chaque ligne commence par
`simulation_id`) :

| Fichier | Contenu |
|---|---|
| `journalier.csv` | Climat et saison par jour |
| `populations.csv` | Effectifs SEIR humains/animaux + total vecteurs |
| `r0_vectoriel.csv` | Par fenêtre de 10 j : `m`, `a`, `p`, `C`, `R0` (Aedes et tous vecteurs), plus `b_moyen`, `c_moyen`, `n_eip` |
| `incidence.csv` | Nouvelles infections et prévalence hôtes/vecteurs |
| `climat.csv` | Variables climatiques brutes (T2M, RH2M, PRECTOTCORR, WS2M) |
| `mares.csv` | Mares actives, volume/niveau moyen, œufs quiescents (infectés/sains), `larves_total` |
| `moustiques.csv` | SEI détaillé par type de vecteur (Aedes/Culex) |
| `controle_memoire.csv` | Agents vivants, dont `cohortes` larvaires (contrôle de charge) |
| `resume.csv` | R₀ moyen et infections totales en fin de simulation |

## 9. Lancer une simulation

Ouvrir `models/main.gaml` dans GAMA Desktop et choisir une expérience dans le menu.

En ligne de commande, le mode `-batch` fonctionne et produit bien les CSV :

```bash
gama-headless.bat -batch Batch_Aedes_3rep <chemin>/models/main.gaml
```

(le mode `-xml` ne sert qu'à valider la compilation ; il ne déroule pas la simulation.)

## 10. Lire le R₀ — et ses limites

`R₀ > 1` signifie que la transmission peut s'installer, `R₀ < 1` qu'elle s'éteint. **Rien n'impose
que R₀ vaille 1** : c'est un seuil, pas une cible. C'est le R *effectif*
(`Rₑ = R₀ × fraction de susceptibles`) qui tend vers 1 à l'équilibre endémique. Le R₀ calculé ici
est un **potentiel de transmission à abondance vectorielle donnée**, sans correction d'immunité :
c'est donc une borne haute.

Comportement attendu et vérifié : R₀ reste très en dessous de 1 en saison sèche (Ceedu), franchit 1
au passage en saison des pluies (Nduungu), et culmine avec l'abondance vectorielle.

**État après calibration (run de 75 jours, données réelles) :**

| Fenêtre | Saison | `m` (vect./hôte) | `a` | `p` | `n` (EIP) | R₀ |
|---|---|---|---|---|---|---|
| F1–F2 | Ceedu (sèche) | 2,5 → 9 | 0,031 → 0,084 | 0,88 → 0,93 | 7,2 → 10,7 j | 0,001 → 0,050 |
| F3–F7 | Nduungu (pluies) | 64 → 191 | 0,061 → 0,073 | 0,88 → 0,93 | 10,7 → 11,3 j | **0,18 → 0,53** |

`p` et `n` sont désormais conformes aux valeurs publiées (survie 0,89–0,93 ; EIP ~11 j contre
10,5 j mesurés à 28 °C), et `m` est déterminé par la biologie et non par un plafond technique.

**Ce qui limite encore le R₀ :** le taux de piqûre `a` plafonne autour de 0,07 alors que sa borne
physiologique est 1/τ ≈ 0,25–0,33. L'ajout de l'abreuvement quotidien (voir
[`docs/processus_comportementaux.md`](docs/processus_comportementaux.md) §4) a fait passer `a` de
0,06 à 0,07 et le R₀ de pic de 0,39 à 0,53, mais l'écart n'est pas comblé.

La raison est structurelle et instructive : **la production vectorielle est répartie sur les
~250 mares, alors que la présence des hôtes se concentre sur les mares proches des campements.**
Les vecteurs issus des mares inoccupées ne piquent jamais, ce qui tire la moyenne vers le bas.

Le R₀ produit ici est donc une **moyenne spatiale sur toute la zone**, qu'il ne faut pas comparer
directement aux R₀ locaux publiés pour le Ferlo — ces derniers sont cartographiés point par point
(Durand et al. 2020). La focalité de la FVR autour des mares fréquentées par le bétail est
elle-même un fait documenté (Talla et al. 2016 : la proximité d'une mare augmente le risque d'être
en hotspot).

**Prochaine étape suggérée :** calculer un R₀ *local*, restreint aux mares effectivement
fréquentées par les hôtes, pour obtenir une grandeur comparable aux cartes publiées.

**Autres points de vigilance :**

- Vérifier dans `controle_memoire.csv` que `vecteurs` reste sous `max_vecteurs` : au dernier run
  le maximum observé est 4 652 pour un plafond de 5 000, donc encore un peu juste. Augmenter
  `echelle_si_vecteur` (ou `max_vecteurs`) si la colonne sature.
- Non modélisé : transmission directe animal→humain (abattage, mise bas — route dominante chez
  l'humain), hétérogénéité du bétail et avortements, immunité inter-annuelle.
