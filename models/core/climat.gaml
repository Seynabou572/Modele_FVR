/**
 * CLIMAT — variables journalières, chargement du CSV et facteurs climatiques
 * modulant l'activité et la survie des vecteurs.
 */
model Climat

import "parametres_globaux.gaml"
import "donnees_chemins.gaml"

global {

    float temperature       <- 28.0;
    float humidite_relative <- 30.0;
    float pluie             <- 0.0;
    float vitesse_vent      <- 3.0;
    list<float> climat_T2M         <- [];
    list<float> climat_RH2M        <- [];
    list<float> climat_PRECTOTCORR <- [];
    list<float> climat_WS2M        <- [];
    int   nb_lignes_climat        <- 0;
    int   jours_sans_pluie_global <- 0;
    float pluie_cumulee           <- 0.0;
    float facteur_temperature     <- 1.0;
    float facteur_humidite        <- 1.0;
    float facteur_vent            <- 1.0;		// module l'activité de piqûre selon le vent
    int   seuil_assechement_mare    <- 45;
    float seuil_eclosion_cumulee    <- 15.0;
    float optimum_thermique_vecteur <- 27.0;
    float largeur_thermique_vecteur <- 8.0;

    // =========================================================================
    // ACTION : CHARGEMENT DU CSV CLIMATIQUE (appelée depuis l'init)
    // =========================================================================
    action charger_climat {
        matrix donnees_climat <- matrix(CLIMAT_CSV);
        int nb_lignes_fichier <- donnees_climat.rows;
        int ligne_debut <- max(1, min(nb_lignes_fichier - 1, jour_debut_simulation));
        int ligne_fin   <- max(1, min(nb_lignes_fichier - 1, jour_fin_simulation));
        loop i from: ligne_debut to: ligne_fin {
            try {
                add float(donnees_climat[2, i]) to: climat_T2M;
                add float(donnees_climat[3, i]) to: climat_RH2M;
                add float(donnees_climat[4, i]) to: climat_PRECTOTCORR;
                add float(donnees_climat[5, i]) to: climat_WS2M;
            } catch { }
        }
        nb_lignes_climat <- length(climat_T2M);
        if (nb_lignes_climat > 0) {
            temperature       <- climat_T2M[0];
            humidite_relative <- climat_RH2M[0];
            pluie             <- climat_PRECTOTCORR[0];
            vitesse_vent      <- climat_WS2M[0];
        }
        write "Climat : " + nb_lignes_climat + " jours chargés.";
    }

    reflex mise_a_jour_climat {
        if (nb_lignes_climat > 0) {
            int idx       <- cycle mod nb_lignes_climat;
            temperature       <- climat_T2M[idx];
            humidite_relative <- climat_RH2M[idx];
            pluie             <- climat_PRECTOTCORR[idx];
            vitesse_vent      <- climat_WS2M[idx];
        }
        jours_sans_pluie_global <- (pluie < 1.0) ? jours_sans_pluie_global + 1 : 0;
        pluie_cumulee <- pluie_cumulee * 0.90 + pluie;
        facteur_temperature <- max(0.05, min(1.0,
            exp(-((temperature - optimum_thermique_vecteur)^2)
                / (2.0 * largeur_thermique_vecteur^2))));
        facteur_humidite <- max(0.05, min(1.0, (humidite_relative - 15.0) / 65.0));
        facteur_vent <- max(0.1, min(1.0, 1.0 - (vitesse_vent / 10.0)));
    }
}
