# Protocole ODD+D — modèle de transmission de la FVR dans le Ferlo

**Révision de la branche `amelioration-realisme-vectoriel`.**

Ce document met à jour le protocole ODD+D rédigé par Ndeye Seynabou Fall le
19 août 2026 (`articles/ProtocoleODD+D.pdf`, branche `na`). Il en conserve la
numérotation de sections pour rester comparable ligne à ligne, et ne réécrit que
ce que six séries de correctifs ont changé dans le code.

La description fine des onze processus comportementaux — mécanisme biologique,
source bibliographique, valeur retenue, renvoi au reflex — reste dans
[`processus_comportementaux.md`](processus_comportementaux.md), qui n'est pas
dupliqué ici.

> **Ce qui a changé depuis la version du 19 août** est signalé par un bloc
> `CHANGÉ` en tête de chaque sous-section concernée. Les sections sans bloc sont
> inchangées et restent décrites par le PDF d'origine.

---

## 1. Introduction générale

Inchangé. Le protocole ODD (Grimm et al.) et son extension ODD+D (Müller et al.
2013) restent le cadre de description. L'exemple d'application le plus proche —
même terrain, même communauté — est le `DundiModel` de Vendel (2025), thèse
UMR SENS/CIRAD sur la zone sylvo-pastorale du Ferlo.

---

## 2. Overview

### 2.1 Objectif du modèle

Inchangé quant à la question scientifique. Une précision s'impose en revanche
sur **ce que le modèle mesure**, car le PDF parle d'un R₀ unique.

> **CHANGÉ.** Le modèle produit désormais **trois grandeurs distinctes**, que la
> littérature sépare et qu'il ne faut pas confondre :
>
> | Grandeur | Ce qu'elle mesure | Rôle de `rho_aedes` |
> |---|---|---|
> | R₀ épidémiologique (Ross-Macdonald) | cas secondaires issus d'un cas index | **aucun** |
> | R₀ vectoriel de gîte, `R0(t,T)` | descendance vectorielle produite par un gîte | **aucun** |
> | Taux de report inter-saisonnier | survie du virus dans le stock d'œufs quiescents | **central** |
>
> La transmission verticale **n'entre dans aucun des deux R₀**. Chitnis et al.
> (2013) montrent que le taux de transmission verticale n'affecte pas le R₀
> mais la persistance inter-épidémique ; Pedro et al. (2016) n'obtiennent un
> effet substantiel qu'au-delà de 20 % de descendance infectée, très au-dessus
> des taux mesurés expérimentalement (revue de Cecilia et al. 2022). Le PDF du
> 19 août laisse entendre le contraire au §2.1 et au §4.3.6.

### 2.2 Public cible

Inchangé.

### 2.3 Base empirique et données de validation

> **CHANGÉ.** La validation dispose maintenant d'un critère publié explicite et
> d'un contrôle de recevabilité du forçage.
>
> **Critère de co-abondance** (Soti et al. 2012, PLoS NTD 6(8)) : sur 43 ans de
> simulation, les principales épidémies surviennent les années de forte
> abondance **simultanée** d'*Ae. vexans* et de *Cx. poicilipes*. C'est le seul
> critère de validation publié pour cette zone, et il porte sur la
> complémentarité des deux espèces, non sur l'abondance de l'une d'elles. Il est
> implémenté dans [`core/validation.gaml`](../models/core/validation.gaml) et
> exporté dans `outputs/validation.csv`.
>
> **Cible hydrologique** : Nash > 0,7 sur les hauteurs d'eau, niveau atteint par
> Soti et al. (2010) sur quatre mares de Barkedji.
>
> **Réserve en vigueur.** Le forçage climatique actuel
> (`data/climat/Climat_2025.csv`) est hors de l'enveloppe documentée : 1833 mm
> sur l'année contre 300–500 mm pour le Ferlo, avec quatre journées à
> 211–331 mm là où le modèle hydrologique de référence est calibré sur
> 0 < P < 45 mm/j. Quatre jours portent 59 % du cumul annuel. Les colonnes T2M
> et RH2M de ces mêmes journées sont cohérentes (chute de 37 à 29 °C, humidité
> à 76–86 %) : ce sont de vrais épisodes pluvieux dont seules les quantités sont
> fausses. Une action de diagnostic tourne à l'initialisation, signale l'écart
> et positionne `forcage_hors_enveloppe`, reporté dans `validation.csv` pour
> qu'aucun résultat ne puisse être lu sans cette réserve. **Aucune sortie
> entomologique ou épidémiologique n'est interprétable tant que l'extraction
> climatique n'a pas été reprise.**

