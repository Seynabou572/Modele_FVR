/**
 * HOTE — espèce parente pour humain et animal : déplacement contraint à la
 * zone d'étude, exploration du réseau routier, déplacement via graphe ou
 * à vol d'oiseau en repli.
 */
model Hote

import "../core/parametres_globaux.gaml"
import "../core/donnees_chemins.gaml"
import "../environnement/route.gaml"

species hote skills: [moving] {
    list<route> chemin_parcouru <- [];
    point cible_exploration <- nil;

    point contraindre(point pt) {
        if (zone_z3 covers pt) { return pt; }
        return zone_z3.centroid;
    }

    point explorer_routes {
        list<route> non_parcourues <- route where !(each in chemin_parcouru);
        route r <- nil;
        if (!empty(non_parcourues)) {
            r <- one_of(non_parcourues);
        } else if (!empty(route)) {
            chemin_parcouru <- [];
            r <- one_of(route);
        }
        if (r != nil) {
            cible_exploration <- any_location_in(r.shape);
            return cible_exploration;
        }
        return nil;
    }

    action se_deplacer_vers(point cible, float vit) {
        if (cible != nil and reseau_routier != nil) {
            try { do goto target: cible on: reseau_routier speed: vit; }
            catch {
                if (cible != nil) {
                    point dir <- cible - location;
                    if (norm(dir) > 0) { location <- location + (dir / norm(dir)) * vit; }
                }
            }
            if (current_edge != nil) {
                route r <- route(current_edge);
                if !(r in chemin_parcouru) { add r to: chemin_parcouru; }
                r.nb_passages <- r.nb_passages + 1;
            }
        } else if (cible != nil) {
            point dir <- cible - location;
            if (norm(dir) > 0) { location <- location + (dir / norm(dir)) * vit; }
        } else {
            location <- location + {rnd(-vit*0.2, vit*0.2), rnd(-vit*0.2, vit*0.2)};
        }
        location <- contraindre(location);
    }
}
