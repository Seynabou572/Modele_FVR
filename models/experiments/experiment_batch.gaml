/**
 * EXPÉRIENCES BATCH
 * Les expériences "_3rep" sont conservées pour des tests rapides ; les
 * "_1000rep" permettent un grand nombre N de réplications via repeat: N
 * et among: range(1, N).
 */
model ExperimentBatch

import "../core/initialisation.gaml"

experiment "Batch_Aedes_3rep" type: batch repeat: 3 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Aedes";
    parameter "Simulation ID" var: simulation_id   among: [1, 2, 3];
}

experiment "Batch_Animal_3rep" type: batch repeat: 3 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Animal";
    parameter "Simulation ID" var: simulation_id   among: [1, 2, 3];
}

experiment "Batch_Aedes_100rep" type: batch repeat: 100 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Aedes";
    parameter "Simulation ID" var: simulation_id   among: range(1, 100);
}

experiment "Batch_Animal_100rep" type: batch repeat: 100 keep_seed: false until: cycle >= duree_simulation - 1 {
    parameter "Expérience"    var: type_experience <- "Animal";
    parameter "Simulation ID" var: simulation_id   among: range(1, 100);
}
