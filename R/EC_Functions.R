# ==== EC Functions ====

# Description: The functions below were written for processing and cleaning raw data in the `Elections-Canada` repository.

# ---- Custom Read Functions ----

# Create custom function for reading multiple csv files from a folder.
custom_read_csv <- function(x) {
  out <- read_csv(x)
  site <- as.character(stri_extract_all_regex(x, "([[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{4})", simplify=TRUE))
  cbind(... = out)
}

# Create second custom function for reading multiple csv files from a folder. This version opens csv files uses a locale "Window-1252" encoding.
custom_read_csv2 <- function(x) {
  out <- read_csv(x, locale = locale(encoding = "WINDOWS-1252"))
  site <- as.character(stri_extract_all_regex(x, "([[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{4})", simplify=TRUE))
  cbind(... = out)
}

# # Create custom function for reading multiple tab-delimited text files folder.
custom_read_delim <- function(x) {
  out <- read.delim(x)
  site <- as.character(stri_extract_all_regex(x, "([[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{4})", simplify=TRUE))
  cbind(... = out)
}

# custom_read_delim <- function(x) {
#   out <- read.delim(x)
#   site <- as.character(stri_extract_all_regex(x, "([[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{4})", simplify=TRUE))
#   cbind(Date_Published=site, out)
# }

# Hat tip to Aaron Left Stack Overflow for working out the regex used in the above functions. 

# ---- Custom Text Cleaning Functions ---- 

# Elections Canada's data are messy in a multitude of ways. One considerable inconsistency is in how Elections Canada records political parties differently across parliaments. In Parliament 38, for example, Elections Canada refers to New Democratic candidates as "N.D.P./N.P.D." whereas in Parliament 43 such candidates are listed as members of the "NDP-New Democratic Party".

# Preserving Elections Canada's names for political parties is, therefore, not an option - as there is no consistent scheme across elections. Instead, a consistent naming scheme for party affiliations is enforced based on the party names recorded in the Library of Canadian Parliament's elections results data set. 

# Create a function to clean candidate names and political affiliations.
clean_names <- function(pattern, replacement, x, ...) {
  for(i in 1:length(pattern))
    x <- gsub(pattern[i], replacement[i], x, ...)
  x
}

# List of unwanted spellings.Note these are the names as they appear after extracting names from a very messy column that combined candidates names, punctuations marks, and party names. See `EC_Process.R` section Parliament 38 for documentation. 
messy_names <- c("appartenance", "canadienne", "Chrétien", "Communist/Communiste", "Conservative/conservateur", "Independent/Indépendant", "Liberal/Libéral", "Libertarian/Libertarien", "Marijuana", "Marxist-Leninist/Marxiste-Léniniste", "N.D.P./N.P.D.", "PC", "Québécois", "Vert")

# List of corrected spellings corresponding to `messy_names`.
cleaned_names <- c("No affiliation to a recognised party", "Canadian Action Party", "Christian Heritage Party of Canada", "Communist Party of Canada", "Conservative Party of Canada", "Independent", "Liberal Party of Canada", "Libertarian Party of Canada", "Marijuana Party", "	Marxist-Leninist Party of Canada", "New Democratic Party", "Progressive Canadian Party", "Bloc Québécois", "Green Party of Canada")

# Hat tip to Jean-Robert's for the idea on which the above functions is based.