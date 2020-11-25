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

# General Notes: Elections Canada (EC) inconsistently presents data in two formats (i.e., wide and long) and uses different file extentions (.csv and .txt) for election results between 1996 and 2019. This script processes the raw data into a tidy format that can be used to analyze election results across time. Unfortunately, Elections Canada did not include any unique identifiers in their csv files to record the election or parliamentary session. For this reason, raw data are read from their respective folders and assigned variables such as `Election_Date` and `Parliament` to identify the election. Furthermore, general inconsistencies, such as colnames containing different characters across election years, missing format options, and other inconsistencies, necessitate small variations on what could have otherwise been a more concise script. Parliament 38, for example, is limited to poll-by-poll election results in EC's "format 1" (i.e., a wide format where each candidate's name appears as a column). Parliaments 36 and 37 present data in an even messier wide format that requires much more effort to process. For more information on the original data, variables, and cleaning operations, please consult the README files in this repository. 

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

# ==== Parliament 37 ==== 

# TODO
# Clean .txt files. 
# See file `EC_Temp2.R`

# ==== Parliament 36 ====

# TODO
# Clean .txt files. 
# See file `EC_Temp2.R`

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

# Save Master File.
saveRDS(EC_1997_present, file = "~/GitHub/Elections-Canada/data/processed/master/EC_1996_present.Rds")

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