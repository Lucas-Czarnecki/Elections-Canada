# ==== EC Paths ====

# Description: Specifies the file paths to raw data.Base function `list.files` returns a character vector of the names of files in each folder.The script assumes that raw data are located in a folder called `GitHub` in your local computer's home directory (as represented by the tilde shortcut in each path). 

# File paths to raw data.
path36 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 36", pattern = "*.txt", full.names = TRUE)
path37 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 37", pattern = "*.txt", full.names = TRUE)
path38 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 38/pollbypoll", pattern = "*.csv", full.names = TRUE)
path39 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 39/pollresults", pattern = "*.csv", full.names = TRUE)
path40 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 40/pollresults", pattern = "*.csv", full.names = TRUE)
path41 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 41/pollresults", pattern = "*.csv", full.names = TRUE)
path42 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 42/pollresults", pattern = "*.csv", full.names = TRUE)
path43 <- list.files("~/GitHub/Elections-Canada/data/raw/Parliament 43/pollresults", pattern = "*.csv", full.names = TRUE)
