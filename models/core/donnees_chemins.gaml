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
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_Ceedu_2025.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_Nduungu_2025.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_Debbundu.tif")
    ];
    map<string, file> occsol_shp_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_2025_Ceedu_barkedji_vecteur.shp"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_2025_Nduungu_barkedji_vecteur.shp"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_2025_Dabbuunde_barkedji_vecteu.shp")
    ];
    map<string, file> ndvi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_Ceedu_2025.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_Nduungu_2025.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_Dabbuunde_2025.tif")
    ];
    map<string, file> ndwi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_Ceedu_2025.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_Nduungu_2025.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_Dabbuunde_2025.tif")
    ];

    file OCCSOL_SHP      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_2025_Ceedu_barkedji_vecteur.shp");
    file SOL_SHP         <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/sol/TYPE DE SOL.shp");
    file VEGETATION_SHP  <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/vegetation/TYPE DE VEGETAION.shp");
    file ROUTE_SHP       <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/routes/chemin.shp");
    file CLIMAT_CSV      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/climat/Climat_2025.csv");
    //file EAU_BINAIRE_SHP <- file("../../data/occsol/eau_binaire/eau_binaire_z3.shp");

    // =========================================================================
    // MONDE ET GÉOMÉTRIE
    // =========================================================================
    geometry shape   <- envelope(occsol_raster_saisons["Nduungu"]);
    geometry zone_z3 <- envelope(OCCSOL_SHP);
}