/**
 * EXPORTS CSV — UN SEUL JEU DE FICHIERS PARTAGÉ PAR TOUTES LES SIMULATIONS
 * D'UN BATCH. Chaque ligne exportée porte simulation_id en première colonne.
 * Les en-têtes sont écrites une seule fois (simulation_id = 1) via
 * initialiser_fichiers_csv, appelée depuis l'init ; le reste des reflex
 * exporte en append (rewrite: false).
 */
model ExportsCsv

import "parametres_globaux.gaml"
import "climat.gaml"
import "r0_vectoriel.gaml"
import "validation.gaml"
import "../environnement/mare.gaml"
import "../environnement/zone_suivi.gaml"
import "../environnement/cohorte_larvaire.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

    string csv_journalier       <- "../outputs/journalier.csv";
    string csv_populations      <- "../outputs/populations.csv";
    string csv_r0_vectoriel     <- "../outputs/r0_vectoriel.csv";
    string csv_r0_local         <- "../outputs/r0_local.csv";
    string csv_incidence        <- "../outputs/incidence.csv";
    string csv_climat           <- "../outputs/climat.csv";
    string csv_mares            <- "../outputs/mares.csv";
    string csv_moustiques       <- "../outputs/moustiques.csv";
    string csv_controle_memoire <- "../outputs/controle_memoire.csv";
    string csv_resume           <- "../outputs/resume.csv";

    // Sorties spatiales : une ligne par ZONE et par pas d'export, jointes sur
    // id_zone dans QGIS. Les agrégats globaux (populations.csv, mares.csv)
    // n'ont aucune variance spatiale et ne peuvent donc pas servir à relier
    // conditions environnementales et apparition de l'infection.
    string csv_zones_epidemio   <- "../outputs/zones_epidemio.csv";
    string csv_zones_environ    <- "../outputs/zones_environnement.csv";
    string csv_transmissions    <- "../outputs/transmissions.csv";
    string csv_validation       <- "../outputs/validation.csv";

    bool export_detail  <- true;
    // Les zones sont nombreuses (796) : un export journalier produirait
    // ~145 000 lignes par simulation. La date de première infection reste
    // enregistrée au jour près, indépendamment de cette cadence.
    int  pas_export_zones <- 5;

    // =========================================================================
    // ACTION : INITIALISATION DES FICHIERS CSV (en-têtes), appelée depuis l'init
    // =========================================================================
    action initialiser_fichiers_csv {
        if (simulation_id = 1) {
            save ["simulation_id","cycle","jour_annee","saison","temperature_C","humidite_pct","pluie_mm","vent_ms",
                  "dist_med_hote_mare_m","hotes_a_620m","hotes_a_2km","mares_en_eau",
                  "x_min_monde","x_max_monde","x_min_zone_z3","x_max_zone_z3"]
                to: csv_journalier format: "csv" rewrite: true;
            save ["simulation_id","cycle","humains_S","humains_E","humains_I","humains_R",
                  "animaux_S","animaux_E","animaux_I","animaux_R","vecteurs_total"]
                to: csv_populations format: "csv" rewrite: true;
            save ["simulation_id","cycle","incidence_hotes","incidence_vecteurs","prevalence_hotes","prevalence_vecteurs"]
                to: csv_incidence format: "csv" rewrite: true;
            save ["simulation_id","cycle","YEAR","DOY","T2M","RH2M","PRECTOTCORR","WS2M"]
                to: csv_climat format: "csv" rewrite: true;
            save ["simulation_id","cycle","nb_mares_actives","volume_moyen","niveau_moyen","oeufs_infectes","oeufs_sains","larves_total","ndwi_moyen","ndvi_moyen"]
                to: csv_mares format: "csv" rewrite: true;
            save ["simulation_id","cycle","aedes_S","aedes_E","aedes_I","culex_S","culex_E","culex_I","total"]
                to: csv_moustiques format: "csv" rewrite: true;
            save ["simulation_id","cycle","humains","animaux","vecteurs","cohortes","total_agents"]
                to: csv_controle_memoire format: "csv" rewrite: true;
            save ["simulation_id","experience","infections_totales",
                  "fenetre_R0_animal","fenetre_R0_aedes",
                  "R0_animal","R0_Aedes",
                  "R0_animal_capacite","R0_Aedes_capacite",
                  "oeufs_inf_pic","oeufs_inf_report","taux_report_oeufs"]
                to: csv_resume format: "csv" rewrite: true;

            save ["simulation_id","cycle","jour_annee","id_zone","type_zone",
                  "classe_zone","x","y","surface_m2",
                  "nb_animaux","animaux_S","animaux_E","animaux_I","animaux_R",
                  "nb_humains","humains_S","humains_E","humains_I","humains_R",
                  "aedes_total","aedes_I","culex_total","culex_I",
                  "oeufs_infectes","oeufs_sains",
                  "nouvelles_infections","cas_cumules","jour_premiere_infection"]
                to: csv_zones_epidemio format: "csv" rewrite: true;

            save ["simulation_id","cycle","jour_annee","id_zone","type_zone","x","y",
                  "saison","pluie_mm","temperature_C","humidite_pct","vent_ms",
                  "ndvi_zone","ndwi_zone","eau_presente","volume_eau_m3"]
                to: csv_zones_environ format: "csv" rewrite: true;

            save ["simulation_id","cycle","jour_annee","espece_hote","nb_hotes_infectes",
                  "espece_vecteur","origine_infection_vecteur",
                  "id_zone","type_zone","x","y","saison",
                  "temperature_C","pluie_mm"]
                to: csv_transmissions format: "csv" rewrite: true;

            save ["simulation_id","experience",
                  "cumul_pluie_mm","pluie_jour_max_mm","jours_pluie",
                  "forcage_hors_enveloppe",
                  "pic_aedes","jour_pic_aedes","pic_culex","jour_pic_culex",
                  "decalage_pics_j","jours_co_abondance","indice_co_abondance",
                  "infections_totales","R0_animal_protocole","R0_Aedes_protocole"]
                to: csv_validation format: "csv" rewrite: true;
        }
    }

    /**
     * JOURNAL DE TRANSMISSION — une ligne par événement d'infection d'hôte.
     *
     * Appelée depuis `repas_sang` (vecteur.gaml) à l'instant précis où un hôte
     * bascule S -> E. Tout y est disponible : le cycle, la position, le vecteur
     * émetteur, son espèce et son origine d'infection. Sans ce journal, rien ne
     * permettait de dire QUAND ni OÙ une infection était apparue : les hôtes ne
     * portent que `jours_dans_etat`, remis à zéro à chaque transition.
     */
    action journaliser_transmission(string espece_hote, int nb, string espece_v,
                                    string origine_v, point lieu) {
        list<zone_suivi> z <- zone_suivi overlapping lieu;
        // Priorité au campement : c'est l'unité d'agrégation de référence de la
        // littérature de Barkedji, et les polygones peuvent se recouvrir.
        list<zone_suivi> camps <- z where (each.type_zone = "campement");
        zone_suivi zz <- !empty(camps) ? first(camps) : (empty(z) ? nil : first(z));
        if (zz != nil) { ask zz { do enregistrer_infection(nb); } }

        if (export_detail) {
            save [simulation_id, cycle, jour_debut_simulation + cycle,
                  espece_hote, nb, espece_v, origine_v,
                  (zz = nil) ? "hors_zone" : zz.id_zone,
                  (zz = nil) ? "hors_zone" : zz.type_zone,
                  with_precision(lieu.x, 1), with_precision(lieu.y, 1), saison,
                  with_precision(temperature, 2), with_precision(pluie, 2)]
                to: csv_transmissions format: "csv" rewrite: false;
        }
    }

    reflex export_zones when: export_detail and (cycle mod pas_export_zones = 0) {
        ask zone_suivi {
            do recenser;
            save [simulation_id, cycle, jour_debut_simulation + cycle,
                  id_zone, type_zone, classe_zone,
                  with_precision(location.x, 1), with_precision(location.y, 1),
                  with_precision(surface_zone, 1),
                  nb_animaux, nb_animaux_S, nb_animaux_E, nb_animaux_I, nb_animaux_R,
                  nb_humains, nb_humains_S, nb_humains_E, nb_humains_I, nb_humains_R,
                  nb_aedes, nb_aedes_I, nb_culex, nb_culex_I,
                  int(oeufs_infectes_zone), int(oeufs_sains_zone),
                  nouvelles_infections, cas_cumules, jour_premiere_infection]
                to: csv_zones_epidemio format: "csv" rewrite: false;
            // Le compteur est remis à zéro APRÈS l'écriture : il représente donc
            // les infections survenues depuis l'export précédent.
            nouvelles_infections <- 0;

            save [simulation_id, cycle, jour_debut_simulation + cycle,
                  id_zone, type_zone,
                  with_precision(location.x, 1), with_precision(location.y, 1),
                  saison, with_precision(pluie, 2), with_precision(temperature, 2),
                  with_precision(humidite_relative, 2), with_precision(vitesse_vent, 2),
                  with_precision(ndvi_zone, 4), with_precision(ndwi_zone, 4),
                  eau_presente, with_precision(volume_eau_zone, 2)]
                to: csv_zones_environ format: "csv" rewrite: false;
        }
    }

    reflex export_journalier when: export_detail {
        // DIAGNOSTIC DE CONTACT. `a` (taux de piqure) ne peut etre non nul que
        // si des hotes entrent dans la portee de vol des vecteurs, qui restent
        // au voisinage de leur gite. Ces colonnes disent si la rencontre est
        // seulement possible ; sans elles, un R0 nul est indiscernable d'un
        // R0 nul POUR UNE AUTRE RAISON.
        //
        // Les bornes de repere sont exportees avec : `contraindre` (hote.gaml)
        // renvoie tout agent hors de `zone_z3` sur son centroide. Si zone_z3 et
        // le monde ne sont pas dans le meme repere, la condition est fausse en
        // permanence et tous les hotes se retrouvent empiles sur ce point.
        list<mare> en_eau <- mare where (each.volume_eau > 0.0);
        float dmed <- 0.0; int n620 <- 0; int n2km <- 0;
        if (!empty(en_eau) and !empty(animal)) {
            list<float> dd <- [];
            loop a over: animal {
                mare mp <- en_eau closest_to a;
                if (mp != nil) { add (a distance_to mp) to: dd; }
            }
            if (!empty(dd)) {
                dmed <- median(dd);
                n620 <- length(dd where (each <= portee_vol_aedes_m));
                n2km <- length(dd where (each <= 2000.0));
            }
        }
        save [simulation_id, cycle, jour_debut_simulation + cycle, saison,
              with_precision(temperature, 2), with_precision(humidite_relative, 2),
              with_precision(pluie, 2), with_precision(vitesse_vent, 2),
              with_precision(dmed, 1), n620, n2km, length(en_eau),
              with_precision(shape.location.x - shape.width/2, 0),
              with_precision(shape.location.x + shape.width/2, 0),
              with_precision(zone_z3.location.x - zone_z3.width/2, 0),
              with_precision(zone_z3.location.x + zone_z3.width/2, 0)]
            to: csv_journalier format: "csv" rewrite: false;
    }

    reflex export_populations when: export_detail {
        save [simulation_id, cycle,
              length(humain where (each.etat_sante = "S")) * echelle_superindividu,
              length(humain where (each.etat_sante = "E")) * echelle_superindividu,
              length(humain where (each.etat_sante = "I")) * echelle_superindividu,
              length(humain where (each.etat_sante = "R")) * echelle_superindividu,
              int(S_c_global), int(E_c_global), int(I_c_global), int(R_c_global),
              length(vecteur) * echelle_si_vecteur]
            to: csv_populations format: "csv" rewrite: false;
    }

    reflex export_incidence when: export_detail {
        save [simulation_id, cycle, int(incidence_c), int(incidence_v),
              with_precision(prevalence_c, 4), with_precision(prevalence_v, 4)]
            to: csv_incidence format: "csv" rewrite: false;
    }

    reflex export_climat when: export_detail {
        save [simulation_id, cycle, 2025, jour_debut_simulation + cycle,
              temperature, humidite_relative, pluie, vitesse_vent]
            to: csv_climat format: "csv" rewrite: false;
    }

    reflex export_mares when: export_detail {
        int   nb_act    <- length(mare where (each.volume_eau > 0));
        float vol_moy   <- (empty(mare)) ? 0.0 : mean(mare collect each.volume_eau);
        float niv_moy   <- (empty(mare)) ? 0.0 : mean(mare collect each.niveau_mare);
        int   oeufs_inf <- int(sum(mare collect each.oeufs_aedes_infectes));
        int   oeufs_san <- int(sum(mare collect each.oeufs_aedes_sains));
        int   larves    <- empty(cohorte_larvaire)
                           ? 0 : int(sum(cohorte_larvaire collect each.effectif));
        save [simulation_id, cycle, nb_act, with_precision(vol_moy, 2), with_precision(niv_moy, 3),
              oeufs_inf, oeufs_san, larves,
              with_precision(ndwi_moyen_global, 4), with_precision(ndvi_moyen_global, 4)]
            to: csv_mares format: "csv" rewrite: false;
    }

    reflex export_moustiques when: export_detail {
        save [simulation_id, cycle,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "S")) * echelle_si_vecteur,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "E")) * echelle_si_vecteur,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "I")) * echelle_si_vecteur,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "S")) * echelle_si_vecteur,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "E")) * echelle_si_vecteur,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "I")) * echelle_si_vecteur,
              length(vecteur) * echelle_si_vecteur]
            to: csv_moustiques format: "csv" rewrite: false;
    }

    reflex export_memoire when: export_detail {
        save [simulation_id, cycle, length(humain), length(animal), length(vecteur),
              length(cohorte_larvaire),
              length(humain) + length(animal) + length(vecteur) + length(cohorte_larvaire)]
            to: csv_controle_memoire format: "csv" rewrite: false;
    }

    reflex stop when: cycle >= duree_simulation - 1 {
        // Les deux R0 sont calcules une seule fois, a la cloture de leur
        // propre fenetre. Si la simulation s'arrete avant, la valeur reste a
        // zero et le signale : c'est plus honnete qu'un calcul sur une fenetre
        // tronquee.
        if (!R0_animal_calcule) {
            write "ATTENTION : simulation trop courte, R0_animal non calcule ("
                + nb_jours_animal + "/" + fenetre_R0_animal + " jours).";
        }
        if (!R0_Aedes_calcule) {
            write "ATTENTION : simulation trop courte, R0_Aedes non calcule ("
                + nb_jours_aedes + "/" + fenetre_R0_aedes + " jours).";
        }

        write "========== FIN | SimID=" + simulation_id
            + " | Exp=" + type_experience + " ==========";
        write "-------- R0, CALCUL UNIQUE PAR GRANDEUR --------";
        write "R0_animal (J1-J" + fenetre_R0_animal + ") : "
            + with_precision(R0_animal_protocole, 4)
            + "   [Garrett-Jones : " + with_precision(R0_animal_capacite, 4) + "]";
        write "R0_Aedes  (J1-J" + fenetre_R0_aedes + ") : "
            + with_precision(R0_Aedes_protocole, 4)
            + "   [Garrett-Jones : " + with_precision(R0_Aedes_capacite, 4) + "]";
        write "Infections totales : " + nb_infections_totales;
        write "-------- PERSISTANCE INTER-SAISONNIÈRE --------";
        write "Œufs infectés, pic     : " + int(oeufs_inf_pic);
        write "Œufs infectés, reportés: " + int(oeufs_inf_report)
            + " (taux " + with_precision(taux_report_oeufs, 4) + ")";
        write "------------------------------------------";

        do calculer_co_abondance;
        save [simulation_id, type_experience,
              with_precision(cumul_pluie_serie, 1),
              with_precision(pluie_jour_max_serie, 1), nb_jours_pluie_serie,
              forcage_hors_enveloppe,
              int(pic_aedes), jour_pic_aedes + jour_debut_simulation,
              int(pic_culex), jour_pic_culex + jour_debut_simulation,
              decalage_pics, jours_co_abondance,
              with_precision(indice_co_abondance, 6),
              nb_infections_totales,
              with_precision(R0_animal_protocole, 6),
              with_precision(R0_Aedes_protocole, 6)]
            to: csv_validation format: "csv" rewrite: false;

        save [simulation_id, type_experience, nb_infections_totales,
              fenetre_R0_animal, fenetre_R0_aedes,
              with_precision(R0_animal_protocole, 6),
              with_precision(R0_Aedes_protocole, 6),
              with_precision(R0_animal_capacite, 6),
              with_precision(R0_Aedes_capacite, 6),
              int(oeufs_inf_pic), int(oeufs_inf_report),
              with_precision(taux_report_oeufs, 6)]
            to: csv_resume format: "csv" rewrite: false;

        do pause;
    }
}
