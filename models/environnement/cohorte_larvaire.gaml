/**
 * COHORTE LARVAIRE — stade aquatique explicite avec DÉLAI de développement.
 *
 * Remplace l'ancienne éclosion instantanée (où un œuf devenait adulte le jour
 * même). Une cohorte représente les immatures pondus/éclos le même jour dans
 * le même gîte, avec le même statut infectieux. Elle progresse d'une fraction
 * 1/duree_dev_larvaire(T) par jour et n'émerge qu'à maturité.
 *
 * C'est ce délai qui produit le décalage réaliste entre le pic de pluie et le
 * pic d'abondance vectorielle.
 *
 * `effectif` est exprimé en INDIVIDUS RÉELS ; la conversion en agents
 * super-individus se fait à l'émergence.
 */
model CohorteLarvaire

import "../core/parametres_globaux.gaml"
import "../core/climat.gaml"
import "../core/biologie_thermique.gaml"
import "mare.gaml"
import "../agents/vecteur.gaml"

species cohorte_larvaire {
    mare   gite         <- nil;
    string type_vecteur <- "culex";
    bool   infectee     <- false;
    float  effectif     <- 0.0;   // individus réels
    float  avancement   <- 0.0;   // 0 -> 1
    bool   issue_cas_index <- false;

    reflex cycle_larvaire {
        // L'assèchement du gîte tue l'ensemble de la cohorte.
        if (gite = nil or dead(gite) or gite.volume_eau <= 0.0) {
            do die;
        } else {
            float survie <- (type_vecteur = "aedes") ? survie_larvaire_aedes : gamma_culex;

            // Mortalité densité-dépendante (Beverton-Holt) : la compétition pour
            // la ressource dans le gîte régule la population. Sans ce terme, la
            // production larvaire est illimitée et l'abondance vectorielle finit
            // bornée par le plafond technique `max_vecteurs`, ce qui rend `m`
            // — et donc le R0 — artificiel.
            float capacite <- max(1.0, Emax_culex * max(1.0, gite.surface_eau));
            survie <- survie / (1.0 + gite.charge_larvaire() / capacite);

            effectif   <- effectif * survie;
            avancement <- avancement
                        + 1.0 / world.duree_dev_larvaire(temperature, type_vecteur);

            if (effectif < 1.0) {
                do die;
            } else if (avancement >= 1.0) {
                do emerger;
            }
        }
    }

    action emerger {
        // Arrondi stochastique : évite de perdre systématiquement les cohortes
        // dont l'effectif est inférieur à un super-individu.
        float nb_exact <- effectif / float(echelle_si_vecteur);
        int   nb_agents <- int(nb_exact);
        if (flip(nb_exact - nb_agents)) { nb_agents <- nb_agents + 1; }

        // Pas de blocage au plafond ici : `action emerger` étant appelée cohorte
        // par cohorte, un refus « premier arrivé, premier servi » élimine
        // l'espèce la moins abondante (les Aedes, noyés sous les Culex). La
        // régulation est confiée à la purge de `reflex mourir`, qui est aveugle
        // à l'espèce. Une borne large reste pour éviter tout emballement.
        loop rep from: 0 to: nb_agents - 1 {
            if (length(vecteur) < max_vecteurs * 2) {
                create vecteur {
                    type_vecteur      <- myself.type_vecteur;
                    etat_sante        <- myself.infectee ? "I" : "S";
                    taille_groupe     <- echelle_si_vecteur;
                    vitesse           <- (myself.type_vecteur = "aedes")
                                         ? vitesse_aedes : vitesse_culex;
                    mare_origine      <- myself.gite;
                    location          <- myself.gite.location
                                       + {rnd(-50.0, 50.0), rnd(-50.0, 50.0)};
                    age               <- 0;
                    jours_dans_etat   <- 0;
                    avancement_eip    <- 0.0;
                    est_cas_index_A   <- false;
                    est_cas_index_B   <- myself.issue_cas_index;
                    origine_infection <- myself.infectee ? "verticale" : "aucune";
                }
            }
        }
        do die;
    }
}
