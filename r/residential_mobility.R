# ===========================================================================
#  Residential mobility — exploratory analysis in R
#
#  Companion to python/residential_mobility.ipynb in the same repository.
#  Data: «Социальная структура» survey, 09.03.2025.
#
#  The .sav file is NOT part of this repository — see the README section
#  "Data and ethics". Point DATA_PATH at your local copy before running.
#
#  Scope: this script covers the exploratory stage (descriptive tables, mosaic
#  plots, factor analysis of the "what drives success" battery, multiple
#  correspondence analysis, logistic regressions and Gower clustering). The
#  confirmatory models are in the Python notebook.
# ===========================================================================

library(haven)           # read_sav(), as_factor()
library(dplyr)           # data manipulation
library(tidyr)           # pivot_longer(), nest(), unnest()
library(ggplot2)         # plotting
library(gtsummary)       # tbl_summary()
library(sjPlot)          # plot_xtab(), tab_model(), tab_df()
library(vcd)             # mosaic()
library(broom)           # tidy(), augment()
library(FactoMineR)      # MCA()
library(factoextra)      # fviz_mca_var(), fviz_mca_ind(), fviz_contrib()
library(marginaleffects) # plot_predictions()
library(gower)           # daisy()
library(patchwork)       # plot_annotation()

DATA_PATH <- "data/Social Structure_09_03_2025_itog.sav"

# A respondent counts as hypermobile from this many moves since age 16.
MOVES_CUTOFF <- 3


# --- 1. Data ---------------------------------------------------------------

outliers <- function(column) {
  iqr <- IQR(column, na.rm = TRUE)
  c(
    quantile(column, 0.25, names = FALSE, na.rm = TRUE) - 1.5 * iqr,
    quantile(column, 0.75, names = FALSE, na.rm = TRUE) + 1.5 * iqr
  )
}

raw <- read_sav(DATA_PATH) |> as_factor()

main <- raw |>
  select(
    age = QAGE,
    moves = Q6,
    sex = Q117,
    okrug = Q118,
    city = Q119,
    important_cause = Q11,
    important_age = Q12,
    educ = Q13,
    work = Q19,
    marrige = Q60,
    children = Q61,
    salary = Q87,
    fam_salary = Q88,
    financial_group = Q91,
    financial_prediction = Q92,
    financial_satisfaction = Q93,
    house = Q94,
    relig = Q101,
    relig_name = Q102,
    will = Q109,

    # What respondents believe drives success (Q110 battery)
    rich_parents = Q110_1,
    successful_relatives = Q110_2,
    good_educ = Q110_3,
    contacts = Q110_4,
    hardwork = Q110_5,
    perseverance_goal = Q110_6,
    risk_skill = Q110_7,
    self_esteem = Q110_8,
    nature_intelegence = Q110_9,
    life_in_capital = Q110_10,
    nationality = Q110_11,
    links_abroad = Q110_12,
    sociability_charisma = Q110_13,
    honesty = Q110_14,
    law_abiding = Q110_15,
    indpendence = Q110_16,
    fortune = Q110_17
  ) |>
  mutate(
    moves_group = factor(
      case_when(
        moves > 2 ~ "3 и более переезда",
        moves > 0 ~ "1-2 переезда",
        moves == 0 ~ "Не переезжал"
      ),
      levels = c("Не переезжал", "1-2 переезда", "3 и более переезда"),
      ordered = TRUE
    ),

    # CORRECTION. The original script read
    #   if_else(moves >= 3, "Обычно-мобильный", "Гиппермобильный")
    # which attached the "mobile" label to respondents with three or more moves
    # and the "hypermobile" label to everyone else — the binary outcome was
    # inverted, so every odds ratio reported from it pointed the wrong way.
    # The levels are also set explicitly so that "Обычно-мобильный" is the
    # reference category in the models below.
    hypermobile = factor(
      if_else(moves >= MOVES_CUTOFF, "Гипермобильный", "Обычно-мобильный"),
      levels = c("Обычно-мобильный", "Гипермобильный")
    ),

    age = as.numeric(age),
    important_age = as.numeric(as.character(important_age))
  )


