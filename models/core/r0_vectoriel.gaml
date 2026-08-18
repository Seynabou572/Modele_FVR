/**
 * R0 VECTORIEL — FORMULE DE ROSS-MACDONALD COMPLÈTE
 *
 *      C  = m . a^2 . b . c . p^n / (-ln p)          R0 = C / r
 *
 *   m : nombre de vecteurs par hôte
 *   a : taux de piqûre journalier (1 / cycle gonotrophique), MESURÉ sur tous
 *       les vecteurs — pas seulement les infectés
 *   b : probabilité de transmission vecteur -> hôte, par piqûre
 *   c : probabilité de transmission hôte -> vecteur, par piqûre
 *   p : survie journalière du vecteur, MESURÉE sur la fenêtre (et non postulée)
 *   n : durée de l'incubation extrinsèque, moyennée sur la fenêtre
 *   r : taux de guérison de l'hôte (1 / durée d'infection)
 *
 * Par rapport à la version précédente : b et c étaient absents de la formule,
 * `a` ne comptait que les piqûres des vecteurs infectés, et `p` était postulé
 * à exp(-mu_v) alors que la mortalité réellement simulée est plus forte.
 *
 * R0_animal désigne le R0 « tous vecteurs confondus » (Aedes + Culex) ;
 * R0_Aedes ne considère que les Aedes.
 */
model R0Vectoriel

