# ==== Elections Canada (Rough First Draft) ==== 

# Author: Lucas Czarnecki

# Description: This script processes and cleans raw data from Elections Canada (EC) on Parliaments 36 through 43. The original data from EC are organized in a myriad of formats, which as a result presents barriers to researchers wishing to analyze these elections results. For more information on the original data, variables, and cleaning operations, please consult the README files in this repository.   

# Source(s): https://www.elections.ca/content.aspx?section=res&dir=rep/off&document=index&lang=e

# ---- Load Data & Packages ----

if(!require(pacman)) install.packages("pacman")
pacman::p_load(stringi, tidyverse) 

# Load custom functions from ED_Functions.R script.
source("~/GitHub/Elections-Canada/R/EC_Functions.R")

# Load file paths to raw data.
source("~/GitHub/Elections-Canada/R/EC_Paths.R")

# ---- Description of Raw Data ----

# General Notes: Elections Canada (EC) inconsistently presents data in two formats (i.e., wide and long) and uses different file extensions (.csv and .txt) for election results between 1996 and 2019. This script processes the raw data into a tidy format that can be used to analyze election results across time. Unfortunately, Elections Canada did not include any unique identifiers in their csv files to record the election or parliamentary session. For this reason, raw data are read from their respective folders and assigned variables such as `Election_Date` and `Parliament` to identify the election. Furthermore, general inconsistencies, such as colnames containing different characters across election years, missing format options, and other inconsistencies, necessitate small variations on what could have otherwise been a more concise script. Parliament 38, for example, is limited to poll-by-poll election results in EC's "format 1" (i.e., a wide format where each candidate's name appears as a column). Parliaments 36 and 37 present data in an even messier wide format that requires much more effort to process. For more information on the original data, variables, and cleaning operations, please consult the README files in this repository. 

# TODO consider creating a master lookup table to replace supplementary tables in this script. 

# ==== Parliament 43 ====

# Apply custom function to read file names from `EC_Paths.R` to create a large list where each element is a data frame containing election results on a given electoral division. 
parl43 <- lapply(path43, custom_read_csv) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the parliamentary session.
parl43 <- lapply(parl43, function(x)
  cbind(x, Election_Date="2019-10-21")) %>% 
    lapply(function(x)
      cbind(x, Parliament="43")) %>% 
    lapply(function(x)
      cbind(x, Election_Type="General"))

# Before it is possible to concatenate the list into a single data frame, it is first necessary to ensure that all variables are consistently encoded within each element. Two variable are problematic (i.e., variables 4 and 8). These variables are coerced into characters to ensure the same class across all elements in the list.
parl43 <- lapply(parl43, function(parl43) mutate_at(parl43, .vars = 8, as.character))
parl43 <- lapply(parl43, function(parl43) mutate_at(parl43, .vars = 4, as.character))

# Concatenate data into a single data frame.
parl43 <- parl43 %>% 
  bind_rows()

# Rename columns for simplicity and consistency.
parl43 <- parl43 %>% 
  rename(Electoral_District_No = `....Electoral District Number/Numéro de circonscription`,
         Constituency_Fr = `....Electoral District Name_French/Nom de circonscription_Français`,
         Constituency = `....Electoral District Name_English/Nom de circonscription_Anglais`,
         Polling_Station_No = `....Polling Station Number/Numéro du bureau de scrutin`,
         Polling_Station_Name = `....Polling Station Name/Nom du bureau de scrutin`,
         No_Poll_Held = `....No Poll Held Indicator/Indicateur de bureau sans scrutin`,
         Void_Poll = `....Void Poll Indicator/Indicateur de bureau supprimé`,
         Merged_With = `....Merge With/Fusionné avec`,
         Rejected_Ballots_PollNo = `....Rejected Ballots for Polling Station/Bulletins rejetés du bureau`,
         Political_Affiliation = `....Political Affiliation Name_English/Appartenance politique_Anglais`,
         Political_Affiliation_Fr = `....Political Affiliation Name_French/Appartenance politique_Français`,
         Incumbent = `....Incumbent Indicator/Indicateur_Candidat sortant`,
         Result = `....Elected Candidate Indicator/Indicateur du candidat élu`,
         Electors = `....Electors for Polling Station/Électeurs du bureau`,
         Votes = `....Candidate Poll Votes Count/Votes du candidat pour le bureau`
         )

# Note 1: Keep in mind that `Rejected_Ballots_PollNo` records the number of rejected ballots at the level of the polling station (i.e., the ballot box) and NOT the number of rejected ballots for that candidate. 

# Note 2: Not included in the rename function above are columns recording candidates' names. For reasons unknown, dplyr's `rename` function returns an `rlang::last_error()`. Could be the apostrophe's in the colname, but it is unclear why the error occures when the script is run from source, but not when executing the individual line of code in console. 

# Base R instead of `dplyr` is used to rename columns that return a `rlang::last_error()`.
colnames(parl43)[11] <- "Last_Name"
colnames(parl43)[12] <- "Middle_Names"
colnames(parl43)[13] <- "First_Name"

# Create a combined key variable, `Candidate`, to record each person's full name.
parl43$Candidate <- paste(parl43$Last_Name, parl43$First_Name, sep = ", ") %>% 
  paste(parl43$Middle_Names, sep = " ")

# Remove NAs from combined key.
parl43$Candidate <- gsub(" NA", "", parl43$Candidate)

# Note: There is an inconsistency in the way that first and middle names are recorded. In most cases, EC records candidates' middle names in the same column as `First_Name`. For example, "Alexander J." and "Judy M.". This error can be easily fixed assuming that the second name in each string is the candidates' middle name. 

