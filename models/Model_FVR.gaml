/**
 * MODÈLE FVR — Zone Z3, Barkedji (Sénégal) — Saison des pluies 2025
 * ---------------------------------------------------------------------------
 */
model ModeleFVRBarkedjiZ3

global {

    // =========================================================================
    // 1. FICHIERS DE DONNÉES
    // =========================================================================
    map<string, file> occsol_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/raster_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/raster_z3.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/raster_z3_Debbundu.tif")
    ];
    map<string, file> occsol_shp_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/occsol_z3_Ceedu2025.shp"),
        "Nduungu"   :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/occsol_z3_Nduungu2025.shp"),
        "Dabbuunde" :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/occsol_z3_Dabbuunde2025.shp")
    ];
    map<string, file> ndvi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndvi_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndvi_z3_Nduungu.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndvi_z3_Dabbuunde.tif")
    ];
    map<string, file> ndwi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndwi_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndwi_z3_Nduungu.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/ndwi_z3_Dabbuunde.tif")
    ];
    file OCCSOL_SHP     <- file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/occsol_z3_Ceedu2025.shp");
    file SOL_SHP        <- file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/type_sol_z3.shp");
    file VEGETATION_SHP <- file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/type_vegetation_z3.shp");
    file ROUTE_SHP      <- file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/chemin_z3.shp");
    file CLIMAT_CSV     <- file("C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/Climat_2025.csv");

    // =========================================================================
    // 2. MONDE ET GÉOMÉTRIE
    // =========================================================================
    geometry shape   <- envelope(occsol_raster_saisons["Nduungu"]);
    geometry zone_z3 <- envelope(OCCSOL_SHP);

    // =========================================================================
    // 3. PARAMÈTRES D'EXPÉRIENCE
    // =========================================================================
    string type_experience <- "Aedes";
    int    simulation_id   <- 1;

    // =========================================================================
    // 4. CALIBRATION DES ÉCHELLES
    // =========================================================================
    float echelle_affichage    <- 1.0;
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
    // 5. SUPER-INDIVIDUS
    // =========================================================================
    int echelle_superindividu     <- 20;
    int population_humaine_reelle <- 800;
    int population_animale_reelle <- 1000;
    int nb_humains_init <- 40;
    int nb_animaux_init <- 50;
    int nb_agents_humains <- 0;
    int nb_agents_animaux <- 0;
    int nb_campements     <- 0;

    // =========================================================================
    // 6. PARAMÈTRES DÉMOGRAPHIQUES
    // =========================================================================
    float B_c     <- 1.0 / (5.0 * 365.0);
    float mu_c    <- 1.0 / (5.0 * 365.0);
    float delta_c <- 0.01;
    float B_v     <- 10.0;
    float mu_v    <- 1.0 / 21.0;

    // =========================================================================
    // 7. PARAMÈTRES DE TRANSMISSION
    // =========================================================================
    float sigma_v <- 0.3;
    float p_h     <- 0.4;
    float p_a     <- 0.7;
    float p_vh    <- 0.2;
    float p_va    <- 0.8;
    float beta_vh <- 0.0;
    float beta_va <- 0.0;
    float beta_hv <- 0.0;
    float beta_av <- 0.0;
    float duree_incubation        <- 4.0;
    float duree_infection         <- 6.0;
    float duree_cycle_extrinseque <- 10.0;

    // =========================================================================
    // 8. PARAMÈTRES BIOLOGIQUES DES VECTEURS
    // =========================================================================
    float kappa_aedes  <- 0.5;		//Fraction des femelles qui pondent après un repas
    float lambda_aedes <- 100.0;	//Fécondité par cycle gonotrophique
    float tau_aedes    <- 3.0;		//Cycle gonotrophique (intervalle entre repas de sang et ponte)
    float beta_aedes   <- 0.60;		//Taux de succès d’éclosion (probabilité de base)
    float phi_aedes    <- 0.80;		//Survie journalière des œufs en période sèche
    float Td_aedes     <- 7.0;		//Durée minimale de sécheresse avant déclenchement de l’éclosion
    float T_aedes      <- 7.0;		//Durée de la phase œuf (incubation en conditions sèches)
    float rho_aedes    <- 0.02;		//Transmission verticale du virus (TOT)

    float kappa_culex  <- 0.5;
    float lambda_culex <- 150.0;
    float tau_culex    <- 3.0;
    float beta_culex   <- 0.75;
    float gamma_culex  <- 0.90;		//Survie journalière des stades pré-imaginaux
    float T_culex      <- 13.0;
    float Emax_culex   <- 7000.0;	//Densité larvaire maximale(7000 individus/m²)

    float proba_activite_aedes <- 0.3;		//Probabilité journalière qu’un moustique cherche à piquer
    float proba_activite_culex <- 0.5;

    int max_vecteurs <- 5000;

    // =========================================================================
    // 9. VARIABLES CLIMATIQUES
    // =========================================================================
    float temperature       <- 28.0;
    float humidite_relative <- 30.0;
    float pluie             <- 0.0;
    float vitesse_vent      <- 3.0;
    list<float> climat_T2M         <- [];
    list<float> climat_RH2M        <- [];
    list<float> climat_PRECTOTCORR <- [];
    list<float> climat_WS2M        <- [];
    int   nb_lignes_climat        <- 0;
    int   jours_sans_pluie_global <- 0;
    float pluie_cumulee           <- 0.0;
    float facteur_temperature     <- 1.0;
    float facteur_humidite        <- 1.0;
    float facteur_vent            <- 1.0;		// module l'activité de piqûre selon le vent
    int   seuil_assechement_mare    <- 45;
    float seuil_eclosion_cumulee    <- 15.0;
    float optimum_thermique_vecteur <- 27.0;
    float largeur_thermique_vecteur <- 8.0;

    // =========================================================================
    // 10. MOBILITÉ PASTORALE
    // =========================================================================
    float Vseuil   <- 0.5;
    float NECseuil <- 2.5;

    // =========================================================================
    // 11. SAISONS ET FOND DE CARTE
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
    // 11bis. NDWI BINAIRE (OPTIONNEL)
    // =========================================================================
    bool   utiliser_ndwi_binaire     <- false;
   // string chemin_ndwi_binaire_shp   <- "C:/Users/user/Desktop/NSF/eau_binaire_z3.shp";
    string colonne_ndwi_binaire      <- "eau";
    list<geometry> zones_eau_binaire <- [];

    // =========================================================================
    // 12. CALENDRIER
    // =========================================================================
    int jour_debut_simulation <- 152;
    int jour_fin_simulation   <- 334;
    int duree_simulation      <- 183;

    // =========================================================================
    // 13. COMPARTIMENTS AGRÉGÉS
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
    // 14. R₀ VECTORIEL — FORMULE ROSS-MACDONALD
    // R0_animal = R0 "tous vecteurs confondus" (Aedes + Culex). C'est le SEUL
    // calcul de R0 côté animal désormais (le mécanisme "indépendant" a été
    // supprimé, voir en-tête du fichier, point 1).
    // =========================================================================
    float p_survie_vect  <- 0.0;
    float ln_p_survie_vect <- -9999.0;
    float n_Aedes        <- 0.0;
    float n_animal       <- 0.0;
    float r_hote         <- 0.0;

    float cumul_m_Aedes       <- 0.0;
    float cumul_bites_Aedes   <- 0.0;
    float cumul_vecteurs_Aedes_jours <- 0.0;

    float cumul_m_vect        <- 0.0;
    float cumul_bites_vect    <- 0.0;
    float cumul_vecteurs_vect_jours <- 0.0;

    int   nb_jours_fenetre <- 0;
    int   num_fenetre      <- 0;

    float m_Aedes_10j   <- 0.0;
    float a_Aedes_10j   <- 0.0;
    float C_Aedes_10j   <- 0.0;
    float R0_Aedes_10j  <- 0.0;

    float m_animal_10j  <- 0.0;
    float a_animal_10j  <- 0.0;
    float C_animal_10j  <- 0.0;
    float R0_animal_10j <- 0.0;

    // Accumulateurs pour le R0 MOYEN sur toute la simulation
    float somme_R0_Aedes    <- 0.0;
    int   nb_R0_Aedes        <- 0;
    float somme_R0_animal   <- 0.0;
    int   nb_R0_animal       <- 0;

    // =========================================================================
    // 15. RÉSEAU ROUTIER
    // =========================================================================
    graph reseau_routier;

    // =========================================================================
    // 16. SORTIES CSV
    // UN SEUL JEU DE FICHIERS PARTAGÉ PAR TOUTES LES SIMULATIONS D'UN BATCH
    // (voir point 2 en en-tête du fichier). Chaque ligne exportée porte
    // simulation_id en première colonne.
    // =========================================================================
    string csv_journalier       <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/journalier.csv";
    string csv_populations      <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/populations.csv";
    string csv_r0_vectoriel     <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/r0_vectoriel.csv";
    string csv_r0_animal        <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/r0_animal.csv";
    string csv_incidence        <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/incidence.csv";
    string csv_climat           <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/climat.csv";
    string csv_mares            <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/mares.csv";
    string csv_moustiques       <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/moustiques.csv";
    string csv_controle_memoire <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/controle_memoire.csv";
    string csv_resume           <- "C:/Users/bmd/OneDrive/Desktop/GAMA/DONNES_OCCUPATION/occsol_2025_2/resume.csv"; 

    bool export_detail  <- true;

    // =========================================================================
    // FONCTIONS UTILITAIRES
    // =========================================================================
    string calculer_saison(int jour) {
        if (jour <= 181) { return "Ceedu"; }
        if (jour <= 304) { return "Nduungu"; }
        return "Dabbuunde";
    }

    int classe_occsol_au_point(point pt) { return -1; }

    float ndvi_moyen_au_point(point pt, float rayon_m) {
        if (ndvi_actuel = nil) { return 0.3; }
        geometry env <- shape;
        int ncols <- ndvi_actuel.columns;
        int nrows <- ndvi_actuel.rows;
        if (ncols = 0 or nrows = 0) { return 0.3; }
        float xmin       <- env.location.x - env.width  / 2;
        float ymax       <- env.location.y + env.height / 2;
        float pixel_size <- env.width / ncols;
        int col      <- int((pt.x - xmin) / env.width  * ncols);
        int row      <- int((ymax - pt.y)  / env.height * nrows);
        int rayon_px <- max(1, int(rayon_m / pixel_size));
        list<float> valeurs <- [];
        loop cx from: max(0, col - rayon_px) to: min(ncols-1, col + rayon_px) {
            loop ry from: max(0, row - rayon_px) to: min(nrows-1, row + rayon_px) {
                add float(ndvi_actuel[cx, ry]) to: valeurs;
            }
        }
        return (empty(valeurs)) ? 0.3 : mean(valeurs);
    }

    float ndwi_moyen_au_point(point pt, float rayon_m) {
        if (ndwi_actuel = nil) { return 0.2; }
        geometry env <- shape;
        int ncols <- ndwi_actuel.columns;
        int nrows <- ndwi_actuel.rows;
        if (ncols = 0 or nrows = 0) { return 0.2; }
        float xmin       <- env.location.x - env.width  / 2;
        float ymax       <- env.location.y + env.height / 2;
        float pixel_size <- env.width / ncols;
        int col      <- int((pt.x - xmin) / env.width  * ncols);
        int row      <- int((ymax - pt.y)  / env.height * nrows);
        int rayon_px <- max(1, int(rayon_m / pixel_size));
        list<float> valeurs <- [];
        loop cx from: max(0, col - rayon_px) to: min(ncols-1, col + rayon_px) {
            loop ry from: max(0, row - rayon_px) to: min(nrows-1, row + rayon_px) {
                add float(ndwi_actuel[cx, ry]) to: valeurs;
            }
        }
        return (empty(valeurs)) ? 0.2 : mean(valeurs);
    }

    list<geometry> clusteriser_par_grille(list<geometry> polys, float taille_cellule) {
        map<string, list<geometry>> cellules <- [];
        loop g over: polys {
            point c  <- g.location;
            int cx   <- int(c.x / taille_cellule);
            int cy   <- int(c.y / taille_cellule);
            string cle <- string(cx) + "_" + string(cy);
            list<geometry> courant <- (cellules contains_key cle) ? cellules[cle] : [];
            add g to: courant;
            cellules[cle] <- courant;
        }
        list<geometry> resultats <- [];
        loop cle over: cellules.keys {
            list<geometry> lg <- cellules[cle];
            add ((length(lg) = 1) ? lg[0] : union(lg)) to: resultats;
        }
        return resultats;
    }

    // =========================================================================
    // ACTION : CALCUL ET EXPORT R₀ PAR FENÊTRE DE 10 JOURS
    // Calcule R0_Aedes (Aedes seuls) ET R0_animal (TOUS vecteurs confondus,Aedes + Culex)
    // =========================================================================
    action calculer_et_exporter_R0 {

        num_fenetre <- num_fenetre + 1;
        int j_debut <- (num_fenetre - 1) * 10 + 1;
        int j_fin   <- num_fenetre * 10;

        write "==================================================";
        write "SIMULATION " + simulation_id + " | EXPÉRIENCE " + type_experience;
        write "FENÊTRE R₀ : J" + j_debut + "–J" + j_fin;
        write "==================================================";


        // ========================
        // EXPÉRIENCE A — Aedes
        // ========================
        m_Aedes_10j  <- (nb_jours_fenetre > 0) ? (cumul_m_Aedes / nb_jours_fenetre) : 0.0;
        a_Aedes_10j  <- (cumul_vecteurs_Aedes_jours > 0.0)
                        ? (cumul_bites_Aedes / cumul_vecteurs_Aedes_jours) : 0.0;

        if (m_Aedes_10j >= 0.0 and a_Aedes_10j >= 0.0
            and p_survie_vect > 0.0 and p_survie_vect < 1.0 and n_Aedes >= 0.0
            and ln_p_survie_vect < 0.0) {
            C_Aedes_10j  <- (m_Aedes_10j * a_Aedes_10j * a_Aedes_10j
                             * (p_survie_vect ^ n_Aedes)) / (-ln_p_survie_vect);
            R0_Aedes_10j <- (r_hote > 0.0) ? (C_Aedes_10j / r_hote) : 0.0;
        } else {
            C_Aedes_10j  <- 0.0;
            R0_Aedes_10j <- 0.0;
        }

        write "AEDES : m=" + with_precision(m_Aedes_10j, 4)
            + " | a=" + with_precision(a_Aedes_10j, 4)
            + " | C=" + with_precision(C_Aedes_10j, 4)
            + " | R0_Aedes=" + with_precision(R0_Aedes_10j, 4);

        // ========================
        // "ANIMAL" — tous vecteurs confondus (Aedes + Culex)
        // ========================
        m_animal_10j  <- (nb_jours_fenetre > 0) ? (cumul_m_vect / nb_jours_fenetre) : 0.0;
        a_animal_10j  <- (cumul_vecteurs_vect_jours > 0.0)
                         ? (cumul_bites_vect / cumul_vecteurs_vect_jours) : 0.0;

        if (m_animal_10j >= 0.0 and a_animal_10j >= 0.0
            and p_survie_vect > 0.0 and p_survie_vect < 1.0 and n_animal >= 0.0
            and ln_p_survie_vect < 0.0) {
            C_animal_10j  <- (m_animal_10j * a_animal_10j * a_animal_10j
                              * (p_survie_vect ^ n_animal)) / (-ln_p_survie_vect);
            R0_animal_10j <- (r_hote > 0.0) ? (C_animal_10j / r_hote) : 0.0;
        } else {
            C_animal_10j  <- 0.0;
            R0_animal_10j <- 0.0;
        }

        write "ANIMAL : m=" + with_precision(m_animal_10j, 4)
            + " | a=" + with_precision(a_animal_10j, 4)
            + " | C=" + with_precision(C_animal_10j, 4)
            + " | R0_animal=" + with_precision(R0_animal_10j, 4);
        write "==================================================";

        somme_R0_Aedes  <- somme_R0_Aedes + R0_Aedes_10j;
        nb_R0_Aedes     <- nb_R0_Aedes + 1;
        somme_R0_animal <- somme_R0_animal + R0_animal_10j;
        nb_R0_animal    <- nb_R0_animal + 1;


        if (simulation_id = 1 and num_fenetre = 1) {
            save ["simulation_id","experience","fenetre","jour_debut","jour_fin",
                  "m_Aedes","a_Aedes","C_Aedes","R0_Aedes",
                  "m_animal","a_animal","C_animal","R0_animal",
                  "saison","temperature_C","pluie_mm","humidite_pct"]
                to: csv_r0_vectoriel format: "csv" rewrite: true;
        }
        save [simulation_id, type_experience, num_fenetre, j_debut, j_fin,
              with_precision(m_Aedes_10j, 6),   with_precision(a_Aedes_10j, 6),
              with_precision(C_Aedes_10j, 6),   with_precision(R0_Aedes_10j, 6),
              with_precision(m_animal_10j, 6),  with_precision(a_animal_10j, 6),
              with_precision(C_animal_10j, 6),  with_precision(R0_animal_10j, 6),
              saison, with_precision(temperature, 2),
              with_precision(pluie, 2), with_precision(humidite_relative, 2)]
            to: csv_r0_vectoriel format: "csv" rewrite: false;

        cumul_m_Aedes              <- 0.0;
        cumul_bites_Aedes          <- 0.0;
        cumul_vecteurs_Aedes_jours <- 0.0;
        cumul_m_vect               <- 0.0;
        cumul_bites_vect           <- 0.0;
        cumul_vecteurs_vect_jours  <- 0.0;
        nb_jours_fenetre           <- 0;
    }

    // =========================================================================
    // ACTION : INITIALISATION DES 100 CULEX — utilisée par EXP A et EXP B.
    // =========================================================================
    action initialiser_culex_100(mare mare_exclue) {
        int nb_culex_init <- 100;
        int nb_infectes   <- int(nb_culex_init * 0.05);
        list<mare> mares_dispo <- list((mare_exclue = nil) ? mare : (mare - mare_exclue));

        if (!empty(mares_dispo)) {
            loop i from: 0 to: nb_culex_init - 1 {
                mare m_c <- mares_dispo[i mod length(mares_dispo)];
                m_c.volume_eau  <- 80.0;
                m_c.surface_eau <- min(m_c.surface_max, m_c.volume_eau * 2.0);

                if (length(vecteur) < max_vecteurs) {
                    bool infecte <- (i < nb_infectes);
                    create vecteur {
                        type_vecteur      <- "culex";
                        etat_sante        <- infecte ? "I" : "S";
                        taille_groupe     <- echelle_superindividu;
                        vitesse           <- vitesse_culex;
                        mare_origine      <- m_c;
                        location          <- m_c.location;
                        age               <- rnd(0, 5);
                        jours_dans_etat   <- 0;
                        est_cas_index_A   <- false;
                        est_cas_index_B   <- false;
                        origine_infection <- infecte ? "horizontale" : "aucune";
                    }
                }
            }
            write "Culex initiaux : " + nb_culex_init + " créés (" + nb_infectes
                + " infectés à 5%), positionnés exactement sur les mares (volume_eau=80.0).";
        }
    }

    // =========================================================================
    // ACTION : MISE À JOUR OCCSOL SAISONNIÈRE
    // =========================================================================
    action mettre_a_jour_occsol_saisonnier(string nouvelle_saison) {
        write "--- Saison " + nouvelle_saison + " (DOY " + (jour_debut_simulation + cycle) + ") ---";
        ndvi_actuel <- matrix(ndvi_raster_saisons[nouvelle_saison]);
        ndwi_actuel <- matrix(ndwi_raster_saisons[nouvelle_saison]);

        create occsol_polygone from: occsol_shp_saisons[nouvelle_saison]
            with: [classe :: int(read("class"))];

        list<geometry> brutes_mares <- (occsol_polygone where (each.classe = 2)) collect each.shape;
        list<geometry> brutes_camps <- (occsol_polygone where (each.classe = 1)) collect each.shape;

        list<geometry> parties_mares <- clusteriser_par_grille(brutes_mares, taille_cellule_cluster_mare);
        list<geometry> parties_camps <- clusteriser_par_grille(brutes_camps, taille_cellule_cluster_camp);

        parties_mares <- parties_mares where (area(each) > seuil_min_mare_m2);
        parties_camps <- parties_camps where (area(each) > seuil_min_campement_m2);

        if (length(parties_mares) > max_mares_actives) {
            list<geometry> tri   <- parties_mares sort_by (-area(each));
            list<geometry> tronc <- [];
            loop i from: 0 to: max_mares_actives - 1 { add tri[i] to: tronc; }
            parties_mares <- tronc;
        }
        if (length(parties_camps) > max_campements_actifs) {
            list<geometry> tri   <- parties_camps sort_by (-area(each));
            list<geometry> tronc <- [];
            loop i from: 0 to: max_campements_actifs - 1 { add tri[i] to: tronc; }
            parties_camps <- tronc;
        }

        list<geometry> mares_restantes <- copy(parties_mares);
        ask mare {
            if (!empty(mares_restantes)) {
                geometry plus_proche <- mares_restantes with_min_of (each distance_to location);
                if ((plus_proche distance_to location) < (unite_z3 * seuil_appariement_saisonnier)) {
                    shape       <- plus_proche;
                    location    <- plus_proche.centroid;
                    surface_max <- area(plus_proche);
                    volume_eau  <- surface_max * 0.30;
                    surface_eau <- min(surface_max, volume_eau * 2.0);
                    remove plus_proche from: mares_restantes;
                }
            }
        }
        if (!empty(mares_restantes)) {
            create mare from: mares_restantes {
                surface_max <- area(shape);
                volume_eau  <- surface_max * 0.30;
                surface_eau <- min(surface_max, volume_eau * 2.0);
            }
        }

        list<geometry> camps_restants <- copy(parties_camps);
        ask campement {
            if (!empty(camps_restants)) {
                geometry plus_proche <- camps_restants with_min_of (each distance_to location);
                if ((plus_proche distance_to location) < (unite_z3 * seuil_appariement_saisonnier)) {
                    remove plus_proche from: camps_restants;
                }
            }
        }
        if (!empty(camps_restants)) { create campement from: camps_restants; }
        nb_campements <- length(campement);

        if (length(mare) = 0) {
            create mare from: [zone_z3.centroid buffer (unite_z3 * 0.01)] {
                surface_max <- area(shape); volume_eau <- surface_max * 0.05;
                surface_eau <- min(surface_max, volume_eau * 2.0);
            }
        }
        if (length(campement) = 0) {
            create campement from: [zone_z3.centroid buffer (unite_z3 * 0.005)];
            nb_campements <- 1;
        }

        fond_geoms   <- [];
        fond_classes <- [];
        list<occsol_polygone> tous_polys <- list(occsol_polygone);
        int nb_total_polys  <- length(tous_polys);
        int pas_echantillon <- max(1, int(nb_total_polys / 3000));
        loop i from: 0 to: nb_total_polys - 1 step: pas_echantillon {
            occsol_polygone p <- tous_polys[i];
            if (area(p.shape) > seuil_min_affichage_m2) {
                add p.shape  to: fond_geoms;
                add p.classe to: fond_classes;
            }
        }
        ask occsol_polygone { do die; }
        write "Saison " + nouvelle_saison + " : " + length(mare) + " mares, "
            + nb_campements + " campements, " + length(fond_geoms) + " polygones.";
    }

    // =========================================================================
    // INITIALISATION
    // =========================================================================
    init {
        write "========== INIT FVR Z3 | Expérience=" + type_experience
            + " | SimID=" + simulation_id + " ==========";

        pluie_cumulee           <- 0.0;
        jours_sans_pluie_global <- 0;
        facteur_temperature     <- 1.0;
        facteur_humidite        <- 1.0;
        facteur_vent            <- 1.0;

        unite_z3          <- min(zone_z3.width, zone_z3.height);
        echelle_affichage <- max(shape.width, shape.height) / 1000.0;

        vitesse_aedes        <- unite_z3 * 0.0006;
        vitesse_culex        <- unite_z3 * 0.0012;
        vitesse_hote_normal  <- unite_z3 * 0.0004;
        vitesse_transhumance <- unite_z3 * 0.006;
        rayon_detection_v        <- unite_z3 * 0.0025;
        rayon_piqure_humain      <- unite_z3 * 0.0015;
        rayon_piqure_animal      <- unite_z3 * 0.0018;
        rayon_depot_oeufs        <- unite_z3 * 0.0012;
        rayon_recherche_paturage <- unite_z3 * 0.05;

        p_survie_vect   <- exp(-mu_v);
        ln_p_survie_vect <- (p_survie_vect > 0.0 and p_survie_vect < 1.0) ? ln(p_survie_vect) : -9999.0;
        n_Aedes       <- duree_cycle_extrinseque;
        n_animal      <- duree_cycle_extrinseque;
        r_hote        <- (duree_infection > 0.0) ? 1.0 / duree_infection : 0.0;

        write "Paramètres R₀ fixes :";
        write "  p = exp(-mu_v) = exp(-" + with_precision(mu_v, 5) + ") = "
            + with_precision(p_survie_vect, 6);
        write "  ln(p) = " + with_precision(ln_p_survie_vect, 6);
        write "  n_Aedes = " + n_Aedes + " j";
        write "  n_animal = " + n_animal + " j";
        write "  r = 1/duree_infection = 1/" + duree_infection + " = "
            + with_precision(r_hote, 4);

        matrix donnees_climat <- matrix(CLIMAT_CSV);
        int nb_lignes_fichier <- donnees_climat.rows;
        int ligne_debut <- max(1, min(nb_lignes_fichier - 1, jour_debut_simulation));
        int ligne_fin   <- max(1, min(nb_lignes_fichier - 1, jour_fin_simulation));
        loop i from: ligne_debut to: ligne_fin {
            try {
                add float(donnees_climat[2, i]) to: climat_T2M;
                add float(donnees_climat[3, i]) to: climat_RH2M;
                add float(donnees_climat[4, i]) to: climat_PRECTOTCORR;
                add float(donnees_climat[5, i]) to: climat_WS2M;
            } catch { }
        }
        nb_lignes_climat <- length(climat_T2M);
        if (nb_lignes_climat > 0) {
            temperature       <- climat_T2M[0];
            humidite_relative <- climat_RH2M[0];
            pluie             <- climat_PRECTOTCORR[0];
            vitesse_vent      <- climat_WS2M[0];
        }
        write "Climat : " + nb_lignes_climat + " jours chargés.";

        create route from: ROUTE_SHP with: [
            code_route   :: int(read("CODE")),
            classe_route :: int(read("CLASSE")),
            revet        :: int(read("REVET")),
            repert       :: int(read("REPERT"))
        ];
        create sol from: SOL_SHP with: [
            msd    :: int(read("MSD")),
            msdnom :: string(read("MSDNOM"))
        ];
        create vegetation from: VEGETATION_SHP with: [
            formcode  :: int(read("FORMCODE")),
            formation :: string(read("FORMATION"))
        ];
        ask sol       { do calculer_proprietes_sol; }
        ask vegetation { do calculer_capacite_vegetation; }


        saison <- calculer_saison(jour_debut_simulation);
        do mettre_a_jour_occsol_saisonnier(saison);

        beta_vh <- p_h  * sigma_v;
        beta_va <- p_a  * sigma_v;
        beta_hv <- p_vh * sigma_v;
        beta_av <- p_va * sigma_v;

        nb_agents_humains <- nb_humains_init;
        nb_agents_animaux <- nb_animaux_init;

        loop i from: 0 to: nb_agents_humains - 1 {
            campement camp <- (empty(campement)) ? nil : campement[i mod nb_campements];
            if (camp != nil) {
                create humain {
                    campement_origine <- camp;
                    taille_groupe     <- echelle_superindividu;
                    location <- camp.location + {
                        rnd(-rayon_piqure_humain * 2, rayon_piqure_humain * 2),
                        rnd(-rayon_piqure_humain * 2, rayon_piqure_humain * 2)
                    };
                    if (!(zone_z3 covers location)) { location <- camp.location; }
                    etat_sante      <- "S";
                    jours_dans_etat <- 0;
                }
            }
        }

        loop i from: 0 to: nb_agents_animaux - 1 {
            campement camp <- (empty(campement)) ? nil : campement[i mod nb_campements];
            if (camp != nil) {
                create animal {
                    campement_origine <- camp;
                    taille_groupe     <- echelle_superindividu;
                    location <- camp.location + {
                        rnd(-rayon_piqure_animal * 3, rayon_piqure_animal * 3),
                        rnd(-rayon_piqure_animal * 3, rayon_piqure_animal * 3)
                    };
                    if (!(zone_z3 covers location)) { location <- camp.location; }
                    etat_sante      <- "S";
                    jours_dans_etat <- 0;
                    NEC             <- 3.5;
                }
            }
        }

        ask animal {
            if (length(humain) > 0) {
                humain h <- one_of(humain);
                berger <- h;
                h.troupeaux_associes <- h.troupeaux_associes union [self];
            }
        }
        write "Humains : " + length(humain) + " agents S. Animaux : " + length(animal) + " agents S.";

        if (type_experience = "Aedes") {
            mare mare_reference <- nil;
            if (!empty(mare)) {
                mare_reference <- first(mare);
                mare_reference.volume_eau  <- 0.0;
                mare_reference.surface_eau <- 0.0;
                write "EXP A : mare de référence forcée sèche (volume_eau=0).";

                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- mare_reference;
                    location         <- mare_reference.location;
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- true;
                    est_cas_index_B  <- false;
                    origine_infection <- "verticale";
                }
                write "EXP A : 1 femelle Aedes adulte infectée (cas index, origine_infection=verticale) créée.";
                write "   Positionnée exactement sur la mare sèche : pondra dès le jour 0 (transmission_verticale,";
                write "   reflex exécuté avant l'incrémentation de l'âge dans mourir) œufs infectés + sains (rho_aedes).";
            }

            do initialiser_culex_100(mare_reference);

        } else if (type_experience = "Animal") {
            if (length(animal) > 0) {
                animal a_index <- first(animal);
                a_index.etat_sante      <- "I";
                a_index.jours_dans_etat <- 0;
                a_index.est_cas_index_B <- true;
                write "EXP B : 1 animal I créé comme cas index.";
            }

            mare mare_seche <- nil;
            if (!empty(mare)) {
                mare_seche <- first(mare);
                mare_seche.volume_eau  <- 0.0;
                mare_seche.surface_eau <- 0.0;

                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- mare_seche;
                    location         <- mare_seche.location;
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- false;
                    est_cas_index_B  <- true;
                    origine_infection <- "verticale";
                }
                write "EXP B : 1 femelle Aedes adulte infectée (cas index B, origine_infection=verticale) créée.";
                write "   Positionnée exactement sur la mare sèche (volume_eau=0) : pondra dès le jour 0.";
            }

            do initialiser_culex_100(mare_seche);
        }

        reseau_routier <- as_edge_graph(route);


        if (simulation_id = 1) {
            save ["simulation_id","cycle","jour_annee","saison","temperature_C","humidite_pct","pluie_mm","vent_ms"]
                to: csv_journalier format: "csv" rewrite: true;
            save ["simulation_id","cycle","humains_S","humains_E","humains_I","humains_R",
                  "animaux_S","animaux_E","animaux_I","animaux_R","vecteurs_total"]
                to: csv_populations format: "csv" rewrite: true;
            save ["simulation_id","cycle","incidence_hotes","incidence_vecteurs","prevalence_hotes","prevalence_vecteurs"]
                to: csv_incidence format: "csv" rewrite: true;
            save ["simulation_id","cycle","YEAR","DOY","T2M","RH2M","PRECTOTCORR","WS2M"]
                to: csv_climat format: "csv" rewrite: true;
            save ["simulation_id","cycle","nb_mares_actives","volume_moyen","niveau_moyen","oeufs_infectes","ndwi_moyen","ndvi_moyen"]
                to: csv_mares format: "csv" rewrite: true;
            save ["simulation_id","cycle","aedes_S","aedes_E","aedes_I","culex_S","culex_E","culex_I","total"]
                to: csv_moustiques format: "csv" rewrite: true;
            save ["simulation_id","cycle","humains","animaux","vecteurs","total_agents"]
                to: csv_controle_memoire format: "csv" rewrite: true;
            save ["simulation_id","experience","infections_totales",
                  "R0_Aedes_moyen","nb_fenetres_Aedes",
                  "R0_animal_moyen","nb_fenetres_animal"]
                to: csv_resume format: "csv" rewrite: true;
        }

        write "========== INIT TERMINÉE | R₀ calculé toutes les 10 fenêtres ==========";
    }

    // =========================================================================
    // RÉFLEXES GLOBAUX
    // =========================================================================

    reflex mise_a_jour_climat {
        if (nb_lignes_climat > 0) {
            int idx       <- cycle mod nb_lignes_climat;
            temperature       <- climat_T2M[idx];
            humidite_relative <- climat_RH2M[idx];
            pluie             <- climat_PRECTOTCORR[idx];
            vitesse_vent      <- climat_WS2M[idx];
        }
        jours_sans_pluie_global <- (pluie < 1.0) ? jours_sans_pluie_global + 1 : 0;
        pluie_cumulee <- pluie_cumulee * 0.90 + pluie;
        facteur_temperature <- max(0.05, min(1.0,
            exp(-((temperature - optimum_thermique_vecteur)^2)
                / (2.0 * largeur_thermique_vecteur^2))));
        facteur_humidite <- max(0.05, min(1.0, (humidite_relative - 15.0) / 65.0));
        facteur_vent <- max(0.1, min(1.0, 1.0 - (vitesse_vent / 10.0)));
    }

    reflex mise_a_jour_saison {
        string ns <- calculer_saison(jour_debut_simulation + cycle + 1);
        if (ns != saison) {
            do mettre_a_jour_occsol_saisonnier(ns);
            saison <- ns;
        }
    }

    reflex accumuler_fenetre_R0 {
        int nb_h <- length(humain) + length(animal);
        if (nb_h > 0) {
            int nb_aedes <- length(vecteur where (each.type_vecteur = "aedes"));
            cumul_m_Aedes              <- cumul_m_Aedes + (float(nb_aedes) / float(nb_h));
            cumul_vecteurs_Aedes_jours <- cumul_vecteurs_Aedes_jours + float(nb_aedes);

            int nb_tous_v <- length(vecteur);
            cumul_m_vect              <- cumul_m_vect + (float(nb_tous_v) / float(nb_h));
            cumul_vecteurs_vect_jours <- cumul_vecteurs_vect_jours + float(nb_tous_v);
        }
        nb_jours_fenetre <- nb_jours_fenetre + 1;
    }

    reflex calculer_R0_fenetre when: (nb_jours_fenetre >= 10) {
        do calculer_et_exporter_R0;
    }

    reflex mise_a_jour_compartiments {
        S_c_global <- float(length(animal where (each.etat_sante = "S"))) * echelle_superindividu;
        E_c_global <- float(length(animal where (each.etat_sante = "E"))) * echelle_superindividu;
        I_c_global <- float(length(animal where (each.etat_sante = "I"))) * echelle_superindividu;
        R_c_global <- float(length(animal where (each.etat_sante = "R"))) * echelle_superindividu;

        S_h_global <- float(length(humain where (each.etat_sante = "S"))) * echelle_superindividu;
        E_h_global <- float(length(humain where (each.etat_sante = "E"))) * echelle_superindividu;
        I_h_global <- float(length(humain where (each.etat_sante = "I"))) * echelle_superindividu;
        R_h_global <- float(length(humain where (each.etat_sante = "R"))) * echelle_superindividu;

        S_v_global <- float(length(vecteur where (each.etat_sante = "S"))) * echelle_superindividu;
        E_v_global <- float(length(vecteur where (each.etat_sante = "E"))) * echelle_superindividu;
        I_v_global <- float(length(vecteur where (each.etat_sante = "I"))) * echelle_superindividu;

        float tot_h   <- S_c_global + E_c_global + I_c_global + R_c_global
                       + S_h_global + E_h_global + I_h_global + R_h_global;
        float tot_I_h <- I_c_global + I_h_global;
        prevalence_c <- (tot_h > 0.0) ? tot_I_h / tot_h : 0.0;
        float tot_v   <- S_v_global + E_v_global + I_v_global;
        prevalence_v  <- (tot_v > 0.0) ? I_v_global / tot_v : 0.0;

        ndvi_moyen_global <- (empty(vegetation)) ? ndvi_moyen_global : mean(vegetation collect each.ndvi_local);
        ndwi_moyen_global <- (empty(mare))       ? ndwi_moyen_global : mean(mare collect each.ndwi_local);
    }

    reflex reset_incidence { incidence_c <- 0.0; incidence_v <- 0.0; }

    reflex naissances_animaux {
        float N_c  <- float(length(animal) * echelle_superindividu);
        float prob <- min(1.0, B_c * N_c / 100.0);
        if (flip(prob) and nb_campements > 0) {
            campement camp <- one_of(campement);
            create animal {
                campement_origine <- camp;
                taille_groupe     <- echelle_superindividu;
                location <- camp.location + {rnd(-100.0, 100.0), rnd(-100.0, 100.0)};
                etat_sante <- "S"; jours_dans_etat <- 0; NEC <- 3.0;
                est_cas_index_B <- false;
            }
        }
    }

    reflex naissances_vecteurs {
        ask mare where (each.volume_eau > 0.0) {
            float prob <- min(1.0, B_v / 1000.0);
            if (flip(prob) and length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "culex";
                    etat_sante       <- "S";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_culex;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-30.0, 30.0), rnd(-30.0, 30.0)};
                    age              <- 0; jours_dans_etat <- 0;
                    est_cas_index_A  <- false; est_cas_index_B <- false;
                    origine_infection <- "aucune";
                }
            }
        }
    }

    // =========================================================================
    // EXPORTS CSV JOURNALIERS — fichiers partagés, chaque ligne commence par
    // simulation_id ; toujours en append (rewrite:false), l'en-tête ayant
    // déjà été écrite une seule fois dans init: (simulation_id = 1).
    // =========================================================================
    reflex export_journalier when: export_detail {
        save [simulation_id, cycle, jour_debut_simulation + cycle, saison,
              with_precision(temperature, 2), with_precision(humidite_relative, 2),
              with_precision(pluie, 2), with_precision(vitesse_vent, 2)]
            to: csv_journalier format: "csv" rewrite: false;
    }

    reflex export_populations when: export_detail {
        save [simulation_id, cycle,
              length(humain where (each.etat_sante = "S")) * echelle_superindividu,
              length(humain where (each.etat_sante = "E")) * echelle_superindividu,
              length(humain where (each.etat_sante = "I")) * echelle_superindividu,
              length(humain where (each.etat_sante = "R")) * echelle_superindividu,
              int(S_c_global), int(E_c_global), int(I_c_global), int(R_c_global),
              length(vecteur) * echelle_superindividu]
            to: csv_populations format: "csv" rewrite: false;
    }

    reflex export_incidence when: export_detail {
        save [simulation_id, cycle, int(incidence_c), int(incidence_v),
              with_precision(prevalence_c, 4), with_precision(prevalence_v, 4)]
            to: csv_incidence format: "csv" rewrite: false;
    }

    reflex export_climat when: export_detail {
        save [simulation_id, cycle, 2025, jour_debut_simulation + cycle,
              temperature, humidite_relative, pluie, vitesse_vent]
            to: csv_climat format: "csv" rewrite: false;
    }

    reflex export_mares when: export_detail {
        int   nb_act    <- length(mare where (each.volume_eau > 0));
        float vol_moy   <- (empty(mare)) ? 0.0 : mean(mare collect each.volume_eau);
        float niv_moy   <- (empty(mare)) ? 0.0 : mean(mare collect each.niveau_mare);
        int   oeufs_inf <- sum(mare collect each.oeufs_aedes_infectes);
        save [simulation_id, cycle, nb_act, with_precision(vol_moy, 2), with_precision(niv_moy, 3), oeufs_inf,
              with_precision(ndwi_moyen_global, 4), with_precision(ndvi_moyen_global, 4)]
            to: csv_mares format: "csv" rewrite: false;
    }

    reflex export_moustiques when: export_detail {
        save [simulation_id, cycle,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "S")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "E")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "I")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "S")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "E")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "I")) * echelle_superindividu,
              length(vecteur) * echelle_superindividu]
            to: csv_moustiques format: "csv" rewrite: false;
    }

    reflex export_memoire when: export_detail {
        save [simulation_id, cycle, length(humain), length(animal), length(vecteur),
              length(humain) + length(animal) + length(vecteur)]
            to: csv_controle_memoire format: "csv" rewrite: false;
    }

    reflex stop when: cycle >= duree_simulation - 1 {
        if (nb_jours_fenetre > 0) { do calculer_et_exporter_R0; }

        float R0_Aedes_moyen  <- (nb_R0_Aedes > 0)  ? somme_R0_Aedes / nb_R0_Aedes   : 0.0;
        float R0_animal_moyen <- (nb_R0_animal > 0) ? somme_R0_animal / nb_R0_animal : 0.0;

        write "========== FIN | SimID=" + simulation_id
            + " | Exp=" + type_experience + " ==========";
        write "R0_Aedes  (dernière fenêtre) : " + with_precision(R0_Aedes_10j, 4);
        write "R0_animal (dernière fenêtre) : " + with_precision(R0_animal_10j, 4);
        write "-------- RÉSUMÉ DE LA SIMULATION --------";
        write "Infections totales           : " + nb_infections_totales;
        write "R0_Aedes moyen (" + nb_R0_Aedes + " fenêtres)  : " + with_precision(R0_Aedes_moyen, 4);
        write "R0_animal moyen (" + nb_R0_animal + " fenêtres) : " + with_precision(R0_animal_moyen, 4);
        write "------------------------------------------";

        save [simulation_id, type_experience, nb_infections_totales,
              with_precision(R0_Aedes_moyen, 6), nb_R0_Aedes,
              with_precision(R0_animal_moyen, 6), nb_R0_animal]
            to: csv_resume format: "csv" rewrite: false;

        do pause;
    }
}