### 2.4 Entités, variables d'état et échelles

> **CHANGÉ — nouvelles entités.**
>
> | Entité | Variables d'état | Rôle |
> |---|---|---|
> | `zone_suivi` | `id_zone` (Ex), `type_zone` (Ex), `classe_zone` (Ex), `surface_zone` (Ex), effectifs S/E/I/R par espèce hôte (En), Aedes et Culex infectés (En), œufs (En), `ndvi_zone` / `ndwi_zone` (En), `eau_presente` (En), `nouvelles_infections` (En), `cas_cumules` (En), `jour_premiere_infection` (En) | couche d'**observation** spatiale |
>
> `zone_suivi` est chargée depuis `data/occsol/shp/zone3_entrainements.shp`, les
> polygones d'entraînement de la classification d'occupation du sol : 796
> entités typées par le champ `Name` en trois classes — `vegetation` (501),
> `campement` (271), `mare` (24), reprises par `id_class` (6, 2, 3). C'est la
> seule couche du jeu de données portant une typologie de zones explicite.
>
> **Elle n'intervient pas dans la dynamique simulée** : elle agrège l'état des
> agents présents sur son emprise et n'a aucun effet en retour. C'est un choix
> délibéré — les sorties spatiales demandées par le protocole expérimental sont
> une question d'observation, pas de mécanisme.
>
> **CHANGÉ — nouvelles variables sur `mare`.**
>
> - Géométrie hydrologique : `S0_mare`, `V0_mare`, `alpha_forme`,
>   `hauteur_max`, `bassin_versant` (tous Ex, dérivés de `surface_max`).
> - ZPOM : `zpom_100`, `zpom_500`, `zpom_1000` (En), `fermeture_500` (En),
>   `hotes_zpom_100/500/1000` (En).
> - R₀ vectoriel : `historique_surface` (En), `rho_recouvrement` (En),
>   `lambda_gite` (En), `R0_vectoriel` (En).
>
> **CHANGÉ — échelles.** Le PDF mentionne une échelle super-individu unique
> (20). Il y en a **deux**, distinctes : `echelle_superindividu = 20` pour les
> hôtes, `echelle_si_vecteur = 2000` pour les vecteurs. Un moustique est ~10⁴
> fois plus nombreux qu'un ruminant ; avec une échelle commune, représenter une
> densité vectorielle réaliste demanderait des millions d'agents et la
> population butait sur `max_vecteurs` — `m` mesurait alors ce plafond
> technique, pas la biologie. Le rapport vecteurs/hôte du R₀ est donc calculé
> en individus réels, en repondérant par les deux échelles.
>
> *Note.* L'attribut `taille_groupe` des hôtes est affecté à
> `echelle_si_vecteur` dans `initialisation.gaml`. C'est sans conséquence — il
> n'est jamais lu du côté hôte, seul celui du vecteur l'est — mais c'est
> trompeur à la lecture et mériterait d'être nettoyé.

### 2.5 Représentation spatio-temporelle

