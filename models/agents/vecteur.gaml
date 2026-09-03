/**
 * VECTEUR — Aedes et Culex (femelles adultes).
 *
 * Le contact hôte/vecteur passe par UN SEUL reflex `repas_sang`, exécuté pour
 * tous les vecteurs quel que soit leur état sanitaire :
 *   - le taux de piqûre `a` vaut 1 / cycle_gonotrophique(T), modulé par le
 *     climat — il ne dépend plus de l'état infectieux ;
 *   - une activation = UN repas sur UN hôte (une femelle ne prend qu'un repas
 *     de sang par cycle gonotrophique) ;
 *   - la transmission se joue ensuite dans un sens (vecteur I vers hôte S, via
 *     b_*) ou dans l'autre (vecteur S vers hôte I, via c_*).
 *
 * Cette structure corrige trois défauts de la version précédente : le compteur
 * de piqûres n'était incrémenté que pour les vecteurs infectés (ce qui biaisait
 * `a` d'un facteur égal à la prévalence vectorielle), `sigma_v` était compté à
 * la fois dans l'activité et dans la transmission, et une seule activation
 * infectait tous les hôtes du rayon.
 */
model Vecteur

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../core/biologie_thermique.gaml"
import "../core/r0_vectoriel.gaml"
import "../environnement/mare.gaml"
import "humain.gaml"
import "animal.gaml"

