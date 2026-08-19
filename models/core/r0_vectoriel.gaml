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
 * à une constante alors que la mortalité réellement simulée est plus forte.
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

    // ---- R0 LOCAL (par gîte) ----
    // Le R0 global mélange les mares fréquentées par le bétail et celles qui ne
    // le sont pas : il écrase le signal. Les R0 publiés pour le Ferlo sont
    // cartographiés point par point ; ces indicateurs-ci sont l'équivalent.
    int   nb_mares_evaluees   <- 0;   // gîtes produisant des vecteurs ET ayant des hôtes à portée
    int   nb_mares_R0_sup1    <- 0;
    float part_mares_R0_sup1  <- 0.0;
    float R0_local_median     <- 0.0;
    float R0_local_max        <- 0.0;
    float R0_local_moyen      <- 0.0;

    /**
     * Calcule le R0 de chaque gîte, en agrège la distribution, et exporte le
     * détail par mare (une ligne par gîte évalué) pour permettre une carte.
     */
    action calculer_et_exporter_R0_local(int fenetre, int j_debut, int j_fin) {
        ask mare { do calculer_R0_local; }

        list<mare> evaluees <- mare where (each.R0_local > 0.0 or
                                  (each.loc_vect_jours > 0.0 and each.hotes_moyens > 0.0));
        nb_mares_evaluees <- length(evaluees);

        if (nb_mares_evaluees > 0) {
            list<float> valeurs <- evaluees collect each.R0_local;
            R0_local_median  <- median(valeurs);
            R0_local_max     <- max(valeurs);
            R0_local_moyen   <- mean(valeurs);
            nb_mares_R0_sup1 <- length(evaluees where (each.R0_local > 1.0));
            part_mares_R0_sup1 <- float(nb_mares_R0_sup1) / float(nb_mares_evaluees);
        } else {
            R0_local_median <- 0.0; R0_local_max <- 0.0; R0_local_moyen <- 0.0;
            nb_mares_R0_sup1 <- 0;  part_mares_R0_sup1 <- 0.0;
        }

        write "LOCAL : " + nb_mares_evaluees + " gîtes évalués | R0 médian="
            + with_precision(R0_local_median, 3)
            + " | max=" + with_precision(R0_local_max, 3)
            + " | gîtes R0>1 : " + nb_mares_R0_sup1
            + " (" + with_precision(part_mares_R0_sup1 * 100.0, 1) + " %)";

        if (export_detail) {
            if (simulation_id = 1 and fenetre = 1) {
                save ["simulation_id","experience","fenetre","jour_debut","jour_fin",
                      "mare","x","y","m_local","a_local","p_local","R0_local",
                      "hotes_moyens","vecteurs_jours","saison"]
                    to: csv_r0_local format: "csv" rewrite: true;
            }
            ask evaluees {
                save [simulation_id, type_experience, fenetre, j_debut, j_fin,
                      name, with_precision(location.x, 1), with_precision(location.y, 1),
                      with_precision(m_local, 4), with_precision(a_local, 4),
                      with_precision(p_local, 4), with_precision(R0_local, 4),
                      with_precision(hotes_moyens, 2), with_precision(loc_vect_jours, 1),
                      saison]
                    to: csv_r0_local format: "csv" rewrite: false;
            }
        }

        ask mare { do reinitialiser_accumulateurs_locaux; }
    }

    /**
     * Composante vectorielle C de Ross-Macdonald, avec garde-fous sur p.
     */
    float composante_C(float m, float a, float p, float n, float b, float c) {
        if (m <= 0.0 or a <= 0.0 or p <= 0.0 or p >= 1.0 or n <= 0.0) { return 0.0; }
        float ln_p <- ln(p);
        if (ln_p >= 0.0) { return 0.0; }
        return (m * a * a * b * c * (p ^ n)) / (-ln_p);
    }

    /**
     * Probabilités de transmission moyennes. La compétence dépend de l'espèce
     * de VECTEUR (Diallo et al. 2016) : pour le R0 « tous vecteurs confondus »
     * on pondère donc par la composition Aedes/Culex de la population.
     */
    action mettre_a_jour_b_c_moyens {
        float N_ae <- float(length(vecteur where (each.type_vecteur = "aedes")));
        float N_cx <- float(length(vecteur where (each.type_vecteur = "culex")));
        float N    <- N_ae + N_cx;
        if (N > 0.0) {
            b_moyen <- (b_aedes * N_ae + b_culex * N_cx) / N;
            c_moyen <- (c_aedes * N_ae + c_culex * N_cx) / N;
        } else {
            b_moyen <- b_aedes;
            c_moyen <- c_aedes;
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

        C_Aedes_10j  <- composante_C(m_Aedes_10j, a_Aedes_10j, p_Aedes_10j, n_Aedes, b_aedes, c_aedes);
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

        C_animal_10j  <- composante_C(m_animal_10j, a_animal_10j, p_animal_10j, n_animal, b_moyen, c_moyen);
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
                  "nb_gites_evalues","R0_local_median","R0_local_max","part_gites_R0_sup1",
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
              nb_mares_evaluees, with_precision(R0_local_median, 6),
              with_precision(R0_local_max, 6), with_precision(part_mares_R0_sup1, 4),
              saison, with_precision(temperature, 2),
              with_precision(pluie, 2), with_precision(humidite_relative, 2)]
            to: csv_r0_vectoriel format: "csv" rewrite: false;

        do calculer_et_exporter_R0_local(num_fenetre, j_debut, j_fin);

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
        // `m` doit être un rapport d'INDIVIDUS RÉELS : hôtes et vecteurs n'ont
        // pas la même échelle super-individu, il faut donc repondérer.
        float nb_h <- float(length(humain) + length(animal)) * float(echelle_superindividu);
        if (nb_h > 0.0) {
            int nb_aedes <- length(vecteur where (each.type_vecteur = "aedes"));
            cumul_m_Aedes              <- cumul_m_Aedes
                + (float(nb_aedes) * float(echelle_si_vecteur) / nb_h);
            cumul_vecteurs_Aedes_jours <- cumul_vecteurs_Aedes_jours + float(nb_aedes);

            int nb_tous_v <- length(vecteur);
            cumul_m_vect              <- cumul_m_vect
                + (float(nb_tous_v) * float(echelle_si_vecteur) / nb_h);
            cumul_vecteurs_vect_jours <- cumul_vecteurs_vect_jours + float(nb_tous_v);
        }
        cumul_eip        <- cumul_eip + eip_jours(temperature);
        nb_jours_fenetre <- nb_jours_fenetre + 1;
    }

    reflex calculer_R0_fenetre when: (nb_jours_fenetre >= 10) {
        do calculer_et_exporter_R0;
    }
}