> **CHANGÉ.** Le PDF annonce « environ 11 km × 10 km ». C'est l'emprise de la
> zone d'étude de Soti autour de Barkedji, pas celle de la zone Z3 simulée.
> L'emprise réelle, mesurée sur `zone3_entrainements.shp`, est de
> **32 065 m × 30 410 m**, ce qui confirme l'`unite_z3 ≈ 32 000` que le code
> attendait sans pouvoir le vérifier.
>
> **Attention aux projections.** Les couches ne sont pas toutes dans le même
> système : `zone3_entrainements`, `type_sol_z3` et `chemin_z3` sont en
> **UTM 28N (mètres)** ; les couches `occsol_*` sont en **coordonnées
> géographiques (degrés)**. Or `zone_z3` — dont dérive `unite_z3`, et donc tous
> les rayons de perception et de vol — est l'enveloppe d'une couche `occsol`.
> C'est un point de fragilité à traiter.

### 2.6 Diagramme conceptuel

Inchangé.

### 2.7 Ordonnancement des processus

> **CHANGÉ — l'ordre des reflex du vecteur.** Le PDF décrit la séquence
> déplacement (5) → piqûre (6) → ponte (8). L'ordre effectif est désormais
> **ponte → déplacement → repas de sang**.
>
> La femelle pond sur le gîte où elle a passé la nuit, puis disperse. Dans
> l'ordre inverse, le cas index de l'expérience A sortait de `rayon_depot_oeufs`
> avant d'avoir pondu : les deux valent `unite_z3 * 0.0012` (~38 m), et la
> marche aléatoire du cycle 0 faisait échouer l'amorçage du réservoir d'œufs
> dans environ une réplication sur cinq.
>
> Séquence à jour d'un pas de temps :
>
> 1. Mise à jour climatique (lecture CSV, facteurs de modulation)
> 2. Mise à jour saisonnière si franchissement de seuil
> 3. Bilan hydrique des mares → historique de surface
> 4. Éclosion des œufs Aedes **à la submersion de la berge**
> 5. Développement et émergence des cohortes larvaires
> 6. **Ponte** (Aedes sur berge exondée, Culex sur eau libre)
> 7. Déplacement des vecteurs
> 8. Repas de sang et transmission bidirectionnelle → journal de transmission
> 9. Transitions SEIR
> 10. Mortalité des vecteurs
> 11. Déplacement des hôtes (abreuvement quotidien prioritaire)
> 12. Accumulation des indicateurs, puis exports

---

## 3. Design concepts

### 3.1 Fondements théoriques et empiriques

