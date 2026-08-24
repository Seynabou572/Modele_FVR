/**
 * INITIALISATION — orchestration du bootstrap : calibration des échelles,
 * chargement du climat et des couches environnementales statiques,
 * mise en place de la saison initiale, création des hôtes, et cas index
 * de l'expérience choisie (Aedes ou Animal).
 */
model Initialisation

import "parametres_globaux.gaml"
import "donnees_chemins.gaml"
import "climat.gaml"
import "biologie_thermique.gaml"
import "saisons_occsol.gaml"
import "dynamique_population.gaml"
import "r0_vectoriel.gaml"
import "exports_csv.gaml"
import "../environnement/occsol_polygone.gaml"
import "../environnement/zone_eau_binaire.gaml"
import "../environnement/sol.gaml"
import "../environnement/vegetation.gaml"
import "../environnement/route.gaml"
import "../environnement/campement.gaml"
import "../environnement/mare.gaml"
import "../environnement/cohorte_larvaire.gaml"
import "../agents/hote.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

    // =========================================================================
    // ACTION : INITIALISATION DES 100 CULEX — utilisée par EXP A et EXP B.
    // =========================================================================
    action initialiser_culex_100(mare mare_exclue) {
        int nb_culex_init <- 100;
        int nb_infectes   <- int(nb_culex_init * 0.05);
        list<mare> mares_dispo <- list((mare_exclue = nil) ? mare : (mare - mare_exclue));

        if (!empty(mares_dispo)) {
            loop i from: 0 to: nb_culex_init - 1 {
                mare m_c <- mares_dispo[i mod length(mares_dispo)];
                m_c.volume_eau  <- 80.0;
                m_c.surface_eau <- min(m_c.surface_max, m_c.volume_eau * 2.0);

                if (length(vecteur) < max_vecteurs) {
                    bool infecte <- (i < nb_infectes);
                    create vecteur {
                        type_vecteur      <- "culex";
                        etat_sante        <- infecte ? "I" : "S";
                        taille_groupe     <- echelle_si_vecteur;
                        vitesse           <- vitesse_culex;
                        mare_origine      <- m_c;
                        location          <- m_c.location;
                        age               <- rnd(0, 5);
                        jours_dans_etat   <- 0;
                        est_cas_index_A   <- false;
                        est_cas_index_B   <- false;
                        origine_infection <- infecte ? "horizontale" : "aucune";
                    }
                }
            }
            write "Culex initiaux : " + nb_culex_init + " créés (" + nb_infectes
                + " infectés à 5%), positionnés exactement sur les mares (volume_eau=80.0).";
        }
    }

    init {
    	
    	// ========== AFFICHAGE DES DIMENSIONS DE LA ZONE ==========
	    write "=========================================";
	    write "DIMENSIONS DE LA ZONE D'ÉTUDE (zone_z3)";
	    write "-----------------------------------------";
	    write "Largeur (x) : " + zone_z3.width + " m";
	    write "Hauteur (y) : " + zone_z3.height + " m";
	    write "Surface totale : " + zone_z3.area + " m² (soit " + (zone_z3.area / 1000000) + " km²)";
	    write "=========================================";
        write "========== INIT FVR Z3 | Expérience=" + type_experience
            + " | SimID=" + simulation_id + " ==========";

        unite_z3 <- min(zone_z3.width, zone_z3.height);

		// ===== NOUVELLES VALEURS CALIBRÉES SUR unite_z3 =====
		vitesse_aedes        <- unite_z3 * 0.026;   // 800 m/jour (Aedes actif)
		vitesse_culex        <- unite_z3 * 0.013;   // 400 m/jour (Culex plus sédentaire)
		vitesse_hote_normal  <- 6000.0;             // 6 km/jour 
		vitesse_transhumance <- 15000.0;            // 15 km/jour 
		
		rayon_detection_v        <- unite_z3 * 0.0065; // 200 m (détection CO2)
		rayon_piqure_humain      <- unite_z3 * 0.0006; // 20 m
		rayon_piqure_animal      <- unite_z3 * 0.0006; // 20 m
		rayon_depot_oeufs        <- unite_z3 * 0.0012; // 37 m 
		rayon_recherche_paturage <- unite_z3 * 0.05;   // 1500 m 

        // Seul r est un paramètre fixe du R0. La survie journalière p est
        // désormais MESURÉE sur chaque fenêtre (morts biologiques / vecteurs-jours)
        // et n (EIP) est la moyenne de eip_jours(T) sur la fenêtre : voir
        // core/r0_vectoriel.gaml. Les valeurs ci-dessous ne servent que d'amorce
        // avant la première fenêtre.
        r_hote           <- (duree_infection > 0.0) ? 1.0 / duree_infection : 0.0;
        p_survie_vect    <- survie_aedes;
        ln_p_survie_vect <- ln(p_survie_vect);
        n_Aedes          <- duree_cycle_extrinseque;
        n_animal         <- duree_cycle_extrinseque;

        do charger_climat;
		
		write "Humidite: " + facteur_humidite + " | Vent: " + facteur_vent;
        write "Paramètres R0 :";
        write "  r = 1/duree_infection = " + with_precision(r_hote, 4);
        write "  unite_z3 = " + with_precision(unite_z3, 0)
            + " (doit valoir ~32000 si la projection est bien métrique)";
        write "  portée de vol : Aedes " + portee_vol_aedes_m + " m, Culex "
            + portee_vol_culex_m + " m";
        write "  a attendu ~ 1/tau : Aedes "
            + with_precision(1.0 / cycle_gonotrophique(temperature, "aedes"), 4)
            + " | Culex " + with_precision(1.0 / cycle_gonotrophique(temperature, "culex"), 4)
            + " piqûre/vecteur/jour à " + with_precision(temperature, 1) + " °C";
        write "  n (EIP) à " + with_precision(temperature, 1) + " °C = "
            + with_precision(eip_jours(temperature), 2) + " j";
        write "  p et n seront réestimés à chaque fenêtre de 10 jours.";

        create route from: ROUTE_SHP with: [
            code_route   :: int(read("CODE")),
            classe_route :: int(read("CLASSE")),
            revet        :: int(read("REVET")),
            repert       :: int(read("REPERT"))
        ];
        create sol from: SOL_SHP with: [
            msd    :: int(read("MSD")),
            msdnom :: string(read("MSDNOM"))
        ];
        create vegetation from: VEGETATION_SHP with: [
            formcode  :: int(read("FORMCODE")),
            formation :: string(read("FORMATION"))
        ];
        ask sol        { do calculer_proprietes_sol; }
        ask vegetation { do calculer_capacite_vegetation; }

        // NDWI binaire désactivé : EAU_BINAIRE_SHP (donnees_chemins.gaml) est commenté
        // tant que data/occsol/eau_binaire/eau_binaire_z3.shp n'est pas fourni.
        // if (utiliser_ndwi_binaire) {
        //     create zone_eau_binaire from: EAU_BINAIRE_SHP with: [eau :: int(read(colonne_ndwi_binaire))];
        //     zones_eau_binaire <- (zone_eau_binaire where (each.eau = 1)) collect each.shape;
        //     write "NDWI binaire : " + length(zones_eau_binaire) + " zones d'eau chargées.";
        // }

        saison <- calculer_saison(jour_debut_simulation);
        do mettre_a_jour_occsol_saisonnier(saison);

        nb_agents_humains <- nb_humains_init;
        nb_agents_animaux <- nb_animaux_init;

        loop i from: 0 to: nb_agents_humains - 1 {
            campement camp <- (empty(campement)) ? nil : campement[i mod nb_campements];
            if (camp != nil) {
                create humain {
                    campement_origine <- camp;
                    taille_groupe     <- echelle_si_vecteur;
                    location <- camp.location + {
                        rnd(-rayon_piqure_humain * 2, rayon_piqure_humain * 2),
                        rnd(-rayon_piqure_humain * 2, rayon_piqure_humain * 2)
                    };
                    if (!(zone_z3 covers location)) { location <- camp.location; }
                    etat_sante      <- "S";
                    jours_dans_etat <- 0;
                }
            }
        }

        loop i from: 0 to: nb_agents_animaux - 1 {
            campement camp <- (empty(campement)) ? nil : campement[i mod nb_campements];
            if (camp != nil) {
                create animal {
                    campement_origine <- camp;
                    taille_groupe     <- echelle_si_vecteur;
                    location <- camp.location + {
                        rnd(-rayon_piqure_animal * 3, rayon_piqure_animal * 3),
                        rnd(-rayon_piqure_animal * 3, rayon_piqure_animal * 3)
                    };
                    if (!(zone_z3 covers location)) { location <- camp.location; }
                    etat_sante      <- "S";
                    jours_dans_etat <- 0;
                    NEC             <- 3.5;
                }
            }
        }

        ask animal {
            if (length(humain) > 0) {
                humain h <- one_of(humain);
                berger <- h;
                h.troupeaux_associes <- h.troupeaux_associes union [self];
            }
        }
        write "Humains : " + length(humain) + " agents S. Animaux : " + length(animal) + " agents S.";

        if (type_experience = "Aedes") {
            mare mare_reference <- nil;
            if (!empty(mare)) {
                mare_reference <- first(mare);
                mare_reference.volume_eau  <- 0.0;
                mare_reference.surface_eau <- 0.0;
                write "EXP A : mare de référence forcée sèche (volume_eau=0).";

                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_si_vecteur;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- mare_reference;
                    location         <- mare_reference.location;
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- true;
                    est_cas_index_B  <- false;
                    origine_infection <- "verticale";
                }
                write "EXP A : 1 femelle Aedes adulte infectée (cas index, origine_infection=verticale) créée.";
                write "   Positionnée exactement sur la mare sèche : pondra dès le jour 0 (transmission_verticale,";
                write "   reflex exécuté avant l'incrémentation de l'âge dans mourir) œufs infectés + sains (rho_aedes).";
            }

            do initialiser_culex_100(mare_reference);

        } else if (type_experience = "Animal") {
            if (length(animal) > 0) {
                animal a_index <- first(animal);
                a_index.etat_sante      <- "I";
                a_index.jours_dans_etat <- 0;
                a_index.est_cas_index_B <- true;
                write "EXP B : 1 animal I créé comme cas index.";
            }

            mare mare_seche <- nil;
            if (!empty(mare)) {
                mare_seche <- first(mare);
                mare_seche.volume_eau  <- 0.0;
                //mare_seche.surface_eau <- 0.0;

                create vecteur {
                    type_vecteur     <- "aedes";
                    etat_sante       <- "I";
                    taille_groupe    <- echelle_si_vecteur;
                    vitesse          <- vitesse_aedes;
                    mare_origine     <- mare_seche;
                    location         <- mare_seche.location;
                    age              <- 0;
                    jours_dans_etat  <- 0;
                    est_cas_index_A  <- false;
                    est_cas_index_B  <- true;
                    origine_infection <- "verticale";
                }
                write "EXP B : 1 femelle Aedes adulte infectée (cas index B, origine_infection=verticale) créée.";
                write "   Positionnée exactement sur la mare sèche (volume_eau=0) : pondra dès le jour 0.";
            }

            do initialiser_culex_100(mare_seche);
        }

        reseau_routier <- as_edge_graph(route);

        do initialiser_fichiers_csv;

        write "========== INIT TERMINÉE | R₀ calculé toutes les 10 fenêtres ==========";
    }
}
