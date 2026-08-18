/**
 * ROUTE — réseau routier utilisé comme graphe de déplacement pour les hôtes.
 */
model Route

species route {
    int code_route; int classe_route; int revet; int repert;
    int nb_passages <- 0;
    aspect default {
        rgb couleur; float largeur;
        if      (revet = 1)         { couleur <- #darkred;        largeur <- 3.5; }
        else if (classe_route <= 4) { couleur <- rgb(200,80,0);   largeur <- 2.5; }
        else                        { couleur <- #goldenrod;       largeur <- 1.5; }
        if (nb_passages > 15)       { couleur <- #black; largeur <- largeur + 1.0; }
        draw shape color: couleur width: largeur;
    }
}
