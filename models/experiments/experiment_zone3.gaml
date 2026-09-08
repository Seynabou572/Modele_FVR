/**
 * EXPÉRIENCE ZONE3 — fenêtre de saison des pluies sur la couche métrique.
 *
 * Reprend la durée de simulation de la branche `na` — J182 à J242, 60 jours,
 * soit du 1er juillet au 30 août — et l'applique sur `zone3_entrainements`
 * comme base spatiale.
 *
 * POURQUOI CETTE FENÊTRE. Le calendrier des saisons place Nduungu de J182 à
 * J304 (core/saisons_occsol.gaml). La fenêtre J182-J242 est donc entièrement
 * contenue dans la saison des pluies, et démarre le jour même où elle commence.
 * C'est une fenêtre MONO-SAISON : `mettre_a_jour_occsol_saisonnier` n'est jamais
 * déclenché pendant le run. Deux conséquences à garder en tête :
 *
 *   - l'appariement saisonnier des mares n'a pas lieu, donc l'état hydrique
 *     n'est jamais réinitialisé — c'est un avantage pour le calage du bilan ;
 *   - le taux de report inter-saisonnier des œufs infectés
 *     (`taux_report_oeufs`, relevé à l'entrée en Nduungu) reste à zéro. La
 *     persistance ne se mesure pas sur une fenêtre qui ne franchit aucune
 *     saison sèche : pour cet indicateur, utiliser les expériences Aedes ou
 *     Animal, qui couvrent J152-J334.
 *
 * POURQUOI CETTE BASE SPATIALE. `zone3_entrainements` est la seule couche du
 * jeu de données nativement projetée en UTM 28N. En la prenant pour enveloppe,
 * `unite_z3` vaut 30 410 m par construction au lieu de dépendre d'une
 * reprojection implicite depuis des degrés. Les rayons de perception, de vol et
 * de dépôt d'œufs, tous exprimés en fraction d'`unite_z3`, deviennent donc
 * déterministes.
 *
 * La branche `na` ne va qu'à moitié au bout de ce raisonnement : elle branche
 * zone3 sur l'entrée « Nduungu » de `occsol_shp_saisons`, ce qui fixe le `shape`
 * du monde, mais laisse `zone_z3` sur `OCCSOL_SHP`, en degrés. Or c'est
 * `zone_z3` qui donne `unite_z3` et donc tous les rayons. Ici les deux sont
 * alignées sur la même couche métrique.
 *
 * La durée de 60 jours donne, avec la fenêtre R0 de 21 jours de l'expérience
 * Aedes, deux fenêtres complètes plus une partielle clôturée à l'arrêt ; avec
 * celle de 10 jours de l'expérience Animal, six fenêtres complètes.
 */
model ExperimentZone3

import "../core/initialisation.gaml"

