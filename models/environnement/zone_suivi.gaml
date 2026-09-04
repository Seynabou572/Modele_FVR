/**
 * ZONE DE SUIVI — support des sorties spatiales.
 *
 * Chargée depuis data/occsol/shp/zone3_entrainements.shp, la couche de
 * polygones d'entraînement de la classification d'occupation du sol : 796
 * entités typées par le champ `Name` en trois classes, vegetation / campement /
 * mare (id_class 6 / 2 / 3).
 *
 * C'est une couche d'OBSERVATION : elle n'intervient pas dans la dynamique
 * simulée (déplacement des hôtes, hydrologie, ponte). Elle agrège, à chaque
 * pas de temps, l'état épidémiologique et environnemental de ce qui se trouve
 * sur son emprise, afin de répondre aux deux questions spatiales du
 * protocole — « où l'infection apparaît-elle ? » et « dans quelles conditions
 * environnementales ? ».
 *
 * Le campement est l'unité d'agrégation de référence : c'est à ce niveau que
 * Soti et al. (2009) agrègent l'incidence sérologique observée à Barkedji, et
 * toute sortie agrégée autrement serait incomparable à la littérature de la
 * zone.
 *
 * ZPOM (zone potentiellement occupée par les moustiques, Vignolles et al.
 * 2009) : anneaux de 100, 500 et 1000 m autour des gîtes, portés par l'espèce
 * `mare` elle-même (voir mare.gaml). Les rayons sont ceux de Soti et al.
 * (2009), qui identifient 500 m comme l'échelle à laquelle l'indice de
 * fermeture du paysage explique le mieux l'incidence.
 */
model ZoneSuivi

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"
import "mare.gaml"

