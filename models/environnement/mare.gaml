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

    float ndwi_local      <- 0.2;
    float ndwi_precedent  <- 0.2;

    bool  appariee <- false;   // transitoire : appariement au changement de saison

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
        niveau_mare <- max(0.0, min(1.0,
            (volume_max_reference > 0) ? volume_eau / volume_max_reference : 0.0));
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
    reflex eclosion_aedes
        when: volume_eau > 0.0
          and duree_secheresse_prec >= int(Td_aedes)
          and (pluie >= 10.0 or pluie_cumulee >= seuil_eclosion_cumulee)
          and (oeufs_aedes_infectes + oeufs_aedes_sains) >= 1.0 {

        float frac_surf <- (surface_max > 0) ? min(1.0, surface_eau / surface_max) : 0.0;
        float taux      <- beta_aedes * frac_surf;

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
