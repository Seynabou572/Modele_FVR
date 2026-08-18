/**
 * SOL — propriétés d'infiltration/rétention dérivées du type pédologique.
 */
model Sol

species sol {
    int    msd;
    string msdnom;
    float  coef_infiltration <- 0.45;
    float  coef_retention    <- 0.45;

    action calculer_proprietes_sol {
        switch msdnom {
            match "HYDROMORPHES"          { coef_infiltration <- 0.15; coef_retention <- 0.85; }
            match "PEU EVOLUES"           { coef_infiltration <- 0.55; coef_retention <- 0.35; }
            match "FERRUGINEUX TROPICAUX" { coef_infiltration <- 0.40; coef_retention <- 0.50; }
            match "REGOSOLS"              { coef_infiltration <- 0.60; coef_retention <- 0.30; }
            match "LITHOSOLS"             { coef_infiltration <- 0.20; coef_retention <- 0.20; }
            default                       { coef_infiltration <- 0.45; coef_retention <- 0.45; }
        }
    }
    aspect default { draw shape color: rgb(210,180,140,0.25) border: rgb(210,180,140,0.25); }
}