species zone_suivi {
    string id_zone      <- "";
    string type_zone    <- "";     // "mare" | "campement" | "vegetation"
    int    classe_zone  <- 0;      // id_class : 3 | 2 | 6
    float  surface_zone <- 0.0;    // m²

    // ---- Effectifs présents sur l'emprise ----
    int nb_animaux <- 0;   int nb_animaux_S <- 0;  int nb_animaux_E <- 0;
    int nb_animaux_I <- 0; int nb_animaux_R <- 0;
    int nb_humains <- 0;   int nb_humains_S <- 0;  int nb_humains_E <- 0;
    int nb_humains_I <- 0; int nb_humains_R <- 0;

    int nb_aedes <- 0;     int nb_aedes_I <- 0;
    int nb_culex <- 0;     int nb_culex_I <- 0;

    float oeufs_infectes_zone <- 0.0;
    float oeufs_sains_zone    <- 0.0;

    // ---- Historique épidémiologique de la zone ----
    // -1 tant qu'aucune infection n'y a été enregistrée.
    int jour_premiere_infection <- -1;
    int nouvelles_infections    <- 0;   // sur le pas de temps courant
    int cas_cumules             <- 0;   // depuis le début de la simulation

    // ---- Variables environnementales de la zone ----
    float ndvi_zone     <- 0.0;
    float ndwi_zone     <- 0.0;
    float volume_eau_zone <- 0.0;
    bool  eau_presente  <- false;

    /**
     * Enregistre une infection survenue sur cette zone. Appelée depuis
     * `repas_sang` (vecteur.gaml) au moment exact où un hôte bascule S -> E.
     */
    action enregistrer_infection(int nb) {
        nouvelles_infections <- nouvelles_infections + nb;
        cas_cumules          <- cas_cumules + nb;
        if (jour_premiere_infection < 0) {
            jour_premiere_infection <- jour_debut_simulation + cycle;
        }
    }

    /**
     * Recensement de la zone. `overlapping` est utilisé plutôt que `inside` :
     * les polygones d'entraînement sont de petites emprises, et un troupeau
     * posé à leur bordure doit être compté.
     *
     * C'est une ACTION et non un reflex, appelée par `export_zones` juste avant
     * l'écriture (voir core/exports_csv.gaml). Deux raisons : les reflex du
     * `global` s'exécutent avant ceux des espèces, donc un reflex ici
     * exporterait toujours l'état du pas précédent ; et 796 zones x 4 requêtes
     * spatiales par cycle est un coût qu'il est inutile de payer entre deux
     * exports. Le compteur d'infections, lui, est alimenté par événement dans
     * `enregistrer_infection` et ne dépend pas de cette cadence.
     */
    action recenser {
        list<animal> a_z <- animal overlapping shape;
        list<humain> h_z <- humain overlapping shape;
        nb_animaux   <- length(a_z) * echelle_superindividu;
        nb_animaux_S <- length(a_z where (each.etat_sante = "S")) * echelle_superindividu;
        nb_animaux_E <- length(a_z where (each.etat_sante = "E")) * echelle_superindividu;
        nb_animaux_I <- length(a_z where (each.etat_sante = "I")) * echelle_superindividu;
        nb_animaux_R <- length(a_z where (each.etat_sante = "R")) * echelle_superindividu;
        nb_humains   <- length(h_z) * echelle_superindividu;
        nb_humains_S <- length(h_z where (each.etat_sante = "S")) * echelle_superindividu;
        nb_humains_E <- length(h_z where (each.etat_sante = "E")) * echelle_superindividu;
        nb_humains_I <- length(h_z where (each.etat_sante = "I")) * echelle_superindividu;
        nb_humains_R <- length(h_z where (each.etat_sante = "R")) * echelle_superindividu;

        list<vecteur> v_z <- vecteur overlapping shape;
        list<vecteur> ae  <- v_z where (each.type_vecteur = "aedes");
        list<vecteur> cx  <- v_z where (each.type_vecteur = "culex");
        nb_aedes   <- length(ae) * echelle_si_vecteur;
        nb_aedes_I <- length(ae where (each.etat_sante = "I")) * echelle_si_vecteur;
        nb_culex   <- length(cx) * echelle_si_vecteur;
        nb_culex_I <- length(cx where (each.etat_sante = "I")) * echelle_si_vecteur;

        // Gîtes couverts par la zone : œufs et eau.
        list<mare> m_z <- mare overlapping shape;
        oeufs_infectes_zone <- empty(m_z) ? 0.0 : sum(m_z collect each.oeufs_aedes_infectes);
        oeufs_sains_zone    <- empty(m_z) ? 0.0 : sum(m_z collect each.oeufs_aedes_sains);
        volume_eau_zone     <- empty(m_z) ? 0.0 : sum(m_z collect each.volume_eau);
        eau_presente        <- volume_eau_zone > 0.0;

        ndvi_zone <- world.ndvi_moyen_au_point(location, sqrt(max(1.0, surface_zone)));
        ndwi_zone <- world.ndwi_moyen_au_point(location, sqrt(max(1.0, surface_zone)));
    }

    aspect default {
        rgb c;
        switch type_zone {
            match "mare"       { c <- rgb(31, 90, 110, 0.45); }
            match "campement"  { c <- rgb(162, 85, 34, 0.45); }
            match "vegetation" { c <- rgb(71, 99, 44, 0.30); }
            default            { c <- rgb(150, 150, 150, 0.30); }
        }
        draw shape color: c border: c;
    }

    /**
     * Aspect de FOND : volontairement pale et sans bordure marquee, pour que
     * les agents dessines par-dessus restent lisibles. La vegetation, qui
     * couvre l'essentiel de la surface, est la plus effacee des trois.
     */
    aspect fond {
        rgb c;
        switch type_zone {
            match "mare"       { c <- rgb(31, 90, 110, 0.30); }
            match "campement"  { c <- rgb(162, 85, 34, 0.22); }
            match "vegetation" { c <- rgb(71, 99, 44, 0.10); }
            default            { c <- rgb(150, 150, 150, 0.08); }
        }
        draw shape color: c border: rgb(120, 120, 120, 0.18);
    }
}
