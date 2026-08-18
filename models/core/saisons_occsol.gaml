/**
 * SAISONS & OCCUPATION DU SOL — calendrier saisonnier, lecture des indices
 * NDVI/NDWI, et reconstruction des mares/campements/fond de carte à chaque
 * changement de saison.
 */
model SaisonsOccsol

global {

    string calculer_saison(int jour) {
        if (jour <= 181) { return "Ceedu"; }
        if (jour <= 304) { return "Nduungu"; }
        return "Dabbuunde";
    }

    float ndvi_moyen_au_point(point pt, float rayon_m) {
        if (ndvi_actuel = nil) { return 0.3; }
        geometry env <- shape;
        int ncols <- ndvi_actuel.columns;
        int nrows <- ndvi_actuel.rows;
        if (ncols = 0 or nrows = 0) { return 0.3; }
        float xmin       <- env.location.x - env.width  / 2;
        float ymax       <- env.location.y + env.height / 2;
        float pixel_size <- env.width / ncols;
        int col      <- int((pt.x - xmin) / env.width  * ncols);
        int row      <- int((ymax - pt.y)  / env.height * nrows);
        int rayon_px <- max(1, int(rayon_m / pixel_size));
        list<float> valeurs <- [];
        loop cx from: max(0, col - rayon_px) to: min(ncols-1, col + rayon_px) {
            loop ry from: max(0, row - rayon_px) to: min(nrows-1, row + rayon_px) {
                add float(ndvi_actuel[cx, ry]) to: valeurs;
            }
        }
        return (empty(valeurs)) ? 0.3 : mean(valeurs);
    }

    float ndwi_moyen_au_point(point pt, float rayon_m) {
        if (ndwi_actuel = nil) { return 0.2; }
        geometry env <- shape;
        int ncols <- ndwi_actuel.columns;
        int nrows <- ndwi_actuel.rows;
        if (ncols = 0 or nrows = 0) { return 0.2; }
        float xmin       <- env.location.x - env.width  / 2;
        float ymax       <- env.location.y + env.height / 2;
        float pixel_size <- env.width / ncols;
        int col      <- int((pt.x - xmin) / env.width  * ncols);
        int row      <- int((ymax - pt.y)  / env.height * nrows);
        int rayon_px <- max(1, int(rayon_m / pixel_size));
        list<float> valeurs <- [];
        loop cx from: max(0, col - rayon_px) to: min(ncols-1, col + rayon_px) {
            loop ry from: max(0, row - rayon_px) to: min(nrows-1, row + rayon_px) {
                add float(ndwi_actuel[cx, ry]) to: valeurs;
            }
        }
        return (empty(valeurs)) ? 0.2 : mean(valeurs);
    }

    list<geometry> clusteriser_par_grille(list<geometry> polys, float taille_cellule) {
        map<string, list<geometry>> cellules <- [];
        loop g over: polys {
            point c  <- g.location;
            int cx   <- int(c.x / taille_cellule);
            int cy   <- int(c.y / taille_cellule);
            string cle <- string(cx) + "_" + string(cy);
            list<geometry> courant <- (cellules contains_key cle) ? cellules[cle] : [];
            add g to: courant;
            cellules[cle] <- courant;
        }
        list<geometry> resultats <- [];
        loop cle over: cellules.keys {
            list<geometry> lg <- cellules[cle];
            add ((length(lg) = 1) ? lg[0] : union(lg)) to: resultats;
        }
        return resultats;
    }

    // =========================================================================
    // ACTION : MISE À JOUR OCCSOL SAISONNIÈRE
    // =========================================================================
    action mettre_a_jour_occsol_saisonnier(string nouvelle_saison) {
        write "--- Saison " + nouvelle_saison + " (DOY " + (jour_debut_simulation + cycle) + ") ---";
        ndvi_actuel <- matrix(ndvi_raster_saisons[nouvelle_saison]);
        ndwi_actuel <- matrix(ndwi_raster_saisons[nouvelle_saison]);

        create occsol_polygone from: occsol_shp_saisons[nouvelle_saison]
            with: [classe :: int(read("class"))];

        list<geometry> brutes_mares <- (occsol_polygone where (each.classe = 2)) collect each.shape;
        list<geometry> brutes_camps <- (occsol_polygone where (each.classe = 1)) collect each.shape;

        list<geometry> parties_mares <- clusteriser_par_grille(brutes_mares, taille_cellule_cluster_mare);
        list<geometry> parties_camps <- clusteriser_par_grille(brutes_camps, taille_cellule_cluster_camp);

        parties_mares <- parties_mares where (area(each) > seuil_min_mare_m2);
        parties_camps <- parties_camps where (area(each) > seuil_min_campement_m2);

        if (length(parties_mares) > max_mares_actives) {
            list<geometry> tri   <- parties_mares sort_by (-area(each));
            list<geometry> tronc <- [];
            loop i from: 0 to: max_mares_actives - 1 { add tri[i] to: tronc; }
            parties_mares <- tronc;
        }
        if (length(parties_camps) > max_campements_actifs) {
            list<geometry> tri   <- parties_camps sort_by (-area(each));
            list<geometry> tronc <- [];
            loop i from: 0 to: max_campements_actifs - 1 { add tri[i] to: tronc; }
            parties_camps <- tronc;
        }

        list<geometry> mares_restantes <- copy(parties_mares);
        ask mare {
            if (!empty(mares_restantes)) {
                geometry plus_proche <- mares_restantes with_min_of (each distance_to location);
                if ((plus_proche distance_to location) < (unite_z3 * seuil_appariement_saisonnier)) {
                    shape       <- plus_proche;
                    location    <- plus_proche.centroid;
                    surface_max <- area(plus_proche);
                    volume_eau  <- surface_max * 0.30;
                    surface_eau <- min(surface_max, volume_eau * 2.0);
                    remove plus_proche from: mares_restantes;
                }
            }
        }
        if (!empty(mares_restantes)) {
            create mare from: mares_restantes {
                surface_max <- area(shape);
                volume_eau  <- surface_max * 0.30;
                surface_eau <- min(surface_max, volume_eau * 2.0);
            }
        }

        list<geometry> camps_restants <- copy(parties_camps);
        ask campement {
            if (!empty(camps_restants)) {
                geometry plus_proche <- camps_restants with_min_of (each distance_to location);
                if ((plus_proche distance_to location) < (unite_z3 * seuil_appariement_saisonnier)) {
                    remove plus_proche from: camps_restants;
                }
            }
        }
        if (!empty(camps_restants)) { create campement from: camps_restants; }
        nb_campements <- length(campement);

        if (length(mare) = 0) {
            create mare from: [zone_z3.centroid buffer (unite_z3 * 0.01)] {
                surface_max <- area(shape); volume_eau <- surface_max * 0.05;
                surface_eau <- min(surface_max, volume_eau * 2.0);
            }
        }
        if (length(campement) = 0) {
            create campement from: [zone_z3.centroid buffer (unite_z3 * 0.005)];
            nb_campements <- 1;
        }

        fond_geoms   <- [];
        fond_classes <- [];
        list<occsol_polygone> tous_polys <- list(occsol_polygone);
        int nb_total_polys  <- length(tous_polys);
        int pas_echantillon <- max(1, int(nb_total_polys / 3000));
        loop i from: 0 to: nb_total_polys - 1 step: pas_echantillon {
            occsol_polygone p <- tous_polys[i];
            if (area(p.shape) > seuil_min_affichage_m2) {
                add p.shape  to: fond_geoms;
                add p.classe to: fond_classes;
            }
        }
        ask occsol_polygone { do die; }
        write "Saison " + nouvelle_saison + " : " + length(mare) + " mares, "
            + nb_campements + " campements, " + length(fond_geoms) + " polygones.";
    }

    reflex mise_a_jour_saison {
        string ns <- calculer_saison(jour_debut_simulation + cycle + 1);
        if (ns != saison) {
            do mettre_a_jour_occsol_saisonnier(ns);
            saison <- ns;
        }
    }
}