> **AJOUT — forme fonctionnelle de la force d'infection.**
>
> Cecilia et al. (2022) relèvent que **29 modèles de FVR sur 43 ne justifient
> pas** leur choix de forme fonctionnelle pour la force d'infection, alors qu'il
> encode l'hypothèse de contact hôte/vecteur et détermine largement les
> prédictions. C'est le reproche principal de leur revue systématique. Le choix
> est donc explicité.
>
> Ce modèle n'utilise **aucune** des trois formes classiques (FR
> frequency-dependent réservoir, MA mass action, FI frequency-dependent
> infectieux). Le contact est **simulé, non postulé** :
>
> - le taux de piqûre par moustique est plafonné par le cycle gonotrophique,
>   `a = 1/tau(T)` — comme dans FR, et non proportionnel à la densité d'hôtes
>   comme dans MA, qui autorise un taux de piqûre au-delà de la capacité
>   physiologique ;
> - les piqûres du groupe sont **réparties** sur les seuls hôtes présents dans
>   la portée de vol, si bien que le nombre de piqûres reçues par hôte croît
>   quand les hôtes se raréfient, sans jamais dépasser ce que le groupe peut
>   délivrer.
>
> Le comportement obtenu est celui de la forme hybride de Chitnis et al. (2013),
> la plus justifiée du corpus (5 modèles sur 8 l'argumentent) : un contact borné
> aux deux extrémités, par la physiologie du vecteur d'un côté et par la
> disponibilité des hôtes de l'autre. La différence est que la borne côté hôte
> n'est pas un paramètre libre — le `sigma_h` de Chitnis, qu'ils reconnaissent
> impossible à estimer sur le terrain — mais **émerge de la géométrie** : portée
> de vol et position réelle des troupeaux.
>
> Formellement, pour un hôte recevant `k` piqûres d'un groupe infectieux :
> `p_eff = 1 − (1 − b)^(k / echelle_superindividu)`, exacte lorsque les deux
> échelles valent 1.

### 3.2 Hypothèses de décision

Inchangé pour les hôtes (voir `processus_comportementaux.md` §4, abreuvement
quotidien).

### 3.3 Adaptation et apprentissage

Inchangé.

### 3.4 Perception

> **CHANGÉ.** La ZPOM formalise ce que « perçoit » un gîte de son voisinage.
> Trois anneaux de 100, 500 et 1000 m sont construits autour de chaque mare
> (Vignolles et al. 2009 ; Soti et al. 2009). La densité d'*Ae. vexans* décroît
> linéairement jusqu'à 500 m du gîte (Bâ et al. 2005) et l'espèce dépasse
> rarement 1 km.
>
> Les trois rayons sont conservés — et non le seul rayon « pertinent » — pour
> pouvoir **refaire** la comparaison de Soti plutôt que de la présupposer : c'est
> à 500 m que l'indice de fermeture du paysage explique le mieux l'incidence
> sérologique observée à Barkedji (AICc = 25,4 ; p < 0,001).

### 3.5 Interactions

Inchangé quant au principe. Le contact hôte–vecteur est décrit en §3.1.

### 3.6 Collectifs

Inchangé.

### 3.7 Hétérogénéité

> **CHANGÉ.** Les mares sont désormais hétérogènes sur trois plans qui pilotent
> leur hydrologie : `surface_max` (issue du shapefile), `est_ensemble1`
> (appartenance au lit principal du Ferlo) et le bassin versant qui en découle.
> Soti et al. (2010) distinguent deux ensembles — les mares du lit, alimentées
> par le ruissellement, et celles hors lit, plus petites, remplies surtout par
> la pluie directe et un ruissellement de proximité.
>
> Faute d'une couche du lit fossile, l'appartenance est approchée par la
> **taille** : Soti relève que les mares hors lit sont « generally smaller »
> (80 % des mares de Barkedji font moins de 0,5 ha, 2,3 % plus de 5 ha). Le
> seuil retenu est 5 000 m². C'est un proxy assumé ; il ne pilote que la taille
> du bassin versant.

### 3.8 Stochasticité

Inchangé.

### 3.9 Observation

> **CHANGÉ — la couche d'observation est entièrement nouvelle.** La version du
> 19 août n'exportait que des **agrégats sur la zone entière**, une ligne par
> cycle. Une moyenne journalière sur toute l'aire n'a aucune variance spatiale,
> donc aucun pouvoir explicatif dans une analyse environnement → infection.
>
> Quatorze fichiers CSV sont produits, dont cinq nouveaux :
>
> | Fichier | Grain | Contenu |
> |---|---|---|
> | `zones_epidemio.csv` | zone × pas d'export | effectifs S/E/I/R par espèce, vecteurs infectés, œufs, nouvelles infections, cas cumulés, jour de première infection |
> | `zones_environnement.csv` | zone × pas d'export | NDVI, NDWI, présence et volume d'eau, météo, saison |
> | `transmissions.csv` | **événement** | une ligne par infection d'hôte : jour, espèce hôte, espèce vecteur, origine de son infection, zone, coordonnées |
> | `validation.csv` | simulation | diagnostic du forçage, pics et décalage des deux espèces, indice de co-abondance |
> | `r0_local.csv` | gîte × fenêtre | enrichi de `R0_vectoriel`, `rho_recouvrement`, ZPOM et indice de fermeture |
>
> Le **journal de transmission** répond à la question « quand et où
> l'infection est-elle apparue ». Elle était auparavant sans réponse possible :
> les hôtes ne portent que `jours_dans_etat`, remis à zéro à chaque transition,
> donc l'information sur la date d'infection était *écrasée*, pas seulement
> absente. Le journal est écrit dans `repas_sang`, au point précis où tout est
> connu — le cycle, la position, le vecteur émetteur, son espèce et son
> `origine_infection`.
>
> L'unité d'agrégation de référence est le **campement** : c'est à ce niveau que
> Soti et al. (2009) agrègent l'incidence sérologique observée à Barkedji, et
> toute sortie agrégée autrement serait incomparable à la littérature de la
> zone. La résolution de zone donne donc priorité au campement quand plusieurs
> polygones se recouvrent.

---

## 4. Details

### 4.1 Initialisation

> **CHANGÉ — les conditions initiales des deux expériences.** La version du
> 19 août créait, dans **les deux** expériences, une femelle Aedes infectée
> *plus* 100 Culex dont 5 % d'infectés. L'expérience Animal comptait donc trois
> foyers concurrents là où le protocole en demande un, et le R₀ mesuré ne
> correspondait pas à sa définition — le nombre de cas secondaires issus d'**un**
> cas index.
>
> **Expérience A — R₀ Aedes.** Une femelle *Ae. vexans* adulte infectée, posée
> sur une mare forcée à sec, qui pond dès le cycle 0. Œufs sains et infectés
> selon `rho_aedes`, avec garde-fou assurant au moins un œuf infecté pour
> amorcer le réservoir. Hôtes tous sains, **Culex tous sains**.
>
> **Expérience B — R₀ animal.** Un animal virémique, foyer unique. Aucun vecteur
> infecté.
>
> Dans les deux cas, une population Culex de fond de 100 agents est créée,
> entièrement saine (`prevalence_culex_init = 0.0`, laissé ouvert pour les
> analyses de sensibilité). Les gîtes qui la portent reçoivent un volume
> d'amorçage : la simulation démarre avant les pluies et les Culex ne survivent
> pas sur un gîte sec. C'est un artefact d'initialisation assumé, repris par le
> bilan hydrique dès le premier pas de temps.

### 4.2 Données d'entrée

#### 4.2.1 Données climatiques

Voir la réserve du §2.3. Le fichier est inchangé ; c'est son contenu qui pose
problème.

#### 4.2.2 Données spatiales

> **AJOUT.** `data/occsol/shp/zone3_entrainements.shp` — 796 polygones typés,
> UTM 28N, emprise 32 065 × 30 410 m. Récupérée depuis la branche `na`, où elle
> est stockée en Git LFS.

#### 4.2.3–4.2.5

Inchangés.

### 4.3 Sous-modèles

#### 4.3.1 Sous-modèle hydrologique

> **CHANGÉ — entièrement réécrit sur Soti et al. (2010)**, modèle calibré sur
> les mares de Barkedji elles-mêmes et validé à Nash > 0,7 sur quatre d'entre
> elles.
>
> ```
> dV/dt  = P(t)·A(t) + Qin(t) − L·A(t)        [m³/j]
> Qin(t) = Kr · Pe(t) · Ac                     ruissellement du bassin versant
> Pe(t)  = max(P − G, 0),  G = max(Gmax − Iap, 0)
> A(h)   = S0 · (h/h0)^alpha
> V(h)   = V0 · (h/h0)^(alpha+1),  V0 = S0·h0/(alpha+1)
> ```
>
> Les termes de pluie et de perte sont proportionnels à la **surface en eau**.
> La version précédente ajoutait la pluie en millimètres directement au volume
> et faisait décroître l'évaporation avec le volume (`L · V/100`) : le séchage
> était exponentiel au lieu de linéaire, l'infiltration était comptée deux fois
> — elle est déjà incluse dans `L` chez Soti — et le pic de volume atteignait
> **53 fois** le volume de référence de la mare.
>
> Paramètres, avec les plages publiées :
>
> | Paramètre | Avant | Maintenant | Plage Soti |
> |---|---|---|---|
> | `Gmax` seuil de ruissellement | 50 mm/j | **15** | 10–20 |
> | `Kr` coefficient de ruissellement | 0,5 | **0,30** | 0,15–0,40 |
> | `L_perte` | 12 (sur le volume) | 12 (**sur la surface**) | 5–20 mm/j |
> | `k_sol` | 0,9 | 0,9 | 0–1 |
> | `alpha_forme` | — (proxy linéaire) | **2,0** | 1–3 |
> | Bassin versant | 1000, constante | **n · Amax**, n = 6 (lit) / 2 (hors lit) | n ∈ [1, 20] |
>
> **L'ordre de priorité du calage est celui de l'analyse de sensibilité de
> Soti**, et il n'est pas celui qu'on devinerait : les propriétés de sol
> (`Gmax`, `k_sol`) et le coefficient de perte `L` pèsent **davantage** que la
> forme de la mare et que l'estimation du bassin versant. Corriger `Gmax` avant
> de se soucier du bassin versant.
>
> Les valeurs de `n` sont **provisoires** : sous le forçage actuel toute valeur
> sature les gîtes, et le bilan ne peut pas être calé tant que l'entrée est
> fausse (§2.3).
>
> `niveau_mare` est désormais une **hauteur** relative (`h / hauteur_max`) et
> non un ratio de volume : avec la loi puissance, les deux ne sont plus
> proportionnels, et c'est bien la hauteur qui submerge la berge portant les
> œufs.
>
> Enfin, une mare appariée au changement de saison **conserve son niveau d'eau**
> et le volume est redéduit dans la nouvelle géométrie, au lieu d'être
> réinitialisé à une fraction fixe — ce qui effaçait trois fois par an l'état du
> bilan hydrique.

#### 4.3.2 Sous-modèle entomologique

> **CHANGÉ — ponte et éclosion.**
>
> **Ponte.** *Ae. vexans* pond sur le sol humide **exondé** en bordure de mare,
> ni sur sol totalement sec ni sur l'eau libre. La condition est
> `niveau_mare < seuil_niveau_ponte_aedes`, avec une quantité proportionnelle à
> la fraction de berge découverte. L'ancienne condition exigeait
> `volume_eau = 0`, jamais vraie dès la mise en eau : la ponte devenait
> impossible toute la saison des pluies et l'espèce s'éteignait.
>
> **Toutes les femelles pondent**, infectées ou non — le PDF du 19 août indique
> au §2.7.8 que « les femelles Aedes infectées pondent », ce qui rendait la
> population vectorielle conditionnée à la présence du virus. Seule la fraction
> `rho_aedes` d'œufs infectés dépend de l'état de la mère.
>
> **Éclosion.** Le déclencheur est la **submersion de la berge portant les
> œufs** (`montee_niveau >= seuil_montee_eclosion`), et non plus une période de
> sécheresse météorologique achevée : un tel épisode ne survient jamais en
> pleine saison des pluies, si bien que les œufs s'accumulaient sans éclore.

#### 4.3.3 Sous-modèle de transmission épidémiologique

> **CHANGÉ.** Les trois reflex de contact sont fusionnés en un seul
> `repas_sang`, exécuté pour **tous** les vecteurs quel que soit leur état : le
> compteur de piqûres n'était auparavant incrémenté que pour les infectés alors
> que le dénominateur comptait tout le monde, ce qui biaisait `a` d'un facteur
> égal à la prévalence vectorielle.
>
> La transmission tient compte de l'échelle super-individu (§3.1). Chaque
> infection d'hôte alimente le journal de transmission (§3.9).

#### 4.3.4 Mobilité pastorale

Inchangé. Voir `processus_comportementaux.md` §4.

#### 4.3.5 Dynamique de la végétation

Inchangé.

#### 4.3.6 Calcul des R₀

> **CHANGÉ — titre et contenu.** Le PDF décrit « le R vectoriel
> (Ross-Macdonald) » au singulier. Il y en a trois (§2.1).
>
> **R₀ épidémiologique**, `C = m·a²·b·c·p^n / (−ln p)`, `R0 = C/r`. Les
> corrections apportées : `b` et `c` entrent dans la formule (ils en étaient
> absents), `sigma_v` n'est plus compté deux fois, `p` est **mesuré** sur la
> fenêtre à partir des morts biologiques au lieu d'être postulé, et `n` est la
> moyenne de l'EIP thermique sur la fenêtre.
>
> **Fenêtre de calcul paramétrable par expérience** : 10 jours pour le R₀
> animal, **21 jours** pour le R₀ Aedes, qui doit laisser le temps d'un cycle
> œuf → adulte. La valeur était figée à 10 ; 21 n'étant pas multiple de 10, elle
> ne pouvait pas s'obtenir en agrégeant.
>
> **R₀ de protocole.** La valeur demandée par le plan d'expérience est celle de
> la **première** fenêtre. Elle est isolée et étiquetée
> (`R0_animal_protocole`, `R0_Aedes_protocole`) plutôt que laissée à retrouver
> dans la première ligne du CSV ; les fenêtres suivantes sont du suivi
> saisonnier et ne répondent pas à la même question.
>
> **R₀ vectoriel de gîte** (Porphyre, Bicout & Sabatier 2005, Ecol. Modelling
> 183) :
>
> ```
> R0(t,T)  = rho(t,T) · Lambda / mu
> rho(t,T) = S(t | t−T) · S(t−T) / Sm²
> ```
>
> `Lambda` est la capacité de production vectorielle du gîte, `1/mu`
> l'espérance de vie de l'adulte, `T` la durée de développement œuf → émergence,
> et `rho` la fonction de disponibilité — le **recouvrement** entre la surface
> de ponte à `t−T` et la surface d'émergence à `t`. Chez *Ae. vexans*, la
> surface de ponte est la berge exondée et l'émergence a lieu sur la part de
> cette berge que la remontée du plan d'eau a submergée.
>
> C'est cette grandeur, définie **gîte par gîte et pas de temps par pas de
> temps**, qui mesure « la dynamique du vecteur ». Elle est directement une
> sortie spatiale.
>
> **Persistance inter-saisonnière.** Le stock d'œufs infectés franchissant la
> saison sèche est relevé à l'entrée en Nduungu, rapporté au pic de la saison
> précédente (`taux_report_oeufs`). C'est là, et nulle part ailleurs, que
> `rho_aedes` se mesure.

### 4.4 Validation du modèle

> **CHANGÉ.** Voir §2.3 pour les critères et la réserve sur le forçage.
> `validation.csv` réunit en une ligne par réplication le diagnostic climatique,
> les pics des deux espèces, leur décalage temporel, l'indice de co-abondance et
> les R₀ de protocole.
>
> Le décalage des pics est un indicateur de forme autant que de niveau : chez
> Soti, *Aedes* culmine peu après les premières pluies et *Culex* plus tard sur
> les mares établies. Quelques semaines sont attendues ; un décalage nul ou de
> plusieurs mois signale un problème de dynamique.

### 4.5 Diagramme fonctionnel

Inchangé sur le principe. À reprendre pour intégrer `zone_suivi`, la ZPOM et le
journal de transmission.

### 4.6 Implémentation informatique

> **CHANGÉ.** GAMA. `models/main.gaml` est le point d'entrée unique et importe
> désormais **l'intégralité** des modules — 27 fichiers `.gaml`, dont deux
> nouveaux : [`core/validation.gaml`](../models/core/validation.gaml) et
> [`environnement/zone_suivi.gaml`](../models/environnement/zone_suivi.gaml).
>
> **État de vérification.** Les modifications de cette branche n'ont pas été
> passées au validateur GAMA : aucun runtime n'était disponible sur la machine
> de développement. Les contrôles effectués sont statiques — équilibrage des
> délimiteurs sur les 27 fichiers, unicité de déclaration de chaque
> identifiant, existence de chaque action appelée, concordance des largeurs
> d'en-tête et de ligne sur les 14 fichiers CSV. **Une ouverture dans l'éditeur
> GAMA reste nécessaire avant tout run.**

---

## 5. Limites connues et travaux en attente

Cette section n'existe pas dans le PDF. Elle rassemble ce qui reste ouvert.

| # | Point ouvert | Bloque |
|---|---|---|
| 1 | **Forçage climatique hors enveloppe** : 1833 mm/an contre 300–500 ; 4 journées à 211–331 mm ; 91 jours de pluie contre 30–45 attendus. Extraction NASA POWER à reprendre. | calage hydrologique, validation entomologique, tout R₀ |
| 2 | **Bassins versants provisoires** (`n_bassin_lit`, `n_bassin_hors_lit`) : ne peuvent être calés que sous un forçage recevable. | Nash > 0,7 |
| 3 | **Validation pluriannuelle** : Soti valide sur 43 ans, le calendrier actuel couvre une saison. Décision à prendre sur la constitution d'une série longue. | critère de co-abondance |
| 4 | **Projections mixtes** : `zone_z3`, dont dérive `unite_z3` et tous les rayons, est l'enveloppe d'une couche en degrés alors que les autres sont en UTM 28N. | fiabilité des distances |
| 5 | **Appartenance au lit du Ferlo** approchée par la taille des mares, faute d'une couche du lit fossile. | hétérogénéité hydrologique |
| 6 | **Production vectorielle répartie sur toutes les mares** alors que la présence des hôtes se concentre sur celles proches des campements : les vecteurs des mares inoccupées ne piquent jamais et tirent `a` vers le bas. Le R₀ global est une moyenne spatiale, à ne pas comparer aux R₀ locaux cartographiés dans la littérature — d'où le R₀ local et le R₀ vectoriel par gîte. | interprétation du R₀ global |
| 7 | **`taille_groupe` des hôtes** affecté à `echelle_si_vecteur` : sans effet, jamais lu, mais trompeur. | lisibilité |

---

## Bibliographie complémentaire

Les références des processus biologiques sont dans
[`processus_comportementaux.md`](processus_comportementaux.md). S'y ajoutent, pour
cette révision :

- **Cecilia H. et al. (2022).** Mechanistic models of Rift Valley fever virus
  transmission: a systematic review. *PLoS Negl Trop Dis* 16(11), e0010339.
  — taxonomie des forces d'infection ; rôle de la transmission verticale.
- **Chitnis N., Hyman J.M., Manore C.A. (2013).** Modelling vertical
  transmission in vector-borne diseases with applications to Rift Valley fever.
  *J Biol Dyn* 7(1), 11–40. — le taux de transmission verticale n'affecte pas le R₀.
- **Porphyre T., Bicout D.J., Sabatier P. (2005).** Modelling the abundance of
  mosquito vectors versus flooding dynamics. *Ecol. Modelling* 183, 173–181.
  — nombre de reproduction vectoriel par gîte.
- **Soti V. et al. (2010).** The potential for remote sensing and hydrologic
  modelling to assess the spatio-temporal dynamics of ponds in the Ferlo Region.
  *Hydrol. Earth Syst. Sci.* 14, 1449–1464. — bilan hydrique, plages de
  paramètres, analyse de sensibilité.
- **Soti V. et al. (2012).** Combining hydrology and mosquito population models
  to identify the drivers of Rift Valley fever emergence in semi-arid regions of
  West Africa. *PLoS Negl Trop Dis* 6(8), e1795. — critère de co-abondance.
- **Soti V. (2011).** Caractérisation des zones et périodes à risque de la FVR
  au Sénégal. Thèse AgroParisTech. — analyse paysagère, indice de fermeture,
  agrégation au campement.
- **Vignolles C. et al. (2009).** Rift Valley fever in a zone potentially
  occupied by *Aedes vexans* in Senegal: dynamics and risk mapping.
  *Geospatial Health* 3(2), 211–220. — ZPOM, aléa × vulnérabilité.
- **Müller B. et al. (2013).** Describing human decisions in agent-based
  models — ODD+D. *Environ. Model. Softw.* 48, 37–48.
- **Vendel F. (2025).** Faire commun par les modèles. Thèse, Université Paul
  Valéry Montpellier III / UMR SENS. — application locale d'ODD+D.
