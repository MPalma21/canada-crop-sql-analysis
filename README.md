# Canada Crop SQL Analysis / Análisis SQL de cultivos de Canadá

Bilingual Quarto project combining Canadian crop production, farm prices, and exchange rates in a temporary SQLite database. It demonstrates validated inputs, parameterized SQL, explicit units, tests, and reproducible rendering.

Proyecto bilingüe que integra producción agrícola, precios y tipos de cambio en una base SQLite temporal, con validación, SQL parametrizado, unidades explícitas y pruebas.

## Reproduce / Reproducir

```bash
Rscript data-raw/prepare-data.R
Rscript -e "renv::restore(); testthat::test_dir('tests/testthat')"
quarto render
```

## Sources / Fuentes

The source URLs and snapshot date are recorded in `data/SOURCES.txt`. Data originate from Statistics Canada materials distributed for the IBM Skills Network course.

- Original publication: https://rpubs.com/MPalmaR19/1296542
- GitHub: https://github.com/MPalma21/canada-crop-sql-analysis
- Posit Connect Cloud: added after deployment.

## License

Code is released under the MIT License. Source datasets retain their original terms.