// =============================================================================
// ESPÈCES ENVIRONNEMENTALES
// =============================================================================
species occsol_polygone { int classe; }

species zone_eau_binaire { int eau <- 0; }

species sol {
    int    msd;
    string msdnom;
    float  coef_infiltration <- 0.45;
    float  coef_retention    <- 0.45;

    action calculer_proprietes_sol {
        switch msdnom {
            match "HYDROMORPHES"          { coef_infiltration <- 0.15; coef_retention <- 0.85; }
            match "PEU EVOLUES"           { coef_infiltration <- 0.55; coef_retention <- 0.35; }
            match "FERRUGINEUX TROPICAUX" { coef_infiltration <- 0.40; coef_retention <- 0.50; }
            match "REGOSOLS"              { coef_infiltration <- 0.60; coef_retention <- 0.30; }
            match "LITHOSOLS"             { coef_infiltration <- 0.20; coef_retention <- 0.20; }
            default                       { coef_infiltration <- 0.45; coef_retention <- 0.45; }
        }
    }
    aspect default { draw shape color: rgb(210,180,140,0.25) border: rgb(210,180,140,0.25); }
}

species vegetation {
    int    formcode;
    string formation;
    float  capacite_max      <- 60.0;
    float  biomasse          <- 40.0;
    int    nb_hotes_presents <- 0;
    float  ndvi_local <- 0.3;

    action calculer_capacite_vegetation {
        float capacite_formation;
        switch formation {
            match "SAVANES ARBUSTIVES ET ARBOREES" { capacite_formation <- 100.0; }
            match "SAVANES ARBUSTIVES"             { capacite_formation <- 85.0;  }
            match "STEPPES ARBOREES"               { capacite_formation <- 60.0;  }
            match "ZONES DE CULTURE"               { capacite_formation <- 40.0;  }
            default                                { capacite_formation <- 55.0;  }
        }
        ndvi_local  <- world.ndvi_moyen_au_point(location, 60.0);
        float facteur_ndvi <- max(0.4, min(1.6, 0.5 + ndvi_local * 1.5));
        capacite_max <- capacite_formation * facteur_ndvi;
        biomasse     <- capacite_max * 0.6;
    }

    reflex compter_hotes {
        nb_hotes_presents <- length(animal at_distance rayon_piqure_animal)
                           + length(humain at_distance rayon_piqure_humain);
    }

    reflex mise_a_jour_ndvi when: (cycle mod 5 = 0) {
        ndvi_local <- world.ndvi_moyen_au_point(location, 60.0);
    }

    reflex dynamique_biomasse {
        if (nb_hotes_presents > 0)  { biomasse <- max(0.0, biomasse - nb_hotes_presents * 1.2); }
        else if (saison = "Nduungu"){
            float facteur_repousse <- max(0.3, min(2.0, 0.5 + ndvi_local * 1.5));
            biomasse <- min(capacite_max, biomasse + 0.08 * pluie * facteur_repousse);
        }
        else if (saison = "Dabbuunde") { biomasse <- max(0.0, biomasse - 0.05); }
        else { biomasse <- max(0.0, biomasse - 0.10); }
    }

    aspect default {
        rgb couleur;
        float ratio <- (capacite_max > 0) ? biomasse / capacite_max : 0.0;
        if      (ratio > 0.7)  { couleur <- rgb(34,139,34,0.55); }
        else if (ratio > 0.4)  { couleur <- rgb(154,205,50,0.5); }
        else if (ratio > 0.15) { couleur <- rgb(189,183,107,0.45); }
        else                   { couleur <- rgb(210,180,140,0.4); }
        draw shape color: couleur border: couleur;
    }
}

