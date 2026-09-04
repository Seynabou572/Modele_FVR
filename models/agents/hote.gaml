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

    /**
     * CONFINEMENT A L'EMPRISE SIMULEE.
     *
     * Le test portait sur `zone_z3`, qui est l'enveloppe d'un FICHIER et
     * conserve donc les coordonnees de ce fichier (UTM : x de 496 735 a
     * 528 800), alors que GAMA translate le monde a l'origine (x de 0 a
     * 32 065). `zone_z3 covers pt` etait donc TOUJOURS FAUX, et chaque agent
     * etait renvoye a chaque pas sur `zone_z3.centroid` — un point situe hors
     * de la carte. Les hotes ne bougeaient jamais reellement, n'approchaient
     * aucun gite, et n'apparaissaient pas a l'ecran.
     *
     * On teste desormais sur `shape`, l'emprise du monde, qui est dans le
     * meme repere que les agents. Et l'on RECADRE sur le bord au lieu de
     * teleporter au centre : renvoyer un troupeau au milieu de la zone parce
     * qu'il a franchi une limite est un artefact violent, qui melangeait les
     * positions a chaque pas.
     */
    point contraindre(point pt) {
        if (shape covers pt) { return pt; }
        float xmin <- shape.location.x - shape.width  / 2;
        float xmax <- shape.location.x + shape.width  / 2;
        float ymin <- shape.location.y - shape.height / 2;
        float ymax <- shape.location.y + shape.height / 2;
        return {min(xmax, max(xmin, pt.x)), min(ymax, max(ymin, pt.y))};
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
