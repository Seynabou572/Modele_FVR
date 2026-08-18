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

## 2. Architecture du projet

```
Modele_FVR/
├── models/
│   ├── Model_FVR.gaml            # point d'entrée : assemble tous les modules ci-dessous
│   ├── core/                     # logique globale (pas d'agents spatiaux)
│   │   ├── donnees_chemins.gaml      # chemins vers data/, géométrie du monde (shape, zone_z3)
│   │   ├── parametres_globaux.gaml   # tous les paramètres/constantes (déclarations pures)
│   │   ├── climat.gaml               # chargement du CSV climat + reflex journalier + facteurs
│   │   ├── saisons_occsol.gaml       # calendrier des 3 saisons, (re)génération mares/campements
│   │   ├── dynamique_population.gaml # agrégation SEIR, naissances animaux/vecteurs
│   │   ├── r0_vectoriel.gaml         # calcul du R₀ (Ross-Macdonald) par fenêtre de 10 jours
│   │   ├── exports_csv.gaml          # chemins des CSV de sortie + tous les reflex d'export
│   │   └── initialisation.gaml       # le bloc init : orchestre tout le bootstrap
│   ├── environnement/            # espèces non mobiles (paysage)
│   │   ├── occsol_polygone.gaml, zone_eau_binaire.gaml, sol.gaml,
│   │   │   vegetation.gaml, route.gaml, campement.gaml, mare.gaml
│   ├── agents/                   # espèces mobiles
│   │   ├── hote.gaml (parent commun humain/animal), humain.gaml, animal.gaml, vecteur.gaml
│   └── experiments/
│       ├── experiment_gui_aedes.gaml   # expérience GUI, cas index = Aedes (EXP A)
│       ├── experiment_gui_animal.gaml  # expérience GUI, cas index = Animal (EXP B)
│       └── experiment_batch.gaml       # 4 expériences batch (3 et 1000 répétitions)
├── data/                         # données SIG/climat — voir data/README.md
└── outputs/                      # CSV générés par les simulations (ignorés par git)
```

Chaque fichier `.gaml` sous `models/` déclare son propre `model <Nom>` (obligatoire en GAML pour
qu'un fichier soit importable) ; c'est `Model_FVR.gaml` qui les assemble via des `import "...";`
en un seul modèle `ModeleFVRBarkedjiZ3`.

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
| `utiliser_ndwi_binaire` | Active un masque d'eau binaire pour forcer l'assèchement des mares hors zone d'eau (désactivé par défaut, shapefile requis — voir §6) |
| `export_detail` | Active/désactive l'écriture des CSV détaillés à chaque cycle |
| `echelle_superindividu` | Nombre d'individus réels représentés par 1 agent (défaut 20) |
| `lambda_aedes`, `rho_aedes` | Fécondité et taux de transmission verticale des Aedes |
| `sigma_v`, `p_h`, `p_a`, `p_vh`, `p_va` | Probabilités de piqûre et de transmission par contact |
| `delta_c` | Létalité de l'infection chez l'animal |
| `max_vecteurs` | Plafond de population vectorielle (limite mémoire/performance) |

## 6. Données (`data/`)

Voir [`data/README.md`](data/README.md) pour l'arborescence exacte attendue (rasters/shapefiles
d'occupation du sol, NDVI, NDWI par saison, sol, végétation, routes, climat).

Le modèle ne gère actuellement que **3 saisons** : Ceedu (jours 1–181), Nduungu (182–304),
Dabbuunde (305–365) — voir `calculer_saison` dans `core/saisons_occsol.gaml`. Un 4ᵉ jeu de
données saisonnier ("Deminaree") existe dans `data/_non_utilise/` mais n'est pas référencé par
le modèle.

La fonctionnalité NDWI binaire (`utiliser_ndwi_binaire`) est câblée dans le code mais désactivée
tant que `data/occsol/eau_binaire/eau_binaire_z3.shp` n'est pas fourni (voir
`models/core/donnees_chemins.gaml` et `models/core/initialisation.gaml`, actuellement commentés).

## 7. Sorties (`outputs/`)

Un seul jeu de CSV partagé par toutes les simulations d'un batch (chaque ligne commence par
`simulation_id`) :

| Fichier | Contenu |
|---|---|
| `journalier.csv` | Climat et saison par jour |
| `populations.csv` | Effectifs SEIR humains/animaux + total vecteurs |
| `r0_vectoriel.csv` | R₀ Aedes et R₀ tous-vecteurs par fenêtre de 10 jours |
| `incidence.csv` | Nouvelles infections et prévalence hôtes/vecteurs |
| `climat.csv` | Variables climatiques brutes (T2M, RH2M, PRECTOTCORR, WS2M) |
| `mares.csv` | Nombre de mares actives, volume/niveau moyen, œufs infectés |
| `moustiques.csv` | SEI détaillé par type de vecteur (Aedes/Culex) |
| `controle_memoire.csv` | Nombre d'agents vivants (contrôle de charge) |
| `resume.csv` | R₀ moyen et infections totales en fin de simulation |

## 8. Lancer une simulation

Ouvrir `models/Model_FVR.gaml` dans GAMA Desktop et choisir une expérience dans le menu. La
compilation du modèle a été validée avec les données réelles via `gama-headless.bat -xml` pour
les 3 types d'expérience ; l'exécution complète est à confirmer visuellement dans GAMA Desktop
(le runner headless générique de cette installation n'a pas produit de sortie exploitable lors
des tests en CLI).
