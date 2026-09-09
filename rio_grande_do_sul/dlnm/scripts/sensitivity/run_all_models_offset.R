source("functions_dlnm_offset_rio_grande_do_sul.R")

rerun_filtered <- identical(
  tolower(Sys.getenv("RERUN_FILTERED_SENSITIVITY", "false")),
  "true"
)

run_geocode_filter_sensitivity(rerun_filtered = rerun_filtered)

