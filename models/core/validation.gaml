/**
 * VALIDATION — confrontation du modèle aux motifs publiés pour Barkedji.
 *
 * Deux volets.
 *
 * 1. DIAGNOSTIC DU FORÇAGE CLIMATIQUE. Aucun résultat entomologique n'est
 *    interprétable si la pluie d'entrée sort du régime documenté pour le
 *    Ferlo. Le contrôle est fait une fois, à l'init, et il est bruyant : une
 *    série hors enveloppe invalide tout ce qui en découle, y compris le
 *    critère de co-abondance ci-dessous.
 *
 * 2. CRITÈRE DE CO-ABONDANCE (Soti et al. 2012, PLoS Negl Trop Dis 6(8)).
 *    Sur 43 ans de simulation (1961-2003), les principales épidémies de FVR
 *    surviennent les années de FORTE ABONDANCE SIMULTANÉE des deux espèces :
 *    Ae. vexans amplifie après les pluies, Cx. poicilipes prend le relais sur
 *    les mares établies. C'est le seul critère de validation publié pour cette
 *    zone, et il porte sur la complémentarité des deux espèces plutôt que sur
 *    l'abondance de l'une d'elles.
 *
 *    Le modèle en est aujourd'hui loin — les Culex saturent le plafond pendant
 *    que les Aedes s'éteignent — d'où l'intérêt d'en faire une sortie explicite
 *    plutôt qu'une lecture a posteriori des courbes.
 */
model Validation

import "parametres_globaux.gaml"
import "climat.gaml"
import "../agents/vecteur.gaml"