// Nom volontairement ASCII et sans espace : il sert d'argument au lanceur
// headless (gama-headless -xml <nom> <modele> <sortie>), qui ne gere ni les
// cadratins ni les accents sur la ligne de commande.
experiment Zone3_J182_J242 type: gui {

    // ---- Base spatiale et calendrier : le cœur de cette expérience ----
    parameter "Base spatiale zone3_entrainements (UTM 28N)"
        var: base_zone3 <- true category: "Cadre";
    parameter "Jour de début (DOY)"
        var: jour_debut_simulation <- 182 category: "Cadre";
    parameter "Jour de fin (DOY)"
        var: jour_fin_simulation   <- 242 category: "Cadre";
    parameter "Durée (jours)"
        var: duree_simulation      <- 60  category: "Cadre";

    parameter "Expérience" var: type_experience <- "Animal" category: "Cadre";
    parameter "Export CSV détaillé" var: export_detail category: "Cadre";
    parameter "Pas d'export des zones (cycles)"
        var: pas_export_zones min: 1 max: 30 step: 1 category: "Cadre";

    parameter "Simulation ID"   var: simulation_id   <- 1;
    parameter "Nb humains init" var: nb_humains_init <- 100;
    parameter "Nb animaux init" var: nb_animaux_init <- 500;

    // ---- Hydrologie : les trois paramètres que l'analyse de sensibilité de
    // Soti et al. (2010) place en tête, devant la forme de la mare et le
    // bassin versant. Bornes = plages publiées.
    parameter "Seuil de ruissellement Gmax (mm/j)"
        var: Gmax_defaut min: 10.0 max: 20.0 step: 0.5 category: "Hydrologie";
    parameter "Coefficient de ruissellement Kr"
        var: Kr_defaut min: 0.15 max: 0.40 step: 0.01 category: "Hydrologie";
    parameter "Pertes journalières L (mm/j)"
        var: L_perte_defaut min: 5.0 max: 20.0 step: 0.5 category: "Hydrologie";
    parameter "Exposant de forme alpha"
        var: alpha_forme_defaut min: 1.0 max: 3.0 step: 0.1 category: "Hydrologie";
    parameter "Bassin versant, lit du Ferlo (n x Amax)"
        var: n_bassin_lit min: 1.0 max: 20.0 step: 0.5 category: "Hydrologie";
    parameter "Bassin versant, hors lit (n x Amax)"
        var: n_bassin_hors_lit min: 1.0 max: 20.0 step: 0.5 category: "Hydrologie";

    // Reservoir d'oeufs quiescents present au demarrage : sans lui, aucun Aedes
    // ne peut emerger (Soti et al. 2012 : 1000 oeufs/m2 sur les mares de Barkedji).
    parameter "Oeufs Aedes initiaux (par m² de berge)"
        var: densite_oeufs_initiale_aedes min: 0.0 max: 5000.0 step: 50.0 category: "Vecteurs";
    parameter "Part infectée du stock initial"
        var: prevalence_oeufs_initiale min: 0.0 max: 0.2 step: 0.005 category: "Vecteurs";
    parameter "Fécondité Aedes (lambda)" var: lambda_aedes min: 50.0 max: 800.0 step: 10.0 category: "Vecteurs";
    parameter "Transmission verticale (rho)" var: rho_aedes min: 0.0 max: 0.2 step: 0.005 category: "Vecteurs";
    parameter "Capacité larvaire (ind/m² d'eau)" var: Emax_culex min: 10.0 max: 7000.0 step: 10.0 category: "Vecteurs";
    parameter "Plafond vecteurs" var: max_vecteurs min: 500 max: 100000 step: 500 category: "Vecteurs";

    output {

        // =====================================================================
        // CARTE PRINCIPALE — agents visibles pendant TOUTE la simulation.
        //
        // Ordre de dessin = ordre de déclaration : le fond en premier, les
        // agents mobiles en dernier pour qu'aucun polygone ne les recouvre.
        // Les zones de végétation peuvent faire jusqu'à 1.8 km² : dessinées
        // après les agents, elles les masqueraient entièrement.
        //
        // `refresh: true` sur chaque couche mobile — sans quoi GAMA peut figer
        // l'affichage d'une espèce et donner l'impression que les agents ont
        // disparu alors qu'ils se déplacent bien.
        // =====================================================================
        display "Carte Zone3" type: java2D background: #white refresh: every(1 #cycle) {

            // ---- 1. Fond : zones d'occupation du sol -------------------------
            species zone_suivi aspect: fond refresh: false;

            // ---- 2. Réseau routier ------------------------------------------
            species route aspect: default refresh: false;

            // ---- 3. Gîtes : la surface en eau varie tous les jours -----------
            species mare aspect: default refresh: true;

            // ---- 4. Hôtes : position ET état sanitaire changent chaque pas ---
            species animal aspect: default refresh: true;
            species humain aspect: default refresh: true;

            // ---- 5. Vecteurs, au premier plan -------------------------------
            species vecteur aspect: default refresh: true;

            // ---- 6. Bandeau d'état ------------------------------------------
            graphics "bandeau" refresh: true {
                point o <- {zone_z3.width * 0.02, zone_z3.height * 0.04};
                draw "J" + (jour_debut_simulation + cycle) + "  ·  " + saison
                   + "  ·  cycle " + cycle + " / " + duree_simulation
                    at: o color: #black font: font("Arial", 13, #bold);
                draw "Hôtes  S=" + int(S_c_global) + "  E=" + int(E_c_global)
                   + "  I=" + int(I_c_global) + "  R=" + int(R_c_global)
                    at: o + {0, zone_z3.height * 0.035}
                    color: #black font: font("Arial", 11, #plain);
                    draw "Vecteurs  Aedes=" + length(vecteur where (each.type_vecteur = "aedes"))
                         + "   Culex=" + length(vecteur where (each.type_vecteur = "culex"))
                    at: o + {0, zone_z3.height * 0.065}
                    color: #black font: font("Arial", 11, #plain);
                draw "Mares en eau : " + length(mare where (each.volume_eau > 0))
                   + " / " + length(mare)
                    at: o + {0, zone_z3.height * 0.095}
                    color: #black font: font("Arial", 11, #plain);
            }

            graphics "legende" refresh: false {
                point o <- {zone_z3.width * 0.72, zone_z3.height * 0.05};
                draw "LEGENDE" at: o color: #black font: font("Arial", 11, #bold);
                float d <- zone_z3.height * 0.032;
                float r <- unite_z3 * 0.004;
                draw circle(r) at: o + {r, d} color: #yellow border: #black;
                draw "Animaux (cercle)" at: o + {r * 3, d} color: #black font: font("Arial", 9, #plain);
                draw square(r) at: o + {r, d * 2} color: rgb(120,200,255) border: #black;
                draw "Humains (carre)" at: o + {r * 3, d * 2} color: #black font: font("Arial", 9, #plain);
                draw triangle(r * 1.5) at: o + {r, d * 3} color: #crimson;
                draw "Aedes (triangle)" at: o + {r * 3, d * 3} color: #black font: font("Arial", 9, #plain);
                draw circle(r * 0.75) at: o + {r, d * 4} color: #darkviolet;
                draw "Culex (cercle violet)" at: o + {r * 3, d * 4} color: #black font: font("Arial", 9, #plain);
                draw "Mare : bleu clair, eau : bleu fonce" at: o + {0, d * 5} color: #black font: font("Arial", 9, #plain);
                draw "Campement : marron fonce" at: o + {0, d * 6} color: #black font: font("Arial", 9, #plain);
                draw "Vegetation : vert fonce" at: o + {0, d * 7} color: #black font: font("Arial", 9, #plain);
            }

        }

        // =====================================================================
        // FOYERS — où l'infection est apparue. Une zone passe au rouge dès que
        // son `jour_premiere_infection` est renseigné ; l'intensité suit le
        // cumul de cas. C'est la lecture spatiale que le protocole demande.
        // =====================================================================
        display "Foyers par zone" type: java2D background: #white {
            graphics "zones_touchees" {
                loop z over: zone_suivi {
                    if (z.jour_premiere_infection >= 0) {
                        draw z.shape color: rgb(200, 30, 30, 0.55) border: #darkred;
                    } else {
                        draw z.shape color: rgb(200, 200, 200, 0.20) border: rgb(180,180,180,0.4);
                    }
                }
            }
            graphics "titre_foyers" {
                draw "Zones ayant connu au moins une infection : "
                    + length(zone_suivi where (each.jour_premiere_infection >= 0))
                    + " / " + length(zone_suivi)
                    at: {zone_z3.width * 0.02, zone_z3.height * 0.05}
                    color: #black font: font("Arial", 11, #bold);
            }
        }

        display "Hydrologie des mares" type: 2d {
            chart "Volume et niveau moyens" type: series background: #white axes: #black {
                data "Volume moyen (m³)" value: empty(mare) ? 0.0 : mean(mare collect each.volume_eau) color: #teal;
                data "Mares en eau"      value: length(mare where (each.volume_eau > 0)) color: #navy;
            }
        }

        display "Vecteurs — co-abondance" type: 2d {
            chart "Abondance des deux espèces (individus réels)" type: series background: #white axes: #black {
                data "Aedes" value: length(vecteur where (each.type_vecteur = "aedes")) color: #darkred;
                data "Culex" value: length(vecteur where (each.type_vecteur = "culex")) color: #darkviolet;
            }
        }

        display "SEIR animaux" type: 2d {
            chart "Animaux" type: series background: #white axes: #black {
                data "S" value: S_c_global color: #green;
                data "E" value: E_c_global color: #orange;
                data "I" value: I_c_global color: #red;
                data "R" value: R_c_global color: #blue;
            }
        }

        display "SEIR humains" type: 2d {
            chart "Humains" type: series background: #white axes: #black {
                data "S" value: S_h_global color: #green;
                data "E" value: E_h_global color: #orange;
                data "I" value: I_h_global color: #red;
                data "R" value: R_h_global color: #blue;
            }
        }

        display "Climat" type: 2d {
            chart "Pluie" type: series background: #white size: {1.0,0.33} position: {0.0,0.0} axes: #black {
                data "Pluie mm/j" value: pluie color: #cyan;
            }
            chart "Température" type: series background: #white size: {1.0,0.33} position: {0.0,0.33} axes: #black {
                data "T °C" value: temperature color: #red;
            }
            chart "Humidité" type: series background: #white size: {0.5,0.34} position: {0.0,0.66} axes: #black {
                data "RH %" value: humidite_relative color: #blue;
            }
            chart "Vent" type: series background: #white size: {0.5,0.34} position: {0.5,0.66} axes: #black {
                data "Vent m/s" value: vitesse_vent color: #darkgray;
            }
        }

        monitor "Jour DOY"        value: jour_debut_simulation + cycle;
        monitor "Saison"          value: saison;
        monitor "unite_z3 (m)"    value: with_precision(unite_z3, 0);
        monitor "Base zone3"      value: base_zone3;
        monitor "Forçage hors enveloppe" value: forcage_hors_enveloppe;
        monitor "Cumul pluie série mm"   value: with_precision(cumul_pluie_serie, 0);

        monitor "Zones chargées"  value: length(zone_suivi);
        monitor "dont campements" value: length(zone_suivi where (each.type_zone = "campement"));
        monitor "Zones avec infection"  value: length(zone_suivi where (each.jour_premiere_infection >= 0));
        monitor "Campements touchés"    value: length(zone_suivi where (each.type_zone = "campement" and each.jour_premiere_infection >= 0));

        monitor "Mares en eau"    value: length(mare where (each.volume_eau > 0));
        monitor "Niveau moyen"    value: with_precision(empty(mare) ? 0.0 : mean(mare collect each.niveau_mare), 3);
        monitor "Aedes (agents)" value: length(vecteur where (each.type_vecteur = "aedes"));
        monitor "Culex (agents)" value: length(vecteur where (each.type_vecteur = "culex"));

        monitor "Jours fenêtre animal" value: nb_jours_animal;
        monitor "Jours fenêtre Aedes"  value: nb_jours_aedes;
        monitor "R0 protocole (animal)" value: with_precision(R0_animal_protocole, 4) color: #darkorange;
        monitor "R0 protocole (Aedes)"  value: with_precision(R0_Aedes_protocole, 4) color: #purple;
        monitor "R0 vectoriel médian"   value: with_precision(
            empty(mare) ? 0.0 : median(mare collect each.R0_vectoriel), 4) color: #seagreen;
        monitor "Infections totales"    value: nb_infections_totales color: #red;
    }
}

/**
 * Variante batch : 50 réplications sur la même fenêtre et la même base.
 */
experiment "Batch_Zone3_50rep" type: batch repeat: 50 keep_seed: false
    until: cycle >= duree_simulation - 1 {
    parameter "Base spatiale zone3" var: base_zone3 <- true;
    parameter "Jour de début"       var: jour_debut_simulation <- 182;
    parameter "Jour de fin"         var: jour_fin_simulation   <- 242;
    parameter "Durée"               var: duree_simulation      <- 60;
    parameter "Expérience"          var: type_experience <- "Animal";
    parameter "Simulation ID"       var: simulation_id   among: range(1, 50);
}

experiment "Batch_Zone3_Aedes_50rep" type: batch repeat: 50 keep_seed: false
    until: cycle >= duree_simulation - 1 {
    parameter "Base spatiale zone3" var: base_zone3 <- true;
    parameter "Jour de début"       var: jour_debut_simulation <- 182;
    parameter "Jour de fin"         var: jour_fin_simulation   <- 242;
    parameter "Durée"               var: duree_simulation      <- 60;
    parameter "Expérience"          var: type_experience <- "Aedes";
    parameter "Simulation ID"       var: simulation_id   among: range(1, 50);
}
