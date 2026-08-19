/**
 * EXPÉRIENCE GUI — Animal (R0_animal)
 * Anciennement désactivée (bloc commenté dans le fichier monolithique) ;
 * réactivée ici comme expérience indépendante, sélectionnable au même titre
 * que l'expérience Aedes.
 */
model ExperimentGuiAnimal

import "../core/initialisation.gaml"

experiment "FVR Z3 — Expérience Animal (R0_animal)" type: gui {
    parameter "Expérience"        var: type_experience <- "Animal" category: "Fonctionnalités";
    parameter "NDWI binaire (assèchement forcé hors masque)" var: utiliser_ndwi_binaire <- false category: "Fonctionnalités";
    parameter "Export CSV détaillé" var: export_detail category: "Fonctionnalités";

    parameter "Simulation ID"     var: simulation_id   <- 1;
    parameter "Nb humains init"   var: nb_humains_init <- 100;
    parameter "Nb animaux init"   var: nb_animaux_init <- 500;
    parameter "Fécondité Aedes (lambda)" var: lambda_aedes min: 50.0 max: 800.0 step: 10.0;
    parameter "Transmission verticale (rho)" var: rho_aedes min: 0.0 max: 0.2 step: 0.005;
    parameter "Cycle gonotrophique τ (j)" var: tau_aedes min: 2.0 max: 10.0 step: 0.5;
    parameter "Préférence zoophile"       var: preference_zoophilie min: 0.0 max: 1.0 step: 0.05;
    parameter "Transmission Aedes→hôte (b)" var: b_aedes min: 0.01 max: 1.0 step: 0.01;
    parameter "Transmission hôte→Aedes (c)" var: c_aedes min: 0.01 max: 1.0 step: 0.01;
    parameter "Létalité δ_c"      var: delta_c  min: 0.0 max: 0.1 step: 0.005;
    parameter "Échelle SI"        var: echelle_superindividu min: 1 max: 50 step: 1;
    parameter "Plafond vecteurs"  var: max_vecteurs min: 500 max: 100000 step: 500;
    parameter "Capacité larvaire (ind/m² d'eau)" var: Emax_culex min: 10.0 max: 7000.0 step: 10.0;

    output {
        display "Carte Z3" type: java2D background: #white {
            graphics "fond_occsol" {
                loop i from: 0 to: length(fond_geoms) - 1 {
                    if (i < length(fond_classes)) {
                        draw fond_geoms[i] color: palette_occsol[fond_classes[i]];
                    }
                }
            }
            species route aspect: default; species mare aspect: default;
            species campement aspect: default; species animal aspect: default;
            species humain aspect: default; species vecteur aspect: default;
            graphics "legende" {
                draw ("Sim" + simulation_id + " | " + type_experience
                    + " | J" + (jour_debut_simulation + cycle)
                    + " | R0_anim=" + with_precision(R0_animal_10j, 3))
                    at: {shape.width * 0.02, shape.height * 0.04}
                    color: #black font: font("Times New Roman", 12, #bold);
            }
        }

        display "SEIR — Humains" type: 2d {
            chart "Humains" type: series background: #white axes: #black {
                data "S" value: S_h_global color: #green;
                data "E" value: E_h_global color: #yellow;
                data "I" value: I_h_global color: #red;
                data "R" value: R_h_global color: #gray;
            }
        }

        display "SEIR — Animaux" type: 2d {
            chart "Animaux" type: series background: #white axes: #black {
                data "S" value: S_c_global color: #green;
                data "E" value: E_c_global color: rgb(252,211,77);
                data "I" value: I_c_global color: #red;
                data "R" value: R_c_global color: #blue;
            }
        }
        display "R₀ animal (10j)" type: 2d {
            chart "R₀ = C/r" type: series background: #white axes: #black {
                data "R0_animal" value: R0_animal_10j color: #darkorange;
                data "Seuil=1"   value: 1.0           color: #red;
            }
        }

        display "R₀ local (par gîte)" type: 2d {
            chart "R₀ mare par mare" type: series background: #white axes: #black {
                data "R0 local médian" value: R0_local_median color: #teal;
                data "R0 local max"    value: R0_local_max    color: #crimson;
                data "R0 global (zone)" value: R0_animal_10j  color: #darkorange;
                data "Seuil=1"         value: 1.0             color: #red;
            }
        }

        display "Climat" type: 2d {
            chart "Pluie"     type: series background: #white size: {0.5,0.5} position: {0.0,0.0} axes: #black { data "Pluie" value: pluie color: #cyan; }
            chart "Temp"      type: series background: #white size: {0.5,0.5} position: {0.5,0.0} axes: #black { data "T°C" value: temperature color: #red; }
            chart "Humidité"  type: series background: #white size: {0.5,0.5} position: {0.0,0.5} axes: #black { data "RH %" value: humidite_relative color: #blue; }
            chart "Vent"      type: series background: #white size: {0.5,0.5} position: {0.5,0.5} axes: #black { data "Vent m/s" value: vitesse_vent color: #darkgray; }
        }

        display "Mares & Biomasse" type: 2d {
            chart "Niveau mares" type: series background: #white size: {1.0,0.5} position: {0.0,0.0} axes: #black {
                data "Niveau moy" value: (empty(mare)) ? 0.0 : mean(mare collect each.niveau_mare) color: #blue;
            }
            chart "Biomasse moyenne" type: series background: #white size: {1.0,0.5} position: {0.0,0.5} axes: #black {
                data "Biomasse moyenne" value: (empty(vegetation)) ? 0.0 : mean(vegetation collect each.biomasse) color: #olive;
            }
        }

        display "Indices satellite" type: 2d {
            chart "NDVI / NDWI moyens" type: series background: #white axes: #black {
                data "NDVI moyen (végétation)" value: ndvi_moyen_global color: #darkgreen;
                data "NDWI moyen (mares)"      value: ndwi_moyen_global color: #blue;
            }
        }

        monitor "R0_animal (10j)" value: with_precision(R0_animal_10j, 4) color: #darkorange;
        monitor "m_animal"        value: with_precision(m_animal_10j, 4);
        monitor "a_animal"        value: with_precision(a_animal_10j, 4);
        monitor "C_animal"        value: with_precision(C_animal_10j, 4);
        monitor "Fenêtre"         value: num_fenetre;

        monitor "Gîtes évalués"   value: nb_mares_evaluees;
        monitor "R0 local médian" value: with_precision(R0_local_median, 4) color: #teal;
        monitor "R0 local max"    value: with_precision(R0_local_max, 4) color: #crimson;
        monitor "Gîtes R0>1"      value: nb_mares_R0_sup1 color: #crimson;
        monitor "Part gîtes R0>1" value: with_precision(part_mares_R0_sup1 * 100.0, 1);

        monitor "Humains S"       value: int(S_h_global) color: #green;
        monitor "Humains E"       value: int(E_h_global) color: #goldenrod;
        monitor "Humains I"       value: int(I_h_global) color: #red;
        monitor "Humains R"       value: int(R_h_global) color: #gray;

        monitor "Animaux I"       value: int(I_c_global) color: #red;
        monitor "Humidité %"      value: with_precision(humidite_relative, 1);
        monitor "Vent m/s"        value: with_precision(vitesse_vent, 1);
        monitor "Facteur humidité" value: with_precision(facteur_humidite, 3);
        monitor "Facteur vent"    value: with_precision(facteur_vent, 3);
        monitor "NDVI moyen"      value: with_precision(ndvi_moyen_global, 3) color: #darkgreen;
        monitor "NDWI moyen"      value: with_precision(ndwi_moyen_global, 3) color: #blue;

        monitor "Infections totales (cumul)"  value: nb_infections_totales color: #red;
        monitor "R0_animal moyen (cumul)"     value: (nb_R0_animal > 0) ? with_precision(somme_R0_animal / nb_R0_animal, 4) : 0.0;
    }
}
