/**
 * VÉGÉTATION — capacité fourragère par formation, modulée par le NDVI local,
 * broutage par les hôtes présents et repousse saisonnière.
 */
model Vegetation

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../core/saisons_occsol.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"

species vegetation {
    int    formcode;
    string formation;
    float  capacite_max      <- 60.0;
    float  biomasse          <- 40.0;
    int    nb_hotes_presents <- 0;
    float  ndvi_local <- 0.3;

    action calculer_capacite_vegetation {
        float capacite_formation;
        switch formation {
            match "SAVANES ARBUSTIVES ET ARBOREES" { capacite_formation <- 100.0; }
            match "SAVANES ARBUSTIVES"             { capacite_formation <- 85.0;  }
            match "STEPPES ARBOREES"               { capacite_formation <- 60.0;  }
            match "ZONES DE CULTURE"               { capacite_formation <- 40.0;  }
            default                                { capacite_formation <- 55.0;  }
        }
        ndvi_local  <- world.ndvi_moyen_au_point(location, 60.0);
        float facteur_ndvi <- max(0.4, min(1.6, 0.5 + ndvi_local * 1.5));
        capacite_max <- capacite_formation * facteur_ndvi;
        biomasse     <- capacite_max * 0.6;
    }

    reflex compter_hotes {
        nb_hotes_presents <- length(animal at_distance rayon_piqure_animal)
                           + length(humain at_distance rayon_piqure_humain);
    }

    reflex mise_a_jour_ndvi when: (cycle mod 5 = 0) {
        ndvi_local <- world.ndvi_moyen_au_point(location, 60.0);
    }

    reflex dynamique_biomasse {
        if (nb_hotes_presents > 0)  { biomasse <- max(0.0, biomasse - nb_hotes_presents * 1.2); }
        else if (saison = "Nduungu"){
            float facteur_repousse <- max(0.3, min(2.0, 0.5 + ndvi_local * 1.5));
            biomasse <- min(capacite_max, biomasse + 0.08 * pluie * facteur_repousse);
        }
        else if (saison = "Dabbuunde") { biomasse <- max(0.0, biomasse - 0.05); }
        else { biomasse <- max(0.0, biomasse - 0.10); }
    }

    aspect default {
        rgb couleur;
        float ratio <- (capacite_max > 0) ? biomasse / capacite_max : 0.0;
        if      (ratio > 0.7)  { couleur <- rgb(34,139,34,0.55); }
        else if (ratio > 0.4)  { couleur <- rgb(154,205,50,0.5); }
        else if (ratio > 0.15) { couleur <- rgb(189,183,107,0.45); }
        else                   { couleur <- rgb(210,180,140,0.4); }
        draw shape color: couleur border: couleur;
    }
}
