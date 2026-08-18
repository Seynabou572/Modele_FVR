/**
 * MODÈLE FVR — Zone Z3, Barkedji (Sénégal) — Saison des pluies 2025
 * ---------------------------------------------------------------------------
 * Point d'entrée : ce fichier ne fait qu'assembler les modules du modèle.
 * Voir core/ (paramètres, climat, saisons, R0, exports), environnement/
 * (sol, végétation, mares, routes, campements), agents/ (hôtes, vecteurs)
 * et experiments/ (GUI et batch).
 */
model ModeleFVRBarkedjiZ3

import "core/donnees_chemins.gaml"
import "core/parametres_globaux.gaml"
import "core/climat.gaml"
import "core/biologie_thermique.gaml"
import "core/saisons_occsol.gaml"
import "core/dynamique_population.gaml"
import "core/r0_vectoriel.gaml"
import "core/exports_csv.gaml"
import "core/initialisation.gaml"

import "environnement/occsol_polygone.gaml"
import "environnement/zone_eau_binaire.gaml"
import "environnement/sol.gaml"
import "environnement/vegetation.gaml"
import "environnement/route.gaml"
import "environnement/campement.gaml"
import "environnement/mare.gaml"
import "environnement/cohorte_larvaire.gaml"

import "agents/hote.gaml"
import "agents/humain.gaml"
import "agents/animal.gaml"
import "agents/vecteur.gaml"

import "experiments/experiment_gui_aedes.gaml"
import "experiments/experiment_gui_animal.gaml"
import "experiments/experiment_batch.gaml"
