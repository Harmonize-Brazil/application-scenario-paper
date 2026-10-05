## Download climate data from the HARMONIZE STAC in R

# Install packages:
# install.packages(c("sf", "rstac", "dplyr"))

library(sf)
library(rstac)
library(dplyr)


#--------------------------------------
# 1. Set constants
HARMONIZE_STAC_URL <- 'https://geolab.inpe.br/bdc/harmonize/stac/v1/'

START_DATE <- "2010-01-01"
END_DATE <- "2025-12-31"

# 2. List Harmonize STAC collections (using RSTAC)
all_collections <- stac(HARMONIZE_STAC_URL) %>%
  collections() %>%
  get_request()

for (collection in all_collections$collections){
  print(collection$id) 
}


# 3. Obtain monthly climate data for each municipality

### 3.1 Set collection id (temperature, precipitation, dengue, zika, etc)

#COLLECTION_ID <- "precip_max_no_mun_epiweek_era5land-1"
#COLLECTION_ID <- "humidity_percent_no_mun_epiweek_era5land-1"
COLLECTION_ID <- "temp_mean_no_mun_epiweek_era5land-1"

### 3.2 Search climate data on Harmonize STAC (Using RSTAC)

stac_search <- stac(HARMONIZE_STAC_URL) %>%
  stac_search(
    collections = COLLECTION_ID,
    datetime = paste(START_DATE, END_DATE, sep = "/"),
    limit = 1000
  ) %>%
  get_request()

stac_search$context

### 3.3 For each feature, retrieve geojson as dataframe

feature_to_geojson_csv <- function(feature) {
  datetime <- feature$properties$datetime
  geojson_href <- feature$assets$geojson$href
  
  as.data.frame(st_read(geojson_href)) %>%
    mutate(year_month = format(as.Date(datetime), "%Y-%m"))
}

dfs <- lapply(X = stac_search$features, FUN = feature_to_geojson_csv)
dfs[1:2]

### 3.4 Rbind lists of dataframes in one big dataframe
#### If Health Data:

# ------------------------------------

# rbind dataframes
rbind_dfs <- do.call(rbind, dfs)

# Select columns 
final_df <- rbind_dfs %>%
  select(-geometry)


dim(final_df)
head(final_df)

### 3.5 Save data

FINAL_CSV_NAME <- paste0(COLLECTION_ID, ".csv")

#write.csv(final_df, FINAL_CSV_NAME, row.names = FALSE)

write.table(final_df, FINAL_CSV_NAME, sep = ",", dec = ".", row.names = FALSE, col.names = TRUE, quote = FALSE)

# ver diretorio em que arquivo foi salvo 
getwd()