species campement {
    aspect default { draw shape color: #saddlebrown border: #saddlebrown; }
}

species route {
    int code_route; int classe_route; int revet; int repert;
    int nb_passages <- 0;
    aspect default {
        rgb couleur; float largeur;
        if      (revet = 1)         { couleur <- #darkred;        largeur <- 3.5; }
        else if (classe_route <= 4) { couleur <- rgb(200,80,0);   largeur <- 2.5; }
        else                        { couleur <- #goldenrod;       largeur <- 1.5; }
        if (nb_passages > 15)       { couleur <- #black; largeur <- largeur + 1.0; }
        draw shape color: couleur width: largeur;
    }
}

// =============================================================================
// MARE — dynamique hydrique + émergence vecteurs
// =============================================================================
species mare {
    float volume_eau           <- 0.0;
    float surface_eau          <- 0.0;
    float surface_max          <- 500.0;
    int   oeufs_aedes_infectes <- 0;
    int   oeufs_aedes_sains    <- 0;
    int   oeufs_culex          <- 0;
    int   jours_sans_pluie     <- 0;
    float volume_max_reference <- 300.0;
    float niveau_mare          <- 0.0;
    float densite_moustiques   <- 0.0;
    float L_perte              <- 12.0;
    float Iap                  <- 0.0;

    float k_sol        <- 0.9;
    float Gmax         <- 50.0;
    float Kr           <- 0.5;
    bool  est_ensemble1 <- true;

    float ndwi_local      <- 0.2;
    float ndwi_precedent  <- 0.2;

    reflex mise_a_jour_ndwi when: (cycle mod 3 = 0) {
        ndwi_precedent <- ndwi_local;
        ndwi_local     <- world.ndwi_moyen_au_point(location, 40.0);
    }

    reflex mise_a_jour_volume {
        Iap       <- k_sol * (Iap + pluie);
        float G_t <- max(0.0, Gmax - Iap);
        float Pe  <- max(0.0, pluie - G_t);
        float Qin <- est_ensemble1 ? (Kr * Pe * 1000.0) : 0.0;

        float facteur_ndwi <- max(0.4, min(2.5, 1.2 - ndwi_local * 2.0));
        float chute_ndwi   <- max(0.0, ndwi_precedent - ndwi_local);
        float bonus_chute  <- 1.0 + min(1.0, chute_ndwi * 5.0);

        float evaporation  <- (volume_eau > 0)
            ? min(volume_eau, L_perte * (volume_eau / 100.0) * facteur_ndwi * bonus_chute)
            : 0.0;
        float infiltration <- volume_eau * 0.05;

        volume_eau            <- max(0.0, volume_eau + pluie - evaporation - infiltration + Qin);
        volume_max_reference  <- max(50.0, surface_max * 0.6);
        surface_eau            <- min(surface_max, volume_eau * 2.0);
    }

    reflex compter_jours_secs {
        jours_sans_pluie <- (pluie < 1.0) ? jours_sans_pluie + 1 : 0;
    }

    reflex disparition_mare when: jours_sans_pluie >= seuil_assechement_mare and volume_eau > 0.0 {
        volume_eau <- 0.0; surface_eau <- 0.0;
    }

    reflex verifier_ndwi_binaire when: utiliser_ndwi_binaire and (cycle mod 3 = 0) {
        bool couverte <- !empty(zones_eau_binaire) and !empty(zones_eau_binaire where (each covers location));
        if (!couverte) {
            volume_eau  <- 0.0;
            surface_eau <- 0.0;
        }
    }

    reflex mise_a_jour_niveau {
        niveau_mare <- max(0.0, min(1.0,
            (volume_max_reference > 0) ? volume_eau / volume_max_reference : 0.0));
        int nb_v <- length(vecteur where (each.mare_origine = self));
        densite_moustiques <- (surface_eau > 0) ? float(nb_v * echelle_superindividu) / surface_eau : 0.0;
    }

    reflex emergence_aedes_infectes
        when: (pluie >= 10.0 or pluie_cumulee >= seuil_eclosion_cumulee)
          and jours_sans_pluie >= int(Td_aedes)
          and volume_eau > 0.0
          and oeufs_aedes_infectes > 0 {

        float survie    <- beta_aedes * (phi_aedes ^ int(T_aedes))
                          * facteur_temperature * facteur_humidite;
        float frac_surf <- min(1.0, surface_eau / surface_max);
        int nb_eclos    <- min(oeufs_aedes_infectes,
                              int(oeufs_aedes_infectes * survie * frac_surf * 0.1));
        oeufs_aedes_infectes <- oeufs_aedes_infectes - nb_eclos;

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-50.0, 50.0), rnd(-50.0, 50.0)};
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- false;
                    est_cas_index_B  <- false;
                    origine_infection <- "verticale";
                }
            }
        }
        if (nb_eclos > 0) {
            write "Émergence Aedes I (verticale) : " + nb_eclos + " agents (cycle " + cycle + ")";
        }
    }

    reflex emergence_aedes_sains
        when: (pluie >= 10.0 or pluie_cumulee >= seuil_eclosion_cumulee)
          and jours_sans_pluie >= int(Td_aedes)
          and volume_eau > 0.0
          and oeufs_aedes_sains > 0 {

        float survie    <- beta_aedes * (phi_aedes ^ int(T_aedes))
                          * facteur_temperature * facteur_humidite;
        float frac_surf <- min(1.0, surface_eau / surface_max);
        int nb_eclos    <- min(oeufs_aedes_sains,
                              int(oeufs_aedes_sains * survie * frac_surf * 0.05));
        oeufs_aedes_sains <- oeufs_aedes_sains - nb_eclos;

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "S";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-50.0, 50.0), rnd(-50.0, 50.0)};
                    age              <- 0; jours_dans_etat <- 0;
                    est_cas_index_A  <- false; est_cas_index_B <- false;
                    origine_infection <- "aucune";
                }
            }
        }
    }

    reflex emergence_culex when: volume_eau > 0.5 and oeufs_culex > 0 {
        float survie  <- beta_culex * (gamma_culex ^ int(T_culex))
                        * facteur_temperature * facteur_humidite;
        float surf_d  <- min(surface_eau, surface_max);
        float densite <- (surf_d > 0) ? float(oeufs_culex) / surf_d : 0.0;
        int nb_eclos  <- (densite > Emax_culex)
            ? int(surf_d * Emax_culex * survie * 0.02)
            : int(float(oeufs_culex) * survie * 0.02);
        nb_eclos    <- min(5, max(0, nb_eclos));
        oeufs_culex <- max(0, oeufs_culex - nb_eclos * int(lambda_culex));

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "culex";
                    etat_sante       <- "S";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_culex;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-20.0, 20.0), rnd(-20.0, 20.0)};
                    age              <- 0; jours_dans_etat <- 0;
                    est_cas_index_A  <- false; est_cas_index_B <- false;
                    origine_infection <- "aucune";
                }
            }
        }
    }

    aspect default {
        if (volume_eau > 0) { draw shape color: #blue border: #blue; }
        else                 { draw shape color: rgb(135,206,235,0.5) border: rgb(135,206,235,0.5); }
    }
}

