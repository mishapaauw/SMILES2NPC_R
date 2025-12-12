## SMILES2NPC

Given a SMILES string of a molecular compound, it is often interesting to find out to which class of chemical compounds this could belong. For natural products, `NPClassifier` does exactly this. It's accessible [via a webserver](https://npclassifier.gnps2.org), but can also be accessed programatically by adding the SMILES string to the link below (see [GNPS API Documentation](https://ccms-ucsd.github.io/GNPSDocumentation/api/) for more details):

```
https://npclassifier.gnps2.org/classify?smiles=<smiles-string-here>
```

This repository contains `R` code to generate and query such links for all SMILES strings contained in a dataframe. This may be useful for example, after running [DreaMS](https://huggingface.co/spaces/anton-bushuiev/DreaMS) on an untargetted metabolomics dataset containing thousands of SMILES strings.

## Usage

First, define the `classify_smiles()` function (L8-L45).

Then a single SMILES string can be analyzed by running:

```R
> smiles = "CC(=O)OC1=CC=CC=C1C(=O)O"
> classify_smiles(smiles)
$class
[1] "Simple phenolic acids"

$superclass
[1] "Phenolic acids (C6-C1)"

$pathway
[1] "Shikimates and Phenylpropanoids"
```

To run `classify_smiles()` on all SMILES entries in a dataframe, first create a dataframe that looks like this:

```R
head(df)
  feature_ID                                                     SMILES          name
1          1                                  C(C1C(C(C(C(O1)CO)O)O)O)O       Glucose
2          2                                                CC(C)C(=O)O        Valine
3          3 CC[C@@H]1C[C@H](C[C@@H]2[C@@H]1C(=O)OC3=C(C=C(C=C3O2)O)O)O         Taxol
4          4                  CC1=C(C(=O)C2=CC=CC=C2O1)C(=O)C3=CC=CC=C3  Aflatoxin B1
5          5                                   CC1=C(C(=O)O)N(C)C(=O)N1   Theobromine
6          6                                      CCCCCCCCCCCCCCCC(=O)O Palmitic acid
```

Then, run `classify_smiles()` on each entry using `purrr:map()`:

```R
classifications <- map(df$SMILES, function(smiles) {
  # pb$tick() # this is optional, gives a progress bar if set up correctly (see code above)
  classify_smiles(smiles)
})
```

Finally, connect the classifications with the dataframe:

```R
df_classified <- df %>%
  mutate(
    np_class = map_chr(classifications, ~.x$class),
    np_superclass = map_chr(classifications, ~.x$superclass),
    np_pathway = map_chr(classifications, ~.x$pathway)
  )
```

To get your final dataframe with NPC predictions:

```R
head(df_classified)
  feature_ID                                                     SMILES          name                                      np_class
1          1                                  C(C1C(C(C(C(O1)CO)O)O)O)O       Glucose                               Monosaccharides
2          2                                                CC(C)C(=O)O        Valine                          Branched fatty acids
3          3 CC[C@@H]1C[C@H](C[C@@H]2[C@@H]1C(=O)OC3=C(C=C(C=C3O2)O)O)O         Taxol                                          <NA>
4          4                  CC1=C(C(=O)C2=CC=CC=C2O1)C(=O)C3=CC=CC=C3  Aflatoxin B1                                     Chromones
5          5                                   CC1=C(C(=O)O)N(C)C(=O)N1   Theobromine                              Purine alkaloids
6          6                                      CCCCCCCCCCCCCCCC(=O)O Palmitic acid Branched fatty acids; Unsaturated fatty acids
               np_superclass                                   np_pathway
1                Saccharides                                Carbohydrates
2 Fatty Acids and Conjugates                                  Fatty acids
3                       <NA> Polyketides; Shikimates and Phenylpropanoids
4                  Chromanes                                  Polyketides
5            Pseudoalkaloids                                    Alkaloids
6 Fatty Acids and Conjugates                                  Fatty acids
```



## References

- [GNPS API Documentation](https://ccms-ucsd.github.io/GNPSDocumentation/api/)
- [NPClassifier: A Deep Neural Network-Based Structural Classification Tool for Natural Products, Kim *et al.* (2021)](https://pubs.acs.org/doi/full/10.1021/acs.jnatprod.1c00399)
