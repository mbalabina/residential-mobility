# Residential Mobility and Social Structure

**Who moves — and who moves again and again?** A quantitative study of residential mobility in Russia, based on the «Социальная структура» survey (**N = 7,563**, March 2025).

<p>
<img src="figures/01_moves_distribution.png" width="32%">
<img src="figures/06_share_by_education.png" width="32%">
<img src="figures/18_scree_b107.png" width="32%">
</p>

Research group **«Городская повседневность»** (Urban Everyday Life) · Python + R · [full results](RESULTS.md)

---

## 1. Research question

Residential mobility is usually studied either as a macro process (migration flows between regions) or as an individual biography (why one person moves and another does not). This project takes the second view and asks a narrower question:

> **What distinguishes people who move repeatedly from those who stay put?**

The outcome is deliberately coarse. Instead of modelling the number of moves — a heavily skewed count with a long right tail — respondents are split into two groups: those who have moved **more than three times** since the age of 16 (*hypermobile*), and everyone else. Public discussion treats mobility as a resource: people who move are said to be more educated, more willing to take risks and more likely to believe that success depends on effort rather than on circumstances. The analysis tests whether any of this is visible in the data.

Three blocks of predictors are examined:

* **Structure** — age, sex, education, income, employment, family status, housing tenure.
* **Attitudes** — two batteries of Likert items, reduced by factor analysis: beliefs about the causes of poverty and fairness (**B107**, 17 items) and individualism / collectivism / family obligation (**B114**, 19 items).
* **Beliefs about success** — 17 items on what drives success in life, explored in the R script.

---

## 2. Data

| | |
| --- | --- |
| Source | «Социальная структура» survey, fieldwork 09.03.2025 |
| Sample | **7,563** respondents, 443 variables |
| Analysed subsample | **7,552** after removing implausible income values |
| Outcome | `all_reloc` — total number of moves since age 16 (mean 1.88, median 1, max 99) |
| Binary outcome | hypermobile = more than 3 moves → **1,240 respondents (16.4 %)** |
| Unit | individual respondent |
| Access | the `.sav` file is **not** distributed with this repository (see §7) |

---

## 3. Method

The same project is implemented twice, deliberately, because the two languages expose different parts of the workflow.

### Python — `python/residential_mobility.ipynb`

The main pipeline, top to bottom:

1. **Preparation.** SPSS question wordings are mapped to short variable names; value labels are recovered from the file metadata rather than hard-coded.
2. **Outcome construction.** The mobility typology (`all_reloc > 3`), with the raw and IQR-trimmed distributions shown side by side.
3. **Cleaning.** Implausible incomes dropped (> 10M ₽/month); SPSS missing-value codes (`9` = "difficult to answer", `8`/`10` = "other") recoded to `NaN` so that they cannot be read as ordinal positions.
4. **Descriptives.** A stratified table one (n / % for categorical, mean (SD) and median [IQR] for numeric, split by mobility type).
5. **Bivariate associations.** Share of hypermobile respondents by each categorical variable, with the raw distribution beside it.
6. **Factor analysis.** Principal-component extraction — five factors for B107, four for B114 — with communalities and factor scores compared across the two mobility groups by independent-samples t-tests.
7. **Cluster analysis.** Agglomerative clustering (complete linkage, city-block distance) on min-max scaled and one-hot encoded sociodemographics, run twice: within the hypermobile subgroup and on the full sample. Cluster differences tested with Kruskal–Wallis (numeric) and χ² (categorical).
8. **Logistic regression.** P(hypermobile) on the full sociodemographic block, with complete-case estimation, a forest plot on the odds-ratio scale, and VIF diagnostics on the design matrix.

### R — `r/residential_mobility.R`

A second pair of eyes on the exploratory stage: `gtsummary` tables, `vcd` mosaic plots with standardised residuals, `factanal` on the success battery with one-way ANOVA per item, **multiple correspondence analysis** (`FactoMineR`), five separate logistic regressions, and hierarchical clustering on a **Gower distance** — which handles mixed numeric and categorical variables without one-hot encoding.

Two independent implementations of the same outcome variable are a feature, not duplication: the folder structure makes the disagreements visible, and the disagreements are documented in §6.

---

## 4. Headline results

> **Provenance.** The numbers below come from the original analysis run. Three defects were corrected during the refactor (§5); those marked ⚠️ will move when the notebook is re-run. Everything else is unaffected.

**Mobility is structured, but weakly.**

