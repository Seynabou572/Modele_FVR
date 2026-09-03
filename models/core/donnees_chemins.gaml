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
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_z3.tif"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/raster/raster_z3_Debbundu.tif")
    ]; 
    map<string, file> occsol_shp_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_z3_Ceedu2025.shp"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/zone3_entrainements.shp"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_z3_Dabbuunde2025.shp")
    ];
    map<string, file> ndvi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_z3_Nduungu2025.csv"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndvi/NDVI_z3_Dabbuunde.tif")
    ];
    map<string, file> ndwi_raster_saisons <- [
        "Ceedu"     :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_z3_Ceedu.tif"),
        "Nduungu"   :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_z3_Nduungu2025.csv"),
        "Dabbuunde" :: file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/ndwi/NDWI_z3_Dabbuunde.tif")
    ];

    file OCCSOL_SHP      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/occsol_z3_Ceedu2025.shp");
    file SOL_SHP         <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/sol/type_sol_z3.shp");
    file VEGETATION_SHP  <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/vegetation/type_vegetation_z3.shp");
    file ROUTE_SHP       <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/routes/chemin_z3.shp");
    file CLIMAT_CSV      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/climat/Climat_2025.csv");
    //file EAU_BINAIRE_SHP <- file("../../data/occsol/eau_binaire/NDWI_z3_Nduungu.shp");

    // =========================================================================
    // MONDE ET GÉOMÉTRIE
    // =========================================================================
    geometry shape   <- envelope(occsol_shp_saisons["Nduungu"]);
    geometry zone_z3 <- envelope(OCCSOL_SHP);
}