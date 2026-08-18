# Données du modèle FVR — Zone Z3, Barkedji

Chemins attendus par `models/core/donnees_chemins.gaml` (relatifs à ce dossier).

```
data/
├── occsol/
│   ├── raster/
│   │   ├── raster_z3_Ceedu.tif
│   │   ├── raster_z3.tif             (saison Nduungu)
│   │   └── raster_z3_Debbundu.tif    (saison Dabbuunde)
│   ├── shp/
│   │   ├── occsol_z3_Ceedu2025.shp   (utilisé aussi comme OCCSOL_SHP)
│   │   ├── occsol_z3_Nduungu2025.shp
│   │   └── occsol_z3_Dabbuunde2025.shp
│   ├── ndvi/
│   │   ├── NDVI_z3_Ceedu.tif
│   │   ├── NDVI_z3_Nduungu.tif
│   │   └── NDVI_z3_Dabbuunde.tif
│   ├── ndwi/
│   │   ├── NDWI_z3_Ceedu.tif
│   │   ├── NDWI_z3_Nduungu.tif
│   │   └── NDWI_z3_Dabbuunde.tif
│   └── eau_binaire/
│       └── eau_binaire_z3.shp        (optionnel — uniquement si le paramètre
│                                       "NDWI binaire" est activé dans l'expérience)
├── sol/
│   └── type_sol_z3.shp
├── vegetation/
│   └── type_vegetation_z3.shp
├── routes/
│   └── chemin_z3.shp
└── climat/
    └── Climat_2025.csv
```

Chaque `.shp` est accompagné de ses fichiers annexes (`.dbf`, `.shx`, `.prj`, `.cpg`).

## `_non_utilise/`

Contient un 4e jeu de données saisonnier "Deminaree" (raster, NDVI, NDWI, occsol) importé
depuis GitHub mais non référencé par le modèle : le calendrier actuel (`calculer_saison`
dans `models/core/saisons_occsol.gaml`) ne gère que 3 saisons (Ceedu / Nduungu / Dabbuunde).
Conservé de côté au cas où cette saison serait intégrée plus tard ; aucun fichier n'a été supprimé.