* Hypermobile respondents are **older** (49.5 vs 44.3 years), more often **women** (57.4 % vs 53.1 %), more often **have children** (80.5 % vs 72.0 %) and less often **employed** (57.5 % vs 63.7 %).
* Hypermobility rises monotonically with **education**: from ≈14 % among those with general secondary education to ≈21 % among those with a master's degree or postgraduate education.
* It falls monotonically with **financial satisfaction**: 19.4 % among the completely dissatisfied, 11.9 % among the completely satisfied — and rises again among those who expect their finances to worsen (21.3 %).
* **Willingness to change one's life** shows the cleanest gradient of all: from 12.6 % among those who say they could not do it to **21.9 %** among those who are certain they could.
* **Housing tenure matters more than anything else.** Among renters, 22.6 % are hypermobile; among those whose dwelling belongs to the state, 9.9 %.

**Attitudes separate the two groups — but only some of them.**

| Factor block | Factor | t | p |
| --- | --- | --- | --- |
| B107 (poverty & fairness, 5 factors, 52.7 % cumulative variance) | `sov_left` | 3.73 | 0.0002 |
| | `lib_cons` | −2.48 | 0.013 |
| | `prog_left` | −4.54 | < 0.0001 |
| | `money`, `merit` | — | n.s. |
| B114 (individualism & collectivism, 4 factors, 47.1 % cumulative variance) | `ego` | −4.30 | < 0.0001 |
| | `colect` | −4.19 | < 0.0001 |
| | `emot`, `ind` | — | n.s. |

Hypermobile respondents score higher on a **Soviet-left** orientation and lower on both **progressive-left** and **ego / collective** orientations. The effect sizes are small; the pattern is consistent.

**Clustering recovers the well-known mobility profiles** — but the full-sample solution is dominated by housing tenure and age rather than by mobility itself (see [RESULTS.md](RESULTS.md) for the cluster profiles).

**The multivariate model is weak and should be read with caution.** ⚠️ In the logistic regression (N = 6,016), pseudo-R² is **0.038** — the sociodemographic block explains very little of the variance in mobility. Significant at p < 0.01: home ownership (`exp(B) = 0.71`), religiosity (1.31), sex (1.21), age (1.03 per year), education (1.07 per level), willingness to change (1.21).

The honest summary: **mobility is associated with a coherent set of sociodemographic and attitudinal characteristics, but none of them predicts it well.** A pseudo-R² of 0.04 is a finding, not a failure — it says that repeated moving is driven by something this survey does not measure.

---

## 5. Corrections applied in the refactor

The original scripts were working research code. This refactor fixes defects that would mislead a reader, and leaves everything else alone. Each fix is marked in the source.

| # | Where | Problem | Fix |
| --- | --- | --- | --- |
| 1 | `r/residential_mobility.R` | **The binary outcome was inverted.** `if_else(moves >= 3, "Обычно-мобильный", "Гиппермобильный")` labelled respondents with 3+ moves as *normal* and everyone else as *hypermobile* — every odds ratio from the R script pointed the wrong way. | Labels corrected and factor levels set explicitly (`Обычно-мобильный` as reference). ⚠️ **Re-run before using any R estimate.** |
| 2 | `python/…ipynb`, cleaning | **Missing values silently became a substantive category.** `home_owner_bin` mapped the codes for "other" and "difficult to answer" to `0`, merging them with "does not own the dwelling". | Missing values preserved; the flag now has three states and the model uses complete cases. ⚠️ Changes the `home_owner_bin` coefficient. |
| 3 | `python/…ipynb`, B114 loadings | **A broken filter hid part of the factor solution.** `(x < 0.4) or (x < -0.4)` evaluates to `x < 0.4`, silently blanking every loading below −0.4, so large negative loadings were invisible. | Shared `pattern()` helper using `abs(x) < 0.4`. ⚠️ May reveal loadings that were previously hidden. |
| 4 | `python/…ipynb`, VIF | **Diagnostics were computed on the wrong matrix.** VIF was calculated on the raw columns, while the model estimated dummy-coded factors — the numbers corresponded to no coefficient in the model. | VIF computed on the patsy design matrix actually used by the model, with a note that multi-level factors need GVIF. ⚠️ Values will change. |
| 5 | `python/…ipynb`, forest plot | **The figure and the table were on different scales.** The table reported odds ratios; the plot showed log-odds coefficients with symmetric ±1.96 SE bars. | Both now show odds ratios with asymmetric confidence intervals on a log axis. |
| 6 | `python/…ipynb` | Duplicate `analysis('fin_pred')` call; a dead, broken `from_dummy()` helper; two near-identical 30-cell cluster blocks; unused imports; a debug cell printing 443 column names. | Duplicates removed, cluster analysis extracted into `run_cluster_analysis()`, broken helper replaced, imports pruned, debug output dropped. No effect on results. |
| 7 | `r/residential_mobility.R` | The ANOVA block ran `aov()` against `main` while iterating over a different data frame, and stored p-values in a column named `Es`. Two `mosaic()` calls were exact duplicates; an interactive `?hunspell::dictionary` and a stray `lemmatize_words()` call were left in; the nested cluster block ended in a broken `mutate(across(where(is.factor), ~ count(.)))`. | Data frames made consistent, p-value column named correctly, duplicates and stray code removed, cluster profiling rewritten. |
| 8 | both | Reproducibility was not addressed: no pinned dependencies, no session info, hard-coded file paths. | `requirements.txt`, `sessionInfo()` at the end of the R script, paths and thresholds promoted to named constants. |

