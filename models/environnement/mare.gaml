/**
 * MARE — dynamique hydrique + réservoir d'œufs quiescents Aedes.
 *
 * La mare ne produit plus d'adultes directement : elle alimente des
 * `cohorte_larvaire` qui portent le délai de développement (voir
 * environnement/cohorte_larvaire.gaml).
 *
 * Deux réservoirs distincts :
 *  - œufs quiescents Aedes (infectés / sains) : pondus sur sol sec, survie
 *    journalière `phi_aedes`, éclosion déclenchée par l'INONDATION après une
 *    période sèche suffisante ;
 *  - pontes Culex du jour : déposées sur eau libre, converties en cohorte le
 *    jour même.
 */
model Mare

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../core/saisons_occsol.gaml"
import "../core/biologie_thermique.gaml"
import "cohorte_larvaire.gaml"
// Requis par la ZPOM : indice de fermeture du paysage et recensement des hôtes
// dans les anneaux de vol.
import "vegetation.gaml"
import "../agents/humain.gaml"
import "../agents/animal.gaml"

species mare {
    float volume_eau           <- 0.0;
    float surface_eau          <- 0.0;
    float surface_max          <- 500.0;

    // Réservoir d'œufs quiescents Aedes, en individus réels (float : la survie
    // journalière doit pouvoir s'appliquer de façon continue).
    float oeufs_aedes_infectes <- 0.0;
    float oeufs_aedes_sains    <- 0.0;
    bool  oeufs_index          <- false;   // trace le cas index de l'expérience

    // Accumulateur des pontes Culex de la journée (converti en cohorte le soir).
    float pontes_culex_jour    <- 0.0;

    int   jours_sans_pluie     <- 0;
    int   duree_secheresse_prec <- 0;      // durée du dernier épisode sec ACHEVÉ
    float volume_max_reference <- 300.0;   // m³, recalculé par calibrer_geometrie
    float niveau_mare          <- 0.0;     // h / hauteur_max, dans [0,1]
    float Iap                  <- 0.0;     // indice de précipitation antécédente (mm)

    // =========================================================================
    // PARAMÈTRES DU BILAN HYDRIQUE — Soti et al. 2010, Hydrol. Earth Syst. Sci.
    // 14, 1449-1464 : modèle calibré sur les mares de Barkedji elles-mêmes,
    // validé à Nash > 0.7 sur quatre d'entre elles. Les plages documentées sont
    // rappelées en regard de chaque valeur.
    //
    // L'analyse de sensibilité de cette étude classe l'influence des paramètres
    // dans cet ordre : les propriétés de sol (Gmax, k_sol) et le coefficient de
    // perte L pèsent DAVANTAGE que la forme de la mare et que l'estimation du
    // bassin versant. Les trois premiers sont donc les seuls à régler en
    // priorité en cas d'écart aux hauteurs d'eau observées.
    // =========================================================================
    // Chaque gîte hérite des valeurs globales à sa création : elles restent
    // ainsi réglables depuis les expériences, tout en pouvant être différenciées
    // par mare le jour où une couche pédologique le permettra.
    float L_perte      <- L_perte_defaut;     // pertes journalières, mm/j     [Soti : 5-20]
    float k_sol        <- k_sol_defaut;       // décroissance de l'humidité    [Soti : 0-1]
    float Gmax         <- Gmax_defaut;        // seuil de ruissellement, mm/j  [Soti : 10-20]
    float Kr           <- Kr_defaut;          // coefficient de ruissellement  [Soti : 0.15-0.40]
    float alpha_forme  <- alpha_forme_defaut; // exposant de la loi A(h)       [Soti : 1-3]
    float hauteur_max  <- hauteur_max_defaut; // profondeur maximale du gîte, m

    // Le lit principal du Ferlo draine un bassin versant bien plus large que
    // les dépressions hors lit, dont le remplissage tient surtout à la pluie
    // directe et au ruissellement de proximité (Soti : « two sets of ponds »).
    bool  est_ensemble1 <- true;

    // Géométrie dérivée de surface_max par calibrer_geometrie (voir plus bas).
    float S0_mare        <- 0.0;  // surface en eau à h = 1 m, m²
    float V0_mare        <- 0.0;  // volume à h = 1 m, m³
    float bassin_versant <- 0.0;  // Ac, m²

    float niveau_precedent <- 0.0;
    float montee_niveau    <- 0.0;

    float ndwi_local      <- 0.2;
    float ndwi_precedent  <- 0.2;

    bool  appariee <- false;   // transitoire : appariement au changement de saison

    // =========================================================================
    // ACCUMULATEURS DU R0 LOCAL (fenêtre de 10 jours)
    // Le R0 global est une moyenne sur toute la zone : il mélange les mares
    // fréquentées par le bétail et celles qui ne le sont pas, ce qui écrase le
    // signal. Les R0 publiés pour le Ferlo sont au contraire cartographiés
    // point par point. On accumule donc ici, par gîte, de quoi calculer un R0
    // local comparable à ces cartes.
    // =========================================================================
    float loc_vect_jours   <- 0.0;   // vecteurs-jours issus de ce gîte
    float loc_aedes_jours  <- 0.0;   // dont Aedes (pour la composition b/c)
    float loc_bites        <- 0.0;   // piqûres prises par ces vecteurs
    float loc_morts        <- 0.0;   // morts biologiques de ces vecteurs
    float loc_hotes_jours  <- 0.0;   // hôtes-jours présents dans le rayon de vol
    int   loc_jours        <- 0;

    float R0_local     <- 0.0;
    float m_local      <- 0.0;
    float a_local      <- 0.0;
    float p_local      <- 0.0;
    float hotes_moyens <- 0.0;

    // =========================================================================
    // R0 VECTORIEL DE GÎTE — Porphyre, Bicout & Sabatier 2005, Ecol. Modelling
    // 183, 173-181.
    //
    //     R0(t,T) = rho(t,T) · Lambda / mu
    //     rho(t,T) = S(t | t-T) · S(t-T) / Sm²
    //
    // Lambda : capacité de production vectorielle du gîte (vecteurs/jour)
    // 1/mu   : espérance de vie de l'adulte
    // T      : durée de développement œuf -> émergence
    // rho    : fonction de disponibilité, dans [0,1] — le RECOUVREMENT entre la
    //          surface de ponte à t-T et la surface d'émergence à t.
    //
    // C'est cette grandeur, et non le R0 de Ross-Macdonald, qui mesure « la
    // dynamique du vecteur » : elle est définie gîte par gîte et pas de temps
    // par pas de temps. Elle ne fait pas intervenir rho_aedes — la transmission
    // verticale n'entre ni dans ce R0 ni dans celui de Ross-Macdonald.
    //
    // Chez Ae. vexans, la surface de ponte est la BERGE EXONDÉE (surface_max -
    // surface_eau) et l'émergence a lieu sur la part de cette berge que la
    // remontée du plan d'eau a submergée entre t-T et t.
    // =========================================================================
    list<float> historique_surface <- [];
    float rho_recouvrement <- 0.0;   // rho(t,T), dans [0,1]
    float lambda_gite      <- 0.0;   // Lambda, capacité de production
    float R0_vectoriel     <- 0.0;   // R0(t,T)

    action calculer_R0_vectoriel {
        int T <- max(1, int(world.duree_dev_larvaire(temperature, "aedes")));
        int n <- length(historique_surface);

        if (n <= T or surface_max <= 0.0) {
            rho_recouvrement <- 0.0; lambda_gite <- 0.0; R0_vectoriel <- 0.0;
        } else {
            float A_t   <- historique_surface[n - 1];       // surface aujourd'hui
            float A_tmT <- historique_surface[n - 1 - T];   // surface il y a T jours

            // S(t-T) : berge exondée au moment de la ponte.
            float S_ponte <- max(0.0, surface_max - A_tmT);
            // S(t|t-T) : part de cette berge désormais sous l'eau.
            float S_emerg <- max(0.0, A_t - A_tmT);

            rho_recouvrement <- min(1.0,
                (S_emerg * S_ponte) / (surface_max * surface_max));

            // Termes statiques regroupés (Porphyre, éq. 3) : fécondité par
            // cycle, succès œuf -> larve, survie des stades aquatiques sur T
            // jours.
            lambda_gite <- lambda_aedes * kappa_aedes * beta_aedes
                         * (survie_larvaire_aedes ^ T);

            float mu <- world.mortalite_adulte_journaliere(
                            temperature, humidite_relative, "aedes");
            R0_vectoriel <- (mu > 0.0) ? (rho_recouvrement * lambda_gite / mu) : 0.0;
        }
    }

    /**
     * Hôtes présents dans le rayon de vol des vecteurs du gîte. C'est la
     * population réellement exposée aux moustiques issus de cette mare.
     */
    reflex comptabiliser_hotes_local {
        int nb <- length(animal at_distance portee_vol_aedes_m)
                + length(humain at_distance portee_vol_aedes_m);
        loc_hotes_jours <- loc_hotes_jours + float(nb);
        loc_jours       <- loc_jours + 1;
    }

    /**
     * R0 de Ross-Macdonald restreint à ce gîte et à sa population d'hôtes.
     * Renvoie 0 si le gîte n'a produit aucun vecteur ou n'a aucun hôte à portée.
     */
    action calculer_R0_local {
        hotes_moyens <- (loc_jours > 0) ? (loc_hotes_jours / float(loc_jours)) : 0.0;
        float hotes_reels <- hotes_moyens * float(echelle_superindividu);

        if (loc_vect_jours <= 0.0 or hotes_reels <= 0.0 or loc_jours = 0) {
            m_local <- 0.0; a_local <- 0.0; p_local <- 0.0; R0_local <- 0.0;
        } else {
            float vect_reels <- (loc_vect_jours / float(loc_jours)) * float(echelle_si_vecteur);
            m_local <- vect_reels / hotes_reels;
            a_local <- loc_bites / loc_vect_jours;
            p_local <- max(0.0, min(0.999, 1.0 - loc_morts / loc_vect_jours));

            // Compétence pondérée par la composition Aedes/Culex du gîte
            float part_ae <- loc_aedes_jours / loc_vect_jours;
            float b_loc <- b_aedes * part_ae + b_culex * (1.0 - part_ae);
            float c_loc <- c_aedes * part_ae + c_culex * (1.0 - part_ae);

            float C_loc <- world.composante_C(m_local, a_local, p_local, n_animal, b_loc, c_loc);
            R0_local <- (r_hote > 0.0) ? (C_loc / r_hote) : 0.0;
        }
    }

    action reinitialiser_accumulateurs_locaux {
        loc_vect_jours  <- 0.0;
        loc_aedes_jours <- 0.0;
        loc_bites       <- 0.0;
        loc_morts       <- 0.0;
        loc_hotes_jours <- 0.0;
        loc_jours       <- 0;
    }

    reflex mise_a_jour_ndwi when: (cycle mod 3 = 0) {
        ndwi_precedent <- ndwi_local;
        ndwi_local     <- world.ndwi_moyen_au_point(location, 40.0);
    }

    // =========================================================================
    // GÉOMÉTRIE VOLUME - SURFACE - HAUTEUR (Soti et al. 2010, éq. 6 et 7)
    //
    //     A(h) = S0 · (h/h0)^alpha
    //     V(h) = V0 · (h/h0)^(alpha+1),   V0 = S0·h0 / (alpha+1)
    //
    // avec h0 = 1 m par convention. En posant que la mare atteint la surface
    // cartographiée `surface_max` à sa profondeur maximale, S0 s'en déduit et
    // le volume maximal vaut simplement Amax · h_max / (alpha+1).
    //
    // Remplace `surface_eau <- volume_eau * 2.0`, un proxy linéaire qui rendait
    // la surface — donc l'évaporation et la pluie directe — indépendante de la
    // forme réelle du gîte.
    // =========================================================================
    action calibrer_geometrie {
        S0_mare <- surface_max / (hauteur_max ^ alpha_forme);
        V0_mare <- S0_mare / (alpha_forme + 1.0);
        volume_max_reference <- max(1.0, V0_mare * (hauteur_max ^ (alpha_forme + 1.0)));
        bassin_versant <- (est_ensemble1 ? n_bassin_lit : n_bassin_hors_lit) * surface_max;
        do construire_zpom;
    }

    // =========================================================================
    // ZPOM — ZONE POTENTIELLEMENT OCCUPÉE PAR LES MOUSTIQUES
    // Vignolles et al. 2009, Geospatial Health 3(2), 211-220.
    //
    // La ZPOM est le gîte augmenté de la portée de vol du vecteur. C'est
    // l'unité spatiale du risque : croisée avec la présence des hôtes (les
    // parcs à bétail), elle donne « aléa x vulnérabilité ». La densité
    // d'Ae. vexans décroît linéairement jusqu'à 500 m du gîte (Bâ et al. 2005),
    // et l'espèce dépasse rarement 1 km.
    //
    // Les trois rayons sont ceux de Soti et al. (2009), qui identifient 500 m
    // comme l'échelle à laquelle l'indice de fermeture du paysage explique le
    // mieux l'incidence sérologique (AICc = 25.4, p < 0.001). Conserver les
    // trois permet de reproduire leur comparaison plutôt que de la présupposer.
    // =========================================================================
    geometry zpom_100  <- nil;
    geometry zpom_500  <- nil;
    geometry zpom_1000 <- nil;

    // Indice de fermeture du paysage dans le tampon de 500 m : fraction de la
    // surface couverte par des formations ligneuses (arborées / arbustives).
    // Calculé une fois par saison, la couche végétation étant statique entre
    // deux changements d'occupation du sol.
    float fermeture_500 <- 0.0;

    // Hôtes présents dans chaque anneau (individus réels).
    int hotes_zpom_100  <- 0;
    int hotes_zpom_500  <- 0;
    int hotes_zpom_1000 <- 0;

    action construire_zpom {
        zpom_100  <- shape buffer rayon_zpom_court;
        zpom_500  <- shape buffer rayon_zpom_moyen;
        zpom_1000 <- shape buffer rayon_zpom_long;

        float aire <- zpom_500.area;
        if (aire > 0.0) {
            list<vegetation> vg <- vegetation overlapping zpom_500;
            list<vegetation> fermees <- vg where (each.formation in formations_fermees);
            float a_fermee <- 0.0;
            loop v over: fermees {
                geometry inter <- v.shape inter zpom_500;
                if (inter != nil) { a_fermee <- a_fermee + inter.area; }
            }
            fermeture_500 <- min(1.0, a_fermee / aire);
        } else {
            fermeture_500 <- 0.0;
        }
    }

    /**
     * Hôtes dans l'anneau de 500 m, l'échelle analytique retenue par Soti.
     * Les anneaux de 100 et 1000 m ne sont recensés qu'au moment de l'export,
     * pour ne pas payer trois requêtes spatiales par gîte et par jour.
     */
    reflex recenser_zpom {
        if (zpom_500 != nil) {
            hotes_zpom_500 <- length(animal overlapping zpom_500)
                             + length(humain overlapping zpom_500);
        }
    }

    action recenser_zpom_complet {
        if (zpom_100 != nil) {
            hotes_zpom_100 <- length(animal overlapping zpom_100)
                             + length(humain overlapping zpom_100);
        }
        if (zpom_1000 != nil) {
            hotes_zpom_1000 <- length(animal overlapping zpom_1000)
                              + length(humain overlapping zpom_1000);
        }
    }

    /** Hauteur d'eau (m) obtenue en inversant V(h). */
    float hauteur_pour_volume(float v) {
        if (v <= 0.0 or V0_mare <= 0.0) { return 0.0; }
        return (v / V0_mare) ^ (1.0 / (alpha_forme + 1.0));
    }

    /** Surface en eau (m²) déduite du volume : A = S0 · (V/V0)^(alpha/(alpha+1)). */
    float surface_pour_volume(float v) {
        if (v <= 0.0 or V0_mare <= 0.0) { return 0.0; }
        return min(surface_max,
                   S0_mare * ((v / V0_mare) ^ (alpha_forme / (alpha_forme + 1.0))));
    }

    // =========================================================================
    // BILAN HYDRIQUE JOURNALIER — Soti et al. 2010, éq. 1 à 5
    //
    //     dV/dt  = P(t)·A(t) + Qin(t) − L·A(t)        [m³/j]
    //     Qin(t) = Kr · Pe(t) · Ac                     ruissellement du BV
    //     Pe(t)  = max(P − G, 0),  G = max(Gmax − Iap, 0)
    //
    // Les termes de pluie et de perte sont proportionnels à la SURFACE EN EAU.
    // La version précédente ajoutait la pluie en millimètres directement au
    // volume et faisait décroître l'évaporation avec le volume (L · V/100), ce
    // qui rendait le séchage exponentiel au lieu de linéaire et comptait
    // l'infiltration deux fois — elle est déjà incluse dans L chez Soti.
    // C'est l'incohérence d'unités signalée dans le commit 66d7731.
    //
    // Le ruissellement s'applique aux DEUX ensembles de mares, avec des bassins
    // versants différents : sans lui, une mare à sec a A = 0, donc P·A = 0, et
    // ne peut jamais se remplir.
    // =========================================================================
    reflex mise_a_jour_volume {
        if (V0_mare <= 0.0) { do calibrer_geometrie; }

        Iap       <- k_sol * (Iap + pluie);
        float G_t <- max(0.0, Gmax - Iap);
        float Pe  <- max(0.0, pluie - G_t);                    // mm
        float Qin <- Kr * (Pe / 1000.0) * bassin_versant;      // m³

        // Surface au début du pas : c'est elle qui porte la pluie et les pertes.
        float A_t <- surface_pour_volume(volume_eau);
        float apport_direct <- (pluie / 1000.0) * A_t;         // m³

        // Modulation NDWI des pertes : extension propre à ce modèle, absente de
        // Soti où L est constant. Un NDWI bas signale un sol sec et une mare qui
        // se retire ; une chute brutale du NDWI, un assèchement en cours.
        float facteur_ndwi <- max(0.4, min(2.5, 1.2 - ndwi_local * 2.0));
        float chute_ndwi   <- max(0.0, ndwi_precedent - ndwi_local);
        float bonus_chute  <- 1.0 + min(1.0, chute_ndwi * 5.0);
        float pertes <- (L_perte / 1000.0) * A_t * facteur_ndwi * bonus_chute;  // m³

        volume_eau  <- max(0.0, min(volume_max_reference,
                           volume_eau + apport_direct + Qin - pertes));
        surface_eau <- surface_pour_volume(volume_eau);
    }

    /**
     * Historique de la surface en eau, alimenté APRÈS le bilan hydrique pour
     * que la dernière valeur soit bien celle du jour. Sert au R0 vectoriel de
     * gîte, qui compare la surface à t et à t-T.
     */
    reflex memoriser_surface {
        add surface_eau to: historique_surface;
        // On ne conserve que de quoi remonter à t-T dans le pire cas.
        if (length(historique_surface) > profondeur_historique_surface) {
            remove index: 0 from: historique_surface;
        }
    }


    /**
     * Mémorise la durée de l'épisode sec qui vient de s'achever : c'est elle
     * qui conditionne l'éclosion des œufs quiescents lors de la remise en eau.
     * (L'ancien code testait `jours_sans_pluie >= Td_aedes` le jour même de la
     * pluie, alors que ce compteur venait d'être remis à zéro — l'éclosion des
     * Aedes ne pouvait donc jamais se déclencher sur un épisode pluvieux.)
     */
    reflex compter_jours_secs {
        if (pluie < 1.0) {
            jours_sans_pluie <- jours_sans_pluie + 1;
        } else {
            if (jours_sans_pluie > 0) { duree_secheresse_prec <- jours_sans_pluie; }
            jours_sans_pluie <- 0;
        }
    }

    reflex disparition_mare when: jours_sans_pluie >= seuil_assechement_mare and volume_eau > 0.0 {
        volume_eau <- 0.0; surface_eau <- 0.0;
    }

    reflex mise_a_jour_niveau {
        niveau_precedent <- niveau_mare;
        // Niveau = hauteur d'eau rapportée à la profondeur maximale. C'est bien
        // la HAUTEUR qui submerge la berge portant les œufs, pas le volume :
        // avec la loi puissance, les deux ne sont plus proportionnels.
        niveau_mare <- max(0.0, min(1.0,
            (hauteur_max > 0.0) ? hauteur_pour_volume(volume_eau) / hauteur_max : 0.0));
        // La MONTÉE du plan d'eau submerge la berge où les œufs ont été pondus :
        // c'est elle qui déclenche l'éclosion, pas la météo.
        montee_niveau <- max(0.0, niveau_mare - niveau_precedent);
    }

    /**
     * Survie journalière des œufs quiescents, appliquée jour par jour (et non
     * en une seule puissance phi^T comme auparavant).
     */
    reflex survie_oeufs_quiescents {
        oeufs_aedes_infectes <- oeufs_aedes_infectes * phi_aedes;
        oeufs_aedes_sains    <- oeufs_aedes_sains    * phi_aedes;
        if (oeufs_aedes_infectes < 0.01) { oeufs_aedes_infectes <- 0.0; }
        if (oeufs_aedes_sains    < 0.01) { oeufs_aedes_sains    <- 0.0; }
    }

    /**
     * Éclosion Aedes : déclenchée par la remise en eau, à condition que les
     * œufs aient subi une période sèche d'au moins Td_aedes jours.
     */
    /**
     * ÉCLOSION AEDES — déclenchée par la SUBMERSION de la berge portant les œufs.
     *
     * Le mécanisme réel est : ponte sur la marge exondée -> le plan d'eau
     * remonte -> les œufs sont noyés -> éclosion synchrone. L'ancienne condition
     * exigeait 7 jours de sécheresse météorologique achevée juste avant la
     * pluie : en pleine saison des pluies un tel épisode sec ne se produit
     * jamais, donc l'éclosion cessait et les œufs s'accumulaient sans éclore
     * (2,5 millions en fin de run) pendant que les adultes s'éteignaient.
     */
    reflex eclosion_aedes
        when: volume_eau > 0.0
          and montee_niveau >= seuil_montee_eclosion
          and (oeufs_aedes_infectes + oeufs_aedes_sains) >= 1.0 {

        // La fraction d'œufs noyés croît avec l'ampleur de la montée.
        float taux <- beta_aedes * min(1.0, montee_niveau / seuil_montee_eclosion);

        float ecl_inf <- oeufs_aedes_infectes * taux;
        float ecl_san <- oeufs_aedes_sains    * taux;
        oeufs_aedes_infectes <- oeufs_aedes_infectes - ecl_inf;
        oeufs_aedes_sains    <- oeufs_aedes_sains    - ecl_san;

        if (ecl_inf >= 1.0) {
            do creer_cohorte("aedes", true, ecl_inf, oeufs_index);
            write "Éclosion Aedes infectés : " + int(ecl_inf)
                + " immatures (cycle " + cycle + ")";
        }
        if (ecl_san >= 1.0) { do creer_cohorte("aedes", false, ecl_san, false); }
    }

    /**
     * Les pontes Culex de la journée deviennent une cohorte unique, plafonnée
     * par la capacité larvaire du gîte (Emax_culex par m²).
     */
    /**
     * Capacité de charge larvaire du gîte : Emax_culex individus par m² d'eau,
     * appliquée au STOCK d'immatures déjà présents (et non à la seule ponte du
     * jour). C'est ce qui donne son sens au paramètre : au-delà, la compétition
     * larvaire empêche tout recrutement supplémentaire.
     */
    float charge_larvaire {
        list<cohorte_larvaire> c <- cohorte_larvaire where (each.gite = self);
        return empty(c) ? 0.0 : sum(c collect each.effectif);
    }

    reflex mise_en_cohorte_culex when: pontes_culex_jour >= 1.0 {
        if (volume_eau > 0.0) {
            float capacite <- Emax_culex * max(1.0, surface_eau);
            float place    <- max(0.0, capacite - charge_larvaire());
            float eff      <- min(pontes_culex_jour * beta_culex, place);
            if (eff >= 1.0) { do creer_cohorte("culex", false, eff, false); }
        }
        pontes_culex_jour <- 0.0;
    }

    action creer_cohorte(string type_v, bool inf, float eff, bool index) {
        create cohorte_larvaire {
            gite            <- myself;
            type_vecteur    <- type_v;
            infectee        <- inf;
            effectif        <- eff;
            avancement      <- 0.0;
            issue_cas_index <- index;
            location        <- myself.location;
        }
    }

    aspect default {
        // Deux traits : l'emprise maximale du gite en pointille clair, et la
        // surface EN EAU du jour en bleu plein. C'est ce contraste qui rend le
        // remplissage et le retrait visibles au fil de la simulation.
        draw shape color: rgb(173, 232, 244, 0.55) border: rgb(31, 90, 110, 0.45);
        if (surface_eau > 0.0) {
            float r <- sqrt(surface_eau / #pi);
            draw circle(r) color: rgb(0, 51, 204, 0.85) border: rgb(10, 30, 100);
        }
    }
}
