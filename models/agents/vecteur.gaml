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

    // -------------------------------------------------------------------
    // ORDRE DES REFLEX — la ponte est déclarée AVANT le déplacement.
    // La femelle pond sur le gîte où elle a passé la nuit, puis disperse.
    // Dans l'ordre inverse (déplacement d'abord), le cas index de l'EXP A
    // sortait de `rayon_depot_oeufs` avant d'avoir pondu : les deux valent
    // unite_z3 * 0.0012, donc la marche aléatoire du cycle 0 faisait échouer
    // l'amorçage du réservoir d'œufs dans environ une réplication sur cinq.
    // -------------------------------------------------------------------

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
        // Ae. vexans pond sur le SOL HUMIDE EXONDÉ en bordure de mare, pas sur
        // sol totalement sec ni sur l'eau libre. L'ancienne condition exigeait
        // `volume_eau = 0`, jamais vraie dès la mise en eau : la ponte devenait
        // impossible toute la saison des pluies et l'espèce s'éteignait.
        // La bande exondée disponible est proportionnelle à (1 - niveau_mare).
        if (m != nil and (location distance_to m.location) < rayon_depot_oeufs
            and m.niveau_mare < seuil_niveau_ponte_aedes) {
            float marge  <- max(0.0, 1.0 - m.niveau_mare);
            float pontes <- lambda_aedes * kappa_aedes * facteur_temperature
                          * facteur_humidite * float(taille_groupe) * marge;
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
        // Meme correction que dans hote.contraindre : le confinement porte sur
        // l'emprise du MONDE, dans le repere des agents, et recadre sur le bord.
        if (!(shape covers location)) {
            float xmin <- shape.location.x - shape.width  / 2;
            float xmax <- shape.location.x + shape.width  / 2;
            float ymin <- shape.location.y - shape.height / 2;
            float ymax <- shape.location.y + shape.height / 2;
            location <- {min(xmax, max(xmin, location.x)),
                         min(ymax, max(ymin, location.y))};
        }
    }

    /**
     * REPAS DE SANG — un agent vecteur représente `taille_groupe` moustiques
     * réels, un agent hôte `echelle_superindividu` animaux. Les piqûres du
     * groupe sont donc RÉPARTIES sur les hôtes à portée, et la probabilité
     * d'infection d'un hôte tient compte du nombre de piqûres qu'il reçoit :
     *
     *     piqures_par_individu = (piqures_recues / echelle_superindividu)
     *     p_eff = 1 - (1 - b) ^ piqures_par_individu
     *
     * Sans cette correction, 500 moustiques infectieux face à 20 animaux ne
     * produisaient qu'un seul tirage à b = 0,11 : la force d'infection était
     * sous-estimée d'un ordre de grandeur et aucune épidémie ne démarrait.
     * La formule est exacte lorsque les deux échelles valent 1.
     *
     * ---------------------------------------------------------------------
     * FORME FONCTIONNELLE DE LA FORCE D'INFECTION
     *
     * Cecilia et al. (2022, PLoS Negl Trop Dis 16(11)) relèvent que 29 modèles
     * de FVR sur 43 ne justifient pas leur choix de forme fonctionnelle, alors
     * qu'il encode l'hypothèse de contact hôte/vecteur et détermine largement
     * les prédictions. Le choix est donc explicité ici.
     *
     * Ce modèle n'utilise aucune des trois formes classiques (frequency-
     * dependent réservoir FR, mass action MA, frequency-dependent infectieux
     * FI). Le contact est SIMULÉ, non postulé :
     *
     *   - le taux de piqûre par moustique est plafonné par le cycle
     *     gonotrophique, a = 1/tau(T) — comme dans FR, et non proportionnel à
     *     la densité d'hôtes comme dans MA, qui autorise un taux de piqûre
     *     au-delà de la capacité physiologique ;
     *   - les piqûres du groupe sont RÉPARTIES sur les seuls hôtes présents
     *     dans la portée de vol, donc le nombre de piqûres reçues par hôte
     *     croît quand les hôtes se raréfient, sans jamais dépasser ce que le
     *     groupe peut délivrer.
     *
     * Le comportement obtenu est celui de la forme hybride de Chitnis et al.
     * (2013), la plus justifiée du corpus (5 modèles sur 8 l'argumentent) :
     * un contact borné aux deux extrémités, par la physiologie du vecteur d'un
     * côté et par la disponibilité des hôtes de l'autre. La différence est que
     * la borne côté hôte n'est pas un paramètre libre (le « sigma_h » de
     * Chitnis, qu'ils reconnaissent impossible à estimer sur le terrain) mais
     * émerge de la géométrie : portée de vol et position réelle des troupeaux.
     * ---------------------------------------------------------------------
     */
    reflex repas_sang {
        float tau_j  <- world.cycle_gonotrophique(temperature, type_vecteur);
        float a_jour <- min(1.0, (1.0 / tau_j) * facteur_humidite * facteur_vent);

        if (flip(a_jour)) {
            // Vol de quête : la femelle cherche activement un hôte dans sa
            // portée de vol documentée (Ba et al. 2005).
            float portee <- (type_vecteur = "aedes")
                            ? portee_vol_aedes_m : portee_vol_culex_m;
            list<animal> a_pr <- animal at_distance portee;
            list<humain> h_pr <- humain at_distance portee;

            if (!empty(a_pr) or !empty(h_pr)) {
                // `a` est un taux PAR MOUSTIQUE : chaque moustique du groupe
                // prend un repas, donc +1 par activation d'agent.
                if (type_vecteur = "aedes") { cumul_bites_Aedes <- cumul_bites_Aedes + 1.0; }
                cumul_bites_vect <- cumul_bites_vect + 1.0;
                if (mare_origine != nil and !dead(mare_origine)) {
                    mare_origine.loc_bites <- mare_origine.loc_bites + 1.0;
                }

                // Répartition zoophile des piqûres du groupe entre bétail et humains
                float part_animal <- empty(a_pr) ? 0.0
                                     : (empty(h_pr) ? 1.0 : preference_zoophilie);
                float piqures_animal <- float(taille_groupe) * part_animal;
                float piqures_humain <- float(taille_groupe) - piqures_animal;

                float p_trans <- b_vecteur();
                float p_infec <- c_vecteur();

                // ---- Vecteur infectieux : il inocule les hôtes qu'il pique ----
                if (etat_sante = "I") {
                    // Capturés ici : dans les `ask` imbriqués ci-dessous,
                    // `myself` désigne l'HÔTE et non plus le vecteur.
                    string v_espece  <- type_vecteur;
                    string v_origine <- origine_infection;
                    if (piqures_animal >= 1.0 and !empty(a_pr)) {
                        float piq_ind <- (piqures_animal / float(length(a_pr)))
                                       / float(echelle_superindividu);
                        float p_eff <- 1.0 - ((1.0 - p_trans) ^ piq_ind);
                        ask a_pr {
                            if (etat_sante = "S" and flip(p_eff)) {
                                etat_sante      <- "E";
                                jours_dans_etat <- 0;
                                nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                                incidence_c           <- incidence_c + echelle_superindividu;
                                // Journal de transmission : c'est le seul point
                                // du modèle où l'on connaisse à la fois QUAND,
                                // OÙ et PAR QUI l'infection s'est produite.
                                ask world {
                                    do journaliser_transmission("animal",
                                        echelle_superindividu, v_espece, v_origine,
                                        myself.location);
                                }
                            }
                        }
                    }
                    if (piqures_humain >= 1.0 and !empty(h_pr)) {
                        float piq_ind <- (piqures_humain / float(length(h_pr)))
                                       / float(echelle_superindividu);
                        float p_eff <- 1.0 - ((1.0 - p_trans) ^ piq_ind);
                        ask h_pr {
                            if (etat_sante = "S" and flip(p_eff)) {
                                etat_sante      <- "E";
                                jours_dans_etat <- 0;
                                nb_infections_totales <- nb_infections_totales + echelle_superindividu;
                                incidence_c           <- incidence_c + echelle_superindividu;
                                ask world {
                                    do journaliser_transmission("humain",
                                        echelle_superindividu, v_espece, v_origine,
                                        myself.location);
                                }
                            }
                        }
                    }
                }
                // ---- Vecteur sain : il peut s'infecter sur un hôte virémique ----
                else if (etat_sante = "S") {
                    // Fraction des piqûres du groupe qui tombent sur un hôte I
                    float f_an <- empty(a_pr) ? 0.0
                        : (float(length(a_pr where (each.etat_sante = "I"))) / float(length(a_pr)));
                    float f_hu <- empty(h_pr) ? 0.0
                        : (float(length(h_pr where (each.etat_sante = "I"))) / float(length(h_pr)));
                    float part_hu <- 1.0 - part_animal;
                    float p_agent <- p_infec * (part_animal * f_an + part_hu * f_hu);

                    if (p_agent > 0.0 and flip(min(1.0, p_agent))) {
                        etat_sante        <- "E";
                        avancement_eip    <- 0.0;
                        origine_infection <- "horizontale";
                        incidence_v       <- incidence_v + echelle_si_vecteur;
                    }
                }

                // La femelle finit sa nuit sur l'un des hôtes visités
                if (!empty(a_pr) and part_animal > 0.0) { location <- one_of(a_pr).location; }
                else if (!empty(h_pr)) { location <- one_of(h_pr).location; }
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
     * Comptabilise la présence du jour au crédit du gîte d'origine : c'est la
     * base du R0 local, calculé mare par mare (voir mare.gaml).
     */
    reflex comptabiliser_gite {
        if (mare_origine != nil and !dead(mare_origine)) {
            mare_origine.loc_vect_jours <- mare_origine.loc_vect_jours + 1.0;
            if (type_vecteur = "aedes") {
                mare_origine.loc_aedes_jours <- mare_origine.loc_aedes_jours + 1.0;
            }
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
            if (mare_origine != nil and !dead(mare_origine)) {
                mare_origine.loc_morts <- mare_origine.loc_morts + 1.0;
            }
            do die;
        }
        // Purge de performance au plafond : artefact de calcul, NON comptée dans
        // `p`. Intensité proportionnelle au dépassement, et appliquée sans
        // distinction d'espèce pour ne pas éliminer la moins abondante.
        if (!dead(self) and length(vecteur) > max_vecteurs) {
            float exces <- float(length(vecteur) - max_vecteurs) / float(max_vecteurs);
            if (flip(min(0.5, exces))) { do die; }
        }
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
