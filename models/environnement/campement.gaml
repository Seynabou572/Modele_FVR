/**
 * CAMPEMENT — point d'ancrage des ménages (humains et animaux).

model Campement

species campement {
    aspect default { draw shape color: #saddlebrown border: #saddlebrown; }
}
 */
 model Campement
 species campement {
    bool permanent <- true; // ou un attribut pour distinguer

    aspect default {
        rgb couleur;
        if (permanent) {
            couleur <- rgb(139,69,19); // MARRON (#8B4513) ← MODIFICATION
        } else {
            couleur <- rgb(255,165,0); // ORANGE (#FFA500) ← MODIFICATION
        }
        draw shape color: couleur border: couleur;
    }
}