// =============================================================================
// HOTE (parent)
// =============================================================================
species hote skills: [moving] {
    list<route> chemin_parcouru <- [];
    point cible_exploration <- nil;

    point contraindre(point pt) {
        if (zone_z3 covers pt) { return pt; }
        return zone_z3.centroid;
    }

    point explorer_routes {
        list<route> non_parcourues <- route where !(each in chemin_parcouru);
        route r <- nil;
        if (!empty(non_parcourues)) {
            r <- one_of(non_parcourues);
        } else if (!empty(route)) {
            chemin_parcouru <- [];
            r <- one_of(route);
        }
        if (r != nil) {
            cible_exploration <- any_location_in(r.shape);
            return cible_exploration;
        }
        return nil;
    }

    action se_deplacer_vers(point cible, float vit) {
        if (cible != nil and reseau_routier != nil) {
            try { do goto target: cible on: reseau_routier speed: vit; }
            catch {
                if (cible != nil) {
                    point dir <- cible - location;
                    if (norm(dir) > 0) { location <- location + (dir / norm(dir)) * vit; }
                }
            }
            if (current_edge != nil) {
                route r <- route(current_edge);
                if !(r in chemin_parcouru) { add r to: chemin_parcouru; }
                r.nb_passages <- r.nb_passages + 1;
            }
        } else if (cible != nil) {
            point dir <- cible - location;
            if (norm(dir) > 0) { location <- location + (dir / norm(dir)) * vit; }
        } else {
            location <- location + {rnd(-vit*0.2, vit*0.2), rnd(-vit*0.2, vit*0.2)};
        }
        location <- contraindre(location);
    }
}

