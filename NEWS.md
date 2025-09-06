# nmrdata NEWS

## Changes in version 0.99.0 (2025-09-04)
- Initial submission to Bioconductor.
- Provides curated 1D ^1H NMR spectra of rat (murine) urine samples from a bariatric surgery study.
- Includes two datasets:
  - Processed dataset (`bariatric`) accessible via `loadBariatric()`.
  - Raw Bruker NMR experiment folders accessible via `getRawExpDir()`.
- Data will be hosted on ExperimentHub (pending onboarding); Zenodo fallback is used during review.
- Adds vignette, caching helpers
