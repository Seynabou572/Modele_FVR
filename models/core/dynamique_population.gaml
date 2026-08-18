/**
 * DYNAMIQUE DE POPULATION GLOBALE — agrégation des compartiments SEIR,
 * remise à zéro de l'incidence journalière, naissances animales et
 * naissances de vecteurs (ponte spontanée liée aux mares en eau).
 */
model DynamiquePopulation

import "parametres_globaux.gaml"
import "climat.gaml"
import "../environnement/mare.gaml"
import "../environnement/vegetation.gaml"
import "../environnement/campement.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

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

    /**
     * Recrutement de fond des Culex (gîtes non cartographiés, immigration).
     * Il passe désormais par le stade aquatique, comme toute autre production
     * de vecteurs : plus aucun adulte n'apparaît spontanément sans délai de
     * développement.
     */
    reflex recrutement_de_fond_culex {
        ask mare where (each.volume_eau > 0.0) {
            float prob <- min(1.0, B_v / 1000.0);
            if (flip(prob)) {
                do creer_cohorte("culex", false, float(echelle_superindividu), false);
            }
        }
    }
}