// =============================================================================
// HUMAIN
// =============================================================================
species humain parent: hote {
    string etat_sante      <- "S";
    int    jours_dans_etat <- 0;
    int    taille_groupe   <- echelle_superindividu;
    campement    campement_origine;
    list<animal> troupeaux_associes    <- [];
    float        exposition_moustiques <- 0.0;
    mare derniere_mare <- nil;

    reflex mise_a_jour_exposition {
        exposition_moustiques <- float(length(vecteur at_distance rayon_piqure_humain)
                                       * echelle_superindividu);
    }

    reflex se_deplacer {
        point cible <- nil;
        float vit   <- vitesse_hote_normal;

        if (saison = "Nduungu") {
            list<mare> md <- mare where (each.volume_eau > 0.0);
            if (!empty(md)) {
                mare m <- md with_max_of (each.volume_eau / (1.0 + (location distance_to each.location)));
                derniere_mare <- m;
                cible <- m.location;
            }
        } else if (saison = "Dabbuunde") {
            if (campement_origine != nil) { cible <- campement_origine.location; }
        } else {
            list<mare> md <- mare where (each.volume_eau > Vseuil);
            if (!empty(md)) {
                mare m <- md with_max_of (each.volume_eau / (1.0 + (location distance_to each.location)));
                derniere_mare <- m;
                cible <- m.location;
            }
        }

        if (cible = nil) {
            list<animal> troupeau_vivant <- troupeaux_associes where (each != nil and !dead(each));
            if (!empty(troupeau_vivant)) {
                list<animal> en_trans <- troupeau_vivant where each.est_transhumant;
                if (!empty(en_trans)) {
                    cible <- (geometry(en_trans collect each.location)).centroid;
                    vit   <- vitesse_transhumance;
                } else {
                    cible <- (geometry(troupeau_vivant collect each.location)).centroid;
                }
            }
        }

        if (cible = nil) {
            cible <- explorer_routes();
        }

        if (cible = nil and campement_origine != nil) { cible <- campement_origine.location; }

        do se_deplacer_vers(cible, vit);
    }

    reflex transition_etat {
        jours_dans_etat <- jours_dans_etat + 1;
        if (etat_sante = "E" and jours_dans_etat >= duree_incubation) {
            etat_sante <- "I"; jours_dans_etat <- 0;
        } else if (etat_sante = "I" and jours_dans_etat >= duree_infection) {
            etat_sante <- "R"; jours_dans_etat <- 0;
        }
    }

    aspect default {
        rgb couleur;
        switch etat_sante {
            match "S" { couleur <- #green;  } match "E" { couleur <- #yellow; }
            match "I" { couleur <- #red;    } match "R" { couleur <- #gray;   }
        }
        draw square(unite_z3 * 0.012) color: couleur border: couleur;
    }
}

// =============================================================================
// ANIMAL
// =============================================================================
species animal parent: hote {
    string etat_sante      <- "S";
    int    jours_dans_etat <- 0;
    int    taille_groupe   <- echelle_superindividu;
    float  NEC             <- 3.5;
    vegetation vegetation_cible     <- nil;
    mare   mare_actuelle            <- nil;
    mare   destination_transhumance <- nil;
    bool   est_transhumant          <- false;
    list<mare> memoire_mares        <- [];
    campement  campement_origine;
    humain     berger               <- nil;
    float      exposition_moustiques <- 0.0;

    bool est_cas_index_B <- false;

    reflex mise_a_jour_exposition {
        exposition_moustiques <- float(length(vecteur at_distance rayon_piqure_animal)
                                       * echelle_superindividu);
    }

    reflex mise_a_jour_NEC {
        mare m <- mare closest_to self; vegetation v <- vegetation closest_to self;
        float eau <- (m = nil) ? 0.0 : m.volume_eau;
        float bio <- (v = nil) ? 0.0 : v.biomasse;
        if (eau < Vseuil or bio < 15.0) { NEC <- max(1.0, NEC - 0.05); }
        else { NEC <- min(5.0, NEC + 0.03); }
    }

    reflex deplacement {
        if (!est_transhumant and saison != "Nduungu" and NEC < NECseuil) {
            list<mare> perm <- mare where (each.volume_eau > Vseuil);
            if (!empty(perm)) { destination_transhumance <- perm with_max_of each.volume_eau; est_transhumant <- true; }
        } else if (est_transhumant and saison = "Nduungu") {
            if (destination_transhumance != nil and !(destination_transhumance in memoire_mares)) {
                add destination_transhumance to: memoire_mares;
            }
            est_transhumant <- false; destination_transhumance <- nil;
        }
        point cible <- nil; float vit <- vitesse_hote_normal;
        if (est_transhumant and destination_transhumance != nil) {
            cible <- destination_transhumance.location; vit <- vitesse_transhumance;
        } else if (saison = "Nduungu") {
            list<mare> md <- mare where (each.volume_eau > Vseuil);
            if (!empty(md)) {
                mare m <- md with_max_of (each.volume_eau / (1.0 + (location distance_to each.location)));
                mare_actuelle <- m;
                if !(m in memoire_mares) { add m to: memoire_mares; }
                cible <- m.location;
            }
        } else if (saison = "Dabbuunde") { cible <- campement_origine.location; }
        else {
            list<vegetation> zones <- vegetation where (each.biomasse > 15.0 and
                (each.location distance_to location) < rayon_recherche_paturage);
            if (!empty(zones)) {
                vegetation v <- zones with_max_of (each.biomasse / (1.0 + (location distance_to each.location)));
                vegetation_cible <- v; cible <- v.location;
            } else {
                list<mare> sec <- mare where (each.volume_eau > Vseuil);
                if (!empty(sec)) { cible <- (sec with_max_of each.volume_eau).location; }
            }
        }
        if (cible = nil) {
            cible <- explorer_routes();
        }
        if (cible = nil) {
            if (campement_origine != nil) { cible <- campement_origine.location; }
            else if (!empty(memoire_mares)) { cible <- last(memoire_mares).location; }
        }
        do se_deplacer_vers(cible, vit);
    }

    reflex transition_etat {
        jours_dans_etat <- jours_dans_etat + 1;
        if (etat_sante = "E" and jours_dans_etat >= duree_incubation) {
            etat_sante <- "I"; jours_dans_etat <- 0;
        } else if (etat_sante = "I" and jours_dans_etat >= duree_infection) {
            if (flip(delta_c)) { do die; }
            else { etat_sante <- "R"; jours_dans_etat <- 0; }
        }
    }

    reflex mortalite_naturelle { if (flip(mu_c)) { do die; } }

    aspect default {
        rgb couleur;
        switch etat_sante {
            match "S" { couleur <- #lightgreen; }  match "E" { couleur <- #orange; }
            match "I" { couleur <- #red; }          match "R" { couleur <- rgb(147,197,253); }
            default   { couleur <- #lightgreen; }
        }
        draw circle(unite_z3 * 0.009) color: couleur border: couleur;
    }
}

// =============================================================================
// VECTEUR (Aedes et Culex)
// =============================================================================
species vecteur {
    string type_vecteur;
    string etat_sante        <- "S";
    float  vitesse;
    int    jours_dans_etat   <- 0;
    int    age               <- 0;
    int    taille_groupe     <- echelle_superindividu;
    mare   mare_origine      <- nil;

    bool   est_cas_index_A   <- false;
    bool   est_cas_index_B   <- false;
    string origine_infection <- "aucune";

    reflex se_deplacer {
        list<humain> h_pr <- humain at_distance rayon_detection_v;
        list<animal> a_pr <- animal at_distance rayon_detection_v;
        point cible <- nil;
        if (etat_sante = "I") {
            if (!empty(a_pr)) { cible <- one_of(a_pr).location; }
            else if (!empty(h_pr)) { cible <- one_of(h_pr).location; }
        } else {
            if (type_vecteur = "culex" and mare_origine != nil and
                (location distance_to mare_origine.location) > rayon_depot_oeufs) {
                cible <- mare_origine.location;
            } else if (!empty(a_pr)) { cible <- one_of(a_pr).location; }
            else if (!empty(h_pr)) { cible <- one_of(h_pr).location; }
        }
        if (cible != nil) {
            point dir <- cible - location; float dist <- norm(dir);
            if (dist > 1.0) { location <- location + (dir / dist) * vitesse; }
        } else {
            location <- location + {rnd(-vitesse, vitesse), rnd(-vitesse, vitesse)};
        }
        if (!(zone_z3 covers location)) { location <- zone_z3.centroid; }
    }

    reflex piquer_humains when: etat_sante = "I" {
        float facteur_climat_activite <- facteur_humidite * facteur_vent;
        bool actif <- (type_vecteur = "aedes")
            ? flip(proba_activite_aedes * sigma_v * facteur_climat_activite)
            : flip(proba_activite_culex * sigma_v * facteur_climat_activite);

        if (actif) {
            if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
            cumul_bites_vect <- cumul_bites_vect + 1.0;

            float fd <- (mare_origine != nil)
                ? min(2.0, 1.0 + mare_origine.densite_moustiques / 100.0) : 1.0;
            list<humain> cibles_S <- (humain at_distance rayon_piqure_humain)
                                     where (each.etat_sante = "S");
            ask cibles_S {
                if (etat_sante = "S" and flip(min(1.0, beta_vh * fd))) {
                    etat_sante      <- "E";
                    jours_dans_etat <- 0;
                    nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                    incidence_c           <- incidence_c + echelle_superindividu;
                }
            }
        }
    }

    reflex piquer_animaux when: etat_sante = "I" {
        float facteur_climat_activite <- facteur_humidite * facteur_vent;
        bool actif <- (type_vecteur = "aedes")
            ? flip(proba_activite_aedes * sigma_v * facteur_climat_activite)
            : flip(proba_activite_culex * sigma_v * facteur_climat_activite);

        if (actif) {
            if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
            cumul_bites_vect <- cumul_bites_vect + 1.0;

            float fd <- (mare_origine != nil)
                ? min(2.0, 1.0 + mare_origine.densite_moustiques / 100.0) : 1.0;
            list<animal> cibles_S <- (animal at_distance rayon_piqure_animal)
                                     where (each.etat_sante = "S");
            ask cibles_S {
                if (etat_sante = "S" and flip(min(1.0, beta_va * fd))) {
                    etat_sante      <- "E";
                    jours_dans_etat <- 0;
                    nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                    incidence_c           <- incidence_c + echelle_superindividu;
                }
            }
        }
    }

    reflex acquerir_infection when: etat_sante = "S" {
        list<humain> h_inf <- (humain at_distance rayon_piqure_humain) where (each.etat_sante = "I");
        if (!empty(h_inf) and flip(beta_hv)) {
            etat_sante       <- "E";
            jours_dans_etat  <- 0;
            origine_infection <- "horizontale";
            incidence_v <- incidence_v + echelle_superindividu;
        }
        if (etat_sante = "S") {
            list<animal> a_inf <- (animal at_distance rayon_piqure_animal) where (each.etat_sante = "I");
            if (!empty(a_inf) and flip(beta_av)) {
                etat_sante       <- "E";
                jours_dans_etat  <- 0;
                origine_infection <- "horizontale";
                incidence_v <- incidence_v + echelle_superindividu;
            }
        }
    }

    reflex transition_etat {
        jours_dans_etat <- jours_dans_etat + 1;
        float duree_EI <- (type_vecteur = "aedes") ? T_aedes : duree_cycle_extrinseque;
        if (etat_sante = "E" and jours_dans_etat >= duree_EI) {
            etat_sante <- "I"; jours_dans_etat <- 0;
        }
    }

    reflex transmission_verticale
        when: type_vecteur = "aedes" and etat_sante = "I"
          and (age mod int(tau_aedes)) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau = 0) {
            int pontes   <- int(lambda_aedes * kappa_aedes * facteur_temperature * facteur_humidite);
            int infectes <- int(pontes * rho_aedes);
            if ((est_cas_index_A or est_cas_index_B) and pontes > 0 and infectes = 0) {
                infectes <- 1;
            }
            m.oeufs_aedes_infectes <- m.oeufs_aedes_infectes + infectes;
            m.oeufs_aedes_sains    <- m.oeufs_aedes_sains + max(0, pontes - infectes);
            write "Ponte Aedes (cycle " + cycle + ", âge " + age + ") : " + infectes
                + " œufs infectés + " + max(0, pontes - infectes) + " œufs sains déposés.";
        }
    }

    reflex ponte_culex when: type_vecteur = "culex" and (age mod int(tau_culex)) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau > 0) {
            m.oeufs_culex <- m.oeufs_culex
                + int(lambda_culex * kappa_culex * facteur_temperature * facteur_humidite);
        }
    }

    reflex mourir {
        age <- age + 1;
        float fmc   <- 2.0 - facteur_humidite;
        bool mort_n <- flip(min(1.0, mu_v * fmc));
        bool mort_a <- age > 21;
        bool mort_c <- temperature > 40.0 and flip(0.1);
        if (mort_n or mort_a or mort_c) { do die; }
        if (!dead(self) and length(vecteur) > max_vecteurs and flip(0.2)) { do die; }
    }

    aspect default {
        rgb   c;
        float taille <- unite_z3 * 0.002;
        if (type_vecteur = "aedes") {
            switch etat_sante {
                match "S" { c <- #pink; }
                match "E" { c <- rgb(255,165,0); }
                match "I" { c <- est_cas_index_A ? #darkred : (origine_infection = "verticale" ? #orangered : #red); }
            }
            draw triangle(taille) color: c border: c;
        } else {
            switch etat_sante {
                match "S" { c <- #violet; }
                match "E" { c <- rgb(180,100,220); }
                match "I" { c <- #darkviolet; }
            }
            draw circle(taille) color: c border: c;
        }
    }
}

// =============================================================================
// EXPÉRIENCE GUI
// =============================================================================
experiment "FVR Z3 — Expérience Aedes (R0_vectoriel)" type: gui {
    parameter "Expérience"        var: type_experience <- "Aedes";
    parameter "Simulation ID"     var: simulation_id   <- 1;
    parameter "Nb humains init"   var: nb_humains_init <- 40;
    parameter "Nb animaux init"   var: nb_animaux_init <- 50;
    parameter "Fécondité Aedes (lambda)" var: lambda_aedes min: 50.0 max: 800.0 step: 10.0;
    parameter "Transmission verticale (rho)" var: rho_aedes min: 0.0 max: 0.2 step: 0.005;
    parameter "Taux piqûre σ_v"   var: sigma_v  min: 0.1 max: 1.0 step: 0.05;
    parameter "Proba v→humain"    var: p_h      min: 0.01 max: 1.0 step: 0.01;
    parameter "Proba v→animal"    var: p_a      min: 0.01 max: 1.0 step: 0.01;
    parameter "Létalité δ_c"      var: delta_c  min: 0.0 max: 0.1 step: 0.005;
    parameter "Échelle SI"        var: echelle_superindividu min: 1 max: 50 step: 1;
    parameter "Plafond vecteurs"  var: max_vecteurs min: 500 max: 20000 step: 500;
    parameter "Export CSV"        var: export_detail;

    output {
        display "Carte Z3" type: java2D background: #white {
            graphics "fond_occsol" {
                loop i from: 0 to: length(fond_geoms) - 1 {
                    if (i < length(fond_classes)) {
                        draw fond_geoms[i] color: palette_occsol[fond_classes[i]];
                    }
                }
            }
            species route     aspect: default;
            species mare      aspect: default;
            species campement aspect: default;
            species animal    aspect: default;
            species humain    aspect: default;
            species vecteur   aspect: default;
            graphics "legende" {
                draw ("Sim" + simulation_id + " | " + type_experience
                    + " | J" + (jour_debut_simulation + cycle)
                    + " | " + saison
                    + " | R0_Aedes=" + with_precision(R0_Aedes_10j, 3)
                    + " | R0_anim=" + with_precision(R0_animal_10j, 3))
                    at: {shape.width * 0.02, shape.height * 0.04}
                    color: #black font: font("Times New Roman", 12, #bold);
            }
        }

        display "SEIR — Humains" type: 2d {
            chart "Humains" type: series background: #white axes: #black {
                data "S" value: S_h_global color: #green;
                data "E" value: E_h_global color: #yellow;
                data "I" value: I_h_global color: #red;
                data "R" value: R_h_global color: #gray;
            }
        }

        display "SEIR — Animaux" type: 2d {
            chart "Animaux" type: series background: #white axes: #black {
                data "S" value: S_c_global color: #green;
                data "E" value: E_c_global color: rgb(252,211,77);
                data "I" value: I_c_global color: #red;
                data "R" value: R_c_global color: #blue;
            }
        }

        display "Vecteurs" type: 2d {
            chart "Vecteurs" type: series background: #white axes: #black {
                data "Aedes S" value: length(vecteur where (each.type_vecteur="aedes" and each.etat_sante="S")) * echelle_superindividu color: #pink;
                data "Aedes I" value: length(vecteur where (each.type_vecteur="aedes" and each.etat_sante="I")) * echelle_superindividu color: #darkred;
                data "Culex S" value: length(vecteur where (each.type_vecteur="culex" and each.etat_sante="S")) * echelle_superindividu color: #violet;
                data "Culex I" value: length(vecteur where (each.type_vecteur="culex" and each.etat_sante="I")) * echelle_superindividu color: #darkviolet;
                data "Aedes vertical I" value: length(vecteur where (each.type_vecteur="aedes" and each.origine_infection="verticale" and each.etat_sante="I")) * echelle_superindividu color: #orangered;
            }
        }

        display "R₀ (fenêtres 10j)" type: 2d {
            chart "R₀ = C/r" type: series background: #white axes: #black {
                data "R0_Aedes"  value: R0_Aedes_10j  color: #purple;
                data "R0_animal" value: R0_animal_10j color: #darkorange;
                data "Seuil=1"   value: 1.0           color: #red;
            }
        }

        display "Composantes C" type: 2d {
            chart "m et a" type: series background: #white axes: #black {
                data "m Aedes"  value: m_Aedes_10j  color: #purple;
                data "m animal" value: m_animal_10j color: #darkorange;
                data "a Aedes"  value: a_Aedes_10j  color: rgb(150,0,200);
                data "a animal" value: a_animal_10j color: rgb(200,100,0);
            }
        }

        display "Climat" type: 2d {
            chart "Pluie"     type: series background: #white size: {0.5,0.5} position: {0.0,0.0} axes: #black { data "Pluie" value: pluie color: #cyan; }
            chart "Temp"      type: series background: #white size: {0.5,0.5} position: {0.5,0.0} axes: #black { data "T°C" value: temperature color: #red; }
            chart "Humidité"  type: series background: #white size: {0.5,0.5} position: {0.0,0.5} axes: #black { data "RH %" value: humidite_relative color: #blue; }
            chart "Vent"      type: series background: #white size: {0.5,0.5} position: {0.5,0.5} axes: #black { data "Vent m/s" value: vitesse_vent color: #darkgray; }
        }

        display "Mares & Biomasse" type: 2d {
            chart "Niveau mares" type: series background: #white size: {1.0,0.5} position: {0.0,0.0} axes: #black {
                data "Niveau moy" value: (empty(mare)) ? 0.0 : mean(mare collect each.niveau_mare) color: #blue;
            }
            chart "Biomasse moyenne" type: series background: #white size: {1.0,0.5} position: {0.0,0.5} axes: #black {
                data "Biomasse moyenne" value: (empty(vegetation)) ? 0.0 : mean(vegetation collect each.biomasse) color: #olive;
            }
        }

        display "Indices satellite" type: 2d {
            chart "NDVI / NDWI moyens" type: series background: #white axes: #black {
                data "NDVI moyen (végétation)" value: ndvi_moyen_global color: #darkgreen;
                data "NDWI moyen (mares)"      value: ndwi_moyen_global color: #blue;
            }
        }

        monitor "Jour DOY"        value: jour_debut_simulation + cycle;
        monitor "Saison"          value: saison;
        monitor "T°C"             value: with_precision(temperature, 1);
        monitor "Pluie mm/j"      value: with_precision(pluie, 1);
        monitor "Humidité %"      value: with_precision(humidite_relative, 1);
        monitor "Vent m/s"        value: with_precision(vitesse_vent, 1);
        monitor "Facteur humidité" value: with_precision(facteur_humidite, 3);
        monitor "Facteur vent"    value: with_precision(facteur_vent, 3);
        monitor "R0_Aedes (10j)"  value: with_precision(R0_Aedes_10j, 4)  color: #purple;
        monitor "R0_animal (10j)" value: with_precision(R0_animal_10j, 4) color: #darkorange;
        monitor "m_Aedes"         value: with_precision(m_Aedes_10j, 4);
        monitor "a_Aedes"         value: with_precision(a_Aedes_10j, 4);
        monitor "C_Aedes"         value: with_precision(C_Aedes_10j, 4);
        monitor "Fenêtre"         value: num_fenetre;
        monitor "Jours fenêtre"   value: nb_jours_fenetre;
        monitor "Aedes I (agents)" value: length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "I"));
        monitor "Aedes vertical I" value: length(vecteur where (each.type_vecteur = "aedes" and each.origine_infection = "verticale" and each.etat_sante = "I"));

        monitor "Humains S"       value: int(S_h_global) color: #green;
        monitor "Humains E"       value: int(E_h_global) color: #goldenrod;
        monitor "Humains I"       value: int(I_h_global) color: #red;
        monitor "Humains R"       value: int(R_h_global) color: #gray;

        monitor "Animaux I"       value: int(I_c_global) color: #red;
        monitor "Mares actives"   value: length(mare where (each.volume_eau > 0));

        monitor "NDVI moyen"      value: with_precision(ndvi_moyen_global, 3) color: #darkgreen;
        monitor "NDWI moyen"      value: with_precision(ndwi_moyen_global, 3) color: #blue;

        monitor "Infections totales (cumul)" value: nb_infections_totales color: #red;
        monitor "R0_Aedes moyen (cumul)"     value: (nb_R0_Aedes > 0) ? with_precision(somme_R0_Aedes / nb_R0_Aedes, 4) : 0.0;
        monitor "R0_animal moyen (cumul)"    value: (nb_R0_animal > 0) ? with_precision(somme_R0_animal / nb_R0_animal, 4) : 0.0;
    }
}
/*
experiment "FVR Z3 — Expérience Animal (R0_animal)" type: gui {
    parameter "Expérience"        var: type_experience <- "Animal";
    parameter "Simulation ID"     var: simulation_id   <- 1;
    parameter "Nb humains init"   var: nb_humains_init <- 40;
    parameter "Nb animaux init"   var: nb_animaux_init <- 50;
    parameter "Fécondité Aedes (lambda)" var: lambda_aedes min: 50.0 max: 800.0 step: 10.0;
    parameter "Transmission verticale (rho)" var: rho_aedes min: 0.0 max: 0.2 step: 0.005;
    parameter "Taux piqûre σ_v"   var: sigma_v  min: 0.1 max: 1.0 step: 0.05;
    parameter "Proba v→humain"    var: p_h      min: 0.01 max: 1.0 step: 0.01;
    parameter "Proba v→animal"    var: p_a      min: 0.01 max: 1.0 step: 0.01;
    parameter "Létalité δ_c"      var: delta_c  min: 0.0 max: 0.1 step: 0.005;
    parameter "Échelle SI"        var: echelle_superindividu min: 1 max: 50 step: 1;
    parameter "Plafond vecteurs"  var: max_vecteurs min: 500 max: 20000 step: 500;
    parameter "Export CSV"        var: export_detail;

    output {
        display "Carte Z3" type: java2D background: #white {
            graphics "fond_occsol" {
                loop i from: 0 to: length(fond_geoms) - 1 {
                    if (i < length(fond_classes)) {
                        draw fond_geoms[i] color: palette_occsol[fond_classes[i]];
                    }
                }
            }
            species route aspect: default; species mare aspect: default;
            species campement aspect: default; species animal aspect: default;
            species humain aspect: default; species vecteur aspect: default;
            graphics "legende" {
                draw ("Sim" + simulation_id + " | " + type_experience
                    + " | J" + (jour_debut_simulation + cycle)
                    + " | R0_anim=" + with_precision(R0_animal_10j, 3))
                    at: {shape.width * 0.02, shape.height * 0.04}
                    color: #black font: font("Times New Roman", 12, #bold);
            }
        }

        display "SEIR — Humains" type: 2d {
            chart "Humains" type: series background: #white axes: #black {
                data "S" value: S_h_global color: #green;
                data "E" value: E_h_global color: #yellow;
                data "I" value: I_h_global color: #red;
                data "R" value: R_h_global color: #gray;
            }
        }

        display "SEIR — Animaux" type: 2d {
            chart "Animaux" type: series background: #white axes: #black {
                data "S" value: S_c_global color: #green;
                data "E" value: E_c_global color: rgb(252,211,77);
                data "I" value: I_c_global color: #red;
                data "R" value: R_c_global color: #blue;
            }
        }
        display "R₀ animal (10j)" type: 2d {
            chart "R₀ = C/r" type: series background: #white axes: #black {
                data "R0_animal" value: R0_animal_10j color: #darkorange;
                data "Seuil=1"   value: 1.0           color: #red;
            }
        }

        display "Climat" type: 2d {
            chart "Pluie"     type: series background: #white size: {0.5,0.5} position: {0.0,0.0} axes: #black { data "Pluie" value: pluie color: #cyan; }
            chart "Temp"      type: series background: #white size: {0.5,0.5} position: {0.5,0.0} axes: #black { data "T°C" value: temperature color: #red; }
            chart "Humidité"  type: series background: #white size: {0.5,0.5} position: {0.0,0.5} axes: #black { data "RH %" value: humidite_relative color: #blue; }
            chart "Vent"      type: series background: #white size: {0.5,0.5} position: {0.5,0.5} axes: #black { data "Vent m/s" value: vitesse_vent color: #darkgray; }
        }

        display "Mares & Biomasse" type: 2d {
            chart "Niveau mares" type: series background: #white size: {1.0,0.5} position: {0.0,0.0} axes: #black {
                data "Niveau moy" value: (empty(mare)) ? 0.0 : mean(mare collect each.niveau_mare) color: #blue;
            }
            chart "Biomasse moyenne" type: series background: #white size: {1.0,0.5} position: {0.0,0.5} axes: #black {
                data "Biomasse moyenne" value: (empty(vegetation)) ? 0.0 : mean(vegetation collect each.biomasse) color: #olive;
            }
        }

        display "Indices satellite" type: 2d {
            chart "NDVI / NDWI moyens" type: series background: #white axes: #black {
                data "NDVI moyen (végétation)" value: ndvi_moyen_global color: #darkgreen;
                data "NDWI moyen (mares)"      value: ndwi_moyen_global color: #blue;
            }
        }

        monitor "R0_animal (10j)" value: with_precision(R0_animal_10j, 4) color: #darkorange;
        monitor "m_animal"        value: with_precision(m_animal_10j, 4);
        monitor "a_animal"        value: with_precision(a_animal_10j, 4);
        monitor "C_animal"        value: with_precision(C_animal_10j, 4);
        monitor "Fenêtre"         value: num_fenetre;

        monitor "Humains S"       value: int(S_h_global) color: #green;
        monitor "Humains E"       value: int(E_h_global) color: #goldenrod;
        monitor "Humains I"       value: int(I_h_global) color: #red;
        monitor "Humains R"       value: int(R_h_global) color: #gray;

        monitor "Animaux I"       value: int(I_c_global) color: #red;
        monitor "Humidité %"      value: with_precision(humidite_relative, 1);
        monitor "Vent m/s"        value: with_precision(vitesse_vent, 1);
        monitor "Facteur humidité" value: with_precision(facteur_humidite, 3);
        monitor "Facteur vent"    value: with_precision(facteur_vent, 3);
        monitor "NDVI moyen"      value: with_precision(ndvi_moyen_global, 3) color: #darkgreen;
        monitor "NDWI moyen"      value: with_precision(ndwi_moyen_global, 3) color: #blue;

        monitor "Infections totales (cumul)"  value: nb_infections_totales color: #red;
        monitor "R0_animal moyen (cumul)"     value: (nb_R0_animal > 0) ? with_precision(somme_R0_animal / nb_R0_animal, 4) : 0.0;
    }
}*/

// =============================================================================
// EXPÉRIENCES BATCH
// Les expériences "_3rep" sont conservées pour des tests rapides ; les
// nouvelles "_1000rep" permettent un grand nombre N de réplications via
// repeat: N et among: range(1, N).
// =============================================================================
experiment "Batch_Aedes_3rep" type: batch repeat: 3 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Aedes";
    parameter "Simulation ID" var: simulation_id   among: [1, 2, 3];
}

experiment "Batch_Animal_3rep" type: batch repeat: 3 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Animal";
    parameter "Simulation ID" var: simulation_id   among: [1, 2, 3];
}

experiment "Batch_Aedes_1000rep" type: batch repeat: 1000 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Aedes";
    parameter "Simulation ID" var: simulation_id   among: range(1, 1000);
}

experiment "Batch_Animal_1000rep" type: batch repeat: 1000 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Animal";
    parameter "Simulation ID" var: simulation_id   among: range(1, 1000);
}
