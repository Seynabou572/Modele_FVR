/**
 * MARE — dynamique hydrique (bilan pluie/évaporation/infiltration modulé par
 * NDWI) et émergence des vecteurs (Aedes infectés/sains par transmission
 * verticale, Culex) à partir des stocks d'œufs.
 */
model Mare

species mare {
    float volume_eau           <- 0.0;
    float surface_eau          <- 0.0;
    float surface_max          <- 500.0;
    int   oeufs_aedes_infectes <- 0;
    int   oeufs_aedes_sains    <- 0;
    int   oeufs_culex          <- 0;
    int   jours_sans_pluie     <- 0;
    float volume_max_reference <- 300.0;
    float niveau_mare          <- 0.0;
    float densite_moustiques   <- 0.0;
    float L_perte              <- 12.0;
    float Iap                  <- 0.0;

    float k_sol        <- 0.9;
    float Gmax         <- 50.0;
    float Kr           <- 0.5;
    bool  est_ensemble1 <- true;

    float ndwi_local      <- 0.2;
    float ndwi_precedent  <- 0.2;

    reflex mise_a_jour_ndwi when: (cycle mod 3 = 0) {
        ndwi_precedent <- ndwi_local;
        ndwi_local     <- world.ndwi_moyen_au_point(location, 40.0);
    }

    reflex mise_a_jour_volume {
        Iap       <- k_sol * (Iap + pluie);
        float G_t <- max(0.0, Gmax - Iap);
        float Pe  <- max(0.0, pluie - G_t);
        float Qin <- est_ensemble1 ? (Kr * Pe * 1000.0) : 0.0;

        float facteur_ndwi <- max(0.4, min(2.5, 1.2 - ndwi_local * 2.0));
        float chute_ndwi   <- max(0.0, ndwi_precedent - ndwi_local);
        float bonus_chute  <- 1.0 + min(1.0, chute_ndwi * 5.0);

        float evaporation  <- (volume_eau > 0)
            ? min(volume_eau, L_perte * (volume_eau / 100.0) * facteur_ndwi * bonus_chute)
            : 0.0;
        float infiltration <- volume_eau * 0.05;

        volume_eau            <- max(0.0, volume_eau + pluie - evaporation - infiltration + Qin);
        volume_max_reference  <- max(50.0, surface_max * 0.6);
        surface_eau            <- min(surface_max, volume_eau * 2.0);
    }

    reflex compter_jours_secs {
        jours_sans_pluie <- (pluie < 1.0) ? jours_sans_pluie + 1 : 0;
    }

    reflex disparition_mare when: jours_sans_pluie >= seuil_assechement_mare and volume_eau > 0.0 {
        volume_eau <- 0.0; surface_eau <- 0.0;
    }

    reflex verifier_ndwi_binaire when: utiliser_ndwi_binaire and (cycle mod 3 = 0) {
        bool couverte <- !empty(zones_eau_binaire) and !empty(zones_eau_binaire where (each covers location));
        if (!couverte) {
            volume_eau  <- 0.0;
            surface_eau <- 0.0;
        }
    }

    reflex mise_a_jour_niveau {
        niveau_mare <- max(0.0, min(1.0,
            (volume_max_reference > 0) ? volume_eau / volume_max_reference : 0.0));
        int nb_v <- length(vecteur where (each.mare_origine = self));
        densite_moustiques <- (surface_eau > 0) ? float(nb_v * echelle_superindividu) / surface_eau : 0.0;
    }

    reflex emergence_aedes_infectes
        when: (pluie >= 10.0 or pluie_cumulee >= seuil_eclosion_cumulee)
          and jours_sans_pluie >= int(Td_aedes)
          and volume_eau > 0.0
          and oeufs_aedes_infectes > 0 {

        float survie    <- beta_aedes * (phi_aedes ^ int(T_aedes))
                          * facteur_temperature * facteur_humidite;
        float frac_surf <- min(1.0, surface_eau / surface_max);
        int nb_eclos    <- min(oeufs_aedes_infectes,
                              int(oeufs_aedes_infectes * survie * frac_surf * 0.1));
        oeufs_aedes_infectes <- oeufs_aedes_infectes - nb_eclos;

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-50.0, 50.0), rnd(-50.0, 50.0)};
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- false;
                    est_cas_index_B  <- false;
                    origine_infection <- "verticale";
                }
            }
        }
        if (nb_eclos > 0) {
            write "Émergence Aedes I (verticale) : " + nb_eclos + " agents (cycle " + cycle + ")";
        }
    }

    reflex emergence_aedes_sains
        when: (pluie >= 10.0 or pluie_cumulee >= seuil_eclosion_cumulee)
          and jours_sans_pluie >= int(Td_aedes)
          and volume_eau > 0.0
          and oeufs_aedes_sains > 0 {

        float survie    <- beta_aedes * (phi_aedes ^ int(T_aedes))
                          * facteur_temperature * facteur_humidite;
        float frac_surf <- min(1.0, surface_eau / surface_max);
        int nb_eclos    <- min(oeufs_aedes_sains,
                              int(oeufs_aedes_sains * survie * frac_surf * 0.05));
        oeufs_aedes_sains <- oeufs_aedes_sains - nb_eclos;

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "S";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-50.0, 50.0), rnd(-50.0, 50.0)};
                    age              <- 0; jours_dans_etat <- 0;
                    est_cas_index_A  <- false; est_cas_index_B <- false;
                    origine_infection <- "aucune";
                }
            }
        }
    }

    reflex emergence_culex when: volume_eau > 0.5 and oeufs_culex > 0 {
        float survie  <- beta_culex * (gamma_culex ^ int(T_culex))
                        * facteur_temperature * facteur_humidite;
        float surf_d  <- min(surface_eau, surface_max);
        float densite <- (surf_d > 0) ? float(oeufs_culex) / surf_d : 0.0;
        int nb_eclos  <- (densite > Emax_culex)
            ? int(surf_d * Emax_culex * survie * 0.02)
            : int(float(oeufs_culex) * survie * 0.02);
        nb_eclos    <- min(5, max(0, nb_eclos));
        oeufs_culex <- max(0, oeufs_culex - nb_eclos * int(lambda_culex));

        loop rep from: 0 to: nb_eclos - 1 {
            if (length(vecteur) < max_vecteurs) {
                create vecteur {
                    type_vecteur     <- "culex";
                    etat_sante       <- "S";
                    taille_groupe    <- echelle_superindividu;
                    vitesse          <- vitesse_culex;
                    mare_origine     <- myself;
                    location         <- myself.location + {rnd(-20.0, 20.0), rnd(-20.0, 20.0)};
                    age              <- 0; jours_dans_etat <- 0;
                    est_cas_index_A  <- false; est_cas_index_B <- false;
                    origine_infection <- "aucune";
                }
            }
        }
    }

    aspect default {
        if (volume_eau > 0) { draw shape color: #blue border: #blue; }
        else                 { draw shape color: rgb(135,206,235,0.5) border: rgb(135,206,235,0.5); }
    }
}
