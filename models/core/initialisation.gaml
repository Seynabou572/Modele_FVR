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
import "validation.gaml"
import "exports_csv.gaml"
import "../environnement/occsol_polygone.gaml"
import "../environnement/zone_eau_binaire.gaml"
import "../environnement/sol.gaml"
import "../environnement/vegetation.gaml"
import "../environnement/route.gaml"
import "../environnement/campement.gaml"
import "../environnement/mare.gaml"
import "../environnement/zone_suivi.gaml"
import "../environnement/cohorte_larvaire.gaml"
import "../agents/hote.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

    // =========================================================================
    // ACTION : POPULATION CULEX DE FOND — utilisée par EXP A et EXP B.
    //
    // Le protocole des deux expériences impose que TOUS les Culex soient sains
    // à l'initialisation : le seul foyer est le cas index de l'expérience
    // (1 animal virémique en EXP B, 1 femelle Aedes infectée en EXP A). La
    // version précédente en infectait 5 % dans les deux cas, ce qui ajoutait
    // cinq foyers concurrents et rendait le R0 mesuré incomparable à sa
    // définition — le nombre de cas secondaires issus d'UN cas index.
    // `prevalence_culex_init` reste exposé pour les analyses de sensibilité.
    // =========================================================================
    action initialiser_culex_fond(mare mare_exclue) {
        int nb_infectes <- int(nb_culex_init * prevalence_culex_init);
        list<mare> mares_dispo <- list((mare_exclue = nil) ? mare : (mare - mare_exclue));

        if (!empty(mares_dispo)) {
            loop i from: 0 to: nb_culex_init - 1 {
                mare m_c <- mares_dispo[i mod length(mares_dispo)];
                // Amorçage hydrique : les Culex pondent sur eau libre et ne
                // survivent pas sur un gîte sec. La simulation démarre avant
                // les pluies, aucune mare n'est encore en eau — on met donc en
                // eau les seuls gîtes porteurs de cette population de fond.
                // C'est un artefact d'initialisation, pas un état simulé : il
                // est repris par le bilan hydrique dès le premier pas de temps.
                if (m_c.volume_eau <= 0.0) {
                    m_c.volume_eau  <- min(volume_amorce_culex, m_c.volume_max_reference);
                    m_c.surface_eau <- m_c.surface_pour_volume(m_c.volume_eau);
                }

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
            write "Culex de fond : " + nb_culex_init + " agents créés, " + nb_infectes
                + " infectés (prévalence initiale " + prevalence_culex_init + ").";
        }
    }

    // =========================================================================
    // ACTION : AMORCAGE DU RESERVOIR D'OEUFS QUIESCENTS AEDES
    //
    // Ae. vexans franchit la saison seche a l'etat d'oeuf, depose sur la berge
    // exondee et resistant a la dessiccation. Une simulation qui demarre en
    // debut de saison des pluies doit donc trouver ce stock deja en place.
    // Sans lui, aucun Aedes ne peut emerger : l'espece n'apparait que si un cas
    // index adulte est cree, et disparait avec lui.
    //
    // Densite : Soti et al. (2012), 1000 oeufs.m-2 sur les mares de Barkedji.
    // Repartie ici sur la partie ASSECHEE de chaque gite, qui est la surface
    // reellement porteuse d'oeufs — et celle qu'utilise `ponte_aedes` ensuite.
    // =========================================================================
    action amorcer_oeufs_aedes {
        if (densite_oeufs_initiale_aedes > 0.0 and !empty(mare)) {
            float total     <- 0.0;
            float total_inf <- 0.0;
            int   nb_gites  <- 0;
            ask mare {
                float berge <- max(0.0, surface_max - surface_eau);
                if (berge > 0.0) {
                    float oeufs <- berge * densite_oeufs_initiale_aedes;
                    float inf   <- oeufs * prevalence_oeufs_initiale;
                    oeufs_aedes_infectes <- oeufs_aedes_infectes + inf;
                    oeufs_aedes_sains    <- oeufs_aedes_sains + max(0.0, oeufs - inf);
                    if (inf > 0.0) { oeufs_index <- true; }
                    total     <- total + oeufs;
                    total_inf <- total_inf + inf;
                    nb_gites  <- nb_gites + 1;
                }
            }
            write "Reservoir Aedes : " + int(total) + " oeufs quiescents deposes sur "
                + nb_gites + " gites (" + int(total_inf) + " infectes, prevalence "
                + prevalence_oeufs_initiale + ").";
            write "   densite " + densite_oeufs_initiale_aedes
                + " oeufs/m2 de berge exondee (Soti et al. 2012).";
        }
    }

    init {
        write "========== INIT FVR Z3 | Expérience=" + type_experience
            + " | SimID=" + simulation_id + " ==========";

        unite_z3 <- min(zone_z3.width, zone_z3.height);

        vitesse_aedes        <- unite_z3 * 0.0012;   // Ae. vexans : forte dispersion
        vitesse_culex        <- unite_z3 * 0.0006;   // Culex : inféodé au gîte
        // Déplacement journalier des hôtes, en mètres (FAO : 6-10 km bovins,
        // 3-5 km petits ruminants entre pâturage et point d'eau). L'ancien
        // réglage (unite_z3 * 0.0004 ~ 13 m/jour) rendait le bétail quasi
        // immobile : il n'atteignait jamais les mares, et le taux de piqûre `a`
        // s'effondrait faute de rencontre hôte/vecteur.
        vitesse_hote_normal  <- 6000.0;
        vitesse_transhumance <- 15000.0;
        rayon_detection_v        <- unite_z3 * 0.0025;
        rayon_piqure_humain      <- unite_z3 * 0.0015;
        rayon_piqure_animal      <- unite_z3 * 0.0018;
        rayon_depot_oeufs        <- unite_z3 * 0.0012;
        rayon_recherche_paturage <- unite_z3 * 0.05;

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
        do diagnostiquer_forcage;

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
        write "  R0_animal calculé UNE FOIS sur les " + fenetre_R0_animal + " premiers jours ;";
        write "  R0_Aedes  calculé UNE FOIS sur les " + fenetre_R0_aedes + " premiers jours.";

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

        // Couche de zonage : 796 polygones typés mare / campement / vegetation.
        // Support des sorties spatiales, sans effet sur la dynamique simulée.
        create zone_suivi from: ZONE_SHP with: [
            type_zone   :: string(read("Name")),
            classe_zone :: int(read("id_class"))
        ] {
            surface_zone <- area(shape);
            id_zone      <- name;
        }
        write "Zones de suivi : " + length(zone_suivi) + " polygones ("
            + length(zone_suivi where (each.type_zone = "mare")) + " mare, "
            + length(zone_suivi where (each.type_zone = "campement")) + " campement, "
            + length(zone_suivi where (each.type_zone = "vegetation")) + " vegetation).";

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
                    if (!(shape covers location)) { location <- camp.location; }
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
                    if (!(shape covers location)) { location <- camp.location; }
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

        // Le reservoir d'oeufs preexiste au cas index : c'est ce qui reste de la
        // saison precedente, et il conditionne toute emergence d'Aedes.
        do amorcer_oeufs_aedes;

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
                write "   Positionnée exactement sur la mare sèche : pond dès le cycle 0 (reflex ponte_aedes";
                write "   déclaré avant se_deplacer) des œufs infectés + sains (rho_aedes).";
            }

            do initialiser_culex_fond(mare_reference);

        } else if (type_experience = "Animal") {
            // Cas index UNIQUE de l'expérience Animal : un seul animal virémique.
            // Ni Aedes infectée, ni Culex infectés — la version précédente créait
            // en plus une femelle Aedes I et 5 Culex I, soit trois foyers pour un
            // R0 censé mesurer la descendance d'un seul.
            if (length(animal) > 0) {
                animal a_index <- first(animal);
                a_index.etat_sante      <- "I";
                a_index.jours_dans_etat <- 0;
                a_index.est_cas_index_B <- true;
                write "EXP B : 1 animal I créé comme cas index (foyer unique).";
            }

            do initialiser_culex_fond(nil);
        }

        reseau_routier <- as_edge_graph(route);

        do initialiser_fichiers_csv;

        write "========== INIT TERMINÉE | R₀ calculé toutes les 10 fenêtres ==========";
    }
}