species vecteur {
    string type_vecteur;
    string etat_sante        <- "S";
    float  vitesse;
    int    jours_dans_etat   <- 0;
    int    age               <- 0;
    int    taille_groupe     <- echelle_si_vecteur;
    mare   mare_origine      <- nil;

    // Avancement fractionnaire de l'incubation extrinsèque (0 vers 1). Permet
    // une EIP qui varie avec la température au cours même de l'incubation.
    float  avancement_eip    <- 0.0;

    bool   est_cas_index_A   <- false;
    bool   est_cas_index_B   <- false;
    string origine_infection <- "aucune";

    /** Transmission vecteur -> hôte par piqûre (compétence de l'espèce). */
    float b_vecteur { return (type_vecteur = "aedes") ? b_aedes : b_culex; }
    /** Transmission hôte -> vecteur par piqûre (compétence de l'espèce). */
    float c_vecteur { return (type_vecteur = "aedes") ? c_aedes : c_culex; }

    reflex se_deplacer {
        list<humain> h_pr <- humain at_distance rayon_detection_v;
        list<animal> a_pr <- animal at_distance rayon_detection_v;
        point cible <- nil;

        // Les Culex restent inféodés à leur gîte ; les Aedes sont plus mobiles.
        if (type_vecteur = "culex" and mare_origine != nil and !dead(mare_origine)
            and (location distance_to mare_origine.location) > rayon_detection_v) {
            cible <- mare_origine.location;
        } else if (!empty(a_pr)) { cible <- one_of(a_pr).location; }
        else if (!empty(h_pr))   { cible <- one_of(h_pr).location; }

        if (cible != nil) {
            point dir <- cible - location; float dist <- norm(dir);
            if (dist > 1.0) { location <- location + (dir / dist) * vitesse; }
        } else {
            location <- location + {rnd(-vitesse, vitesse), rnd(-vitesse, vitesse)};
        }
        if (!(zone_z3 covers location)) { location <- zone_z3.centroid; }
    }

    reflex repas_sang {
        float tau_j  <- world.cycle_gonotrophique(temperature, type_vecteur);
        float a_jour <- min(1.0, (1.0 / tau_j) * facteur_humidite * facteur_vent);

        if (flip(a_jour)) {
            // Vol de quête nocturne : la femelle cherche activement un hôte dans
            // sa portée de vol, elle n'attend pas qu'un hôte passe à quelques
            // dizaines de mètres du gîte. Sans cela les rencontres hôte/vecteur
            // sont quasi nulles et le taux de piqûre `a` s'effondre à zéro.
            float portee <- (type_vecteur = "aedes")
                            ? portee_vol_aedes_m : portee_vol_culex_m;
            list<animal> a_pr <- animal at_distance portee;
            list<humain> h_pr <- humain at_distance portee;

            if (!empty(a_pr) or !empty(h_pr)) {
                // La piqûre est comptabilisée pour TOUS les vecteurs.
                if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
                cumul_bites_vect <- cumul_bites_vect + 1.0;

                bool sur_animal <- !empty(a_pr)
                                   and (empty(h_pr) or flip(preference_zoophilie));

                float p_trans <- b_vecteur();   // pré-calculé : dans `ask`, le
                float p_infec <- c_vecteur();   // contexte est l'hôte, pas le vecteur

                if (sur_animal) {
                    animal cible <- one_of(a_pr);
                    location <- cible.location;   // la femelle rejoint son hôte
                    if (etat_sante = "I") {
                        ask cible {
                            if (etat_sante = "S" and flip(p_trans)) {
                                etat_sante      <- "E";
                                jours_dans_etat <- 0;
                                nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                                incidence_c           <- incidence_c + echelle_superindividu;
                            }
                        }
                    } else if (etat_sante = "S" and cible.etat_sante = "I" and flip(p_infec)) {
                        etat_sante        <- "E";
                        avancement_eip    <- 0.0;
                        origine_infection <- "horizontale";
                        incidence_v       <- incidence_v + echelle_si_vecteur;
                    }
                } else {
                    humain cible <- one_of(h_pr);
                    location <- cible.location;   // la femelle rejoint son hôte
                    if (etat_sante = "I") {
                        ask cible {
                            if (etat_sante = "S" and flip(p_trans)) {
                                etat_sante      <- "E";
                                jours_dans_etat <- 0;
                                nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                                incidence_c           <- incidence_c + echelle_superindividu;
                            }
                        }
                    } else if (etat_sante = "S" and cible.etat_sante = "I" and flip(p_infec)) {
                        etat_sante        <- "E";
                        avancement_eip    <- 0.0;
                        origine_infection <- "horizontale";
                        incidence_v       <- incidence_v + echelle_si_vecteur;
                    }
                }
            }
        }
    }

    /**
     * Incubation extrinsèque : progression fractionnaire pilotée par la
     * température du jour (et non un compteur de jours fixe).
     */
    reflex incubation_extrinseque when: etat_sante = "E" {
        avancement_eip <- avancement_eip + 1.0 / world.eip_jours(temperature);
        if (avancement_eip >= 1.0) {
            etat_sante      <- "I";
            avancement_eip  <- 0.0;
            jours_dans_etat <- 0;
        }
    }

    reflex vieillir_dans_etat { jours_dans_etat <- jours_dans_etat + 1; }

    /**
     * Ponte Aedes sur mare ASSÉCHÉE : le fait d'être infectée ne conditionne
     * plus la ponte elle-même (auparavant seules les femelles I pondaient, ce
     * qui rendait la population d'Aedes non auto-entretenue), mais seulement la
     * fraction rho_aedes d'œufs infectés (transmission verticale / TOT).
     */
    reflex ponte_aedes
        when: type_vecteur = "aedes"
          and (age mod max(1, int(world.cycle_gonotrophique(temperature, type_vecteur)))) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau = 0) {
            float pontes <- lambda_aedes * kappa_aedes * facteur_temperature
                          * facteur_humidite * float(taille_groupe);
            float infectes <- (etat_sante = "I") ? pontes * rho_aedes : 0.0;

            // Le cas index doit amorcer le réservoir même si rho est très faible.
            if ((est_cas_index_A or est_cas_index_B) and pontes > 0.0 and infectes < 1.0) {
                infectes <- 1.0;
            }
            if (infectes > 0.0) { m.oeufs_index <- true; }

            m.oeufs_aedes_infectes <- m.oeufs_aedes_infectes + infectes;
            m.oeufs_aedes_sains    <- m.oeufs_aedes_sains + max(0.0, pontes - infectes);
        }
    }

    /**
     * Ponte Culex sur eau libre : alimente l'accumulateur journalier du gîte,
     * que la mare convertit en une cohorte larvaire unique (voir mare.gaml).
     */
    reflex ponte_culex
        when: type_vecteur = "culex"
          and (age mod max(1, int(world.cycle_gonotrophique(temperature, type_vecteur)))) = 0 {
        mare m <- mare closest_to self;
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.volume_eau > 0) {
            m.pontes_culex_jour <- m.pontes_culex_jour
                + lambda_culex * kappa_culex * facteur_temperature
                * facteur_humidite * float(taille_groupe);
        }
    }

    reflex mourir {
        age <- age + 1;
        float mu_jour <- world.mortalite_adulte_journaliere(temperature, humidite_relative, type_vecteur);
        bool mort_n <- flip(mu_jour);
        bool mort_a <- age > ((type_vecteur = "aedes") ? longevite_max_aedes : longevite_max_culex);

        if (mort_n or mort_a) {
            // Seules les morts BIOLOGIQUES alimentent l'estimation de la survie
            // journalière `p` utilisée dans le R0.
            cumul_morts_vect <- cumul_morts_vect + 1.0;
            if (type_vecteur = "aedes") { cumul_morts_Aedes <- cumul_morts_Aedes + 1.0; }
            do die;
        }
        // Purge de performance au plafond : artefact, NON comptée dans p.
        if (!dead(self) and length(vecteur) > max_vecteurs and flip(0.2)) { do die; }
    }

    aspect default {
        rgb   c;
        float taille <- unite_z3 * 0.002;
        if (type_vecteur = "aedes") {
			switch etat_sante {
			    match "S" { c <- #pink; }                         // ROSE
			    match "E" { c <- rgb(255,165,0); }               // ORANGE
			    match "I" { c <- est_cas_index_A ? #darkred : (origine_infection = "verticale" ? #orangered : #red); }
			}
			draw triangle(taille) color: c border: c;
        } else {
		switch etat_sante {
		    match "S" { c <- #violet; }                       // VIOLET
		    match "E" { c <- rgb(180,100,220); }             // VIOLET CLAIR
		    match "I" { c <- #darkviolet; }                  // VIOLET FONCÉ
		}
		draw circle(taille) color: c border: c;
        }
    }
}
