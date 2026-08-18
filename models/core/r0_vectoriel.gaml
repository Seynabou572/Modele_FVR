/**
 * R₀ VECTORIEL — FORMULE ROSS-MACDONALD
 * R0_animal = R0 "tous vecteurs confondus" (Aedes + Culex) : c'est le SEUL
 * calcul de R0 côté animal (il n'y a pas de mécanisme Culex indépendant).
 */
model R0Vectoriel

global {

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
    // ACTION : CALCUL ET EXPORT R₀ PAR FENÊTRE DE 10 JOURS
    // Calcule R0_Aedes (Aedes seuls) ET R0_animal (TOUS vecteurs confondus,
    // Aedes + Culex)
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
}
