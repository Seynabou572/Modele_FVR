/**
 * PARAMÈTRES GLOBAUX — déclarations pures (aucun comportement ici).
 * Échelles, démographie, transmission, biologie des vecteurs, calendrier,
 * compartiments agrégés et bascules de fonctionnalités.
 *
 * NOTATION ROSS-MACDONALD : le taux de piqûre `a` n'est PAS un paramètre ; il
 * découle du cycle gonotrophique (a = 1/tau) dans agents/vecteur.gaml. Les
 * paramètres b_* / c_* sont les probabilités de transmission PAR PIQÛRE.
 */
model ParametresGlobaux

global {

    // =========================================================================
    // PARAMÈTRES D'EXPÉRIENCE / FONCTIONNALITÉS
    // =========================================================================
    string type_experience <- "Aedes";
    int    simulation_id   <- 1;
    bool   utiliser_ndwi_binaire <- false;
    string colonne_ndwi_binaire  <- "eau";
    list<geometry> zones_eau_binaire <- [];

    // =========================================================================
    // CALIBRATION DES ÉCHELLES
    // =========================================================================
    float unite_z3             <- 0.0;
    float vitesse_aedes        <- 0.0;
    float vitesse_culex        <- 0.0;
    float vitesse_hote_normal  <- 0.0;
    float vitesse_transhumance <- 0.0;
    float rayon_piqure_humain      <- 0.0;
    float rayon_piqure_animal      <- 0.0;
    float rayon_depot_oeufs        <- 0.0;
    float rayon_detection_v        <- 0.0;
    float rayon_recherche_paturage <- 0.0;
    float seuil_min_mare_m2            <- 300.0;
    float seuil_min_campement_m2       <- 300.0;
    float seuil_min_affichage_m2       <- 400.0;
    float seuil_appariement_saisonnier <- 0.02;
    float taille_cellule_cluster_mare  <- 1000.0;
    float taille_cellule_cluster_camp  <- 600.0;
    int   max_mares_actives     <- 250;
    int   max_campements_actifs <- 150;

    // =========================================================================
    // SUPER-INDIVIDUS
    // =========================================================================
    // Échelle des HÔTES : 1 agent = 20 têtes / 20 personnes.
    int echelle_superindividu <- 20;

    // Échelle des VECTEURS, distincte. Un moustique est ~10^4 fois plus
    // nombreux qu'un ruminant : avec une échelle commune, représenter une
    // densité vectorielle réaliste demanderait des millions d'agents, et la
    // population reste en pratique bornée par `max_vecteurs`. Le rapport
    // vecteurs/hôte `m` du R0 est donc calculé en INDIVIDUS RÉELS, en
    // repondérant par les deux échelles (voir core/r0_vectoriel.gaml).
    // Relevé à 2 000 : à 500, la population de Culex saturait `max_vecteurs`
    // dès le cycle 30. Or `action emerger` (cohorte_larvaire.gaml) crée les
    // adultes sous condition `length(vecteur) < max_vecteurs` : une fois le
    // plafond atteint, PLUS AUCUN Aedes ne pouvait émerger. Le plafond ne
    // bornait donc pas seulement `m`, il éliminait l'espèce la moins abondante.
    int echelle_si_vecteur <- 2000;
    // Densité d'hôtes calée sur la structure pastorale du Ferlo (Ancey et al.
    // 2014, Pastoralism) : un campement héberge typiquement moins de 50 bovins
    // et 50 ovins, soit ~100 têtes. Avec 150 campements et une échelle de 20
    // individus par agent, cela donne ~500 agents animaux (10 000 têtes, soit
    // 67 par campement) et ~100 agents humains (2 000 personnes, ~13 par
    // campement pour 1-2 ménages). L'ancien réglage (50 et 40 agents) ne
    // représentait que 6.7 animaux par campement, ce qui gonflait
    // artificiellement le rapport vecteurs/hôte `m` du R0.
    int nb_humains_init <- 100;
    int nb_animaux_init <- 500;
    int nb_agents_humains <- 0;
    int nb_agents_animaux <- 0;
    int nb_campements     <- 0;

    // Population Culex de fond, présente dans les deux expériences. Le protocole
    // impose qu'elle soit ENTIÈREMENT SAINE : le seul foyer initial est le cas
    // index de l'expérience. `prevalence_culex_init` n'est laissé ouvert que
    // pour les analyses de sensibilité.
    int   nb_culex_init         <- 100;
    float prevalence_culex_init <- 0.0;
    // Volume d'amorçage des seuls gîtes portant ces Culex (m³) : la simulation
    // démarre avant les pluies et les Culex ne survivent pas sur un gîte sec.
    float volume_amorce_culex   <- 80.0;

    // =========================================================================
    // PARAMÈTRES DÉMOGRAPHIQUES
    // =========================================================================
    float B_c     <- 1.0 / (5.0 * 365.0);
    float mu_c    <- 1.0 / (5.0 * 365.0);
    float delta_c <- 0.01;
    float B_v     <- 10.0;

    // =========================================================================
    // PARAMÈTRES DE TRANSMISSION (Ross-Macdonald)
    //   b_* = probabilité de transmission vecteur -> hôte, PAR PIQÛRE
    //   c_* = probabilité de transmission hôte -> vecteur, PAR PIQÛRE
    // Le taux de piqûre est porté par le cycle gonotrophique (tau), pas ici :
    // c'est ce qui évite le double comptage de l'ancien sigma_v.
    // =========================================================================
    // Compétence vectorielle mesurée sur des populations et des souches
    // SÉNÉGALAISES (Diallo et al. 2016, Parasites & Vectors) : ces probabilités
    // dépendent de l'espèce de VECTEUR, pas du type d'hôte.
    //   b_* = transmission vecteur -> hôte par piqûre (taux de transmission
    //         salivaire : Ae. vexans 13.3-33.3 %, Cx. poicilipes 11.1 %)
    //   c_* = transmission hôte -> vecteur par piqûre (taux d'infection :
    //         Ae. vexans 30-85 %, Cx. poicilipes 8.3-46.7 %)
    float b_aedes <- 0.23;
    float b_culex <- 0.11;
    float c_aedes <- 0.57;
    float c_culex <- 0.28;

    // Part des repas pris sur le bétail plutôt que sur l'humain. Ae. vexans
    // arabiensis du Ferlo est très fortement zoophile : seuls 1.28 % des repas
    // mixtes impliquaient un humain (Diallo et al. 2019, PLoS One).
    float preference_zoophilie <- 0.98;

    // WOAH : incubation 12-72 h chez les ruminants adultes.
    float duree_incubation <- 2.0;
    // Virémie expérimentale chez l'agneau/le veau : pic à J2, ~3-5 j au total.
    float duree_infection  <- 4.0;
    // EIP de repli (valeur à 28 °C, Turell et al.) si la température manque.
    float duree_cycle_extrinseque <- 10.5;

    // =========================================================================
    // PARAMÈTRES BIOLOGIQUES DES VECTEURS
    // =========================================================================
    float kappa_aedes  <- 0.5;      // Fraction des femelles qui pondent après un repas
    float lambda_aedes <- 100.0;    // Fécondité par cycle gonotrophique (par femelle)
    float tau_aedes    <- 4.0;      // Cycle gonotrophique, Ba et al. 2005 (Barkédji)
    float beta_aedes   <- 0.60;     // Fraction des œufs quiescents qui éclosent à l'inondation
    float phi_aedes    <- 0.995;    // Survie JOURNALIÈRE des œufs quiescents. À CALIBRER.
                                    // (appliquée jour par jour : 0.995/j => demi-vie ~140 j,
                                    //  compatible avec la survie inter-saisonnière réelle)
    float survie_larvaire_aedes <- 0.85;  // Survie journalière des stades aquatiques Aedes

    // =========================================================================
    // RESERVOIR D'OEUFS QUIESCENTS A L'INITIALISATION
    // =========================================================================
    // Ae. vexans passe la saison seche a l'etat d'oeuf, depose sur le sol
    // exonde en bordure de mare et resistant a la dessiccation. Une simulation
    // qui demarre en debut de saison des pluies doit donc trouver un stock
    // deja constitue : partir de zero revient a supposer que l'espece vient de
    // disparaitre de la zone, et aucune emergence n'est alors possible.
    //
    // Densite reprise de Soti et al. (2012, PLoS Negl Trop Dis 6(8)), qui
    // amorcent leur modele de Barkedji avec « an initial density of 1000
    // eggs.m-2 » proportionnelle a la surface de la mare, pour des simulations
    // demarrant le 1er juin.
    //
    // Ici le stock est reparti sur la BERGE EXONDEE (surface_max - surface_eau)
    // plutot que sur la surface totale : c'est la partie assechee qui porte les
    // oeufs, et c'est aussi la surface qu'utilise `ponte_aedes` en cours de
    // simulation. Les deux coincident quand la mare est a sec.
    float densite_oeufs_initiale_aedes <- 1000.0;   // oeufs / m2 de berge exondee

    // Fraction du stock initial deja infectee. A ZERO PAR DEFAUT : le protocole
    // des deux experiences impose un foyer unique (le cas index), et des oeufs
    // infectes en constitueraient un second. Ce parametre n'est ouvert que pour
    // etudier la persistance inter-saisonniere, ou l'hypothese d'un virus ayant
    // franchi la saison seche dans les oeufs est justement ce que l'on teste.
    float prevalence_oeufs_initiale <- 0.0;
    float Td_aedes     <- 7.0;      // Durée minimale de sécheresse avant éclosion
    // Niveau de remplissage au-dessus duquel il ne reste plus de bande exondée
    // où pondre. En dessous, la quantité pondue est proportionnelle à la
    // fraction de berge découverte (1 - niveau_mare).
    float seuil_niveau_ponte_aedes <- 0.95;
    // Montée du plan d'eau (en fraction de niveau) qui submerge la berge et
    // déclenche l'éclosion des œufs quiescents qui y ont été pondus.
    float seuil_montee_eclosion <- 0.05;
    // Transmission verticale (transovarienne). Elle N'ENTRE PAS dans le R0 :
    // Chitnis et al. (2013) montre que le taux de transmission verticale
    // n'affecte pas le R0 mais la persistance inter-épidémique ; Pedro et al.
    // (2016) ne trouve un effet substantiel qu'au-dessus de 20 % de descendance
    // infectée, très au-dessus des taux mesurés expérimentalement (revue de
    // Cecilia et al. 2022, PLoS Negl Trop Dis 16(11)). rho_aedes se mesure donc
    // sur le stock d'œufs infectés franchissant la saison sèche — voir
    // `oeufs_infectes_survivants` dans core/r0_vectoriel.gaml.
    float rho_aedes    <- 0.02;

    // =========================================================================
    // GÉOMÉTRIE ET BASSIN VERSANT DES MARES (Soti et al. 2010)
    // =========================================================================
    // Ac = n · Amax, avec n entre 1 et 20. Faute de MNT exploitable pour
    // délimiter le bassin versant réel des mares du lit du Ferlo, les deux
    // ensembles ne sont distingués que par la valeur de n : le lit principal
    // draine largement, les dépressions hors lit se remplissent surtout par la
    // pluie directe et un ruissellement de proximité.
    // VALEURS PROVISOIRES. Le calibrage propre demande la série climatique
    // corrigée : celle de data/climat/Climat_2025.csv totalise 1833 mm/an pour
    // 300-500 mm documentés au Ferlo, avec quatre journées à 211-331 mm là où
    // Soti borne le forçage à 45 mm/j. Sous ce forçage, toute valeur de n
    // sature les gîtes — le bilan ne peut pas être calé tant que l'entrée est
    // fausse. Ces valeurs restent dans la plage publiée [1, 20] et évitent la
    // saturation sous un forçage plausible.
    float n_bassin_lit      <- 6.0;
    float n_bassin_hors_lit <- 2.0;

    // Valeurs par défaut du bilan hydrique, reprises par chaque mare à sa
    // création. Elles existent au niveau global pour pouvoir être exposées aux
    // expériences : l'analyse de sensibilité de Soti et al. (2010) place les
    // propriétés de sol (Gmax, k_sol) et le coefficient de perte L DEVANT la
    // forme de la mare et l'estimation du bassin versant. Ce sont donc les
    // premiers paramètres à balayer, et les bornes reprennent les plages
    // publiées.
    float Gmax_defaut        <- 15.0;   // seuil de ruissellement, mm/j  [10-20]
    float Kr_defaut          <- 0.30;   // coefficient de ruissellement  [0.15-0.40]
    float L_perte_defaut     <- 12.0;   // pertes journalières, mm/j     [5-20]
    float k_sol_defaut       <- 0.9;    // décroissance de l'humidité    [0-1]
    float alpha_forme_defaut <- 2.0;    // exposant de la loi A(h)       [1-3]
    float hauteur_max_defaut <- 1.5;    // profondeur maximale du gîte, m
    // Surface au-delà de laquelle une mare est rattachée au lit principal.
    // Proxy de taille : Soti et al. (2010) relève que 80 % des mares de
    // Barkedji font moins de 0.5 ha et 2.3 % plus de 5 ha, les plus grandes
    // étant celles du lit fossile.
    float seuil_surface_lit_ferlo <- 5000.0;   // m²
    // Remplissage des gîtes à la (re)création saisonnière, en fraction du
    // volume maximal. Valeur de travail : la reconstruction des mares à chaque
    // changement de saison réinitialise l'état hydrique.
    float remplissage_initial_mare <- 0.30;

    // =========================================================================
    // ZPOM ET ZONAGE (Vignolles et al. 2009 ; Soti et al. 2009)
    // =========================================================================
    // Rayons des tampons autour des gîtes, en mètres. 500 m est l'échelle à
    // laquelle l'indice de fermeture du paysage explique le mieux l'incidence
    // sérologique observée à Barkedji ; 100 et 1000 m sont conservés pour
    // pouvoir refaire la comparaison au lieu de la présupposer.
    float rayon_zpom_court <- 100.0;
    float rayon_zpom_moyen <- 500.0;
    float rayon_zpom_long  <- 1000.0;

    // Formations comptées comme « fermées » dans l'indice de fermeture : les
    // couverts ligneux, arborés ou arbustifs. Les steppes et les cultures sont
    // des milieux ouverts.
    list<string> formations_fermees <- [
        "SAVANES ARBUSTIVES ET ARBOREES",
        "SAVANES ARBUSTIVES",
        "STEPPES ARBOREES"
    ];
    // Longueur de l'historique de surface en eau conservé par gîte, en jours.
    // Doit couvrir la plus longue durée de développement larvaire attendue,
    // puisque le R0 vectoriel de Porphyre compare la surface à t et à t-T.
    int   profondeur_historique_surface <- 40;

    // =========================================================================
    // FENÊTRES DE CALCUL DU R0
    // =========================================================================
    // Chaque R0 est calcule UNE SEULE FOIS, sur les premiers jours de la
    // simulation, et les deux fenetres sont independantes : 10 jours pour le
    // R0 animal, 21 pour le R0 Aedes — ce dernier doit laisser le temps d'un
    // cycle oeuf -> adulte, ce qui n'aurait pas de sens pour un R0 mesure a
    // partir d'un cas index animal.
    int fenetre_R0_animal <- 10;
    int fenetre_R0_aedes  <- 21;

    // =========================================================================
    // PERSISTANCE INTER-SAISONNIÈRE
    // =========================================================================
    // Effet réel de la transmission verticale, que le R0 ne capte pas.
    float oeufs_inf_pic     <- 0.0;   // pic du stock d'œufs infectés
    float oeufs_inf_report  <- 0.0;   // stock au retour de la saison des pluies
    float taux_report_oeufs <- 0.0;   // report / pic

    float kappa_culex  <- 0.5;
    float lambda_culex <- 150.0;
    float tau_culex    <- 3.0;
    float beta_culex   <- 0.75;     // Succès œuf -> larve
    float gamma_culex  <- 0.90;     // Survie journalière des stades pré-imaginaux
    // Capacité de charge larvaire, en individus par m² d eau. 7000/m2 est le
    // maximum physiologique cite dans la litterature, mais a cette valeur la
    // competition ne regule jamais : la population vectorielle sature alors le
    // plafond technique max_vecteurs et `m` (donc R0) devient un artefact.
    // Valeur de travail ramenee a une densite de gite productif. A CALIBRER.
    float Emax_culex   <- 300.0;

    int   max_vecteurs <- 5000;

    // ---- Survie et longévité mesurées à Barkédji (Ba et al. 2005, J Med Entomol)
    // Ae. vexans     : 94 % par la parité, 91-96 % par capture-marquage-recapture
    // Cx. poicilipes : 94 % par la parité, 70-79 % par capture-marquage-recapture
    // On retient la PARITÉ pour les deux espèces : c'est l'estimateur usuel de
    // la capacité vectorielle, et la CMR sous-estime la survie (l'émigration
    // hors de la zone de recapture est comptée comme une mortalité). Le R0 est
    // très sensible à ce choix via le terme p^n : avec 0.77 pour Culex, moins
    // de 2 % des femelles survivent à l'EIP et la transmission devient nulle.
    float survie_aedes <- 0.94;
    float survie_culex <- 0.94;
    int   longevite_max_aedes <- 26;   // âge maximal calculé, Ba et al. 2005
    int   longevite_max_culex <- 15;

    // ---- Mobilité des hôtes, en MÈTRES PAR JOUR.
    // Le bétail sahélien s'abreuve quotidiennement en saison chaude et parcourt
    // 6-10 km (bovins) ou 3-5 km (petits ruminants) entre l'aire de pâturage et
    // le point d'eau (FAO). Les campements sont installés à 100 m - 3 km d'une
    // mare, 80 % entre 1 et 1.5 km du lit du Ferlo (Chevalier et al. 2013,
    // Int J Health Geogr) : le passage quotidien à la mare est donc bien dans
    // le rayon de déplacement du troupeau, et c'est lui qui crée l'essentiel du
    // contact avec les vecteurs, qui émergent et piquent aux mares.
    float distance_abreuvement_max <- 6000.0;

    // ---- Dispersion maximale depuis le gîte (Ba et al. 2005), en MÈTRES.
    // Le shapefile est en WGS84 mais GAMA le reprojette en UTM métrique
    // (vérifiable : unite_z3 est journalisé à l'init, ~32 000 m).
    float portee_vol_aedes_m <- 620.0;
    float portee_vol_culex_m <- 550.0;

    // =========================================================================
    // MOBILITÉ PASTORALE
    // =========================================================================
    float Vseuil   <- 0.5;
    float NECseuil <- 2.5;

    // =========================================================================
    // SAISONS ET FOND DE CARTE
    // =========================================================================
    string saison <- "";
    matrix ndvi_actuel;
    matrix ndwi_actuel;
    // Emprise géographique propre à chacun de ces rasters, mémorisée en même
    // temps qu'eux. C'est elle, et non l'emprise du monde, qui convertit une
    // position en indice de pixel : les deux ne coïncident que si `shape` est
    // l'enveloppe du raster, ce qui cesse d'être vrai dès que la base spatiale
    // change (voir base_zone3 dans donnees_chemins.gaml).
    geometry env_ndvi <- nil;
    geometry env_ndwi <- nil;
    list<geometry> fond_geoms   <- [];
    list<int>      fond_classes <- [];
    list<rgb> palette_occsol <- [
        rgb(200,150,100), rgb(139,69,19),   rgb(0,51,204),
        rgb(173,232,244), rgb(34,139,34),   rgb(210,180,140),
        rgb(189,183,107), rgb(180,180,180)
    ];

    float ndvi_moyen_global <- 0.3;
    float ndwi_moyen_global <- 0.2;

    // =========================================================================
    // CALENDRIER
    // =========================================================================
    int jour_debut_simulation <- 152;
    int jour_fin_simulation   <- 334;
    int duree_simulation      <- 183;

    // =========================================================================
    // COMPARTIMENTS AGRÉGÉS
    // =========================================================================
    float S_c_global   <- 0.0;
    float E_c_global   <- 0.0;
    float I_c_global   <- 0.0;
    float R_c_global   <- 0.0;

    float S_h_global   <- 0.0;
    float E_h_global   <- 0.0;
    float I_h_global   <- 0.0;
    float R_h_global   <- 0.0;

    float S_v_global   <- 0.0;
    float E_v_global   <- 0.0;
    float I_v_global   <- 0.0;
    float incidence_c  <- 0.0;
    float incidence_v  <- 0.0;
    float prevalence_c <- 0.0;
    float prevalence_v <- 0.0;
    int   nb_infections_totales <- 0;

    // =========================================================================
    // RÉSEAU ROUTIER
    // =========================================================================
    graph reseau_routier;
}
