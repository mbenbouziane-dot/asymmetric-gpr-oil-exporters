# Asymmetric Geopolitical Risk and Macroeconomic Resilience: Do Oil Exporters Suffer More?

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stata](https://img.shields.io/badge/Stata-16%2B-blue.svg)](https://www.stata.com/)
[![R](https://img.shields.io/badge/R-4.3%2B-blue.svg)](https://www.r-project.org/)
[![Data](https://img.shields.io/badge/Data-CSV-green.svg)](./data/)

> **Paper status:** Under submission at *Energy Economics*  
> **Authors:** Benbouziane Mohamed, Professor of Economics, Algerian University  
> **Date:** August 2026

---

## 📋 Abstract

This paper asks whether oil-exporting emerging markets respond differently to global geopolitical risk (GPR) shocks than their diversified peers do. Using a panel of 30 emerging and frontier economies over 2000 to 2024, we estimate Mean Group ARDL models and add a nonlinear ARDL (NARDL) decomposition. The central finding is that oil exporters absorb geopolitical shocks on the external balance sheet rather than in output: GDP growth shows no significant direct response, while foreign reserves fall as GPR rises. A one-standard-deviation shock is associated with a reserve drawdown of roughly 1.1 percentage points of GDP in the short run. The NARDL decomposition reveals asymmetry: de-escalations raise reserves more dependably than escalations lower them, implying a cumulative drain on reserve adequacy across repeated geopolitical cycles.

---

## 📁 Repository Structure

```
.
├── code/                          # Replication scripts
│   ├── 00_master.do              # Master Stata script (runs everything)
│   ├── 01_data_prep.do           # Data cleaning & variable construction
│   ├── 02_descriptive_stats.do   # Table 1: Descriptive statistics
│   ├── 03_mg_ardl_baseline.do    # Table 2: MG-ARDL baseline & split-sample
│   ├── 04_nardl_asymmetry.do     # Table 3: NARDL asymmetric decomposition
│   ├── 05_robustness.do          # Section 6.5: Robustness checks
│   ├── 06_gdp_inflation_channels.do  # Table 2, Cols 4-7: Growth & inflation
│   └── R/
│       └── 01_main_analysis.R    # Equivalent R implementation
│
├── data/                          # Datasets
│   ├── main_data.csv             # Cleaned panel dataset (30 countries, 2000-2024)
│   └── data_dictionary.csv       # Variable definitions & sources
│
├── figures/                       # Generated figures (populated after running code)
├── out/                           # Generated tables & logs (populated after running code)
│
├── paper/                         # Working paper directory (empty until acceptance)
│
├── .gitignore                     # Git ignore rules
├── CITATION.cff                   # Citation metadata
├── LICENSE                        # MIT License
└── README.md                      # This file
```

---

## 🚀 Quick Start

### Option A: Stata (Primary)

1. **Clone or download** this repository to your local machine.
2. **Open Stata 16 or later**.
3. **Edit the path** in `code/00_master.do`:
   ```stata
   global root "C:/your/path/to/this/repository"
   ```
4. **Run the master script**:
   ```stata
   do "${root}/code/00_master.do"
   ```
5. **Expected runtime:** ~3–5 minutes on a standard laptop.
6. **Outputs** will appear in `out/` and `figures/`.

### Option B: R (Open-source alternative)

1. **Open RStudio** (R 4.3+ required).
2. **Set the working directory** to the repository root.
3. **Run** `code/R/01_main_analysis.R`.
4. **Required packages** (auto-installed if missing): `plm`, `dplyr`, `readr`, `sandwich`, `lmtest`, `texreg`, `tibble`.

---

## 📊 Data

### Sample
- **Countries:** 30 emerging and frontier economies
- **Time period:** Annual data, 2000–2024 (25 years)
- **Observations:** 750 country-year observations (raw); effective sample varies by model after lag/difference creation

### Classification
| Group | Countries | Count |
|-------|-----------|-------|
| **Oil exporters** | Angola, Azerbaijan, Bahrain, Brunei, Colombia, Algeria, Egypt, Gabon, Indonesia, Iraq, Kazakhstan, Kuwait, Mexico, Malaysia, Nigeria, Oman, Qatar, Saudi Arabia, Turkmenistan, Timor-Leste, Trinidad and Tobago, UAE, Uzbekistan | 23 |
| **Non-oil exporters** | Brazil, Chile, Ghana, Morocco, Mongolia, Peru, South Africa | 7 |

### Data Sources

| Variable | Source | URL |
|----------|--------|-----|
| Global GPR Index | Caldara & Iacoviello (2022) | https://www.matteoiacoviello.com/gpr.htm |
| Foreign Reserves (% GDP) | IMF International Financial Statistics | https://data.imf.org/ |
| Real GDP Growth | World Bank WDI + IMF WEO | https://databank.worldbank.org/ |
| CPI Inflation | IMF IFS + national statistical offices | https://data.imf.org/ |
| Commodity Terms of Trade | IMF WEO | https://www.imf.org/en/Publications/WEO |
| Trade Openness | World Bank WDI | https://databank.worldbank.org/ |
| Control of Corruption | World Governance Indicators | https://info.worldbank.org/governance/wgi/ |
| De Facto Exchange-Rate Regime | Ilzetzki, Reinhart & Rogoff (2019) | https://www.carmenreinhart.com/data/ |

> **Note:** Some raw data sources require subscription or registration. The cleaned dataset (`main_data.csv`) is provided for direct replication. See `data_dictionary.csv` for full variable definitions.

---

## 🔬 Methodology

### Mean Group ARDL (MG-ARDL)
We implement the **Pesaran, Shin & Smith (1999)** Mean Group estimator manually by estimating separate ARDL(1,1) regressions in error-correction form for each country, then computing unweighted mean-group statistics:

```
Δy_it = φ_i (y_{i,t-1} − θ_{0i} − θ_i' X_{i,t-1}) + γ_i' ΔX_{i,t} + ε_it
```

Long-run coefficient: β_j = −θ_j / φ_i  
Mean Group SE: σ_j / √N

### Nonlinear ARDL (NARDL)
Following **Shin, Yu & Greenwood-Nimmo (2014)**, we decompose GPR into positive and negative partial sums:
- `GPR_t^+ = Σ max(ΔGPR_t, 0)`  (escalations)
- `GPR_t^- = Σ min(ΔGPR_t, 0)`  (de-escalations)

Wald test for long-run symmetry: H₀: β⁺ = β⁻

---

## 📈 Key Results

| Result | Estimate | Significance |
|--------|----------|--------------|
| Short-run reserve drawdown (oil exporters) | −1.1 pp of GDP per 1-sd GPR shock | p = 0.058 (marginally) |
| Long-run reserve level (oil exporters) | −2.7 pp of GDP | p = 0.074 (marginally) |
| NARDL: Positive GPR shock (escalation) | −0.171 | p = 0.107 (marginally) |
| NARDL: Negative GPR shock (de-escalation) | +0.135 | p = 0.006 (***) |
| Wald test for symmetry | χ²(1) = 5.42 | p = 0.020 (**) |

---

## 🛡️ Robustness

The replication package includes four robustness checks:
1. **Driscoll-Kraay** standard errors (cross-sectional dependence)
2. **De facto peg interaction** (exchange-rate regime rigidity)
3. **Pre-2020 sample** (exclude COVID/Gaza war period)
4. **Country-specific GPR** (where available)

See `code/05_robustness.do` for implementation.

---

## 📚 Citation

If you use this code or data, please cite:

```bibtex
@article{benbouziane2026asymmetric,
  title={Asymmetric Geopolitical Risk and Macroeconomic Resilience: Do Oil Exporters Suffer More?},
  author={Benbouziane, Mohamed},
  journal={Energy Economics},
  year={2026},
  note={Forthcoming}
}
```

See [`CITATION.cff`](./CITATION.cff) for machine-readable citation metadata.

---

## ⚖️ License

This repository is licensed under the **MIT License** — see [`LICENSE`](./LICENSE) for details.

The **code and documentation** are provided under MIT. The **underlying data** are subject to the terms of the original data providers (IMF, World Bank, etc.).

---

## 🙋 Contact

For questions about replication, data, or code:

**Benbouziane Mohamed**  
Professor of Economics  
Algerian University  
Email: mohamed.benbouziane@univ-tlemcen.dz 
GitHub: [@your-github-handle]

---

## 📝 Notes for Replicators

- **Stata version:** 16 or later recommended. The MG-ARDL estimator is implemented manually; no user-written packages are strictly required for the core estimation (only `estout` and `outreg2` for table export).
- **Dropped countries:** After creating lags and first differences, 1 country drops from reserves/inflation specifications (effective N = 29) and none from growth (effective N = 30). The `valid_*` flags in the dataset handle this automatically.
- **Random seeds:** Not applicable — no simulation or bootstrap is used.
- **Computational environment:** Results were generated on Stata 17.0 (Windows 11, 64-bit). R results were cross-checked on R 4.3.1.

---

*Last updated: August 2026*