**Not changed, on purpose.** A fix that changes the analysis is not a refactor, and I could not re-run the pipeline (the survey file is not distributable — see §7). Corrections 1–4 therefore need one clean re-run before the numbers in §4 are final. The code is written so that each one is a one-line change you can revert.

---

## 6. Known inconsistencies and open questions

These are substantive issues, listed rather than silently fixed.

1. **The mobility threshold differs between the two implementations.** Python uses `all_reloc > 3` (4 or more moves), R uses `moves >= 3` (3 or more). Both are defensible — but they are not the same variable, so the two scripts cannot be compared directly. Pick one and state it in the paper. The number of moves is also self-reported, retrospective, and the survey does not distinguish voluntary from forced moves.
2. **`home_owner` is nominal but treated as numeric.** The codebook distinguishes family ownership, state ownership, employer-provided housing, cooperatives and renting (codes 1–5). Mean (SD) is reported for it and it enters the cluster analysis as an ordinal-scaled variable. The correct treatment is dummy coding; this was left unchanged because it alters the cluster solution.
3. **VIF values above 8 for variables that are not collinear.** In the original run, `relig`, `sex`, `children` and `work` all showed VIF around 9 on raw columns. This is an artefact of computing VIF on a matrix the model never used (correction 4) — re-check before drawing any conclusion about multicollinearity.
4. **`volya` is the only variable that never separates the clusters** (Kruskal–Wallis p = 0.07 among the hypermobile, p = 0.10 in the full sample). Either the item does not discriminate, or the clusters are not the right partition. Worth a sentence in the paper.
5. **The 2015 wave was loaded but never analysed.** The original R script read a second survey file, printed its structure and stopped. A 2015 / 2025 comparison is a genuinely interesting design — mobility before and after 2022 — but it is a separate piece of work, so the half-finished block was removed rather than shipped.
6. **No sampling weights.** The survey table reports unweighted shares. If the sample is not self-weighting, every percentage in §4 is a sample statistic, not a population estimate.
7. **Causal language is not warranted anywhere.** The design is cross-sectional. "Hypermobile respondents are more often women" is an association; education and mobility are jointly determined by things measured nowhere in this file.

---

## 7. Data and ethics

**The microdata are not in this repository and must not be added to it.**

`Social Structure_09_03_2025_itog.sav` is a proprietary survey file owned by the research group. It contains individual-level responses on income, religiosity and family circumstances. Neither the `.sav` file nor any respondent-level derivative (subset, recoded extract, factor-score table) belongs in a public repository — some of these variables are special-category personal data under the GDPR, and the survey's consent terms were written for research use, not for open publication.

What *is* published here: analysis code, the variable mapping (question wording → short name), value-label dictionaries, and aggregated results. `.gitignore` excludes `*.sav`, `*.dta`, `*.rds` and a `data/` directory to make that policy hard to break by accident.

**To reproduce:** obtain the survey file from the research group, place it in `data/`, and adjust `DATA_PATH` at the top of each script.

---

## 8. Repository layout

```
README.md                          this file
RESULTS.md                         full tables and figures from the original run
python/
  residential_mobility.ipynb       main pipeline (preparation → models)
  requirements.txt                 declared Python dependencies
r/
  residential_mobility.R           exploratory analysis in R
docs/
  variables.md                     variable mapping and derived variables
figures/                           22 figures produced by the analysis
```

