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
    int echelle_si_vecteur <- 500;
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
    float Td_aedes     <- 7.0;      // Durée minimale de sécheresse avant éclosion
    float rho_aedes    <- 0.02;     // Transmission verticale du virus (TOT)

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
