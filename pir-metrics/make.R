library(here)

# suppressMessages({
  source(here('pir-metrics', 'import', 'src', 'import.R'))
  source(here('process-centers', 'src', 'process-centers.R'))
  gc(full = T)
  source(here('pir-metrics', 'clean', 'src', 'clean.R'))
  source(here('pir-metrics', 'reporting', 'src', 'reporting.R'))
# })