# Correct Candidates' middle names. 
parl43 <- parl43 %>% 
  separate(col = First_Name, into = c("First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Create `Province_Territory` column in `parl43.` based on supplementary data.

# Load supplementary table to identify `Province_Territory` in `parl43` based on common Electoral District Number in said data and table 11.
sup43 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 43/tables/table_tableau11.csv")

# Identify the province or territory for each electoral district. To this end, the name of the province or territory is identified by matching the Electoral district numbers in `parl43` to the same variable in `sup43`.
parl43$Province_Territory <-  sup43$Province[match(parl43$Electoral_District_No, sup43$`Electoral District Number/Numéro de circonscription`)] 

# Distinguish between French and English spellings in `parl43`'s `Province_Territory` variable.
parl43 <- parl43 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/", remove = FALSE)
  
# Organize column order.
parl43 <- parl43 %>%
  select(Province_Territory, Province_Territory_Fr, Election_Date, Election_Type, Parliament, Constituency, Constituency_Fr, Electoral_District_No, Electors, Polling_Station_Name, Polling_Station_No, Merged_With, Void_Poll, No_Poll_Held, Candidate, Last_Name, First_Name, Middle_Names, Political_Affiliation, Political_Affiliation_Fr, Incumbent, Result, Votes, Rejected_Ballots_PollNo)

# ==== Parliament 42 ====

# Apply the same custom function to read file names for Parliament 42.
parl42 <- lapply(path42, custom_read_csv) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl42 <- lapply(parl42, function(x)
  cbind(x, Election_Date="2015-10-19")) %>% 
  lapply(function(x)
    cbind(x, Parliament="42")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element.
parl42 <- lapply(parl42, function(parl42) mutate_at(parl42, .vars = 8, as.character))
parl42 <- lapply(parl42, function(parl42) mutate_at(parl42, .vars = 4, as.character))

# Concatenate data into a single data frame.
parl42 <- parl42 %>% 
  bind_rows()

# Rename columns for simplicity.
parl42 <- parl42 %>% 
  rename(Electoral_District_No = `....Electoral District Number/Numéro de circonscription`,
         Constituency_Fr = `....Electoral District Name_French/Nom de circonscription_Français`,
         Constituency = `....Electoral District Name_English/Nom de circonscription_Anglais`,
         Polling_Station_No = `....Polling Station Number/Numéro du bureau de scrutin`,
         Polling_Station_Name = `....Polling Station Name/Nom du bureau de scrutin`,
         No_Poll_Held = `....No Poll Held Indicator/Indicateur de bureau sans scrutin`,
         Void_Poll = `....Void Poll Indicator/Indicateur de bureau supprimé`,
         Merged_With = `....Merge With/Fusionné avec`,
         Rejected_Ballots_PollNo = `....Rejected Ballots for Polling Station/Bulletins rejetés du bureau`,
         Political_Affiliation = `....Political Affiliation Name_English/Appartenance politique_Anglais`,
         Political_Affiliation_Fr = `....Political Affiliation Name_French/Appartenance politique_Français`,
         Incumbent = `....Incumbent Indicator/Indicateur_Candidat sortant`,
         Result = `....Elected Candidate Indicator/Indicateur du candidat élu`,
         Electors = `....Electors for Polling Station/Électeurs du bureau`,
         Votes = `....Candidate Poll Votes Count/Votes du candidat pour le bureau`
  )

# Rename columns that return a `rlang::last_error()` when using `dplyr`.
colnames(parl42)[11] <- "Last_Name"
colnames(parl42)[12] <- "Middle_Names"
colnames(parl42)[13] <- "First_Name"

# Create a combined key variable, `Candidate`, to record each person's full name.
parl42$Candidate <- paste(parl42$Last_Name, parl42$First_Name, sep = ", ") %>% 
  paste(parl42$Middle_Names, sep = " ")

# Remove NAs from combined key.
parl42$Candidate <- gsub(" NA", "", parl42$Candidate)

# Correct Candidates' middle names. 
parl42 <- parl42 %>% 
  separate(col = First_Name, into = c("First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Create `Province_Territory` column in `parl42` based on supplementary data.

# Load supplementary table to identify `Province_Territory` in `parl42` based on common Electoral District Number in said data and table 11.
sup42 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 42/tables/table_tableau11.csv")

# Identify the province or territory for each electoral district. To this end, the name of the province or territory is identified by matching the Electoral district numbers in `parl42` to the same variable in `sup42`.
parl42$Province_Territory <-  sup42$Province[match(parl42$Electoral_District_No, sup42$`Electoral District Number/Numéro de circonscription`)] 

# Distinguish between French and English spellings in `parl43`'s `Province_Territory` variable.
parl42 <- parl42 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/", remove = FALSE)

# Organize column order.
parl42 <- parl42 %>%
  select(Province_Territory, Province_Territory_Fr, Election_Date, Election_Type, Parliament, Constituency, Constituency_Fr, Electoral_District_No, Electors, Polling_Station_Name, Polling_Station_No, Merged_With, Void_Poll, No_Poll_Held, Candidate, Last_Name, First_Name, Middle_Names, Political_Affiliation, Political_Affiliation_Fr, Incumbent, Result, Votes, Rejected_Ballots_PollNo)

# ==== Parliament 41 ====

# Apply a custom function to read csv file names for Parliament 41 a locale "Window-1252" encoding.
parl41 <- lapply(path41, custom_read_csv2) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl41 <- lapply(parl41, function(x)
  cbind(x, Election_Date="2011-05-02")) %>% 
  lapply(function(x)
    cbind(x, Parliament="41")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element.
parl41 <- lapply(parl41, function(parl41) mutate_at(parl41, .vars = 8, as.character))
parl41 <- lapply(parl41, function(parl41) mutate_at(parl41, .vars = 4, as.character))

# Concatenate data into a single data frame.
parl41 <- parl41 %>% 
  bind_rows()

# Rename columns for simplicity and consistency.
parl41 <- parl41 %>% 
  rename(Electoral_District_No = `....Electoral District Number/Numéro de circonscription`,
         Constituency_Fr = `....Electoral District Name_French/Nom de circonscription_Français`,
         Constituency = `....Electoral District Name_English/Nom de circonscription_Anglais`,
         Polling_Station_No = `....Polling Station Number/Numéro du bureau de scrutin`,
         Polling_Station_Name = `....Polling Station Name/Nom du bureau de scrutin`,
         No_Poll_Held = `....No Poll Held Indicator/Indicateur de bureau sans scrutin`,
         Void_Poll = `....Void Poll Indicator/Indicateur de bureau supprimé`,
         Merged_With = `....Merge With/Fusionné avec`,
         Rejected_Ballots_PollNo = `....Rejected Ballots for Polling Station/Bulletins rejetés du bureau`,
         Last_Name =  `....Candidate's Family Name/Nom de famille du candidat`,
         First_Name = `....Candidate's First Name/Prénom du candidat`,
         Middle_Names = `....Candidate's Middle Name/Second prénom du candidat`,
         Political_Affiliation = `....Political Affiliation Name_English/Appartenance politique_Anglais`,
         Political_Affiliation_Fr = `....Political Affiliation Name_French/Appartenance politique_Français`,
         Incumbent = `....Incumbent Indicator/Indicateur_Candidat sortant`,
         Result = `....Elected Candidate Indicator/Indicateur du candidat élu`,
         Electors = `....Electors for Polling Station/Électeurs du bureau`,
         Votes = `....Candidate Poll Votes Count/Votes du candidat pour le bureau`
  )

# Create a combined key variable, `Candidate`, to record each person's full name.
parl41$Candidate <- paste(parl41$Last_Name, parl41$First_Name, sep = ", ") %>% 
  paste(parl41$Middle_Names, sep = " ")

# Remove NAs from combined key.
parl41$Candidate <- gsub(" NA", "", parl41$Candidate)

# Correct Candidates' middle names. 
parl41 <- parl41 %>% 
  separate(col = First_Name, into = c("First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Create `Province_Territory` column in `parl41` based on supplementary data.

# Load supplementary table to identify `Province_Territory` in `parl41` based on common Electoral District Number in said data and table 11.
sup41 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 41/tables/table_tableau11.csv", locale = locale(encoding = "WINDOWS-1252"))

# Identify the province or territory for each electoral district. To this end, the name of the province or territory is identified by matching the Electoral district numbers in `parl41` to the same variable in `sup41`.
parl41$Province_Territory <-  sup41$Province[match(parl41$Electoral_District_No, sup41$`Electoral District Number/Numéro de circonscription`)] 

# Distinguish between French and English spellings in `parl43`'s `Province_Territory` variable.
parl41 <- parl41 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/", remove = FALSE)

# Organize column order.
parl41 <- parl41 %>%
  select(Province_Territory, Province_Territory_Fr, Election_Date, Election_Type, Parliament, Constituency, Constituency_Fr, Electoral_District_No, Electors, Polling_Station_Name, Polling_Station_No, Merged_With, Void_Poll, No_Poll_Held, Candidate, Last_Name, First_Name, Middle_Names, Political_Affiliation, Political_Affiliation_Fr, Incumbent, Result, Votes, Rejected_Ballots_PollNo)

# ==== Parliament 40 ====

# Apply a custom function to read csv file names for Parliament 40 using  a locale "Window-1252" encoding.
parl40 <- lapply(path40, custom_read_csv2) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl40 <- lapply(parl40, function(x)
  cbind(x, Election_Date="2008-10-08")) %>% 
  lapply(function(x)
    cbind(x, Parliament="40")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element.
parl40 <- lapply(parl40, function(parl40) mutate_at(parl40, .vars = 8, as.character))
parl40 <- lapply(parl40, function(parl40) mutate_at(parl40, .vars = 4, as.character))

# Concatenate data into a single data frame.
parl40 <- parl40 %>% 
  bind_rows()

# Rename columns for simplicity.
parl40 <- parl40 %>% 
  rename(Electoral_District_No = `....Electoral District Number/Numéro de circonscription`,
         Constituency_Fr = `....Electoral District Name_French/Nom de circonscription_Français`,
         Constituency = `....Electoral District Name_English/Nom de circonscription_Anglais`,
         Polling_Station_No = `....Polling Station Number/Numéro du bureau de scrutin`,
         Polling_Station_Name = `....Polling Station Name/Nom du bureau de scrutin`,
         No_Poll_Held = `....No Poll Held Indicator/Indicateur de bureau sans scrutin`,
         Void_Poll = `....Void Poll Indicator/Indicateur de bureau supprimé`,
         Merged_With = `....Merge With/Fusionné avec`,
         Rejected_Ballots_PollNo = `....Rejected Ballots for Polling Station/Bulletins rejetés du bureau`,
         Last_Name =  `....Candidate's Family Name/Nom de famille du candidat`,
         First_Name = `....Candidate's First Name/Prénom du candidat`,
         Middle_Names = `....Candidate's Middle Name/Second prénom du candidat`,
         Political_Affiliation = `....Political Affiliation Name_English/Appartenance politique_Anglais`,
         Political_Affiliation_Fr = `....Political Affiliation Name_French/Appartenance politique_Français`,
         Incumbent = `....Incumbent Indicator/Indicateur_Candidat sortant`,
         Result = `....Elected Candidate Indicator/Indicateur du candidat élu`,
         Electors = `....Electors for Polling Station/Électeurs du bureau`,
         Votes = `....Candidate Poll Votes Count/Votes du candidat pour le bureau`
  )

# Create a combined key variable, `Candidate`, to record each person's full name.
parl40$Candidate <- paste(parl40$Last_Name, parl40$First_Name, sep = ", ") %>% 
  paste(parl40$Middle_Names, sep = " ")

# Remove NAs from combined key.
parl40$Candidate <- gsub(" NA", "", parl40$Candidate)

# Correct Candidates' middle names. 
parl40 <- parl40 %>% 
  separate(col = First_Name, into = c("First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Create `Province_Territory` column in `parl40` based on supplementary data.

# Load supplementary table to identify `Province_Territory` in `parl40` based on common Electoral District Number in said data and table 11.
sup40 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 40/tables/table_tableau11.csv", locale = locale(encoding = "WINDOWS-1252"))

# Identify the province or territory for each electoral district. To this end, the name of the province or territory is identified by matching the Electoral district numbers in `parl40` to the same variable in `sup40`.
parl40$Province_Territory <-  sup40$Province[match(parl40$Electoral_District_No, sup40$`Electoral District Number/Numéro de circonscription`)] 

# Distinguish between French and English spellings in `parl43`'s `Province_Territory` variable.
parl40 <- parl40 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/", remove = FALSE)

# Remove extra character from values in `Constituency`.
parl40$Constituency <- gsub("\"", "", parl40$Constituency)

# Organize column order.
parl40 <- parl40 %>%
  select(Province_Territory, Province_Territory_Fr, Election_Date, Election_Type, Parliament, Constituency, Constituency_Fr, Electoral_District_No, Electors, Polling_Station_Name, Polling_Station_No, Merged_With, Void_Poll, No_Poll_Held, Candidate, Last_Name, First_Name, Middle_Names, Political_Affiliation, Political_Affiliation_Fr, Incumbent, Result, Votes, Rejected_Ballots_PollNo)

# ==== Parliament 39 ====

# Apply a custom function to read csv file names for Parliament 40 using  a locale "Window-1252" encoding.
parl39 <- lapply(path39, custom_read_csv2) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl39 <- lapply(parl39, function(x)
  cbind(x, Election_Date="2006-01-23")) %>% 
  lapply(function(x)
    cbind(x, Parliament="39")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element.
parl39 <- lapply(parl39, function(parl39) mutate_at(parl39, .vars = 8, as.character))
parl39 <- lapply(parl39, function(parl39) mutate_at(parl39, .vars = 4, as.character))

# Concatenate data into a single data frame.
parl39 <- parl39 %>% 
  bind_rows()

# Rename columns for simplicity.
parl39 <- parl39 %>% 
  rename(Electoral_District_No = `....Electoral District Number/Numéro de circonscription`,
         Constituency_Fr = `....Electoral District Name_French/Nom de circonscription_Français`,
         Constituency = `....Electoral District Name_English/Nom de circonscription_Anglais`,
         Polling_Station_No = `....Polling Station Number/Numéro du bureau de scrutin`,
         Polling_Station_Name = `....Polling Station Name/Nom du bureau de scrutin`,
         No_Poll_Held = `....No Poll Held Indicator/Indicateur de bureau sans scrutin`,
         Void_Poll = `....Void Poll Indicator/Indicateur de bureau supprimé`,
         Merged_With = `....Merge With/Fusionné avec`,
         Rejected_Ballots_PollNo = `....Rejected Ballots for Polling Station/Bulletins rejetés du bureau`,
         Last_Name =  `....Candidate's Family Name/Nom de famille du candidat`,
         First_Name = `....Candidate's First Name/Prénom du candidat`,
         Middle_Names = `....Candidate's Middle Name/Second prénom du candidat`,
         Political_Affiliation = `....Political Affiliation Name_English/Appartenance politique_Anglais`,
         Political_Affiliation_Fr = `....Political Affiliation Name_French/Appartenance politique_Français`,
         Incumbent = `....Incumbent Indicator/Indicateur_Candidat sortant`,
         Result = `....Elected Candidate Indicator/Indicateur du candidat élu`,
         Electors = `....Electors for Polling Station/Électeurs du bureau`,
         Votes = `....Candidate Poll Votes Count/Votes du candidat pour le bureau`)

# Create a combined key variable, `Candidate`, to record each person's full name.
parl39$Candidate <- paste(parl39$Last_Name, parl39$First_Name, sep = ", ") %>% 
  paste(parl39$Middle_Names, sep = " ")

# Remove NAs from combined key.
parl39$Candidate <- gsub(" NA", "", parl39$Candidate)

# Correct Candidates' middle names. 
parl39 <- parl39 %>% 
  separate(col = First_Name, into = c("First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Create `Province_Territory` column in `parl39` based on supplementary data.

# Load supplementary table to identify `Province_Territory` in `parl39` based on common Electoral District Number in said data and table 11.
# sup39 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 39/tables/table_tableau11.csv", locale = locale(encoding = "WINDOWS-1252"))

# Identify the province or territory for each electoral district. To this end, the name of the province or territory is identified by matching the Electoral district numbers in `parl39` to the same variable in `sup39`.
parl39$Province_Territory <-  sup40$Province[match(parl39$Electoral_District_No, sup40$`Electoral District Number/Numéro de circonscription`)] 

# Note table 11 from parliament 39 does not contain electoral number. As electoral numbers are consistent with the subsequent election, table 11 from parliament 40 is used instead. 

# Distinguish between French and English spellings in `parl43`'s `Province_Territory` variable.
parl39 <- parl39 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/", remove = FALSE)

# Organize column order.
parl39 <- parl39 %>%
  select(Province_Territory, Province_Territory_Fr, Election_Date, Election_Type, Parliament, Constituency, Constituency_Fr, Electoral_District_No, Electors, Polling_Station_Name, Polling_Station_No, Merged_With, Void_Poll, No_Poll_Held, Candidate, Last_Name, First_Name, Middle_Names, Political_Affiliation, Political_Affiliation_Fr, Incumbent, Result, Votes, Rejected_Ballots_PollNo)

# ==== Parliament 38 ==== 

# Apply a custom function to read csv file 
parl38 <- lapply(path38, custom_read_csv2) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl38 <- lapply(parl38, function(x)
  cbind(x, Election_Date="2004-06-28")) %>% 
  lapply(function(x)
    cbind(x, Parliament="38")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element. For simplicity, all columns are treated as characters. 
parl38 <- lapply(parl38, function(parl38) mutate_all(parl38, as.character))

# Alt. approach is to transform columns to characters later after bind_rows() has been called:
# parl38 <- data.frame(lapply(parl38, as.character), stringsAsFactors=FALSE)

# Concatenate results into a single data frame.
parl38 <- parl38 %>% 
  bind_rows()

# Rename columns to enforce a consistent naming scheme with other data from Elections Canada. 
parl38 <- parl38 %>% 
  rename(Constituency = `....District`,
         Polling_Station_No = `....Poll Number`,
         Polling_Station_Name = `....Poll Name`,
         Electors = `....Electors`,
         Total_Votes = `....Total Vote`,
         Rejected_Ballots_PollNo = `....Rejected Ballots`)

# Note: Poll-by-poll results are not in a tidyr form. Each candidate's vote totals, for instance, are presented in a separate column such that there is a separate column for each candidate. As a result there are close to 1,700 "variables" in the data set at this point. The next operation is to transform the data from a wide to long format to reduce the number of columns and lengthen the data set. 

# Increases the length and reduces the number of columns to create a tidier data froma. Two new variables are created. `Candidate` records the candidates' names, while "Votes" records the total number of votes the candidate received at a given polling station.  
parl38 <- parl38 %>% 
  pivot_longer(
    cols = starts_with("...."),
    names_to = "Candidate",
    names_prefix = "....",
    values_to = "Votes",
    values_drop_na = TRUE
  )

# Create new variables to record candidates' first, middle, and last names. Some middle and last names will be incorrectly identified.
parl38 <- parl38 %>% 
  separate(col=Candidate, into = c("First_Name", "Middle_Names", "Last_Name"), sep = " ", remove = FALSE)

# Correct middle and last names. 
parl38$Last_Name <- ifelse(is.na(parl38$Last_Name), 
                           parl38$Middle_Names, 
                           parl38$Last_Name)

parl38$Middle_Names <- ifelse(parl38$Middle_Names == parl38$Last_Name, 
                              NA, 
                              parl38$Middle_Names)

# Recreate the `Candidate` combined key using cleaned first, middle, and last names.
parl38$Candidate <-  paste(parl38$Last_Name, parl38$First_Name, sep=", ") %>% 
  paste(parl38$Middle_Names, sep=" ") 

# Remove NA from combined key.
parl38$Candidate <- gsub(" NA", "", parl38$Candidate)

# Separate `Constituency` to differentiate between english and french spellings.
parl38 <- parl38 %>% 
  separate(col=Constituency, into = c("Constituency", "Constituency_Fr"), sep = "/", remove = FALSE)

# Create a new variable `Merged_With` akin to other data from Elections Canada.
parl38 <- parl38 %>% 
  separate(col=Votes, into = c("Votes", "Merged_With"), sep= "Merged with No. ", remove = TRUE)

# Treat blank cells as missing values.
parl38$Votes[parl38$Votes==""] <- NA

# Given the format Electins Canada choose, there is no column recording candidates' political affiliation or the province.
# Note: Table 12 contains data that can be used to create variables missing in `parl38.` 

# Create blank columns to introduce variables available in other election years.
parl38$Province_Territory <- NA
parl38$Province_Territory_Fr <- NA
parl38$Political_Affiliation <- NA
parl38$Political_Affiliation_Fr <- NA
parl38$Result <- NA 
parl38$Void_Poll <- NA
parl38$No_Poll_Held <- NA
parl38$Incumbent <- NA
parl38$Electoral_District_No <- NA

# Order variables
parl38 <- parl38 %>% 
  select("Province_Territory", "Province_Territory_Fr", "Election_Date", "Election_Type", "Parliament", "Constituency", "Constituency_Fr", "Electoral_District_No", "Electors", "Polling_Station_Name", "Polling_Station_No", "Merged_With", "Void_Poll", "No_Poll_Held", "Candidate", "Last_Name", "First_Name", "Middle_Names", "Political_Affiliation", "Political_Affiliation_Fr", "Incumbent", "Result", "Votes", "Rejected_Ballots_PollNo")

# Identify candidates' political affiliations.

# Political affiliations for `parl38` are found in supplementary data. Specifically, table 12 in Parliament 38. 
sup38 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 38/tables/table12.csv",
                  locale = locale(encoding = "WINDOWS-1252"))

# Rename relevant columns.
sup38 <- sup38 %>% 
  rename(Province_Territory = `Province`,
         Constituency = `District`,
         Messy_Candidate = `Candidate`) # Raw data combines candidates' names with party affiliation.

# For `Province_Territory` separate English from French.
sup38 <- sup38 %>% 
  separate(col = Province_Territory, into = c("Province_Territory", "Province_Territory_Fr"), sep = "/")

# Missing values indicate the same spelling in English as in French. Replace NAs in `Province_Territory_Fr` with `Province_Territory` spellings. 
sup38$Province_Territory_Fr <- ifelse(is.na(sup38$Province_Territory_Fr), 
                                      sup38$Province_Territory, 
                                      sup38$Province_Territory_Fr)

# Create a separate variable for Constituency names in French.
sup38 <- sup38 %>% 
  separate(col = Constituency, into = c("Constituency", "Constituency_Fr"), sep = "/")

# Missing values are treated as the same spelling. 
sup38$Constituency_Fr <- ifelse(is.na(sup38$Constituency_Fr), sup38$Constituency, sup38$Constituency_Fr)

# Match data from supplementary table to main elections results data frame. 
parl38$Province_Territory  <- sup38$Province_Territory[match(parl38$Constituency, sup38$Constituency)]
parl38$Province_Territory_Fr  <- sup38$Province_Territory_Fr[match(parl38$Constituency, sup38$Constituency)]

# Extract party affiliation from Candidates' names.

# Remove asterisks. 
sup38$Messy_Candidate <- gsub("** ", "", sup38$Messy_Candidate, fixed = TRUE)

# Create a variable to record each candidates' political affiliation. 
sup38$Political_Affiliation <- sub(".*\\ ", "", sup38$Messy_Candidate)

# Remove party affiliation from `Last_Name`. Unfortunately, the data are so messy that there is no satisfying solution aside from specifying to R each individual character string that must be removed from candidates' names.  
sup38$Messy_Candidate <- gsub(" Green Party/Parti Vert", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Liberal/Libéral", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Conservative/conservateur", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" N.D.P./N.P.D.", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Independent/Indépendant", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Christian Heritage Party/Parti de l'Héritage Chrétien", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Marxist-Leninist/Marxiste-Léniniste", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" PC Party/Parti PC", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Marijuana Party/Parti Marijuana", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Canadian Action/Action canadienne", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Bloc Québécois/Bloc Québécois", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Communist/Communiste", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" No Affiliation/Aucune appartenance", "", sup38$Messy_Candidate)
sup38$Messy_Candidate <- gsub(" Libertarian/Libertarien", "", sup38$Messy_Candidate)

# Create variables for candidates' first, middle, and last names.
sup38 <- sup38 %>% 
  separate(col=Messy_Candidate, into = c("First_Name", "Middle_Names", "Last_Name"), sep = " ", remove = FALSE)

# Correct middle and last names. 
sup38$Last_Name <- ifelse(is.na(sup38$Last_Name), 
                          sup38$Middle_Names, 
                          sup38$Last_Name)

sup38$Middle_Names <- ifelse(sup38$Middle_Names == sup38$Last_Name, 
                             NA, 
                             sup38$Middle_Names)

# Recreate a combined key for candidates' full names using cleaned first, middle, and last names.
sup38$Messy_Candidate <-  paste(sup38$Last_Name, sup38$First_Name, sep=", ") %>% 
  paste(sup38$Middle_Names, sep=" ") 

# Remove NAs from combined key.
sup38$Messy_Candidate <- gsub(" NA", "", sup38$Messy_Candidate)

# Rename column. 
sup38 <- sup38 %>% 
  rename(Candidate = Messy_Candidate)

# Clean names in `Political_Affiliation` using the same naming scheme as the `Canadian-Federal-Elections` database. A custom function, i.e. `clean_names()`, is used to this end. For documentation see `EC_Functions.R`.
sup38$Political_Affiliation <- clean_names(messy_names, cleaned_names, sup38$Political_Affiliation)

# Match political affiliation from cleaned supplementary table to election results in `parl38` using candidates' full name as a comination key.
parl38$Political_Affiliation <- sup38$Political_Affiliation[match(parl38$Candidate, sup38$Candidate)]

# Import table with supplementary data on Parliament 38. (Table 12). This table only records the names of candidates who won in their respective ridings. From this list of successful candidates the `Result` variable can be created for `parl38`. 
sup38_2 <- read_csv("~/GitHub/Elections-Canada/data/raw/Parliament 38/tables/table11.csv",
                    locale = locale(encoding = "WINDOWS-1252"))

# Candidate names in table 11 need to be cleaned before it will be possible to match results between data frames.
sup38_2$Candidate <- gsub(" Green Party/Parti Vert", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Liberal/Libéral", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Conservative/conservateur", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" N.D.P./N.P.D.", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Independent/Indépendant", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Christian Heritage Party/Parti de l'Héritage Chrétien", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Marxist-Leninist/Marxiste-Léniniste", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" PC Party/Parti PC", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Marijuana Party/Parti Marijuana", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Canadian Action/Action canadienne", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Bloc Québécois/Bloc Québécois", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Communist/Communiste", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" No Affiliation/Aucune appartenance", "", sup38_2$Candidate)
sup38_2$Candidate <- gsub(" Libertarian/Libertarien", "", sup38_2$Candidate)

# Create variables for candidates' first, middle, and last names.
sup38_2 <- sup38_2 %>% 
  separate(col=Candidate, into = c("Last_Name", "First_Name", "Middle_Names"), sep = " ", remove = FALSE)

# Recreate a combined key for candidates' full names using cleaned first, middle, and last names.
sup38_2$Candidate <-  paste(sup38_2$Last_Name, sup38_2$First_Name, sep=" ") %>% 
  paste(sup38_2$Middle_Names, sep=" ") 

# Remove commas from`Last_Name`
sup38_2$Last_Name <- gsub(",", "", sup38_2$Last_Name)

# Remove NAs from combined key.
sup38_2$Candidate <- gsub(" NA", "", sup38_2$Candidate)

# In `parl38` record that a candidate won if the same candidate is found in table `sup38_2`. Here values correspond to `Canadian-Federal-Elections` (i.e., "Elected", "Defeated") naming conventions and not Elections Canada's scheme (i.e., "Y", "N").
parl38$Result <- ifelse(parl38$Candidate %in% sup38_2$Candidate, 
                        "Elected", 
                        "Defeated")

# TODO check if the below is viable. 
# Parliament 387 is missing `Electoral_District_No`. There is no supplementary data for parliaments before parliament 38. Supplementary data that was assigned to parliament 40 is used instead to match electoral district numbers based on matching constituency names between the two data frames. 
parl38$Electoral_District_No <- parl39$Electoral_District_No[match(parl38$Constituency, parl40$Constituency)]

# TODO
# Identify incumbents 
# There is no supplementary data for parliaments before parliament 38. If there were I could use table 11 from the previous election to identify incumbents in parliament 38. Will have to see what options are available in the .txt files for parliaments 37 and 36.

# TODO 
# Use table 11 to identify the candidates who won; the `Result` variable. 

# ==== Parliament 36 and 37 ==== 

# == Parliament 37 == 

# Apply a custom function to read txt files 
parl37 <- lapply(path37, custom_read_delim) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl37 <- lapply(parl37, function(x)
  cbind(x, Election_Date="2000-11-27")) %>% 
  lapply(function(x)
    cbind(x, Parliament="37")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element. For simplicity, all columns are treated as characters. 
parl37 <- lapply(parl37, function(parl37) mutate_all(parl37, as.character))

# Concatenate results into a single data frame.
parl37 <- parl37 %>%
  bind_rows()

# == Parliament 36 == 

# Apply a custom function to read .txt files 
parl36 <- lapply(path36, custom_read_delim) 

# Create two new columns for each element in the list. One to identify the date of the election and the other to identify the Parliamentary session.
parl36 <- lapply(parl36, function(x)
  cbind(x, Election_Date="1997-06-02")) %>% 
  lapply(function(x)
    cbind(x, Parliament="36")) %>% 
  lapply(function(x)
    cbind(x, Election_Type="General"))

# Ensure that all variables are consistently encoded within each element. For simplicity, all columns are treated as characters. 
parl36 <- lapply(parl36, function(parl36) mutate_all(parl36, as.character))

# Concatenate results into a single data frame.
parl36 <- parl36 %>%
  bind_rows()

# Rename columns for parliament 36.
parl36 <- parl36 %>% 
  rename(Event_Number = `....event_number`,
         Event_Name = `....event_english_name`,
         Event_Name_Fr = `....event_french_name`,
         Ed_Code =  `....ed_code`, # TODO Different format from Electoral_District_No. Keep current name as a reminder to reformat. 
         Constituency = `....ed_english_name`,
         Constituency_Fr = `....ed_french_name`,
         Province_Territory = `....province_name_english`, 
         Province_Territory_Fr = `....province_name_french`,
         Poll_Rejected_Ballots = `....poll_rejected_ballot_count`,
         Total_Rejected_Ballots = `....ed_rejected_ballot_count`,
         Poll_Total_Ballots = `....poll_total_ballot_count`,
         Poll_Valid_Votes = `....poll_valid_vote_count`,
         Total_Valid_Votes = `....ed_valid_vote_count`,
         Poll_Electors = `....poll_electors_on_list_count`,
         Total_Electors = `....ed_electors_on_list_count`,
         Poll_Count = `....total_poll_count`, 
         Advanced_Count = `....advance_poll_count`,
         Mobile_Count = `....mobile_poll_count`,
         SVR_Count = `....svr_group1_ballot_count`, # Special Voting Rules include alternative methods of voting such as by mail.
         SVR_Count2 = `....svr_group2_ballot_count`,
         SVR_Total = `....svr_total_ballot_count`,
         Population = `....population_cnt`,
         Census_Year = `....census_year`,
         Judicial_Recount = `....judicial_recount_indictator`, 
         Majority_Count = `....majority_count`,
         Majority_Precentage = `....majority_percentage`,
         Voter_Turnout = `....voter_participation_percentage`, # TODO Should double-check how they calculated this variable.
         Elected_Party = `....elected_party_english_name`,
         Elected_Party_Fr = `....elected_party_french_name`,
         Returning_Officer = `....returning_officer`,
         Polling_Station_Name = `....polling_station_name`,
         Polling_Station_No = `....poll_number`,
         Poll_Type = `....poll_type`,
         Urban_Rural = `....urban_rural_indicator`,
         Void_Poll = `....void_indicator`,
         No_Poll_Held = `....no_poll_indicator`,
         Split_Poll = `....split_indicator`,
         Merged_Poll = `....merge_indicator`,
         Merged_With = `....merged_with_poll_number`,
         Advanced_Poll = `....advance_poll_indicator`,
         SVR_Poll = `....svr_poll_indicator`,
         Mobile_Poll = `....mobile_poll_indicator`, 
  ) 

# Remove redundant columns. Event_Name is already captured in variables such as `Election_Date`, `Parliament`, and `Election_Type`.
parl36 <- parl36 %>% 
  select(-contains("Event_Name"), -contains("Event_Name_Fr"))

# Treat blank cells as missing values.
parl36 <- parl36 %>% 
  mutate_all(na_if, "")

# Create a unique ID for rows.
parl36 <- tibble::rowid_to_column(parl36, "ID")

# Rename columns for parliament 37
# Note: see above notes on parliament 36 as they also apply below.
parl37 <- parl37 %>% 
  rename(Event_Number = `....event_number`,
         Event_Name = `....event_english_name`,
         Event_Name_Fr = `....event_french_name`,
         Ed_Code =  `....ed_code`,  
         Constituency = `....ed_english_name`,
         Constituency_Fr = `....ed_french_name`,
         Province_Territory = `....province_name_english`, 
         Province_Territory_Fr = `....province_name_french`,
         Poll_Rejected_Ballots = `....poll_rejected_ballot_count`,
         Total_Rejected_Ballots = `....ed_rejected_ballot_count`,
         Poll_Total_Ballots = `....poll_total_ballot_count`,
         Poll_Valid_Votes = `....poll_valid_vote_count`,
         Total_Valid_Votes = `....ed_valid_vote_count`,
         Poll_Electors = `....poll_electors_on_list_count`,
         Total_Electors = `....ed_electors_on_list_count`,
         Poll_Count = `....total_poll_count`, 
         Advanced_Count = `....advance_poll_count`,
         Mobile_Count = `....mobile_poll_count`,
         SVR_Count = `....svr_group1_ballot_count`, 
         SVR_Count2 = `....svr_group2_ballot_count`,
         SVR_Total = `....svr_total_ballot_count`,
         Population = `....population_cnt`,
         Census_Year = `....census_year`,
         Judicial_Recount = `....judicial_recount_indictator`, 
         Majority_Count = `....majority_count`,
         Majority_Precentage = `....majority_percentage`,
         Voter_Turnout = `....voter_participation_percentage`,
         Elected_Party = `....elected_party_english_name`,
         Elected_Party_Fr = `....elected_party_french_name`,
         Returning_Officer = `....returning_officer`,
         Polling_Station_Name = `....polling_station_name`,
         Polling_Station_No = `....poll_number`,
         Poll_Type = `....poll_type`,
         Urban_Rural = `....urban_rural_indicator`,
         Void_Poll = `....void_indicator`,
         No_Poll_Held = `....no_poll_indicator`,
         Split_Poll = `....split_indicator`,
         Merged_Poll = `....merge_indicator`,
         Merged_With = `....merged_with_poll_number`,
         Advanced_Poll = `....advance_poll_indicator`,
         SVR_Poll = `....svr_poll_indicator`,
         Mobile_Poll = `....mobile_poll_indicator`, 
  ) 

# Remove redundant columns.
parl37 <- parl37 %>% 
  select(-contains("Event_Name"), -contains("Event_Name_Fr"))

# Treat blank cells as missing values.
parl37 <- parl37 %>% 
  mutate_all(na_if, "")

# Create a unique ID for rows.
parl37 <- tibble::rowid_to_column(parl37, "ID")

# Create a new column to identify the candidate who was elected in each ED. Remove redundant columns.
parl36 <- parl36 %>% 
  unite(col="Elected_Candidate", 
        c("....elected_last_name", "....elected_first_name", "....elected_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep =", ")

# Unite candidate columns. Remove redundant columns.
parl36 <- parl36 %>% 
  unite(col = "Candidate_1", 
        c("....cand_1_last_name", "....cand_1_first_name", "....cand_1_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_2", 
        c("....cand_2_last_name", "....cand_2_first_name", "....cand_2_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_3", 
        c("....cand_3_last_name", "....cand_3_first_name", "....cand_3_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_4", 
        c("....cand_4_last_name", "....cand_4_first_name", "....cand_4_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_5", 
        c("....cand_5_last_name", "....cand_5_first_name", "....cand_5_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_6", 
        c("....cand_6_last_name", "....cand_6_first_name", "....cand_6_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_7", 
        c("....cand_7_last_name", "....cand_7_first_name", "....cand_7_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_8", 
        c("....cand_8_last_name", "....cand_8_first_name", "....cand_8_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_9", 
        c("....cand_9_last_name", "....cand_9_first_name", "....cand_9_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_10", 
        c("....cand_10_last_name", "....cand_10_first_name", "....cand_10_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_11", 
        c("....cand_11_last_name", "....cand_11_first_name", "....cand_11_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_12", 
        c("....cand_12_last_name", "....cand_12_first_name", "....cand_12_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl36 <- parl36 %>% 
  unite(col = "Candidate_13", 
        c("....cand_13_last_name", "....cand_13_first_name", "....cand_13_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

# Clean `Elected_Candidate`
parl36$Elected_Candidate <- gsub(", NA", "", parl36$Elected_Candidate)
parl36$Elected_Candidate <- gsub("((?:[^,]+, ){1}[^,]+),", "\\1", parl36$Elected_Candidate) # Hat tip to P.K.Rajwanshi for working out this regular expression. 

# Subset data. Create a separate data frame for candidates (wide format). Include variables on EDs/polls to serve as a combined key that can later be used to match data. 
parl36_cand <- parl36 %>% 
  select(starts_with("Candidate_"), 
         "Ed_Code",
         "ID",
         starts_with("Polling_Station_"), 
         starts_with("...."))

# Treat blank cells as missing values.
parl36_cand <- parl36_cand %>% 
  mutate_all(na_if, "")

# Simplify election results. Keep only the data already in tidy(ish) format.
parl36 <- parl36 %>% 
  select(-contains("...."), 
         -contains("Candidate_"))

# Subset data and rename columns for each candidate number. 
cand1 <- parl36_cand %>% 
  select("ID", "Candidate_1", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_1_"))

cand1 <- cand1 %>% 
  rename(Candidate = Candidate_1,
         Political_Affiliation = `....cand_1_party_english_name`,
         Political_Affiliation_Fr = `....cand_1_party_french_name`,
         Gender = `....cand_1_gender_code`,
         Result = `....cand_1_elected_indicator`,
         Incumbent = `....cand_1_incumbent_indicator`,
         Votes = `....cand_1_poll_vote`)

# Variations on the code above is used to tidy data for each candidate. 
cand2 <- parl36_cand %>% 
  select("ID", "Candidate_2", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_2_"))

cand2 <- cand2 %>% 
  rename(Candidate = Candidate_2,
         Political_Affiliation = `....cand_2_party_english_name`,
         Political_Affiliation_Fr = `....cand_2_party_french_name`,
         Gender = `....cand_2_gender_code`,
         Result = `....cand_2_elected_indicator`,
         Incumbent = `....cand_2_incumbent_indicator`,
         Votes = `....cand_2_poll_vote`)

# Candidate 3. 
cand3 <- parl36_cand %>% 
  select("ID", "Candidate_3", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_3_"))

cand3 <- cand3 %>% 
  rename(Candidate = Candidate_3,
         Political_Affiliation = `....cand_3_party_english_name`,
         Political_Affiliation_Fr = `....cand_3_party_french_name`,
         Gender = `....cand_3_gender_code`,
         Result = `....cand_3_elected_indicator`,
         Incumbent = `....cand_3_incumbent_indicator`,
         Votes = `....cand_3_poll_vote`)

# Candidate 4. 
cand4 <- parl36_cand %>% 
  select("ID", "Candidate_4", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_4_"))

cand4 <- cand4 %>% 
  rename(Candidate = Candidate_4,
         Political_Affiliation = `....cand_4_party_english_name`,
         Political_Affiliation_Fr = `....cand_4_party_french_name`,
         Gender = `....cand_4_gender_code`,
         Result = `....cand_4_elected_indicator`,
         Incumbent = `....cand_4_incumbent_indicator`,
         Votes = `....cand_4_poll_vote`)

# Candidate 5. 
cand5 <- parl36_cand %>% 
  select("ID", "Candidate_5", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_5_"))

cand5 <- cand5 %>% 
  rename(Candidate = Candidate_5,
         Political_Affiliation = `....cand_5_party_english_name`,
         Political_Affiliation_Fr = `....cand_5_party_french_name`,
         Gender = `....cand_5_gender_code`,
         Result = `....cand_5_elected_indicator`,
         Incumbent = `....cand_5_incumbent_indicator`,
         Votes = `....cand_5_poll_vote`)

# Candidate 6. 
cand6 <- parl36_cand %>% 
  select("ID", "Candidate_6", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_6_"))

cand6 <- cand6 %>% 
  rename(Candidate = Candidate_6,
         Political_Affiliation = `....cand_6_party_english_name`,
         Political_Affiliation_Fr = `....cand_6_party_french_name`,
         Gender = `....cand_6_gender_code`,
         Result = `....cand_6_elected_indicator`,
         Incumbent = `....cand_6_incumbent_indicator`,
         Votes = `....cand_6_poll_vote`)

# Candidate 7. 
cand7 <- parl36_cand %>% 
  select("ID", "Candidate_7", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_7_"))

cand7 <- cand7 %>% 
  rename(Candidate = Candidate_7,
         Political_Affiliation = `....cand_7_party_english_name`,
         Political_Affiliation_Fr = `....cand_7_party_french_name`,
         Gender = `....cand_7_gender_code`,
         Result = `....cand_7_elected_indicator`,
         Incumbent = `....cand_7_incumbent_indicator`,
         Votes = `....cand_7_poll_vote`)

# Candidate 8. 
cand8 <- parl36_cand %>% 
  select("ID", "Candidate_8", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_8_"))

cand8 <- cand8 %>% 
  rename(Candidate = Candidate_8,
         Political_Affiliation = `....cand_8_party_english_name`,
         Political_Affiliation_Fr = `....cand_8_party_french_name`,
         Gender = `....cand_8_gender_code`,
         Result = `....cand_8_elected_indicator`,
         Incumbent = `....cand_8_incumbent_indicator`,
         Votes = `....cand_8_poll_vote`)

# Candidate 9. 
cand9 <- parl36_cand %>% 
  select("ID", "Candidate_9", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_9_"))

cand9 <- cand9 %>% 
  rename(Candidate = Candidate_9,
         Political_Affiliation = `....cand_9_party_english_name`,
         Political_Affiliation_Fr = `....cand_9_party_french_name`,
         Gender = `....cand_9_gender_code`,
         Result = `....cand_9_elected_indicator`,
         Incumbent = `....cand_9_incumbent_indicator`,
         Votes = `....cand_9_poll_vote`)

# Candidate 10. 
cand10 <- parl36_cand %>% 
  select("ID", "Candidate_10", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_10_"))

cand10 <- cand10 %>% 
  rename(Candidate = Candidate_10,
         Political_Affiliation = `....cand_10_party_english_name`,
         Political_Affiliation_Fr = `....cand_10_party_french_name`,
         Gender = `....cand_10_gender_code`,
         Result = `....cand_10_elected_indicator`,
         Incumbent = `....cand_10_incumbent_indicator`,
         Votes = `....cand_10_poll_vote`)

# Candidate 11. 
cand11 <- parl36_cand %>% 
  select("ID", "Candidate_11", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_11_"))

cand11 <- cand11 %>% 
  rename(Candidate = Candidate_11,
         Political_Affiliation = `....cand_11_party_english_name`,
         Political_Affiliation_Fr = `....cand_11_party_french_name`,
         Gender = `....cand_11_gender_code`,
         Result = `....cand_11_elected_indicator`,
         Incumbent = `....cand_11_incumbent_indicator`,
         Votes = `....cand_11_poll_vote`)

# Candidate 12. 
cand12 <- parl36_cand %>% 
  select("ID", "Candidate_12", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_12_"))

cand12 <- cand12 %>% 
  rename(Candidate = Candidate_12,
         Political_Affiliation = `....cand_12_party_english_name`,
         Political_Affiliation_Fr = `....cand_12_party_french_name`,
         Gender = `....cand_12_gender_code`,
         Result = `....cand_12_elected_indicator`,
         Incumbent = `....cand_12_incumbent_indicator`,
         Votes = `....cand_12_poll_vote`)

# Candidate 13. 
cand13 <- parl36_cand %>% 
  select("ID", "Candidate_13", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_13_"))

cand13 <- cand13 %>% 
  rename(Candidate = Candidate_13,
         Political_Affiliation = `....cand_13_party_english_name`,
         Political_Affiliation_Fr = `....cand_13_party_french_name`,
         Gender = `....cand_13_gender_code`,
         Result = `....cand_13_elected_indicator`,
         Incumbent = `....cand_13_incumbent_indicator`,
         Votes = `....cand_13_poll_vote`)

# Concatenate the data, which now share the same number of columns; each according to a standardized naming scheme. Remove redundant objects.
parl36_cand <- rbind(cand1, cand2, cand3, cand4, cand5, cand6, cand7, cand8, cand9, cand10, cand11, cand12, cand13)
rm(cand1, cand2, cand3, cand4, cand5, cand6, cand7, cand8, cand9, cand10, cand11, cand12, cand13)

# Clean candidate names.
parl36_cand$Candidate <- gsub(", NA", "", parl36_cand$Candidate)
parl36_cand$Candidate <- gsub("((?:[^,]+, ){1}[^,]+),", "\\1", parl36_cand$Candidate) 

# Match Data by ID.
parl36 <- parl36_cand %>% 
  left_join(parl36, 
            by = c("ID","Ed_Code", "Polling_Station_No", "Polling_Station_Name"),
            keep = FALSE)

# Remove rows missing candidates. 
parl36[parl36$Candidate=="NA",] <- NA 
parl36 <- parl36 %>% drop_na(Candidate)

# Create a new column to identify the candidate who was elected in each ED. Remove redundant columns.
parl37 <- parl37 %>% 
  unite(col="Elected_Candidate", 
        c("....elected_last_name", "....elected_first_name", "....elected_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep =", ")

# Unite candidate columns. Remove redundant columns.
parl37 <- parl37 %>% 
  unite(col = "Candidate_1", 
        c("....cand_1_last_name", "....cand_1_first_name", "....cand_1_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_2", 
        c("....cand_2_last_name", "....cand_2_first_name", "....cand_2_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_3", 
        c("....cand_3_last_name", "....cand_3_first_name", "....cand_3_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_4", 
        c("....cand_4_last_name", "....cand_4_first_name", "....cand_4_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_5", 
        c("....cand_5_last_name", "....cand_5_first_name", "....cand_5_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_6", 
        c("....cand_6_last_name", "....cand_6_first_name", "....cand_6_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_7", 
        c("....cand_7_last_name", "....cand_7_first_name", "....cand_7_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_8", 
        c("....cand_8_last_name", "....cand_8_first_name", "....cand_8_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_9", 
        c("....cand_9_last_name", "....cand_9_first_name", "....cand_9_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_10", 
        c("....cand_10_last_name", "....cand_10_first_name", "....cand_10_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_11", 
        c("....cand_11_last_name", "....cand_11_first_name", "....cand_11_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_12", 
        c("....cand_12_last_name", "....cand_12_first_name", "....cand_12_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

parl37 <- parl37 %>% 
  unite(col = "Candidate_13", 
        c("....cand_13_last_name", "....cand_13_first_name", "....cand_13_middle_name"), 
        remove = TRUE, 
        na.rm = FALSE, 
        sep=", ") 

# Clean `Elected_Candidate`
parl37$Elected_Candidate <- gsub(", NA", "", parl37$Elected_Candidate)
parl37$Elected_Candidate <- gsub("((?:[^,]+, ){1}[^,]+),", "\\1", parl37$Elected_Candidate) # Hat tip to P.K.Rajwanshi for working out this regular expression. 

# Subset data. Create a separate data frame for candidates (wide format). Include variables on EDs/polls to serve as a combined key that can later be used to match data. 
parl37_cand <- parl37 %>% 
  select(starts_with("Candidate_"), 
         "Ed_Code",
         "ID",
         starts_with("Polling_Station_"), 
         starts_with("...."))

# Treat blank cells as missing values.
parl37_cand <- parl37_cand %>% 
  mutate_all(na_if, "")

# Simplify election results. Keep only the data already in tidy(ish) format.
parl37 <- parl37 %>% 
  select(-contains("...."), 
         -contains("Candidate_"))

# Subset data and rename columns for each candidate number. 
cand1 <- parl37_cand %>% 
  select("ID", "Candidate_1", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_1_"))

cand1 <- cand1 %>% 
  rename(Candidate = Candidate_1,
         Political_Affiliation = `....cand_1_party_english_name`,
         Political_Affiliation_Fr = `....cand_1_party_french_name`,
         Gender = `....cand_1_gender_code`,
         Result = `....cand_1_elected_indicator`,
         Incumbent = `....cand_1_incumbent_indicator`,
         Votes = `....cand_1_poll_vote`)

# Variations on the code above is used to tidy data for each candidate. 
cand2 <- parl37_cand %>% 
  select("ID", "Candidate_2", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_2_"))

cand2 <- cand2 %>% 
  rename(Candidate = Candidate_2,
         Political_Affiliation = `....cand_2_party_english_name`,
         Political_Affiliation_Fr = `....cand_2_party_french_name`,
         Gender = `....cand_2_gender_code`,
         Result = `....cand_2_elected_indicator`,
         Incumbent = `....cand_2_incumbent_indicator`,
         Votes = `....cand_2_poll_vote`)

# Candidate 3. 
cand3 <- parl37_cand %>% 
  select("ID", "Candidate_3", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_3_"))

cand3 <- cand3 %>% 
  rename(Candidate = Candidate_3,
         Political_Affiliation = `....cand_3_party_english_name`,
         Political_Affiliation_Fr = `....cand_3_party_french_name`,
         Gender = `....cand_3_gender_code`,
         Result = `....cand_3_elected_indicator`,
         Incumbent = `....cand_3_incumbent_indicator`,
         Votes = `....cand_3_poll_vote`)

# Candidate 4. 
cand4 <- parl37_cand %>% 
  select("ID", "Candidate_4", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_4_"))

cand4 <- cand4 %>% 
  rename(Candidate = Candidate_4,
         Political_Affiliation = `....cand_4_party_english_name`,
         Political_Affiliation_Fr = `....cand_4_party_french_name`,
         Gender = `....cand_4_gender_code`,
         Result = `....cand_4_elected_indicator`,
         Incumbent = `....cand_4_incumbent_indicator`,
         Votes = `....cand_4_poll_vote`)

# Candidate 5. 
cand5 <- parl37_cand %>% 
  select("ID", "Candidate_5", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_5_"))

cand5 <- cand5 %>% 
  rename(Candidate = Candidate_5,
         Political_Affiliation = `....cand_5_party_english_name`,
         Political_Affiliation_Fr = `....cand_5_party_french_name`,
         Gender = `....cand_5_gender_code`,
         Result = `....cand_5_elected_indicator`,
         Incumbent = `....cand_5_incumbent_indicator`,
         Votes = `....cand_5_poll_vote`)

# Candidate 6. 
cand6 <- parl37_cand %>% 
  select("ID", "Candidate_6", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_6_"))

cand6 <- cand6 %>% 
  rename(Candidate = Candidate_6,
         Political_Affiliation = `....cand_6_party_english_name`,
         Political_Affiliation_Fr = `....cand_6_party_french_name`,
         Gender = `....cand_6_gender_code`,
         Result = `....cand_6_elected_indicator`,
         Incumbent = `....cand_6_incumbent_indicator`,
         Votes = `....cand_6_poll_vote`)

# Candidate 7. 
cand7 <- parl37_cand %>% 
  select("ID", "Candidate_7", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_7_"))

cand7 <- cand7 %>% 
  rename(Candidate = Candidate_7,
         Political_Affiliation = `....cand_7_party_english_name`,
         Political_Affiliation_Fr = `....cand_7_party_french_name`,
         Gender = `....cand_7_gender_code`,
         Result = `....cand_7_elected_indicator`,
         Incumbent = `....cand_7_incumbent_indicator`,
         Votes = `....cand_7_poll_vote`)

# Candidate 8. 
cand8 <- parl37_cand %>% 
  select("ID", "Candidate_8", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_8_"))

cand8 <- cand8 %>% 
  rename(Candidate = Candidate_8,
         Political_Affiliation = `....cand_8_party_english_name`,
         Political_Affiliation_Fr = `....cand_8_party_french_name`,
         Gender = `....cand_8_gender_code`,
         Result = `....cand_8_elected_indicator`,
         Incumbent = `....cand_8_incumbent_indicator`,
         Votes = `....cand_8_poll_vote`)

# Candidate 9. 
cand9 <- parl37_cand %>% 
  select("ID", "Candidate_9", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_9_"))

cand9 <- cand9 %>% 
  rename(Candidate = Candidate_9,
         Political_Affiliation = `....cand_9_party_english_name`,
         Political_Affiliation_Fr = `....cand_9_party_french_name`,
         Gender = `....cand_9_gender_code`,
         Result = `....cand_9_elected_indicator`,
         Incumbent = `....cand_9_incumbent_indicator`,
         Votes = `....cand_9_poll_vote`)

# Candidate 10. 
cand10 <- parl37_cand %>% 
  select("ID", "Candidate_10", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_10_"))

cand10 <- cand10 %>% 
  rename(Candidate = Candidate_10,
         Political_Affiliation = `....cand_10_party_english_name`,
         Political_Affiliation_Fr = `....cand_10_party_french_name`,
         Gender = `....cand_10_gender_code`,
         Result = `....cand_10_elected_indicator`,
         Incumbent = `....cand_10_incumbent_indicator`,
         Votes = `....cand_10_poll_vote`)

# Candidate 11. 
cand11 <- parl37_cand %>% 
  select("ID", "Candidate_11", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_11_"))

cand11 <- cand11 %>% 
  rename(Candidate = Candidate_11,
         Political_Affiliation = `....cand_11_party_english_name`,
         Political_Affiliation_Fr = `....cand_11_party_french_name`,
         Gender = `....cand_11_gender_code`,
         Result = `....cand_11_elected_indicator`,
         Incumbent = `....cand_11_incumbent_indicator`,
         Votes = `....cand_11_poll_vote`)

# Candidate 12. 
cand12 <- parl37_cand %>% 
  select("ID", "Candidate_12", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_12_"))

cand12 <- cand12 %>% 
  rename(Candidate = Candidate_12,
         Political_Affiliation = `....cand_12_party_english_name`,
         Political_Affiliation_Fr = `....cand_12_party_french_name`,
         Gender = `....cand_12_gender_code`,
         Result = `....cand_12_elected_indicator`,
         Incumbent = `....cand_12_incumbent_indicator`,
         Votes = `....cand_12_poll_vote`)

# Candidate 13. 
cand13 <- parl37_cand %>% 
  select("ID", "Candidate_13", "Ed_Code", "Polling_Station_No", "Polling_Station_Name", starts_with("....cand_13_"))

cand13 <- cand13 %>% 
  rename(Candidate = Candidate_13,
         Political_Affiliation = `....cand_13_party_english_name`,
         Political_Affiliation_Fr = `....cand_13_party_french_name`,
         Gender = `....cand_13_gender_code`,
         Result = `....cand_13_elected_indicator`,
         Incumbent = `....cand_13_incumbent_indicator`,
         Votes = `....cand_13_poll_vote`)

# Concatenate the data, which now share the same number of columns; each according to a standardized naming scheme. Remove redundant objects.
parl37_cand <- rbind(cand1, cand2, cand3, cand4, cand5, cand6, cand7, cand8, cand9, cand10, cand11, cand12, cand13)
rm(cand1, cand2, cand3, cand4, cand5, cand6, cand7, cand8, cand9, cand10, cand11, cand12, cand13)

# Clean candidate names.
parl37_cand$Candidate <- gsub(", NA", "", parl37_cand$Candidate)
parl37_cand$Candidate <- gsub("((?:[^,]+, ){1}[^,]+),", "\\1", parl37_cand$Candidate) 

# Match Data by ID.
parl37 <- parl37_cand %>% 
  left_join(parl37, 
            by = c("ID","Ed_Code", "Polling_Station_No", "Polling_Station_Name"),
            keep = FALSE)

# Remove rows missing candidates. 
parl37[parl37$Candidate=="NA",] <- NA 
parl37 <- parl37 %>% drop_na(Candidate)

# TODO Check to see if parl 36 and 37 work in this workflow.

# ___ end section on Parliaments 36 and 37 ___

# ---- Concatenate, Clean, and Export ----

# 1. Concatenate data frames
EC_1997_present <- rbind(parl38, parl39, parl40, parl42, parl43)

# FIXME parl38 cannot be added above due to an error. 
# Error: Error in match.names(clabs, names(xi)) : names do not match previous names
# EC_1997_present <- rbind(parl38, parl39, parl40, parl42, parl43)

# 2. Assign classes to variables 

# As date.
EC_1997_present$Election_Date <- as.Date(EC_1997_present$Election_Date)

# As Factors. 
EC_1997_present$Province_Territory <- factor(EC_1997_present$Province_Territory, levels = c("British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Quebec", "Newfoundland and Labrador", "New Brunswick", "Nova Scotia", "Prince Edward Island", "Yukon", "Northwest Territories", "Nunavut"))
# TODO
# `Province_Territory_Fr`
EC_1997_present$Election_Type <- as.factor(EC_1997_present$Election_Type)
EC_1997_present$Parliament <- as.factor(EC_1997_present$Parliament)
EC_1997_present$Constituency <- as.factor(EC_1997_present$Constituency)
EC_1997_present$Constituency_Fr <- as.factor(EC_1997_present$Constituency_Fr)
# EC_1997_present$Political_Affiliation <- as.factor(EC_1997_present$Political_Affiliation) # error
EC_1997_present$Result <- as.factor(EC_1997_present$Result)
EC_1997_present$Polling_Station_Name <- as.factor(EC_1997_present$Polling_Station_Name)

# As numeric.
EC_1997_present$Electors <- as.numeric(EC_1997_present$Electors)
EC_1997_present$Votes <- as.numeric(EC_1997_present$Votes)
EC_1997_present$Rejected_Ballots_PollNo <- as.numeric(EC_1997_present$Rejected_Ballots_PollNo)

# 3. Export Data

# Save Master File.
saveRDS(EC_1997_present, file = "~/GitHub/Elections-Canada/data/processed/master/EC_1996_present.Rds")

# Set working directory.
setwd("~/GitHub/Elections-Canada/data/processed/parliaments")

# Split dataframe into a list according to `Parliament`.
EC_Parliaments <- split(EC_1997_present, list(EC_1997_present$Parliament)) 

# Write a csv file for each general election by `Parliament`.
for (Parliament in names(EC_Parliaments)) {
  write.csv(EC_Parliaments[[Parliament]], paste0(Parliament, "_Parliament.csv"), row.names = FALSE, fileEncoding = "UTF-8")
}

# TODO split csv files 
# CSV files will need to be split as GitHub does not accept files larger than 100MB.
# write.csv(EC_1997_present, file = "~/GitHub/Elections-Canada/data/processed/master/EC_1996_present.csv", row.names = FALSE, fileEncoding = "UTF-8")

# TODO Clean candidate names. For example, John C. Turmel aka "The Engineer".

# ---- Summarize at Constituency-Level ----

# TODO 

# Summarize results at the constituency-level
# temp <- parl38 %>% 
#   group_by(Province_Territory, Election_Date, Constituency, Candidate) %>% 
#   summarise(Votes = sum(Votes, na.rm = TRUE))


# ==== NOTES ====

# Note 1: French spellings will need to be corrected. Some party names are all in lowercase while others capitalize the first letter. 

# ___ end ___ 