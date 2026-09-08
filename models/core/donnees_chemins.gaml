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

    // Couche de zonage : polygones d'entraînement digitalisés à la main pour la
    // classification d'occupation du sol. 796 entités, typées par le champ
    // `Name` en trois classes — vegetation (501), campement (271), mare (24),
    // reprises par `id_class` (6, 2, 3). C'est la seule couche du jeu de
    // données qui porte une TYPOLOGIE DE ZONES explicite ; elle sert de support
    // aux sorties spatiales, sans intervenir dans la dynamique simulée.
    //
    // Elle est projetée en UTM 28N (mètres), comme type_sol_z3 et chemin_z3 et
    // contrairement aux couches occsol_* qui sont en degrés. Son emprise
    // (32 065 x 30 410 m) confirme l'unite_z3 attendue par le modèle.
    //
    // ASSAINISSEMENT DU FICHIER (voir docs/ODD+D.md §4.2.2). La version livrée
    // était inexploitable par GAMA pour deux raisons cumulées :
    //   - sa table portait 28 champs hérités d'un export KML, soit 4053 octets
    //     par enregistrement ; GeoTools rendait alors la géométrie mais AUCUN
    //     attribut, sans le moindre message — `read("Name")` renvoyait nil et
    //     la typologie disparaissait silencieusement ;
    //   - 190 de ses 796 polygones étaient multi-parties, et GAMA éclate les
    //     multi-géométries en agents distincts : 796 enregistrements donnaient
    //     1248 agents, sans correspondance possible avec la table.
    // Le fichier a donc été réécrit : géométries mono-partie (la plus grande
    // partie de chaque enregistrement, soit 1 à 2.4 % d'aire écartée selon la
    // classe), converties de PolygonZ en Polygon 2D, et table réduite aux deux
    // champs utiles `Name` et `id_class`. Projection inchangée. Les fichiers
    // d'origine font autorité sur la branche `na`, où ils sont suivis par Git
    // LFS (git lfs fetch origin refs/remotes/origin/na).
    file ZONE_SHP        <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/occsol/shp/zone3_entrainements.shp");


    file OCCSOL_SHP      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR./data/occsol/shp/occsol_z3_Ceedu2025.shp");
    file SOL_SHP         <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/sol/type_sol_z3.shp");
    file VEGETATION_SHP  <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/vegetation/type_vegetation_z3.shp");
    file ROUTE_SHP       <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/routes/chemin_z3.shp");
    file CLIMAT_CSV      <- file("C:/Users/bmd/Gama_Workspace/Model_FVR/data/climat/Climat_2025.csv");
    //file EAU_BINAIRE_SHP <- file("../../data/occsol/eau_binaire/eau_binaire_z3.shp");

    // =========================================================================
    // MONDE ET GÉOMÉTRIE
    // =========================================================================
    // Base spatiale du monde, commutable par l'expérience.
    //
    // Par défaut (false) : comportement historique — l'enveloppe vient des
    // couches occsol, qui sont en coordonnées GÉOGRAPHIQUES. `unite_z3` en
    // dépend, et donc tous les rayons de perception, de vol et de ponte : le
    // modèle suppose que GAMA reprojette en métrique, ce qui n'est vérifiable
    // qu'a posteriori sur la valeur journalisée à l'init.
    //
    // À true : la base devient `zone3_entrainements`, seule couche du jeu de
    // données nativement projetée en UTM 28N. Son emprise (32 065 x 30 410 m)
    // s'aligne exactement sur type_sol_z3 et chemin_z3, et fixe `unite_z3` sans
    // dépendre d'une reprojection implicite. C'est la base de l'expérience
    // « Zone3 » (voir experiments/experiment_zone3.gaml).
    bool base_zone3 <- false;

    geometry shape   <- envelope(base_zone3 ? ZONE_SHP : occsol_raster_saisons["Nduungu"]);

    // zone_z3 EST le monde. Auparavant c'etait l'enveloppe d'un autre fichier,
    // qui conservait les coordonnees de ce fichier : elle n'etait donc pas dans
    // le meme repere que les agents, et tous les tests `zone_z3 covers ...`
    // etaient faux en permanence. Seules ses dimensions (width / height, d'ou
    // derive unite_z3) etaient exploitables, parce qu'elles sont invariantes
    // par translation — ce qui masquait le probleme.
    geometry zone_z3 <- shape;
}
