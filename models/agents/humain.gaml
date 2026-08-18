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

        if (saison = "Nduungu") {
            list<mare> md <- mare where (each.volume_eau > 0.0);
            if (!empty(md)) {
                mare m <- md with_max_of (each.volume_eau / (1.0 + (location distance_to each.location)));
                derniere_mare <- m;
                cible <- m.location;
            }
        } else if (saison = "Dabbuunde") {
            if (campement_origine != nil) { cible <- campement_origine.location; }
        } else {
            list<mare> md <- mare where (each.volume_eau > Vseuil);
            if (!empty(md)) {
                mare m <- md with_max_of (each.volume_eau / (1.0 + (location distance_to each.location)));
                derniere_mare <- m;
                cible <- m.location;
            }
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

        if (cible = nil and campement_origine != nil) { cible <- campement_origine.location; }

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
            match "S" { couleur <- #green;  } match "E" { couleur <- #yellow; }
            match "I" { couleur <- #red;    } match "R" { couleur <- #gray;   }
        }
        draw square(unite_z3 * 0.012) color: couleur border: couleur;
    }
}
