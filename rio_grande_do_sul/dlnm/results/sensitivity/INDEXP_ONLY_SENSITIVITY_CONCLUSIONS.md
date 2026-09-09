## IndexP Sensitivity Conclusions

This note addresses the specific reviewer request to evaluate whether the main conclusions remain similar with and without the RS geocode filter (`<10` total cases).

The organized sensitivity work was prepared under:

- `scripts/sensibilidade_geocodes_mesmo_pipeline/`
- with the exact no-plot audit scripted in `run_sensitivity_audit_no_plots.R`

### Exact same-pipeline comparison for IndexP

Filtered production model:

- geocodes used: `150`
- geocodes removed: `51`
- rows used: `60900`
- AIC: `55919`
- theta: `0.36316`

Exact unfiltered rerun:

- geocodes used: `201`
- geocodes removed: `0`
- rows used: `81606`
- AIC: `57423`
- theta: `0.36233`

### Main result

For `IndexP`, removing the RS geocode filter **worsened model fit substantially**:

- delta AIC (`unfiltered - filtered`) = `1504`

Because lower AIC indicates a better fit among directly comparable models, this result supports the interpretation that the RS filter improves statistical stability in the same modeling pipeline.

### Do the substantive conclusions remain similar?

Yes, **the main qualitative conclusion remains similar for IndexP**.

In both analyses:

- lower `IndexP` values were associated with markedly higher relative risk;
- intermediate values remained close to the reference region;
- higher `IndexP` values were associated with lower relative risk.

Key RR summaries:

Filtered model:

- 10th percentile (`IndexP ~ 0.4`): `RR = 7.74` (`95% CI 5.40-11.08`)
- 50th percentile (`IndexP ~ 0.7`): `RR = 0.88` (`95% CI 0.86-0.89`)
- 90th percentile (`IndexP ~ 1.1`): `RR = 0.10` (`95% CI 0.07-0.14`)

Unfiltered model:

- 10th percentile (`IndexP ~ 0.4`): `RR = 6.91` (`95% CI 4.92-9.71`)
- 50th percentile (`IndexP ~ 0.7`): `RR = 0.78` (`95% CI 0.75-0.80`)
- 90th percentile (`IndexP ~ 1.0`): `RR = 0.12` (`95% CI 0.09-0.16`)

### Interpretation for the reviewer

The exact same-pipeline sensitivity analysis for `IndexP` shows that:

1. the RS geocode filter improves model fit materially;
2. the direction and overall shape of the `IndexP` association are preserved without the filter;
3. therefore, the substantive conclusion based on `IndexP` is robust, while the filtered analysis provides a more stable specification for RS.

### Suggested reviewer-facing sentence

```text
In an exact same-pipeline sensitivity analysis restricted to the Index P model, removing the RS geocode filter (<10 total cases) worsened model fit substantially (AIC 57,423 without the filter vs 55,919 with the filter), but the main qualitative conclusion remained unchanged: lower Index P values were consistently associated with higher relative risk, whereas higher Index P values remained associated with lower relative risk. These findings indicate that the RS filter improves model stability while preserving the substantive interpretation of the climate-risk relationship.
```
