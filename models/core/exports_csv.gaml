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
import "../environnement/mare.gaml"
import "../environnement/cohorte_larvaire.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"
import "../agents/vecteur.gaml"

global {

    string csv_journalier       <- "../outputs/journalier.csv";
    string csv_populations      <- "../outputs/populations.csv";
    string csv_r0_vectoriel     <- "../outputs/r0_vectoriel.csv";
    string csv_r0_animal        <- "../outputs/r0_animal.csv";
    string csv_incidence        <- "../outputs/incidence.csv";
    string csv_climat           <- "../outputs/climat.csv";
    string csv_mares            <- "../outputs/mares.csv";
    string csv_moustiques       <- "../outputs/moustiques.csv";
    string csv_controle_memoire <- "../outputs/controle_memoire.csv";
    string csv_resume           <- "../outputs/resume.csv";

    bool export_detail  <- true;

    // =========================================================================
    // ACTION : INITIALISATION DES FICHIERS CSV (en-têtes), appelée depuis l'init
    // =========================================================================
    action initialiser_fichiers_csv {
        if (simulation_id = 1) {
            save ["simulation_id","cycle","jour_annee","saison","temperature_C","humidite_pct","pluie_mm","vent_ms"]
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
                  "R0_Aedes_moyen","nb_fenetres_Aedes",
                  "R0_animal_moyen","nb_fenetres_animal"]
                to: csv_resume format: "csv" rewrite: true;
        }
    }

    reflex export_journalier when: export_detail {
        save [simulation_id, cycle, jour_debut_simulation + cycle, saison,
              with_precision(temperature, 2), with_precision(humidite_relative, 2),
              with_precision(pluie, 2), with_precision(vitesse_vent, 2)]
            to: csv_journalier format: "csv" rewrite: false;
    }

    reflex export_populations when: export_detail {
        save [simulation_id, cycle,
              length(humain where (each.etat_sante = "S")) * echelle_superindividu,
              length(humain where (each.etat_sante = "E")) * echelle_superindividu,
              length(humain where (each.etat_sante = "I")) * echelle_superindividu,
              length(humain where (each.etat_sante = "R")) * echelle_superindividu,
              int(S_c_global), int(E_c_global), int(I_c_global), int(R_c_global),
              length(vecteur) * echelle_superindividu]
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
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "S")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "E")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "aedes" and each.etat_sante = "I")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "S")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "E")) * echelle_superindividu,
              length(vecteur where (each.type_vecteur = "culex" and each.etat_sante = "I")) * echelle_superindividu,
              length(vecteur) * echelle_superindividu]
            to: csv_moustiques format: "csv" rewrite: false;
    }

    reflex export_memoire when: export_detail {
        save [simulation_id, cycle, length(humain), length(animal), length(vecteur),
              length(cohorte_larvaire),
              length(humain) + length(animal) + length(vecteur) + length(cohorte_larvaire)]
            to: csv_controle_memoire format: "csv" rewrite: false;
    }

    reflex stop when: cycle >= duree_simulation - 1 {
        if (nb_jours_fenetre > 0) { do calculer_et_exporter_R0; }

        float R0_Aedes_moyen  <- (nb_R0_Aedes > 0)  ? somme_R0_Aedes / nb_R0_Aedes   : 0.0;
        float R0_animal_moyen <- (nb_R0_animal > 0) ? somme_R0_animal / nb_R0_animal : 0.0;

        write "========== FIN | SimID=" + simulation_id
            + " | Exp=" + type_experience + " ==========";
        write "R0_Aedes  (dernière fenêtre) : " + with_precision(R0_Aedes_10j, 4);
        write "R0_animal (dernière fenêtre) : " + with_precision(R0_animal_10j, 4);
        write "-------- RÉSUMÉ DE LA SIMULATION --------";
        write "Infections totales           : " + nb_infections_totales;
        write "R0_Aedes moyen (" + nb_R0_Aedes + " fenêtres)  : " + with_precision(R0_Aedes_moyen, 4);
        write "R0_animal moyen (" + nb_R0_animal + " fenêtres) : " + with_precision(R0_animal_moyen, 4);
        write "------------------------------------------";

        save [simulation_id, type_experience, nb_infections_totales,
              with_precision(R0_Aedes_moyen, 6), nb_R0_Aedes,
              with_precision(R0_animal_moyen, 6), nb_R0_animal]
            to: csv_resume format: "csv" rewrite: false;

        do pause;
    }
}
