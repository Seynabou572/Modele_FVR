/**
 * VECTEUR — Aedes et Culex : recherche d'hôte/mare, piqûre (transmission
 * vecteur→hôte), acquisition d'infection (hôte→vecteur), transitions SEI,
 * ponte (transmission verticale pour Aedes), mortalité.
 */
model Vecteur

species vecteur {
    string type_vecteur;
    string etat_sante        <- "S";
    float  vitesse;
    int    jours_dans_etat   <- 0;
    int    age               <- 0;
    int    taille_groupe     <- echelle_superindividu;
    mare   mare_origine      <- nil;

    bool   est_cas_index_A   <- false;
    bool   est_cas_index_B   <- false;
    string origine_infection <- "aucune";

    reflex se_deplacer {
        list<humain> h_pr <- humain at_distance rayon_detection_v;
        list<animal> a_pr <- animal at_distance rayon_detection_v;
        point cible <- nil;
        if (etat_sante = "I") {
            if (!empty(a_pr)) { cible <- one_of(a_pr).location; }
            else if (!empty(h_pr)) { cible <- one_of(h_pr).location; }
        } else {
            if (type_vecteur = "culex" and mare_origine != nil and
                (location distance_to mare_origine.location) > rayon_depot_oeufs) {
                cible <- mare_origine.location;
            } else if (!empty(a_pr)) { cible <- one_of(a_pr).location; }
            else if (!empty(h_pr)) { cible <- one_of(h_pr).location; }
        }
        if (cible != nil) {
            point dir <- cible - location; float dist <- norm(dir);
            if (dist > 1.0) { location <- location + (dir / dist) * vitesse; }
        } else {
            location <- location + {rnd(-vitesse, vitesse), rnd(-vitesse, vitesse)};
        }
        if (!(zone_z3 covers location)) { location <- zone_z3.centroid; }
    }

    reflex piquer_humains when: etat_sante = "I" {
        float facteur_climat_activite <- facteur_humidite * facteur_vent;
        bool actif <- (type_vecteur = "aedes")
            ? flip(proba_activite_aedes * sigma_v * facteur_climat_activite)
            : flip(proba_activite_culex * sigma_v * facteur_climat_activite);

        if (actif) {
            if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
            cumul_bites_vect <- cumul_bites_vect + 1.0;

            float fd <- (mare_origine != nil)
                ? min(2.0, 1.0 + mare_origine.densite_moustiques / 100.0) : 1.0;
            list<humain> cibles_S <- (humain at_distance rayon_piqure_humain)
                                     where (each.etat_sante = "S");
            ask cibles_S {
                if (etat_sante = "S" and flip(min(1.0, beta_vh * fd))) {
                    etat_sante      <- "E";
                    jours_dans_etat <- 0;
                    nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                    incidence_c           <- incidence_c + echelle_superindividu;
                }
            }
        }
    }

    reflex piquer_animaux when: etat_sante = "I" {
        float facteur_climat_activite <- facteur_humidite * facteur_vent;
        bool actif <- (type_vecteur = "aedes")
            ? flip(proba_activite_aedes * sigma_v * facteur_climat_activite)
            : flip(proba_activite_culex * sigma_v * facteur_climat_activite);

        if (actif) {
            if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
            cumul_bites_vect <- cumul_bites_vect + 1.0;

            float fd <- (mare_origine != nil)
                ? min(2.0, 1.0 + mare_origine.densite_moustiques / 100.0) : 1.0;
            list<animal> cibles_S <- (animal at_distance rayon_piqure_animal)
                                     where (each.etat_sante = "S");
            ask cibles_S {
                if (etat_sante = "S" and flip(min(1.0, beta_va * fd))) {
                    etat_sante      <- "E";
                    jours_dans_etat <- 0;
                    nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                    incidence_c           <- incidence_c + echelle_superindividu;
                }
            }
        }
    }

    reflex acquerir_infection when: etat_sante = "S" {
        list<humain> h_inf <- (humain at_distance rayon_piqure_humain) where (each.etat_sante = "I");
        if (!empty(h_inf) and flip(beta_hv)) {
            etat_sante       <- "E";
            jours_dans_etat  <- 0;
            origine_infection <- "horizontale";
            incidence_v <- incidence_v + echelle_superindividu;
        }
        if (etat_sante = "S") {
            list<animal> a_inf <- (animal at_distance rayon_piqure_animal) where (each.etat_sante = "I");
            if (!empty(a_inf) and flip(beta_av)) {
                etat_sante       <- "E";
                jours_dans_etat  <- 0;
                origine_infection <- "horizontale";
                incidence_v <- incidence_v + echelle_superindividu;
            }
        }
    }

    reflex transition_etat {
        jours_dans_etat <- jours_dans_etat + 1;
        float duree_EI <- (type_vecteur = "aedes") ? T_aedes : duree_cycle_extrinseque;
        if (etat_sante = "E" and jours_dans_etat >= duree_EI) {
            etat_sante <- "I"; jours_dans_etat <- 0;
        }
    }

    reflex transmission_verticale
        when: type_vecteur = "aedes" and etat_sante = "I"
          and (age mod int(tau_aedes)) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau = 0) {
            int pontes   <- int(lambda_aedes * kappa_aedes * facteur_temperature * facteur_humidite);
            int infectes <- int(pontes * rho_aedes);
            if ((est_cas_index_A or est_cas_index_B) and pontes > 0 and infectes = 0) {
                infectes <- 1;
            }
            m.oeufs_aedes_infectes <- m.oeufs_aedes_infectes + infectes;
            m.oeufs_aedes_sains    <- m.oeufs_aedes_sains + max(0, pontes - infectes);
            write "Ponte Aedes (cycle " + cycle + ", âge " + age + ") : " + infectes
                + " œufs infectés + " + max(0, pontes - infectes) + " œufs sains déposés.";
        }
    }

    reflex ponte_culex when: type_vecteur = "culex" and (age mod int(tau_culex)) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau > 0) {
            m.oeufs_culex <- m.oeufs_culex
                + int(lambda_culex * kappa_culex * facteur_temperature * facteur_humidite);
        }
    }

    reflex mourir {
        age <- age + 1;
        float fmc   <- 2.0 - facteur_humidite;
        bool mort_n <- flip(min(1.0, mu_v * fmc));
        bool mort_a <- age > 21;
        bool mort_c <- temperature > 40.0 and flip(0.1);
        if (mort_n or mort_a or mort_c) { do die; }
        if (!dead(self) and length(vecteur) > max_vecteurs and flip(0.2)) { do die; }
    }

    aspect default {
        rgb   c;
        float taille <- unite_z3 * 0.002;
        if (type_vecteur = "aedes") {
            switch etat_sante {
                match "S" { c <- #pink; }
                match "E" { c <- rgb(255,165,0); }
                match "I" { c <- est_cas_index_A ? #darkred : (origine_infection = "verticale" ? #orangered : #red); }
            }
            draw triangle(taille) color: c border: c;
        } else {
            switch etat_sante {
                match "S" { c <- #violet; }
                match "E" { c <- rgb(180,100,220); }
                match "I" { c <- #darkviolet; }
            }
            draw circle(taille) color: c border: c;
        }
    }
}