import "parametres_globaux.gaml"
import "climat.gaml"
import "biologie_thermique.gaml"
import "exports_csv.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

    float p_survie_vect    <- 0.0;
    float ln_p_survie_vect <- -9999.0;
    float n_Aedes          <- 0.0;
    float n_animal         <- 0.0;
    float r_hote           <- 0.0;
    float b_moyen          <- 0.0;
    float c_moyen          <- 0.0;

    // Accumulateurs de la fenêtre — Aedes seuls
    float cumul_m_Aedes              <- 0.0;
    float cumul_bites_Aedes          <- 0.0;
    float cumul_vecteurs_Aedes_jours <- 0.0;
    float cumul_morts_Aedes          <- 0.0;

    // Accumulateurs de la fenêtre — tous vecteurs
    float cumul_m_vect              <- 0.0;
    float cumul_bites_vect          <- 0.0;
    float cumul_vecteurs_vect_jours <- 0.0;
    float cumul_morts_vect          <- 0.0;

    // Incubation extrinsèque cumulée (pour la moyenne de n sur la fenêtre)
    float cumul_eip <- 0.0;

    int   nb_jours_fenetre <- 0;
    int   num_fenetre      <- 0;

    float m_Aedes_10j   <- 0.0;
    float a_Aedes_10j   <- 0.0;
    float p_Aedes_10j   <- 0.0;
    float C_Aedes_10j   <- 0.0;
    float R0_Aedes_10j  <- 0.0;

    float m_animal_10j  <- 0.0;
    float a_animal_10j  <- 0.0;
    float p_animal_10j  <- 0.0;
    float C_animal_10j  <- 0.0;
    float R0_animal_10j <- 0.0;

    // Accumulateurs pour le R0 MOYEN sur toute la simulation
    float somme_R0_Aedes  <- 0.0;
    int   nb_R0_Aedes     <- 0;
    float somme_R0_animal <- 0.0;
    int   nb_R0_animal    <- 0;

    /**
     * Composante vectorielle C de Ross-Macdonald, avec garde-fous sur p.
     */
    float composante_C(float m, float a, float p, float n) {
        if (m <= 0.0 or a <= 0.0 or p <= 0.0 or p >= 1.0 or n <= 0.0) { return 0.0; }
        float ln_p <- ln(p);
        if (ln_p >= 0.0) { return 0.0; }
        return (m * a * a * b_moyen * c_moyen * (p ^ n)) / (-ln_p);
    }

    /**
     * Probabilités de transmission moyennes, pondérées par l'abondance relative
     * des deux types d'hôtes : le R0 est calculé sur un pool d'hôtes unique.
     */
    action mettre_a_jour_b_c_moyens {
        float N_h <- float(length(humain));
        float N_a <- float(length(animal));
        float N   <- N_h + N_a;
        if (N > 0.0) {
            b_moyen <- (b_vh * N_h + b_va * N_a) / N;
            c_moyen <- (c_hv * N_h + c_av * N_a) / N;
        }
    }

    // =========================================================================
    // ACTION : CALCUL ET EXPORT R0 PAR FENÊTRE DE 10 JOURS
    // =========================================================================
    action calculer_et_exporter_R0 {

        num_fenetre <- num_fenetre + 1;
        int j_debut <- (num_fenetre - 1) * 10 + 1;
        int j_fin   <- num_fenetre * 10;

        do mettre_a_jour_b_c_moyens;

        // n : EIP moyenne observée sur la fenêtre
        float n_fenetre <- (nb_jours_fenetre > 0)
            ? (cumul_eip / float(nb_jours_fenetre)) : duree_cycle_extrinseque;
        n_Aedes  <- n_fenetre;
        n_animal <- n_fenetre;

        write "==================================================";
        write "SIMULATION " + simulation_id + " | EXPÉRIENCE " + type_experience;
        write "FENÊTRE R0 : J" + j_debut + "–J" + j_fin;
        write "==================================================";

        // ---------------- Aedes seuls ----------------
        m_Aedes_10j <- (nb_jours_fenetre > 0) ? (cumul_m_Aedes / nb_jours_fenetre) : 0.0;
        a_Aedes_10j <- (cumul_vecteurs_Aedes_jours > 0.0)
                       ? (cumul_bites_Aedes / cumul_vecteurs_Aedes_jours) : 0.0;
        p_Aedes_10j <- (cumul_vecteurs_Aedes_jours > 0.0)
                       ? max(0.0, min(0.999, 1.0 - cumul_morts_Aedes / cumul_vecteurs_Aedes_jours))
                       : 0.0;

        C_Aedes_10j  <- composante_C(m_Aedes_10j, a_Aedes_10j, p_Aedes_10j, n_Aedes);
        R0_Aedes_10j <- (r_hote > 0.0) ? (C_Aedes_10j / r_hote) : 0.0;

        write "AEDES : m=" + with_precision(m_Aedes_10j, 4)
            + " | a=" + with_precision(a_Aedes_10j, 4)
            + " | p=" + with_precision(p_Aedes_10j, 4)
            + " | n=" + with_precision(n_Aedes, 2)
            + " | C=" + with_precision(C_Aedes_10j, 4)
            + " | R0_Aedes=" + with_precision(R0_Aedes_10j, 4);

        // ---------------- Tous vecteurs confondus ----------------
        m_animal_10j <- (nb_jours_fenetre > 0) ? (cumul_m_vect / nb_jours_fenetre) : 0.0;
        a_animal_10j <- (cumul_vecteurs_vect_jours > 0.0)
                        ? (cumul_bites_vect / cumul_vecteurs_vect_jours) : 0.0;
        p_animal_10j <- (cumul_vecteurs_vect_jours > 0.0)
                        ? max(0.0, min(0.999, 1.0 - cumul_morts_vect / cumul_vecteurs_vect_jours))
                        : 0.0;

        C_animal_10j  <- composante_C(m_animal_10j, a_animal_10j, p_animal_10j, n_animal);
        R0_animal_10j <- (r_hote > 0.0) ? (C_animal_10j / r_hote) : 0.0;

        // Conservé pour les moniteurs de l'interface
        p_survie_vect    <- p_animal_10j;
        ln_p_survie_vect <- (p_animal_10j > 0.0 and p_animal_10j < 1.0)
                            ? ln(p_animal_10j) : -9999.0;

        write "ANIMAL : m=" + with_precision(m_animal_10j, 4)
            + " | a=" + with_precision(a_animal_10j, 4)
            + " | p=" + with_precision(p_animal_10j, 4)
            + " | C=" + with_precision(C_animal_10j, 4)
            + " | R0_animal=" + with_precision(R0_animal_10j, 4);
        write "  b_moyen=" + with_precision(b_moyen, 4)
            + " | c_moyen=" + with_precision(c_moyen, 4);
        write "==================================================";

        somme_R0_Aedes  <- somme_R0_Aedes + R0_Aedes_10j;
        nb_R0_Aedes     <- nb_R0_Aedes + 1;
        somme_R0_animal <- somme_R0_animal + R0_animal_10j;
        nb_R0_animal    <- nb_R0_animal + 1;

        if (simulation_id = 1 and num_fenetre = 1) {
            save ["simulation_id","experience","fenetre","jour_debut","jour_fin",
                  "m_Aedes","a_Aedes","p_Aedes","C_Aedes","R0_Aedes",
                  "m_animal","a_animal","p_animal","C_animal","R0_animal",
                  "b_moyen","c_moyen","n_eip",
                  "saison","temperature_C","pluie_mm","humidite_pct"]
                to: csv_r0_vectoriel format: "csv" rewrite: true;
        }
        save [simulation_id, type_experience, num_fenetre, j_debut, j_fin,
              with_precision(m_Aedes_10j, 6),   with_precision(a_Aedes_10j, 6),
              with_precision(p_Aedes_10j, 6),
              with_precision(C_Aedes_10j, 6),   with_precision(R0_Aedes_10j, 6),
              with_precision(m_animal_10j, 6),  with_precision(a_animal_10j, 6),
              with_precision(p_animal_10j, 6),
              with_precision(C_animal_10j, 6),  with_precision(R0_animal_10j, 6),
              with_precision(b_moyen, 6),       with_precision(c_moyen, 6),
              with_precision(n_Aedes, 4),
              saison, with_precision(temperature, 2),
              with_precision(pluie, 2), with_precision(humidite_relative, 2)]
            to: csv_r0_vectoriel format: "csv" rewrite: false;

        cumul_m_Aedes              <- 0.0;
        cumul_bites_Aedes          <- 0.0;
        cumul_vecteurs_Aedes_jours <- 0.0;
        cumul_morts_Aedes          <- 0.0;
        cumul_m_vect               <- 0.0;
        cumul_bites_vect           <- 0.0;
        cumul_vecteurs_vect_jours  <- 0.0;
        cumul_morts_vect           <- 0.0;
        cumul_eip                  <- 0.0;
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
        cumul_eip        <- cumul_eip + eip_jours(temperature);
        nb_jours_fenetre <- nb_jours_fenetre + 1;
    }

    reflex calculer_R0_fenetre when: (nb_jours_fenetre >= 10) {
        do calculer_et_exporter_R0;
    }
}
