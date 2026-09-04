/**
 * HUMAIN — mobilité saisonnière (vers les mares, le troupeau, ou le
 * campement), progression SEIR, exposition aux vecteurs.
 */
model Humain

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../environnement/mare.gaml"
import "../environnement/campement.gaml"
import "hote.gaml"
import "animal.gaml"
import "vecteur.gaml"

species humain parent: hote {
    string etat_sante      <- "S";
    int    jours_dans_etat <- 0;
    int    taille_groupe   <- echelle_superindividu;
    campement    campement_origine;
    list<animal> troupeaux_associes    <- [];
    float        exposition_moustiques <- 0.0;
    mare derniere_mare <- nil;

    reflex mise_a_jour_exposition {
        exposition_moustiques <- float(length(vecteur at_distance rayon_piqure_humain)
                                       * echelle_superindividu);
    }

    reflex se_deplacer {
        point cible <- nil;
        float vit   <- vitesse_hote_normal;

        // Les mares sont aussi la ressource en eau des familles pastorales : le
        // puisage est quotidien et se fait à la mare accessible la plus proche.
        list<mare> md <- mare where (each.volume_eau > Vseuil
                    and (each.location distance_to location) < distance_abreuvement_max);
        if (!empty(md)) {
            mare m <- md closest_to self;
            derniere_mare <- m;
            cible <- m.location;
        } else if (saison = "Dabbuunde" and campement_origine != nil
                   and !dead(campement_origine)) {
            cible <- campement_origine.location;
        }

        if (cible = nil) {
            list<animal> troupeau_vivant <- troupeaux_associes where (each != nil and !dead(each));
            if (!empty(troupeau_vivant)) {
                list<animal> en_trans <- troupeau_vivant where each.est_transhumant;
                if (!empty(en_trans)) {
                    cible <- (geometry(en_trans collect each.location)).centroid;
                    vit   <- vitesse_transhumance;
                } else {
                    cible <- (geometry(troupeau_vivant collect each.location)).centroid;
                }
            }
        }

        if (cible = nil) {
            cible <- explorer_routes();
        }

        if (cible = nil and campement_origine != nil and !dead(campement_origine)) {
            cible <- campement_origine.location;
        }

        do se_deplacer_vers(cible, vit);
    }

    reflex transition_etat {
        jours_dans_etat <- jours_dans_etat + 1;
        if (etat_sante = "E" and jours_dans_etat >= duree_incubation) {
            etat_sante <- "I"; jours_dans_etat <- 0;
        } else if (etat_sante = "I" and jours_dans_etat >= duree_infection) {
            etat_sante <- "R"; jours_dans_etat <- 0;
        }
    }

    aspect default {
        rgb couleur;
        switch etat_sante {
            match "S" { couleur <- rgb(120, 200, 255); }   // bleu clair
            match "E" { couleur <- rgb(255, 150, 0);   }
            match "I" { couleur <- rgb(220, 0, 0);     }
            match "R" { couleur <- rgb(120, 120, 120); }
            default   { couleur <- rgb(120, 200, 255); }
        }
        draw square(unite_z3 * 0.007) color: couleur border: rgb(40, 40, 40);
    }
}