global {

    // =========================================================================
    // ENVELOPPE DOCUMENTÉE DU FORÇAGE (Ferlo / Barkedji)
    // =========================================================================
    // Cumul annuel : 300-500 mm (Soti et al. 2012 ; Paul et al. 2014 ;
    // Durand et al. 2020). Maximum journalier : le modèle hydrologique de Soti
    // et al. (2010) est calibré sur 0 < P < 45 mm/j. Nombre de jours de pluie :
    // 30 à 45 dans un Sahel à ce cumul.
    float cumul_annuel_min_ref <- 300.0;
    float cumul_annuel_max_ref <- 500.0;
    float pluie_jour_max_ref   <- 45.0;

    bool  forcage_hors_enveloppe <- false;
    float cumul_pluie_serie      <- 0.0;
    float pluie_jour_max_serie   <- 0.0;
    int   nb_jours_pluie_serie   <- 0;

    /**
     * Contrôle de la série chargée. N'altère RIEN : signale seulement, et
     * positionne `forcage_hors_enveloppe`, qui est reporté dans validation.csv
     * pour qu'aucun résultat ne puisse être lu sans cette réserve.
     */
    action diagnostiquer_forcage {
        if (empty(climat_PRECTOTCORR)) {
            write "DIAGNOSTIC CLIMAT : série vide, contrôle impossible.";
        } else {
            cumul_pluie_serie    <- sum(climat_PRECTOTCORR);
            pluie_jour_max_serie <- max(climat_PRECTOTCORR);
            nb_jours_pluie_serie <- length(climat_PRECTOTCORR where (each > 1.0));

            // Le cumul de référence est annuel : on le ramène à la fenêtre
            // effectivement chargée pour que la comparaison ait un sens.
            float part_annee <- float(nb_lignes_climat) / 365.0;
            float attendu_min <- cumul_annuel_min_ref * part_annee;
            float attendu_max <- cumul_annuel_max_ref * part_annee;

            bool cumul_ko <- cumul_pluie_serie > attendu_max * 1.5;
            bool pic_ko   <- pluie_jour_max_serie > pluie_jour_max_ref;
            forcage_hors_enveloppe <- cumul_ko or pic_ko;

            write "===================================================";
            write "DIAGNOSTIC DU FORÇAGE CLIMATIQUE";
            write "  fenêtre chargée   : " + nb_lignes_climat + " jours";
            write "  cumul             : " + with_precision(cumul_pluie_serie, 0)
                + " mm   (attendu " + with_precision(attendu_min, 0)
                + "-" + with_precision(attendu_max, 0) + " mm)";
            write "  maximum journalier: " + with_precision(pluie_jour_max_serie, 1)
                + " mm/j (borne de calibrage Soti : " + pluie_jour_max_ref + ")";
            write "  jours de pluie    : " + nb_jours_pluie_serie
                + "   (30-45 attendus sur une année entière)";
            if (forcage_hors_enveloppe) {
                write "  >>> FORÇAGE HORS ENVELOPPE DOCUMENTÉE <<<";
                write "  Les mares resteront en eau hors saison, l'abondance";
                write "  vectorielle et le R0 qui en découle ne sont pas";
                write "  comparables à la littérature. Reprendre l'extraction";
                write "  climatique avant d'interpréter ces sorties.";
            } else {
                write "  Forçage dans l'enveloppe documentée.";
            }
            write "===================================================";
        }
    }

    // =========================================================================
    // CO-ABONDANCE DES DEUX ESPÈCES
    // =========================================================================
    // Séries journalières d'abondance en INDIVIDUS RÉELS.
    list<float> serie_aedes <- [];
    list<float> serie_culex <- [];

    // Une espèce est dite « en forte abondance » un jour donné si elle dépasse
    // cette fraction de son propre pic sur la période. La normalisation par
    // espèce est nécessaire : Culex et Aedes ne se comparent pas en effectifs
    // bruts, seule leur COÏNCIDENCE temporelle est le critère de Soti.
    float seuil_co_abondance <- 0.5;

    float pic_aedes          <- 0.0;
    float pic_culex          <- 0.0;
    int   jours_co_abondance <- 0;
    float indice_co_abondance <- 0.0;   // moyenne de min(a_norm, c_norm)
    int   jour_pic_aedes     <- -1;
    int   jour_pic_culex     <- -1;
    int   decalage_pics      <- 0;      // en jours, |pic Culex - pic Aedes|

    reflex accumuler_abondances {
        add float(length(vecteur where (each.type_vecteur = "aedes")))
            * float(echelle_si_vecteur) to: serie_aedes;
        add float(length(vecteur where (each.type_vecteur = "culex")))
            * float(echelle_si_vecteur) to: serie_culex;
    }

    /**
     * Calcul du critère, appelé en fin de simulation.
     *
     * `jours_co_abondance` compte les jours où LES DEUX espèces dépassent
     * simultanément la fraction seuil de leur propre pic. `decalage_pics`
     * mesure le décalage entre les deux maxima : chez Soti, Aedes culmine peu
     * après les premières pluies et Culex plus tard sur les mares établies, un
     * décalage de quelques semaines est donc attendu — un décalage nul ou de
     * plusieurs mois signale un problème de dynamique.
     */
    action calculer_co_abondance {
        int n <- min(length(serie_aedes), length(serie_culex));
        if (n = 0) {
            pic_aedes <- 0.0; pic_culex <- 0.0;
            jours_co_abondance <- 0; indice_co_abondance <- 0.0;
        } else {
            pic_aedes <- max(serie_aedes);
            pic_culex <- max(serie_culex);
            jour_pic_aedes <- (pic_aedes > 0.0) ? serie_aedes index_of pic_aedes : -1;
            jour_pic_culex <- (pic_culex > 0.0) ? serie_culex index_of pic_culex : -1;
            decalage_pics  <- (jour_pic_aedes >= 0 and jour_pic_culex >= 0)
                              ? abs(jour_pic_culex - jour_pic_aedes) : 0;

            int    compte <- 0;
            float  somme  <- 0.0;
            loop i from: 0 to: n - 1 {
                float a <- (pic_aedes > 0.0) ? (serie_aedes[i] / pic_aedes) : 0.0;
                float c <- (pic_culex > 0.0) ? (serie_culex[i] / pic_culex) : 0.0;
                somme <- somme + min(a, c);
                if (a >= seuil_co_abondance and c >= seuil_co_abondance) {
                    compte <- compte + 1;
                }
            }
            jours_co_abondance  <- compte;
            indice_co_abondance <- somme / float(n);
        }

        write "===================================================";
        write "CRITÈRE DE CO-ABONDANCE (Soti et al. 2012)";
        write "  pic Aedes : " + int(pic_aedes) + " individus au jour "
            + (jour_pic_aedes + jour_debut_simulation);
        write "  pic Culex : " + int(pic_culex) + " individus au jour "
            + (jour_pic_culex + jour_debut_simulation);
        write "  décalage des pics    : " + decalage_pics + " jours";
        write "  jours de co-abondance: " + jours_co_abondance
            + " (les deux espèces au-dessus de "
            + int(seuil_co_abondance * 100) + " % de leur pic)";
        write "  indice de co-abondance : " + with_precision(indice_co_abondance, 4);
        if (forcage_hors_enveloppe) {
            write "  >>> à ne pas interpréter : forçage climatique hors enveloppe";
        }
        write "===================================================";
    }
}
