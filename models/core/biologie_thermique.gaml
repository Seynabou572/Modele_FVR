/**
 * BIOLOGIE THERMIQUE — durées de développement dépendantes de la température.
 *
 * Remplace les constantes fixes (EIP, cycle gonotrophique, développement
 * larvaire, mortalité adulte) par des modèles degré-jours :
 *     duree = degres_jours_total / max(eps, T - T_seuil)
 * bornés par un minimum et un maximum physiologiques.
 *
 * C'est la dépendance thermique de ces DURÉES qui produit la saisonnalité
 * réelle de la transmission ; le facteur gaussien `facteur_temperature`
 * (core/climat.gaml) reste utilisé pour la ponte et l'activité, mais plus
 * pour les durées.
 *
 * TOUTES LES VALEURS CI-DESSOUS SONT PLAUSIBLES MAIS À CALIBRER.
 */
model BiologieThermique

import "parametres_globaux.gaml"
import "climat.gaml"

global {

    // ---- Incubation extrinsèque du virus dans le vecteur ----
    float T_seuil_eip      <- 14.0;    // °C sous lesquels le virus ne se développe pas
    float degres_jours_eip <- 110.0;   // °C·jour pour compléter l'EIP
    float eip_min          <- 4.0;
    float eip_max          <- 30.0;

    // ---- Développement aquatique (œuf/larve/nymphe -> adulte) ----
    float T_seuil_larve            <- 10.0;
    float degres_jours_larve_aedes <- 90.0;
    float degres_jours_larve_culex <- 145.0;
    float duree_larve_min          <- 4.0;
    float duree_larve_max          <- 40.0;

    // ---- Cycle gonotrophique (intervalle entre deux repas de sang) ----
    float T_seuil_gono      <- 12.0;
    float degres_jours_gono <- 37.0;   // ~3 j à 24 °C
    float gono_min          <- 2.0;
    float gono_max          <- 15.0;

    // ---- Bornes de la mortalité adulte journalière ----
    float mortalite_adulte_min <- 0.02;
    float mortalite_adulte_max <- 0.50;
    float T_stress_chaud       <- 35.0;

    /**
     * Durée de l'incubation extrinseque, en jours, à la température T.
     */
    float eip_jours(float T) {
        float dd <- max(0.1, T - T_seuil_eip);
        return max(eip_min, min(eip_max, degres_jours_eip / dd));
    }

    /**
     * Durée du développement aquatique, en jours, à la température T.
     */
    float duree_dev_larvaire(float T, string type_v) {
        float dd  <- max(0.1, T - T_seuil_larve);
        float ddt <- (type_v = "aedes") ? degres_jours_larve_aedes : degres_jours_larve_culex;
        return max(duree_larve_min, min(duree_larve_max, ddt / dd));
    }

    /**
     * Durée du cycle gonotrophique, en jours, à la température T.
     * Son inverse est le taux de piqûre `a` de Ross-Macdonald.
     */
    float cycle_gonotrophique(float T) {
        float dd <- max(0.1, T - T_seuil_gono);
        return max(gono_min, min(gono_max, degres_jours_gono / dd));
    }

    /**
     * Mortalité journalière d'un vecteur adulte : mortalité de base majorée
     * par le stress hydrique (air sec) et le stress thermique (T élevée).
     */
    float mortalite_adulte_journaliere(float T, float RH) {
        float f_hum       <- max(0.05, min(1.0, (RH - 15.0) / 65.0));
        float stress_sec  <- 2.0 - f_hum;
        float stress_chaud <- (T > T_stress_chaud) ? (1.0 + (T - T_stress_chaud) * 0.15) : 1.0;
        return max(mortalite_adulte_min,
                   min(mortalite_adulte_max, mu_v * stress_sec * stress_chaud));
    }
}