# --- 2. Descriptives -------------------------------------------------------

# Number of moves: raw distribution and IQR-trimmed view.
main |>
  ggplot(aes(x = moves)) +
  geom_histogram(binwidth = 1, fill = "grey35") +
  labs(
    title = "Number of moves since age 16",
    subtitle = sprintf("max = %d, IQR bounds = [%.0f, %.0f]",
                       max(main$moves, na.rm = TRUE),
                       outliers(main$moves)[1], outliers(main$moves)[2]),
    x = "moves", y = "respondents"
  )

diagnostics <- main |>
  ggplot(aes(y = moves)) +
  geom_boxplot(fill = "grey85") +
  labs(x = NULL, y = "moves")

distribution <- main |>
  ggplot(aes(x = moves)) +
  geom_histogram(binwidth = 1, fill = "grey35") +
  labs(x = "moves", y = "respondents")

diagnostics + distribution +
  plot_annotation(title = "Diagnostics: distribution of the number of moves")

main |>
  count(moves_group) |>
  ggplot(aes(x = moves_group, y = n)) +
  geom_col(fill = "grey35") +
  labs(title = "Mobility groups", x = NULL, y = "respondents")

# Table one, split by the binary outcome and by the three-level grouping.
main |>
  tbl_summary(
    include = -c(moves, important_cause, moves_group),
    by = hypermobile
  ) |>
  add_p(all_categorical() ~ "chisq.test") |>
  bold_labels() |>
  bold_p()

main |>
  tbl_summary(
    include = -c(moves, important_cause, moves_group, hypermobile),
    by = moves_group
  ) |>
  add_p(all_categorical() ~ "chisq.test") |>
  bold_labels() |>
  bold_p()


# --- 3. Bivariate exploration ----------------------------------------------

plot_xtab(main$moves_group, main$sex, show.total = FALSE)
plot_xtab(main$moves_group, main$educ, show.total = FALSE)
plot_xtab(main$moves_group, main$work, show.total = FALSE)
plot_xtab(main$moves_group, main$marrige, show.total = FALSE)

# Mosaic plots: cell shading shows the standardised residuals, i.e. which
# combinations are over- or under-represented.
mosaic(~ sex + hypermobile, data = main, shade = TRUE)
mosaic(~ work + moves_group, data = main, shade = TRUE)
mosaic(~ children + moves_group, data = main, gp_args = list(interpolate = 2), shade = TRUE)
mosaic(~ educ + moves_group, data = main, shade = TRUE)

