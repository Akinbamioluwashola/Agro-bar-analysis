
# Project Memory — Sales Rep & Customer Analysis

## Data Source

- **File:** `Customers and their Sales Reps xlsx.xlsx`
- **Company:** Agro Bar Magen Nigeria LTD
- **Author:** Akinbami Oluwashola
- **Description:** Customer-to-sales-rep mapping, listing all customers and their assigned sales representatives.

## Loading & Cleaning

The raw Excel file has a messy header (company name, timestamp, report title in the first rows) and 11 unnamed columns. Raw import produces `shola` (2,609 × 11, all character).

### Cleaning steps applied to produce `shola_clean` (2,273 × 7):

1.  **Skip header rows** — the actual column names start several rows into the sheet.
2.  **Drop near-empty columns** — columns with ~100% missing values were removed (`Address (Line 2)`, `State`, `Fax Number`).
3.  **Rename columns** to: `Customer Number`, `Customer Name`, `Street Address`, `City/County`, `Phone Number`, `Sales Rep Number`, `Sales Rep Name`.
4.  **Type conversion** — `Customer Number` and `Sales Rep Number` converted to numeric.
5.  **Standardise `Sales Rep Name`** — title-cased; mapping of original → standardised names stored in `name_changes` (28 reps affected).
6.  **Standardise `City/County`** into a cleaner `location` column used in derived tables (e.g., "Oyo State" → "Ibadan / Oyo").

### Key missingness (from raw 2,604-row data before final clean):

| Column           | Missing % |
|------------------|-----------|
| Street Address   | 9.5%      |
| Phone Number     | 4.9%      |
| Sales Rep Number | 4.8%      |
| Customer Number  | 0.2%      |

## Derived Datasets

| Object               | Rows | Description                               |
|----------------------|------|-------------------------------------------|
| `rep_summary`        | 31   | Sales reps ranked by customer count       |
| `rep_region`         | 60   | Sales rep presence by location            |
| `rep_region_full`    | —    | Full rep × location cross-tabulation      |
| `ian_detail`         | 31   | Ian's customer distribution by location   |
| `peter_detail`       | 22   | Peter's customer distribution by location |
| `city_summary`       | 20   | Top 20 locations by customer count        |
| `overlap`            | 7    | Locations where Ian & Peter both operate  |
| `overlap_long`       | —    | Long-form version of overlap data         |
| `combined`           | —    | Combined Ian + Peter data for comparison  |
| `missing_summary`    | —    | Column-level missingness summary          |
| `single_cust_reps`   | —    | Reps with only 1 customer                 |
| `dup_customers`      | —    | Duplicate customer entries                |
| `rep_summary_export` | —    | Export-ready version of rep summary       |

## Key Findings

- **Top 3 reps by customer count:** Customer Office (341), Ian (232), Peter (209).
- **Ian** covers 31 locations (spread risk); heaviest in Enugu (22%), Delta (16.8%), Rivers/PH (14.7%).
- **Peter** covers 22 locations; heavily concentrated in Ibadan/Oyo (55%).
- Largest customer locations: Ibadan/Oyo (711), Ogun State (236), Lagos (197), Kaduna (158).
- **Ian & Peter overlap:** 7 shared locations out of 46 unique. Overlap is lopsided — in each shared location one rep dominates (typically the other has only 1 customer). 55.6% of Ian's customers and 20.6% of Peter's customers fall in shared locations, but there is very little actual competitive overlap.

## Saved Outputs

### Cleaned Data
- `shola_clean.csv`, `shola_clean.rds`, `shola_clean.xlsx` — cleaned data

### Exports
- `Sales_Rep_Summary.xlsx` — rep summary export

### Reports & Presentations
- `CEO_Customer_Report.qmd` / `.html` / `.pdf` — Quarto HTML/PDF report for CEO
- `CEO_Presentation.qmd` / `.pdf` — Quarto Beamer (LaTeX PDF) slide deck (Madrid theme, dolphin colour)
- `CEO_Presentation_PPTX.qmd` / `.pptx` — Quarto PowerPoint slide deck

### Memos
- `Combined_Risk_Memo_Ian_and_Peter.md` — combined risk memo for Ian & Peter
- `Peter_Risk_Flag_Memo.md` — Peter-specific risk memo

### Serialised R Objects
- `.rds` files: `city_summary.rds`, `ian_detail.rds`, `peter_detail.rds`, `rep_region.rds`, `rep_summary_export.rds`

## Version Control (Git)

- **Initialised:** Yes — local Git repo with one commit (`82dd95f`).
- **Remote:** `https://github.com/Akinbamioluwashola/Agro-bar-analysis.git`
- **`.gitignore`** excludes `.Rproj.user`, `.Rhistory`, `.RData`, `.Ruserdata`, `.positai`, rendered `_files/` directories, and `*.knit.md`.
- **Branch:** `master`.

### Plots (PNG)
- `Customer_Distribution_by_Location.png` — top locations bar chart
- `Sales_Rep_Coverage_by_Region.png` — rep coverage heatmap/bar chart
- `Ian_Regional_Spread_Risk.png` — Ian's geographic spread
- `Ian_Customer_Distribution.png` — colourful bar chart of Ian's locations
- `Peter_Regional_Spread_Risk.png` — Peter's geographic spread
- `Peter_Customer_Distribution.png` — colourful bar chart of Peter's locations
- `Ian_vs_Peter_Comparison.png` — side-by-side top 10 locations comparison
- `Ian_vs_Peter_Overlap.png` — shared locations dodged bar chart
