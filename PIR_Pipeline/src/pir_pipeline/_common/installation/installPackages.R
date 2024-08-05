################################################################################
## Written by: Reggie Gilliard
## Date: 02/23/2024
## Description: Script to restore packages using renv.
################################################################################


# This script takes command line arguments and restores packages using renv.

# Retrieve command line arguments
args <- commandArgs(TRUE)
# Extract the path to the renv folder
renv_path <- args[1]

# Activate the renv environment
source(file.path(renv_path, "activate.R"))
# Restore packages
renv::restore()
renv::activate()