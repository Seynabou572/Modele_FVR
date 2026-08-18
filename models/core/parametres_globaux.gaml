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
    // Portée de la recherche nocturne d hote (vol de quete). Ae. vexans parcourt
    // plusieurs km, Culex quelques centaines de metres. A CALIBRER.
    float rayon_recherche_hote_aedes <- 0.0;
    float rayon_recherche_hote_culex <- 0.0;
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
    int echelle_superindividu <- 20;
    int nb_humains_init <- 40;
    int nb_animaux_init <- 50;
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
    float mu_v    <- 1.0 / 21.0;

    // =========================================================================
    // PARAMÈTRES DE TRANSMISSION (Ross-Macdonald)
    //   b_* = probabilité de transmission vecteur -> hôte, PAR PIQÛRE
    //   c_* = probabilité de transmission hôte -> vecteur, PAR PIQÛRE
    // Le taux de piqûre est porté par le cycle gonotrophique (tau), pas ici :
    // c'est ce qui évite le double comptage de l'ancien sigma_v.
    // =========================================================================
    float p_h  <- 0.4;   // vecteur -> humain
    float p_a  <- 0.7;   // vecteur -> animal
    float p_vh <- 0.2;   // humain  -> vecteur
    float p_va <- 0.8;   // animal  -> vecteur
    float b_vh <- 0.0;
    float b_va <- 0.0;
    float c_hv <- 0.0;
    float c_av <- 0.0;

    // Fraction des repas pris sur un animal quand hôtes des deux types sont
    // disponibles (Aedes/Culex du Ferlo sont majoritairement zoophiles).
    // À CALIBRER.
    float preference_zoophilie <- 0.8;

    float duree_incubation        <- 4.0;
    float duree_infection         <- 6.0;
    float duree_cycle_extrinseque <- 10.0;   // EIP de repli si pas de température

    // =========================================================================
    // PARAMÈTRES BIOLOGIQUES DES VECTEURS
    // =========================================================================
    float kappa_aedes  <- 0.5;      // Fraction des femelles qui pondent après un repas
    float lambda_aedes <- 100.0;    // Fécondité par cycle gonotrophique (par femelle)
    float tau_aedes    <- 3.0;      // Cycle gonotrophique de repli (jours)
    float beta_aedes   <- 0.60;     // Fraction des œufs quiescents qui éclosent à l'inondation
    float phi_aedes    <- 0.995;    // Survie JOURNALIÈRE des œufs quiescents. À CALIBRER.
                                    // (appliquée jour par jour : 0.995/j => demi-vie ~140 j,
                                    //  compatible avec la survie inter-saisonnière réelle)
    float survie_larvaire_aedes <- 0.85;  // Survie journalière des stades aquatiques Aedes
    float Td_aedes     <- 7.0;      // Durée minimale de sécheresse avant éclosion
    float duree_phase_oeuf_aedes <- 7.0;  // Durée de la phase œuf (distincte de l'EIP)
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
    int   longevite_max_vecteur <- 60;  // borne de sécurité, pas le mécanisme dominant

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
