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
        // Utilisation directe du NDVI pour la couleur
        float ndvi <- ndvi_local;
        if      (ndvi > 0.35)  { couleur <- rgb(34,139,34,0.55); }   // Vert foncé – forte végétation
        else if (ndvi > 0.20)  { couleur <- rgb(154,205,50,0.5); }   // Vert clair – végétation moyenne
        else if (ndvi > 0.05)  { couleur <- rgb(173,255,47,0.45); }   // JAUNE – NDVI faible
        else                   { couleur <- rgb(210,180,140,0.4); }  // Marron clair – sol nu
        draw shape color: couleur border: couleur;
    }
}
