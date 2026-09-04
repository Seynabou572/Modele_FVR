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
                draw "Vecteurs  Aedes=" + (length(vecteur where (each.type_vecteur = "aedes")) * echelle_si_vecteur)
                   + "   Culex=" + (length(vecteur where (each.type_vecteur = "culex")) * echelle_si_vecteur)
                    at: o + {0, zone_z3.height * 0.065}
                    color: #black font: font("Arial", 11, #plain);
                draw "Mares en eau : " + length(mare where (each.volume_eau > 0))
                   + " / " + length(mare)
                    at: o + {0, zone_z3.height * 0.095}
                    color: #black font: font("Arial", 11, #plain);
            }

            // ---- 7. Légende -------------------------------------------------
            graphics "legende" refresh: false {
                point o  <- {zone_z3.width * 0.70, zone_z3.height * 0.04};
                float dy <- zone_z3.height * 0.029;
                float r  <- unite_z3 * 0.006;
                float rh <- unite_z3 * 0.007;
                float rv <- unite_z3 * 0.004;
                draw "LEGENDE" at: o color: #black font: font("Arial", 11, #bold);

                draw "ANIMAUX (cercle)" at: o + {0, dy}
                    color: rgb(70,70,70) font: font("Arial", 10, #bold);
                draw circle(r) at: o + {r*1.5, dy*2} color: rgb(255,235,60)  border: rgb(60,60,60);
                draw "sain (S)"      at: o + {r*4, dy*2} color: #black font: font("Arial", 10, #plain);
                draw circle(r) at: o + {r*1.5, dy*3} color: rgb(255,150,0)   border: rgb(60,60,60);
                draw "expose (E)"    at: o + {r*4, dy*3} color: #black font: font("Arial", 10, #plain);
                draw circle(r) at: o + {r*1.5, dy*4} color: rgb(220,0,0)     border: rgb(60,60,60);
                draw "infecte (I)"   at: o + {r*4, dy*4} color: #black font: font("Arial", 10, #plain);
                draw circle(r) at: o + {r*1.5, dy*5} color: rgb(120,120,120) border: rgb(60,60,60);
                draw "gueri (R)"     at: o + {r*4, dy*5} color: #black font: font("Arial", 10, #plain);

                draw "HUMAINS (carre)" at: o + {0, dy*6.5}
                    color: rgb(70,70,70) font: font("Arial", 10, #bold);
                draw square(rh) at: o + {r*1.5, dy*7.5} color: rgb(120,200,255) border: rgb(40,40,40);
                draw "sain (S)"      at: o + {r*4, dy*7.5} color: #black font: font("Arial", 10, #plain);
                draw square(rh) at: o + {r*1.5, dy*8.5} color: rgb(255,150,0)   border: rgb(40,40,40);
                draw "expose (E)"    at: o + {r*4, dy*8.5} color: #black font: font("Arial", 10, #plain);
                draw square(rh) at: o + {r*1.5, dy*9.5} color: rgb(220,0,0)     border: rgb(40,40,40);
                draw "infecte (I)"   at: o + {r*4, dy*9.5} color: #black font: font("Arial", 10, #plain);
                draw square(rh) at: o + {r*1.5, dy*10.5} color: rgb(120,120,120) border: rgb(40,40,40);
                draw "gueri (R)"     at: o + {r*4, dy*10.5} color: #black font: font("Arial", 10, #plain);

                draw "VECTEURS" at: o + {0, dy*12}
                    color: rgb(70,70,70) font: font("Arial", 10, #bold);
                draw triangle(rv*2) at: o + {r*1.5, dy*13} color: #crimson;
                draw "Aedes (triangle)"  at: o + {r*4, dy*13} color: #black font: font("Arial", 10, #plain);
                draw circle(rv) at: o + {r*1.5, dy*14} color: #darkviolet;
                draw "Culex (rond violet)" at: o + {r*4, dy*14} color: #black font: font("Arial", 10, #plain);

                draw "ZONES" at: o + {0, dy*15.5}
                    color: rgb(70,70,70) font: font("Arial", 10, #bold);
                draw square(rh) at: o + {r*1.5, dy*16.5} color: rgb(20,110,160,0.75);
                draw "mare en eau"  at: o + {r*4, dy*16.5} color: #black font: font("Arial", 10, #plain);
                draw square(rh) at: o + {r*1.5, dy*17.5} color: rgb(162,85,34,0.5);
                draw "campement"    at: o + {r*4, dy*17.5} color: #black font: font("Arial", 10, #plain);
                draw square(rh) at: o + {r*1.5, dy*18.5} color: rgb(71,99,44,0.4);
                draw "vegetation"   at: o + {r*4, dy*18.5} color: #black font: font("Arial", 10, #plain);
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
                data "Aedes" value: length(vecteur where (each.type_vecteur = "aedes")) * echelle_si_vecteur color: #darkred;
                data "Culex" value: length(vecteur where (each.type_vecteur = "culex")) * echelle_si_vecteur color: #darkviolet;
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

        display "Climat" type: 2d {
            chart "Pluie" type: series background: #white size: {1.0,0.5} position: {0.0,0.0} axes: #black {
                data "Pluie mm/j" value: pluie color: #cyan;
            }
            chart "Température" type: series background: #white size: {1.0,0.5} position: {0.0,0.5} axes: #black {
                data "T °C" value: temperature color: #red;
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
        monitor "Aedes (individus)" value: int(length(vecteur where (each.type_vecteur = "aedes")) * echelle_si_vecteur);
        monitor "Culex (individus)" value: int(length(vecteur where (each.type_vecteur = "culex")) * echelle_si_vecteur);

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
 * Variante batch : 30 réplications sur la même fenêtre et la même base.
 */
experiment "Batch_Zone3_30rep" type: batch repeat: 30 keep_seed: false
    until: cycle >= duree_simulation - 1 {
    parameter "Base spatiale zone3" var: base_zone3 <- true;
    parameter "Jour de début"       var: jour_debut_simulation <- 182;
    parameter "Jour de fin"         var: jour_fin_simulation   <- 242;
    parameter "Durée"               var: duree_simulation      <- 60;
    parameter "Expérience"          var: type_experience <- "Animal";
    parameter "Simulation ID"       var: simulation_id   among: range(1, 30);
}
