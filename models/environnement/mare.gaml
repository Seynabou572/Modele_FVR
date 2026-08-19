/**
 * MARE — dynamique hydrique + réservoir d'œufs quiescents Aedes.
 *
 * La mare ne produit plus d'adultes directement : elle alimente des
 * `cohorte_larvaire` qui portent le délai de développement (voir
 * environnement/cohorte_larvaire.gaml).
 *
 * Deux réservoirs distincts :
 *  - œufs quiescents Aedes (infectés / sains) : pondus sur sol sec, survie
 *    journalière `phi_aedes`, éclosion déclenchée par l'INONDATION après une
 *    période sèche suffisante ;
 *  - pontes Culex du jour : déposées sur eau libre, converties en cohorte le
 *    jour même.
 */
model Mare

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../core/saisons_occsol.gaml"
import "../core/biologie_thermique.gaml"
import "cohorte_larvaire.gaml"

species mare {
    float volume_eau           <- 0.0;
    float surface_eau          <- 0.0;
    float surface_max          <- 500.0;

    // Réservoir d'œufs quiescents Aedes, en individus réels (float : la survie
    // journalière doit pouvoir s'appliquer de façon continue).
    float oeufs_aedes_infectes <- 0.0;
    float oeufs_aedes_sains    <- 0.0;
    bool  oeufs_index          <- false;   // trace le cas index de l'expérience

    // Accumulateur des pontes Culex de la journée (converti en cohorte le soir).
    float pontes_culex_jour    <- 0.0;

    int   jours_sans_pluie     <- 0;
    int   duree_secheresse_prec <- 0;      // durée du dernier épisode sec ACHEVÉ
    float volume_max_reference <- 300.0;
    float niveau_mare          <- 0.0;
    float L_perte              <- 12.0;
    float Iap                  <- 0.0;

    float k_sol        <- 0.9;
    float Gmax         <- 50.0;
    float Kr           <- 0.5;
    bool  est_ensemble1 <- true;

    float niveau_precedent <- 0.0;
    float montee_niveau    <- 0.0;

    float ndwi_local      <- 0.2;
    float ndwi_precedent  <- 0.2;

    bool  appariee <- false;   // transitoire : appariement au changement de saison

    // =========================================================================
    // ACCUMULATEURS DU R0 LOCAL (fenêtre de 10 jours)
    // Le R0 global est une moyenne sur toute la zone : il mélange les mares
    // fréquentées par le bétail et celles qui ne le sont pas, ce qui écrase le
    // signal. Les R0 publiés pour le Ferlo sont au contraire cartographiés
    // point par point. On accumule donc ici, par gîte, de quoi calculer un R0
    // local comparable à ces cartes.
    // =========================================================================
    float loc_vect_jours   <- 0.0;   // vecteurs-jours issus de ce gîte
    float loc_aedes_jours  <- 0.0;   // dont Aedes (pour la composition b/c)
    float loc_bites        <- 0.0;   // piqûres prises par ces vecteurs
    float loc_morts        <- 0.0;   // morts biologiques de ces vecteurs
    float loc_hotes_jours  <- 0.0;   // hôtes-jours présents dans le rayon de vol
    int   loc_jours        <- 0;

    float R0_local     <- 0.0;
    float m_local      <- 0.0;
    float a_local      <- 0.0;
    float p_local      <- 0.0;
    float hotes_moyens <- 0.0;

    /**
     * Hôtes présents dans le rayon de vol des vecteurs du gîte. C'est la
     * population réellement exposée aux moustiques issus de cette mare.
     */
    reflex comptabiliser_hotes_local {
        int nb <- length(animal at_distance portee_vol_aedes_m)
                + length(humain at_distance portee_vol_aedes_m);
        loc_hotes_jours <- loc_hotes_jours + float(nb);
        loc_jours       <- loc_jours + 1;
    }

    /**
     * R0 de Ross-Macdonald restreint à ce gîte et à sa population d'hôtes.
     * Renvoie 0 si le gîte n'a produit aucun vecteur ou n'a aucun hôte à portée.
     */
    action calculer_R0_local {
        hotes_moyens <- (loc_jours > 0) ? (loc_hotes_jours / float(loc_jours)) : 0.0;
        float hotes_reels <- hotes_moyens * float(echelle_superindividu);

        if (loc_vect_jours <= 0.0 or hotes_reels <= 0.0 or loc_jours = 0) {
            m_local <- 0.0; a_local <- 0.0; p_local <- 0.0; R0_local <- 0.0;
        } else {
            float vect_reels <- (loc_vect_jours / float(loc_jours)) * float(echelle_si_vecteur);
            m_local <- vect_reels / hotes_reels;
            a_local <- loc_bites / loc_vect_jours;
            p_local <- max(0.0, min(0.999, 1.0 - loc_morts / loc_vect_jours));

            // Compétence pondérée par la composition Aedes/Culex du gîte
            float part_ae <- loc_aedes_jours / loc_vect_jours;
            float b_loc <- b_aedes * part_ae + b_culex * (1.0 - part_ae);
            float c_loc <- c_aedes * part_ae + c_culex * (1.0 - part_ae);

            float C_loc <- world.composante_C(m_local, a_local, p_local, n_animal, b_loc, c_loc);
            R0_local <- (r_hote > 0.0) ? (C_loc / r_hote) : 0.0;
        }
    }

    action reinitialiser_accumulateurs_locaux {
        loc_vect_jours  <- 0.0;
        loc_aedes_jours <- 0.0;
        loc_bites       <- 0.0;
        loc_morts       <- 0.0;
        loc_hotes_jours <- 0.0;
        loc_jours       <- 0;
    }

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
        surface_eau           <- min(surface_max, volume_eau * 2.0);
    }

    /**
     * Mémorise la durée de l'épisode sec qui vient de s'achever : c'est elle
     * qui conditionne l'éclosion des œufs quiescents lors de la remise en eau.
     * (L'ancien code testait `jours_sans_pluie >= Td_aedes` le jour même de la
     * pluie, alors que ce compteur venait d'être remis à zéro — l'éclosion des
     * Aedes ne pouvait donc jamais se déclencher sur un épisode pluvieux.)
     */
    reflex compter_jours_secs {
        if (pluie < 1.0) {
            jours_sans_pluie <- jours_sans_pluie + 1;
        } else {
            if (jours_sans_pluie > 0) { duree_secheresse_prec <- jours_sans_pluie; }
            jours_sans_pluie <- 0;
        }
    }

    reflex disparition_mare when: jours_sans_pluie >= seuil_assechement_mare and volume_eau > 0.0 {
        volume_eau <- 0.0; surface_eau <- 0.0;
    }

    reflex mise_a_jour_niveau {
        niveau_precedent <- niveau_mare;
        niveau_mare <- max(0.0, min(1.0,
            (volume_max_reference > 0) ? volume_eau / volume_max_reference : 0.0));
        // La MONTÉE du plan d'eau submerge la berge où les œufs ont été pondus :
        // c'est elle qui déclenche l'éclosion, pas la météo.
        montee_niveau <- max(0.0, niveau_mare - niveau_precedent);
    }

    /**
     * Survie journalière des œufs quiescents, appliquée jour par jour (et non
     * en une seule puissance phi^T comme auparavant).
     */
    reflex survie_oeufs_quiescents {
        oeufs_aedes_infectes <- oeufs_aedes_infectes * phi_aedes;
        oeufs_aedes_sains    <- oeufs_aedes_sains    * phi_aedes;
        if (oeufs_aedes_infectes < 0.01) { oeufs_aedes_infectes <- 0.0; }
        if (oeufs_aedes_sains    < 0.01) { oeufs_aedes_sains    <- 0.0; }
    }

    /**
     * Éclosion Aedes : déclenchée par la remise en eau, à condition que les
     * œufs aient subi une période sèche d'au moins Td_aedes jours.
     */
    /**
     * ÉCLOSION AEDES — déclenchée par la SUBMERSION de la berge portant les œufs.
     *
     * Le mécanisme réel est : ponte sur la marge exondée -> le plan d'eau
     * remonte -> les œufs sont noyés -> éclosion synchrone. L'ancienne condition
     * exigeait 7 jours de sécheresse météorologique achevée juste avant la
     * pluie : en pleine saison des pluies un tel épisode sec ne se produit
     * jamais, donc l'éclosion cessait et les œufs s'accumulaient sans éclore
     * (2,5 millions en fin de run) pendant que les adultes s'éteignaient.
     */
    reflex eclosion_aedes
        when: volume_eau > 0.0
          and montee_niveau >= seuil_montee_eclosion
          and (oeufs_aedes_infectes + oeufs_aedes_sains) >= 1.0 {

        // La fraction d'œufs noyés croît avec l'ampleur de la montée.
        float taux <- beta_aedes * min(1.0, montee_niveau / seuil_montee_eclosion);

        float ecl_inf <- oeufs_aedes_infectes * taux;
        float ecl_san <- oeufs_aedes_sains    * taux;
        oeufs_aedes_infectes <- oeufs_aedes_infectes - ecl_inf;
        oeufs_aedes_sains    <- oeufs_aedes_sains    - ecl_san;

        if (ecl_inf >= 1.0) {
            do creer_cohorte("aedes", true, ecl_inf, oeufs_index);
            write "Éclosion Aedes infectés : " + int(ecl_inf)
                + " immatures (cycle " + cycle + ")";
        }
        if (ecl_san >= 1.0) { do creer_cohorte("aedes", false, ecl_san, false); }
    }

    /**
     * Les pontes Culex de la journée deviennent une cohorte unique, plafonnée
     * par la capacité larvaire du gîte (Emax_culex par m²).
     */
    /**
     * Capacité de charge larvaire du gîte : Emax_culex individus par m² d'eau,
     * appliquée au STOCK d'immatures déjà présents (et non à la seule ponte du
     * jour). C'est ce qui donne son sens au paramètre : au-delà, la compétition
     * larvaire empêche tout recrutement supplémentaire.
     */
    float charge_larvaire {
        list<cohorte_larvaire> c <- cohorte_larvaire where (each.gite = self);
        return empty(c) ? 0.0 : sum(c collect each.effectif);
    }

    reflex mise_en_cohorte_culex when: pontes_culex_jour >= 1.0 {
        if (volume_eau > 0.0) {
            float capacite <- Emax_culex * max(1.0, surface_eau);
            float place    <- max(0.0, capacite - charge_larvaire());
            float eff      <- min(pontes_culex_jour * beta_culex, place);
            if (eff >= 1.0) { do creer_cohorte("culex", false, eff, false); }
        }
        pontes_culex_jour <- 0.0;
    }

    action creer_cohorte(string type_v, bool inf, float eff, bool index) {
        create cohorte_larvaire {
            gite            <- myself;
            type_vecteur    <- type_v;
            infectee        <- inf;
            effectif        <- eff;
            avancement      <- 0.0;
            issue_cas_index <- index;
            location        <- myself.location;
        }
    }

    aspect default {
        if (volume_eau > 0) { draw shape color: #blue border: #blue; }
        else                { draw shape color: rgb(135,206,235,0.5) border: rgb(135,206,235,0.5); }
    }
}
