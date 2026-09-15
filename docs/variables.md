# Codebook — variables, mapping and derived measures

This documents the variables used in the analysis, so that the code can be read without access to the survey file. **No respondent-level data is reproduced here** — only the questionnaire structure, which is required to understand the pipeline.

---

## 1. Source

**«Социальная структура»**, fieldwork 09.03.2025. SPSS file `Social Structure_09_03_2025_itog.sav`, 7,563 respondents × 443 variables. The file is **not distributed with this repository** (see README §7).

---

## 2. Variable mapping

The SPSS file stores questions under technical names (`Q6`, `Q115`, …) with the wording kept in the file metadata (`meta.column_labels`). Both scripts map the wording to short names.

| SPSS | Question wording | Short name | Type |
| --- | --- | --- | --- |
| `Q115`-ish | В115. Возраст: число лет | `age` | numeric |
| `Q117` | В117. Пол | `sex` | 1 = Мужчина, 2 = Женщина |
| `Q6` | В6. Общее число переездов, начиная с 16 лет | `all_reloc` | count — **outcome** |
| `Q7` | В7. Число переездов в пределах одного населённого пункта | `city_reloc` | count |
| `Q8` | В8. Переезды за пределы населённого пункта, в пределах России | `russia_reloc` | count |
| `Q8` | В8. Переезды за пределы населённого пункта, в пределах СССР | `ussr_reloc` | count |
| `Q9` | В9. Переезды в другую страну или из другой страны | `world_reloc` | count |
| `Q13` | В13. Уровень образования респондента | `educ` | ordinal 1–10 |
| `Q19` | В19. Работаете ли Вы в настоящее время? | `work` | 1 = Да, 2 = Нет |
| `Q25` | В25. Как оформлены отношения с нанимателем | `contract` | nominal |
| `Q87` | В87. Совокупный месячный доход респондента | `personal_income` | numeric, ₽ |
| `Q88` | В88. Совокупный месячный доход семьи | `fam_income` | numeric, ₽ |
| `Q61` | В61. Есть ли у Вас дети? | `children` | 1 = Да, 2 = Нет |
| `Q60` | В60. Семейное положение респондента | `marrige` | nominal (8 categories) |
| `Q94` | В94. Жилищные условия респондента | `home` | nominal (10 categories) |
| `Q95` | В95. Кто собственник жилья респондента | `home_owner` | nominal 1–5, 8, 9 |
| `Q93` | В93. Удовлетворённость материальным положением | `fin_satisfaction` | ordinal 1–5, 9 |
| `Q91` | В91. К какой из следующих групп Вы себя относите? | `fin_group` | ordinal 1–6 |
| `Q92` | В92. Как изменится материальное положение в 2025 году | `fin_pred` | ordinal 1–5, 9 |
| `Q101` | В101. Вы – верующий человек? | `relig` | 1 = Да, 2 = Нет |
| `Q109` | В109. Достаточно ли у Вас воли радикально изменить жизнь? | `volya` | ordinal 1–5, 9 |
| `Q119` | В119. Тип населённого пункта | `city` | nominal 1–10 |
| `Q21` | В21. Профессия: укрупнённые группы ISCO | `work_name` | nominal |
| `Q21` | В21. Кодировка работы: ISCO-08 | `work_name2` | nominal, unit groups |

R-only variables (used in `r/residential_mobility.R` but not in the Python pipeline): `Q118` (`okrug`, federal district), `Q11`/`Q12` (`important_cause`, `important_age`), `Q102` (`relig_name`), and the 17-item success battery `Q110_1` … `Q110_17`.

---

## 3. Missing-value codes

The questionnaire does not use SPSS system-missing for non-response; it uses explicit numeric codes, which is why they must be recoded before any model is fitted.

| Code | Meaning | Variables | Handling |
| --- | --- | --- | --- |
| `9` | «Затрудняюсь ответить» | `fin_satisfaction`, `fin_pred`, `volya`, `home_owner`, B107/B114 items | → `NaN` |
| `8` | «Другое» | `home_owner` | → `NaN` |
| `10` | «Другое» | `home` | → `NaN` |
| `8` | «Затрудняюсь ответить» | success battery (`Q110_*`) — R only | → `NA` |

**This matters.** If these codes are left in place they are read as an extreme position on the scale: code `9` on a 1–5 satisfaction item becomes "more satisfied than 5". The original version of the Python code made a related mistake in the opposite direction, mapping the missing codes of `home_owner` to `0` and so merging "no answer" with "does not own" — see README §5.2.

---

## 4. Derived variables

| Variable | Definition | Notes |
| --- | --- | --- |
| `type` | `"Сверхмобильные"` if `all_reloc > MOVES_THRESHOLD` else `"Маломобильные"` | `MOVES_THRESHOLD = 3` in Python, `MOVES_CUTOFF = 3` with `>=` in R — **the two differ**, see README §6.1 |
| `type_bin` | `1` for hypermobile, `0` otherwise | outcome in the logistic regression |
| `home_owner_bin` | `1` if `home_owner == 1` (the family owns the dwelling), `0` otherwise, `NaN` if missing | corrected: misses are preserved, not folded into `0` |
| `sov_left`, `lib_cons`, `prog_left`, `money`, `merit` | factor scores, block B107 (5 factors, 52.7 % cumulative variance) | principal-component extraction on min-max scaled items |
| `emot`, `ego`, `colect`, `ind` | factor scores, block B114 (4 factors, 47.1 % cumulative variance) | same procedure |
| `moves_group` (R) | ordered factor: «Не переезжал» / «1-2 переезда» / «3 и более переезда» | descriptive grouping |
| `hypermobile` (R) | factor with levels «Обычно-мобильный» (reference) / «Гипермобильный» | **corrected**: the original labels were inverted |

---

## 5. Item batteries

**B107** — 17 Likert items (5-point) on the causes of poverty, the meaning of fairness, and the role of authorities and experts. Items `В107.13` and `В107.14` form a reversed pair (intrinsic vs. extrinsic work motivation).

**B114** — 19 Likert items (5-point) on individualism, competitiveness, collectivism and family obligation.

**Q110** — 17 items on what drives success in life (wealthy parents, education, contacts, hard work, risk-taking, self-esteem, natural intelligence, living in the capital, nationality, links abroad, charisma, honesty, law-abidingness, independence, fortune). Used only in the R script, where a 3-factor solution is extracted and each item is tested by one-way ANOVA across mobility groups.

Item wordings for the B107 and B114 batteries are reproduced verbatim in `python/residential_mobility.ipynb` (cells defining `B107_ITEMS` and `B114_ITEMS`), because the regular expressions and factor labels are meaningless without them.
