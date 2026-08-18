/**
 * DONNÉES SIG & CLIMAT — chemins de fichiers et géométrie du monde.
 * Tous les chemins sont relatifs au dossier data/ du projet.
 */
model DonneesChemins

global {

    // =========================================================================
    // FICHIERS DE DONNÉES SAISONNIÈRES
    // =========================================================================
    map<string, file> occsol_raster_saisons <- [
        "Ceedu"     :: file("../../data/occsol/raster/raster_z3_Ceedu.tif"),
        "Nduungu"   :: file("../../data/occsol/raster/raster_z3.tif"),
        "Dabbuunde" :: file("../../data/occsol/raster/raster_z3_Debbundu.tif")
    ];
    map<string, file> occsol_shp_saisons <- [
        "Ceedu"     :: file("../../data/occsol/shp/occsol_z3_Ceedu2025.shp"),
        "Nduungu"   :: file("../../data/occsol/shp/occsol_z3_Nduungu2025.shp"),
        "Dabbuunde" :: file("../../data/occsol/shp/occsol_z3_Dabbuunde2025.shp")
    ];
    map<string, file> ndvi_raster_saisons <- [
        "Ceedu"     :: file("../../data/occsol/ndvi/NDVI_z3_Ceedu.tif"),
        "Nduungu"   :: file("../../data/occsol/ndvi/NDVI_z3_Nduungu.tif"),
        "Dabbuunde" :: file("../../data/occsol/ndvi/NDVI_z3_Dabbuunde.tif")
    ];
    map<string, file> ndwi_raster_saisons <- [
        "Ceedu"     :: file("../../data/occsol/ndwi/NDWI_z3_Ceedu.tif"),
        "Nduungu"   :: file("../../data/occsol/ndwi/NDWI_z3_Nduungu.tif"),
        "Dabbuunde" :: file("../../data/occsol/ndwi/NDWI_z3_Dabbuunde.tif")
    ];

    file OCCSOL_SHP      <- file("../../data/occsol/shp/occsol_z3_Ceedu2025.shp");
    file SOL_SHP         <- file("../../data/sol/type_sol_z3.shp");
    file VEGETATION_SHP  <- file("../../data/vegetation/type_vegetation_z3.shp");
    file ROUTE_SHP       <- file("../../data/routes/chemin_z3.shp");
    file CLIMAT_CSV      <- file("../../data/climat/Climat_2025.csv");
    //file EAU_BINAIRE_SHP <- file("../../data/occsol/eau_binaire/eau_binaire_z3.shp");

    // =========================================================================
    // MONDE ET GÉOMÉTRIE
    // =========================================================================
    geometry shape   <- envelope(occsol_raster_saisons["Nduungu"]);
    geometry zone_z3 <- envelope(OCCSOL_SHP);
}