# Mean number of moves by education.
main |>
  group_by(educ) |>
  summarise(mean_moves = mean(moves, na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(y = educ, x = mean_moves)) +
  geom_col(fill = "grey35") +
  geom_text(aes(label = round(mean_moves, 2)), hjust = 1.1, colour = "white") +
  labs(title = "Mean number of moves by education", x = "moves", y = NULL)

# Mean number of moves by federal district and sex.
main |>
  group_by(okrug, sex) |>
  summarise(mean_moves = mean(moves, na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(x = okrug, y = mean_moves, fill = sex)) +
  geom_col(position = position_dodge(width = 1)) +
  geom_text(
    aes(label = round(mean_moves, 2), group = sex),
    position = position_dodge(width = 1),
    vjust = 1.3, colour = "white", fontface = "bold"
  ) +
  coord_flip() +
  labs(title = "Mean number of moves by federal district and sex", x = NULL, y = "moves")

# Sex gap in the number of moves, estimated separately within each district.
main |>
  group_by(okrug) |>
  nest() |>
  reframe(ttest = map(data, ~ tidy(t.test(moves ~ sex, data = .x)))) |>
  unnest(ttest) |>
  ggplot(aes(y = okrug, x = estimate, colour = p.value < 0.05)) +
  geom_point() +
  geom_linerange(aes(xmin = conf.low, xmax = conf.high)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_text(aes(x = estimate, label = round(estimate, 2)), vjust = -0.8, show.legend = FALSE) +
  labs(
    title = "Difference in the number of moves between men and women, by district",
    subtitle = "Colour marks districts where the difference is significant at p < 0.05",
    x = "difference in means", y = NULL, colour = "p < 0.05"
  ) +
  theme_classic()


# --- 4. What drives success: factor analysis and ANOVA ---------------------

# The Q110 battery uses 8 as "difficult to answer"; it is set to NA and
# complete cases are used.
main_success <- main |>
  select(hypermobile, moves_group, rich_parents:fortune) |>
  mutate(across(rich_parents:fortune, ~ na_if(as.numeric(as.character(.x)), 8))) |>
  drop_na()

success_factors <- main_success |>
  select(rich_parents:fortune) |>
  factanal(factors = 3, scores = "regression")

success_factors |> loadings() |> print(cutoff = 0.3, sort = TRUE)
success_factors |> tidy()

# Does the perceived importance of each success factor differ across mobility
# groups? One-way ANOVA per item, with the factor scores appended.
success_scored <- augment(success_factors, main_success)

success_anova <- success_scored |>
  summarise(across(
    rich_parents:.fs3,
    ~ tidy(aov(.x ~ moves_group, data = success_scored))$p.value[1]
  )) |>
  pivot_longer(everything(), names_to = "variable", values_to = "p_value") |>
  mutate(significant = if_else(p_value < 0.05, "*", "")) |>
  arrange(p_value)

tab_df(
  as.data.frame(success_anova),
  show.footnote = TRUE,
  footnote = "One-way ANOVA of each item on the three-level mobility group. * p < 0.05"
)


# --- 5. Multiple correspondence analysis -----------------------------------

mca <- main |>
  select(sex, educ, marrige, financial_group, children) |>
  MCA(graph = FALSE)

fviz_mca_var(mca, col.var = "black")
fviz_mca_ind(mca, habillage = main$hypermobile, geom = "point", addEllipses = TRUE)
fviz_contrib(mca, choice = "var", axes = 1)


# --- 6. Logistic regressions -----------------------------------------------

# Five separate models rather than one saturated model, so that each
# socio-demographic block is read on its own.
models <- list(
  children = glm(hypermobile ~ age + children, family = binomial("logit"), data = main),
  work = glm(hypermobile ~ age + work, family = binomial("logit"), data = main),
  sex = glm(hypermobile ~ age + sex, family = binomial("logit"), data = main),
  finances = glm(hypermobile ~ age + financial_group, family = binomial("logit"), data = main),
  educ = glm(hypermobile ~ age + educ, family = binomial("logit"), data = main)
)

tab_model(
  models$children, models$work, models$sex, models$finances, models$educ,
  show.ci = FALSE, p.style = "stars"
)

# Predicted probability of being hypermobile by number of children.
plot_predictions(models$children, variables = "children", by = "children")


# --- 7. Cluster analysis (Gower distance) ----------------------------------

cluster_vars <- c("age", "sex", "educ", "salary", "work", "marrige", "children")

cluster_input <- main |> select(all_of(cluster_vars))

# Gower distance handles the mix of numeric and categorical variables without
# one-hot encoding.
cluster_distance <- daisy(cluster_input, metric = "gower")
cluster_fit <- hclust(cluster_distance)

# Cluster sizes for a range of k, to choose the solution.
for (k in 1:5) {
  cat("k =", k, "\n")
  print(table(cutree(cluster_fit, k = k)))
}

main_clustered <- cluster_input |>
  mutate(cluster = factor(cutree(cluster_fit, k = 5)))

main_clustered |>
  tbl_summary(by = cluster, missing = "no") |>
  add_p() |>
  bold_labels()


# --- 8. Reproducibility ----------------------------------------------------

sessionInfo()

# ---------------------------------------------------------------------------
# Note on scope. An earlier version of this script also loaded the 2015 wave
# ("Проект-2015. База количественного этапа исследования.sav") and printed its
# structure, but no analysis was run on it. That block has been removed: a
# comparative 2015 / 2025 design is a separate piece of work, and shipping a
# half-finished comparison is worse than not shipping it. The 2025 file is the
# one analysed here.
# ---------------------------------------------------------------------------
