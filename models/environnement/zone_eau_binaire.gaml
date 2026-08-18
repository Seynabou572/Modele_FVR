/**
 * ZONE_EAU_BINAIRE — polygones du masque d'eau binaire optionnel (chargés
 * uniquement si utiliser_ndwi_binaire = true, voir core/initialisation.gaml).
 */
model ZoneEauBinaire

species zone_eau_binaire {
    int eau <- 0;
}