---

## 9. Reproducing

```bash
# Python
pip install -r python/requirements.txt
jupyter lab python/residential_mobility.ipynb

# R
Rscript r/residential_mobility.R
```

**Python dependencies.** `pandas`, `numpy`, `seaborn`, `matplotlib`, `pyreadstat`, `statsmodels`, `patsy`, `scikit-learn`, `factor_analyzer`, `scipy`, `stargazer`, [`pysummaries`](https://genentech.github.io/pysummaries/) (publication-style tables).

**R dependencies.** `haven`, `dplyr`, `tidyr`, `ggplot2`, `gtsummary`, `sjPlot`, `vcd`, `broom`, `FactoMineR`, `factoextra`, `marginaleffects`, `gower`, `patchwork`.

All outputs are cleared in the committed notebook, so the first run regenerates every table and figure.

---

## 10. Skills demonstrated

* **Survey methodology** — working directly from SPSS metadata: value labels, missing-value codes, item batteries, and the difference between a nominal code and an ordinal scale.
* **Measurement decisions made explicit** — dichotomising a skewed count, recoding "difficult to answer", and documenting what each choice costs.
* **Dimensionality reduction** — principal-component factor analysis with scree plots, communalities, factor scores, and group comparison of scores.
* **Unsupervised learning** — hierarchical clustering with mixed data types (city-block and Gower distances), dendrograms, cluster profiling and non-parametric tests of cluster differences (Kruskal–Wallis, χ²).
* **Regression modelling** — binary logistic regression with odds ratios, complete-case handling, and model-quality reporting (pseudo-R²).
* **Model diagnostics** — variance inflation factors computed on the design matrix, with an understanding of why dummy sets inflate VIF.
* **Bilingual tooling** — the same research question implemented in Python (`statsmodels`, `scikit-learn`, `factor_analyzer`) and in R (`gtsummary`, `FactoMineR`, `gower`, `marginaleffects`).
* **Research software hygiene** — pinned environments, cleared outputs, named constants, dead code removed, known defects documented instead of hidden.

---

## 11. Authors and context

**Research group «Городская повседневность»** (Urban Everyday Life), HSE University.
Survey: «Социальная структура», 09.03.2025.
Analysis code in this repository: **Marina Balabina**.

Illustrations and results are from the original analysis run; see §5 for the corrections applied since.

---

## Краткое описание (по-русски)

Количественное исследование **residential mobility** по данным опроса «Социальная структура» (09.03.2025, N = 7 563). Работа выполнена в исследовательской группе **«Городская повседневность»**.

**Вопрос.** Чем отличаются люди, которые переезжают многократно, от тех, кто остаётся на месте? Бинарный исход — «сверхмобильные» (больше трёх переездов с 16 лет, 16,4 % выборки) против остальных.

**Методы.** Обработка данных SPSS с восстановлением кодовых книг из метаданных; описательные статистики; факторный анализ двух батарей вопросов (B107 — 17 пунктов о бедности и справедливости, 5 факторов, 52,7 % объяснённой дисперсии; B114 — 19 пунктов об индивидуализме и коллективизме, 4 фактора, 47,1 %); сравнение факторных оценок между группами (t-тест); иерархическая кластеризация (complete linkage, city-block, а также Gower distance в R); бинарная логистическая регрессия с диагностикой мультиколлинеарности (VIF); в R дополнительно — мозаичные диаграммы остатков, множественный анализ соответствий (MCA) и ANOVA по пунктам.

**Основные результаты.** Сверхмобильность растёт с образованием (с ≈14 % до ≈21 %) и с готовностью радикально изменить жизнь (12,6 % → 21,9 %), падает с удовлетворённостью материальным положением (19,4 % → 11,9 %) и сильнее всего связана с типом жилья: среди арендующих жильё — 22,6 %, среди живущих в государственном — 9,9 %. Однако объясняющая сила модели мала (pseudo-R² = 0,038): устойчивые переезды определяются чем-то, что в этом опросе не измерено.

**Важно.** В рефакторинге исправлены четыре содержательные ошибки исходного кода (в R была инвертирована бинарная зависимая переменная, в Python пропуски превращались в категорию «не собственник», битый фильтр скрывал часть факторных нагрузок, VIF считался не по той матрице). Номера в разделе результатов — из исходного прогона; после повторного запуска помеченные значения изменятся. Микроданные в репозиторий не выкладываются: `.sav` принадлежит исследовательской группе.
