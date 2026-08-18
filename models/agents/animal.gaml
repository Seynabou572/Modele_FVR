/**
 * ANIMAL — bétail : condition corporelle (NEC), transhumance saisonnière,
 * pâturage, progression SEIR avec mortalité liée à l'infection.
 */
model Animal

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../environnement/mare.gaml"
import "../environnement/campement.gaml"
import "../environnement/vegetation.gaml"
import "hote.gaml"
import "humain.gaml"
import "vecteur.gaml"

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
        } else if (!empty(mare where (each.volume_eau > Vseuil
                       and (each.location distance_to location) < distance_abreuvement_max))) {
            // ABREUVEMENT QUOTIDIEN — le bétail sahélien boit tous les jours en
            // saison chaude et accepte de parcourir plusieurs kilomètres pour le
            // faire (FAO). Ce passage journalier à la mare, quelle que soit la
            // saison, est le principal lieu de contact avec les vecteurs, qui y
            // émergent et y piquent au crépuscule.
            list<mare> abreuvoirs <- mare where (each.volume_eau > Vseuil
                       and (each.location distance_to location) < distance_abreuvement_max);
            mare m <- abreuvoirs closest_to self;
            mare_actuelle <- m;
            if !(m in memoire_mares) { add m to: memoire_mares; }
            cible <- m.location;
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
