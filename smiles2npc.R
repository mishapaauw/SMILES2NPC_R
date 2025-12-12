library(httr)
library(jsonlite)
library(tidyverse)
library(purrr)
library(progress)

## Function definition
classify_smiles <- function(smiles) {
  # Handle empty or NA values
  if (is.na(smiles) || smiles == "") {
    return(list(class = NA, superclass = NA, pathway = NA))
  }
  
  # Encode SMILES for safe URL usage
  smiles_encoded <- URLencode(smiles, reserved = TRUE)
  
  # Build URL
  url <- paste0("https://npclassifier.gnps2.org/classify?smiles=", smiles_encoded)
  
  # Try to query the API with error handling
  tryCatch({
    res <- GET(url)
    out <- fromJSON(content(res, "text", encoding = "UTF-8"))
    
    # Helper function to extract and collapse results
    extract_field <- function(field) {
      if (is.null(field) || length(field) == 0) {
        return(NA)
      }
      return(paste(field, collapse = "; "))
    }
    
    # Return relevant fields with proper extraction
    return(list(
      class = extract_field(out$class_results),
      superclass = extract_field(out$superclass_results),
      pathway = extract_field(out$pathway_results)
    ))
  }, error = function(e) {
    return(list(class = NA, superclass = NA, pathway = NA))
  })
  
  # Add a small delay to avoid overwhelming the API
  Sys.sleep(0.1)
}

# Example with one SMILES string
smiles = "CC(=O)OC1=CC=CC=C1C(=O)O"

classify_smiles(smiles)

# Test dataframe with small dataset
df <- data.frame(
  feature_ID = 1:6,
  SMILES = c(
    "C(C1C(C(C(C(O1)CO)O)O)O)O",
    "CC(C)C(=O)O",
    "CC[C@@H]1C[C@H](C[C@@H]2[C@@H]1C(=O)OC3=C(C=C(C=C3O2)O)O)O", 
    "CC1=C(C(=O)C2=CC=CC=C2O1)C(=O)C3=CC=CC=C3",
    "CC1=C(C(=O)O)N(C)C(=O)N1",
    "CCCCCCCCCCCCCCCC(=O)O"
  ),
  name = c(
    "Glucose",
    "Valine",
    "Taxol",
    "Aflatoxin B1",
    "Theobromine",
    "Palmitic acid"
  ))

# Setup progress bar
pb <- progress_bar$new(
  format = "  Classifying [:bar] :current/:total (:percent) eta: :eta",
  total = nrow(df),
  clear = FALSE,
  width = 60
)

# Run the classification on each dataframe SMILES entry
classifications <- map(df$SMILES, function(smiles) {
  pb$tick()
  classify_smiles(smiles)
})

# Connect classifications to dataframe
df_classified <- df %>%
  mutate(
    np_class = map_chr(classifications, ~.x$class),
    np_superclass = map_chr(classifications, ~.x$superclass),
    np_pathway = map_chr(classifications, ~.x$pathway)
  )
