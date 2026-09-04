/**
 * R0 VECTORIEL — DEUX FORMES, EXPORTÉES CÔTE À CÔTE
 *
 *   (1) Capacité vectorielle de Garrett-Jones, formule du document de
 *       référence du projet (articles/CalculR0.pdf, éq. 2) :
 *
 *           C  = m . a^2 . p^n / (-ln p)             R0 = C / r
 *
 *   (2) Ross-Macdonald pondéré par la compétence vectorielle :
 *
 *           C' = m . a^2 . b . c . p^n / (-ln p)     R0 = C' / r
 *
 * Le rapport entre les deux vaut 1/(b.c). Voir le commentaire détaillé devant
 * `capacite_vectorielle` plus bas.
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

    // Accumulateurs SEPARES : chaque grandeur a sa propre fenetre.
    int   nb_jours_animal  <- 0;
    int   nb_jours_aedes   <- 0;
    float cumul_eip_animal <- 0.0;
    float cumul_eip_aedes  <- 0.0;
    bool  R0_animal_calcule <- false;
    bool  R0_Aedes_calcule  <- false;
    bool  entete_r0_ecrite  <- false;

    float m_Aedes_10j   <- 0.0;
    float a_Aedes_10j   <- 0.0;
    float p_Aedes_10j   <- 0.0;
    float C_Aedes_10j   <- 0.0;
    float R0_Aedes_10j  <- 0.0;

    // Forme de Garrett-Jones (CalculR0.pdf) : sans b ni c.
    float C_Aedes_capacite   <- 0.0;
    float R0_Aedes_capacite  <- 0.0;
    float C_animal_capacite  <- 0.0;
    float R0_animal_capacite <- 0.0;

    float m_animal_10j  <- 0.0;
    float a_animal_10j  <- 0.0;
    float p_animal_10j  <- 0.0;
    float C_animal_10j  <- 0.0;
    float R0_animal_10j <- 0.0;

    // Valeurs de protocole : une seule par grandeur, figée à la clôture de sa
    // fenêtre (10 jours pour l'animal, 21 pour les Aedes).
    float R0_animal_protocole <- 0.0;
    float R0_Aedes_protocole  <- 0.0;

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
        ask mare {
            do calculer_R0_local;
            do calculer_R0_vectoriel;
            do recenser_zpom_complet;   // anneaux 100 et 1000 m, pour l'export
        }

        // Un gîte est exporté s'il porte de la transmission (R0 local) OU s'il
        // produit des vecteurs (R0 vectoriel) : une mare productive sans hôte à
        // portée reste une information spatiale, c'est même le cas typique du
        // Ferlo où les campements ne bordent qu'une partie des mares.
        list<mare> evaluees <- mare where (each.R0_local > 0.0
                                  or each.R0_vectoriel > 0.0
                                  or (each.loc_vect_jours > 0.0 and each.hotes_moyens > 0.0));
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
                      "hotes_moyens","vecteurs_jours",
                      "R0_vectoriel","rho_recouvrement","lambda_gite",
                      "surface_max_m2","surface_eau_m2","niveau_mare","est_lit_ferlo",
                      "hotes_zpom_100","hotes_zpom_500","hotes_zpom_1000","fermeture_500",
                      "oeufs_infectes","oeufs_sains","saison"]
                    to: csv_r0_local format: "csv" rewrite: true;
            }
            ask evaluees {
                save [simulation_id, type_experience, fenetre, j_debut, j_fin,
                      name, with_precision(location.x, 1), with_precision(location.y, 1),
                      with_precision(m_local, 4), with_precision(a_local, 4),
                      with_precision(p_local, 4), with_precision(R0_local, 4),
                      with_precision(hotes_moyens, 2), with_precision(loc_vect_jours, 1),
                      with_precision(R0_vectoriel, 4), with_precision(rho_recouvrement, 6),
                      with_precision(lambda_gite, 4),
                      with_precision(surface_max, 1), with_precision(surface_eau, 1),
                      with_precision(niveau_mare, 4), est_ensemble1,
                      hotes_zpom_100, hotes_zpom_500, hotes_zpom_1000,
                      with_precision(fermeture_500, 4),
                      int(oeufs_aedes_infectes), int(oeufs_aedes_sains),
                      saison]
                    to: csv_r0_local format: "csv" rewrite: false;
            }
        }

        ask mare { do reinitialiser_accumulateurs_locaux; }
    }

    // =========================================================================
    // DEUX FORMES DE LA CAPACITÉ VECTORIELLE
    //
    // (1) CAPACITÉ VECTORIELLE DE GARRETT-JONES — c'est la formule du document
    //     de référence du projet (articles/CalculR0.pdf, éq. 2) :
    //
    //         C  = m · a² · p^n / (−ln p)          R0 = C / r
    //
    //     « nombre moyen de piqûres que les vecteurs ayant piqué un individu
    //     infectant infligent à la population hôte pendant le reste de leur
    //     vie, une fois le cycle d'incubation accompli. » Elle mesure un
    //     POTENTIEL de contact : la compétence vectorielle n'y figure pas,
    //     volontairement — c'est ce qui en fait une capacité et non un taux de
    //     transmission réalisé.
    //
    // (2) FORME PONDÉRÉE PAR LA COMPÉTENCE — Ross-Macdonald complet :
    //
    //         C' = m · a² · b · c · p^n / (−ln p)
    //
    //     où b et c sont les probabilités de transmission par piqûre, mesurées
    //     sur souches sénégalaises (Diallo et al. 2016).
    //
    // Les deux sont standard et ne mesurent pas la même chose. Le rapport entre
    // elles vaut exactement 1/(b·c) : avec b=0.23 et c=0.57 pour Aedes, la
    // capacité est 7.6 fois la forme pondérée ; avec b=0.11 et c=0.28 pour
    // Culex, 32 fois. L'écart n'est donc pas anecdotique, et les deux sont
    // exportées côte à côte pour que la comparaison à la littérature se fasse
    // sur la même définition que la source citée.
    // =========================================================================

    /** (1) Capacité vectorielle de Garrett-Jones — formule de CalculR0.pdf. */
    float capacite_vectorielle(float m, float a, float p, float n) {
        if (m <= 0.0 or a <= 0.0 or p <= 0.0 or p >= 1.0 or n <= 0.0) { return 0.0; }
        float ln_p <- ln(p);
        if (ln_p >= 0.0) { return 0.0; }
        return (m * a * a * (p ^ n)) / (-ln_p);
    }

    /** (2) Composante C pondérée par la compétence vectorielle. */
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
    // DEUX R0, CALCULÉS UNE SEULE FOIS CHACUN
    //
    // Le protocole ne demande pas un suivi par fenêtres glissantes mais UNE
    // valeur par grandeur, mesurée sur les premiers jours de la simulation :
    //
    //     R0_animal  sur les 10 premiers jours
    //     R0_Aedes   sur les 21 premiers jours
    //
    // Les deux fenêtres sont INDÉPENDANTES et démarrent ensemble au cycle 0.
    // Chaque grandeur possède ses propres accumulateurs, arrêtés à la clôture
    // de sa fenêtre : celle des Aedes continue de courir onze jours après que
    // celle de l'animal s'est refermée.
    //
    // Les 21 jours de la fenêtre Aedes laissent le temps d'un cycle complet
    // œuf -> adulte, ce qui n'aurait pas de sens pour un R0 mesuré à partir
    // d'un cas index animal.
    // =========================================================================

    /** Écrit une ligne de résultat — une seule par grandeur et par simulation. */
    action exporter_ligne_R0(string grandeur, int nb_j, float m, float a, float p,
                             float n, float b, float c,
                             float C_comp, float R0_comp, float C_cap, float R0_cap) {
        if (simulation_id = 1 and !entete_r0_ecrite) {
            save ["simulation_id","experience","grandeur","jour_debut","jour_fin","nb_jours",
                  "m","a","p","n_eip","b","c",
                  "C_competence","R0_competence","C_capacite","R0_capacite",
                  "nb_gites_evalues","R0_local_median","R0_local_max","part_gites_R0_sup1",
                  "saison","temperature_C","pluie_mm","humidite_pct"]
                to: csv_r0_vectoriel format: "csv" rewrite: true;
            entete_r0_ecrite <- true;
        }
        save [simulation_id, type_experience, grandeur,
              jour_debut_simulation, jour_debut_simulation + nb_j - 1, nb_j,
              with_precision(m, 6), with_precision(a, 6), with_precision(p, 6),
              with_precision(n, 4), with_precision(b, 6), with_precision(c, 6),
              with_precision(C_comp, 6), with_precision(R0_comp, 6),
              with_precision(C_cap, 6),  with_precision(R0_cap, 6),
              nb_mares_evaluees, with_precision(R0_local_median, 6),
              with_precision(R0_local_max, 6), with_precision(part_mares_R0_sup1, 4),
              saison, with_precision(temperature, 2),
              with_precision(pluie, 2), with_precision(humidite_relative, 2)]
            to: csv_r0_vectoriel format: "csv" rewrite: false;
    }

    /**
     * R0 ANIMAL — tous vecteurs confondus, sur les `fenetre_R0_animal` premiers
     * jours. Exécuté une seule fois.
     */
    action calculer_R0_animal_unique {
        do mettre_a_jour_b_c_moyens;
        n_animal <- (nb_jours_animal > 0)
                    ? (cumul_eip_animal / float(nb_jours_animal)) : duree_cycle_extrinseque;

        m_animal_10j <- (nb_jours_animal > 0) ? (cumul_m_vect / nb_jours_animal) : 0.0;
        a_animal_10j <- (cumul_vecteurs_vect_jours > 0.0)
                        ? (cumul_bites_vect / cumul_vecteurs_vect_jours) : 0.0;
        p_animal_10j <- (cumul_vecteurs_vect_jours > 0.0)
                        ? max(0.0, min(0.999, 1.0 - cumul_morts_vect / cumul_vecteurs_vect_jours))
                        : 0.0;

        C_animal_10j  <- composante_C(m_animal_10j, a_animal_10j, p_animal_10j,
                                      n_animal, b_moyen, c_moyen);
        R0_animal_10j <- (r_hote > 0.0) ? (C_animal_10j / r_hote) : 0.0;
        C_animal_capacite  <- capacite_vectorielle(m_animal_10j, a_animal_10j,
                                                   p_animal_10j, n_animal);
        R0_animal_capacite <- (r_hote > 0.0) ? (C_animal_capacite / r_hote) : 0.0;

        R0_animal_protocole <- R0_animal_10j;
        p_survie_vect    <- p_animal_10j;
        ln_p_survie_vect <- (p_animal_10j > 0.0 and p_animal_10j < 1.0)
                            ? ln(p_animal_10j) : -9999.0;

        write "==================================================";
        write "R0 ANIMAL - calcul unique sur les " + fenetre_R0_animal + " premiers jours";
        write "  m=" + with_precision(m_animal_10j, 4)
            + " | a=" + with_precision(a_animal_10j, 4)
            + " | p=" + with_precision(p_animal_10j, 4)
            + " | n=" + with_precision(n_animal, 2)
            + " | b=" + with_precision(b_moyen, 4)
            + " | c=" + with_precision(c_moyen, 4);
        write "  R0_animal (pondere b.c)   = " + with_precision(R0_animal_10j, 4);
        write "  R0_animal (Garrett-Jones) = " + with_precision(R0_animal_capacite, 4);
        write "==================================================";

        do calculer_et_exporter_R0_local(1, 1, fenetre_R0_animal);
        do exporter_ligne_R0("animal", fenetre_R0_animal, m_animal_10j, a_animal_10j,
                             p_animal_10j, n_animal, b_moyen, c_moyen,
                             C_animal_10j, R0_animal_10j,
                             C_animal_capacite, R0_animal_capacite);
        R0_animal_calcule <- true;
    }

    /**
     * R0 AEDES — Aedes seuls, sur les `fenetre_R0_aedes` premiers jours.
     * Exécuté une seule fois.
     */
    action calculer_R0_aedes_unique {
        n_Aedes <- (nb_jours_aedes > 0)
                   ? (cumul_eip_aedes / float(nb_jours_aedes)) : duree_cycle_extrinseque;

        m_Aedes_10j <- (nb_jours_aedes > 0) ? (cumul_m_Aedes / nb_jours_aedes) : 0.0;
        a_Aedes_10j <- (cumul_vecteurs_Aedes_jours > 0.0)
                       ? (cumul_bites_Aedes / cumul_vecteurs_Aedes_jours) : 0.0;
        p_Aedes_10j <- (cumul_vecteurs_Aedes_jours > 0.0)
                       ? max(0.0, min(0.999, 1.0 - cumul_morts_Aedes / cumul_vecteurs_Aedes_jours))
                       : 0.0;

        C_Aedes_10j  <- composante_C(m_Aedes_10j, a_Aedes_10j, p_Aedes_10j,
                                     n_Aedes, b_aedes, c_aedes);
        R0_Aedes_10j <- (r_hote > 0.0) ? (C_Aedes_10j / r_hote) : 0.0;
        C_Aedes_capacite  <- capacite_vectorielle(m_Aedes_10j, a_Aedes_10j,
                                                  p_Aedes_10j, n_Aedes);
        R0_Aedes_capacite <- (r_hote > 0.0) ? (C_Aedes_capacite / r_hote) : 0.0;

        R0_Aedes_protocole <- R0_Aedes_10j;

        write "==================================================";
        write "R0 AEDES - calcul unique sur les " + fenetre_R0_aedes + " premiers jours";
        write "  m=" + with_precision(m_Aedes_10j, 4)
            + " | a=" + with_precision(a_Aedes_10j, 4)
            + " | p=" + with_precision(p_Aedes_10j, 4)
            + " | n=" + with_precision(n_Aedes, 2)
            + " | b=" + with_precision(b_aedes, 4)
            + " | c=" + with_precision(c_aedes, 4);
        write "  R0_Aedes (pondere b.c)   = " + with_precision(R0_Aedes_10j, 4);
        write "  R0_Aedes (Garrett-Jones) = " + with_precision(R0_Aedes_capacite, 4);
        write "==================================================";

        do calculer_et_exporter_R0_local(2, 1, fenetre_R0_aedes);
        do exporter_ligne_R0("aedes", fenetre_R0_aedes, m_Aedes_10j, a_Aedes_10j,
                             p_Aedes_10j, n_Aedes, b_aedes, c_aedes,
                             C_Aedes_10j, R0_Aedes_10j,
                             C_Aedes_capacite, R0_Aedes_capacite);
        R0_Aedes_calcule <- true;
    }

    // =========================================================================
    // ACCUMULATION — deux compteurs indépendants, chacun figé à la clôture de
    // sa propre fenêtre.
    // =========================================================================
    reflex accumuler_R0 {
        float nb_h <- float(length(humain) + length(animal)) * float(echelle_superindividu);

        if (!R0_animal_calcule) {
            if (nb_h > 0.0) {
                int nb_tous_v <- length(vecteur);
                cumul_m_vect <- cumul_m_vect
                    + (float(nb_tous_v) * float(echelle_si_vecteur) / nb_h);
                cumul_vecteurs_vect_jours <- cumul_vecteurs_vect_jours + float(nb_tous_v);
            }
            cumul_eip_animal <- cumul_eip_animal + eip_jours(temperature);
            nb_jours_animal  <- nb_jours_animal + 1;
        }

        if (!R0_Aedes_calcule) {
            if (nb_h > 0.0) {
                int nb_aedes <- length(vecteur where (each.type_vecteur = "aedes"));
                cumul_m_Aedes <- cumul_m_Aedes
                    + (float(nb_aedes) * float(echelle_si_vecteur) / nb_h);
                cumul_vecteurs_Aedes_jours <- cumul_vecteurs_Aedes_jours + float(nb_aedes);
            }
            cumul_eip_aedes <- cumul_eip_aedes + eip_jours(temperature);
            nb_jours_aedes  <- nb_jours_aedes + 1;
        }
    }

    reflex clore_fenetre_animal
        when: (!R0_animal_calcule and nb_jours_animal >= fenetre_R0_animal) {
        do calculer_R0_animal_unique;
    }

    reflex clore_fenetre_aedes
        when: (!R0_Aedes_calcule and nb_jours_aedes >= fenetre_R0_aedes) {
        do calculer_R0_aedes_unique;
    }


    /**
     * Suivi du stock d'œufs infectés : son pic sert de référence au taux de
     * report inter-saisonnier calculé au retour des pluies (saisons_occsol).
     */
    reflex suivre_persistance_oeufs {
        float stock <- empty(mare) ? 0.0 : sum(mare collect each.oeufs_aedes_infectes);
        if (stock > oeufs_inf_pic) { oeufs_inf_pic <- stock; }
    }
}
