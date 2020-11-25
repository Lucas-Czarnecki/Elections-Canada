
## NOTE: This repository is under active development. You can expect significant changes in the short term.


--- 
# Elections Canada (1997 to the Present)

This repository processes raw data from [Elections Canada](https://www.elections.ca/home.aspx) and presents it in a more researcher-friendly format. 

## Raw Data

Constituency-level results from Canadian federal elections are available for all general elections between 1997 to the present via Elections Canada's [Resource Centre](https://www.elections.ca/content.aspx?section=res&dir=rep/off&document=index&lang=e). Results are not available on general elections prior to 1997. Of the data that are available, researchers will find that they must invest significant effort before being able to run any meaningful analysis – especially across election years. The purpose of this repository is, therefore, to present the data in a format that makes data more accessible to the researcher.

More information regarding the raw data, its formats, variables, etc., can be found [HERE](https://github.com/Lucas-Czarnecki/Elections-Canada/tree/master/data/raw).

## Cleaned Data

This repository processes Elections Canada's data with the goal of making it more accessible for researchers to analyze. To this end, the repository addresses a number of inconsistencies in the available data set. Elections Canada (EC), for example, inconsistently presents election results across multiple formats and file types. While more recent elections are presented in one of two formats (i.e., wide and long), long formats are not available for elections before the 2006 general election. For more historic elections, Elections Canada saves its data as tab-delimited text files rather than comma-separated values. This respository consolidates conflicting formats and file extensions to present the data in a uniform and consistent manner enforcing consistent nomenclature, column names, and file extensions. 

More specifically, candidate-level election results are wrangled into long-formatted .csv files and a master .Rds file for R-users. The cleaned data also features modified variables that help facilitate data exploration and analysis. 

You will find the modified data and more information on the variables and operations in this [folder](https://github.com/Lucas-Czarnecki/Elections-Canada/tree/master/data/processed). The scripts used to process the raw data can also be found [HERE](https://github.com/Lucas-Czarnecki/Elections-Canada/tree/master/R).

### What is different?

The cleaned data differs from the original Elections Canada data set in the following ways:
* All data are presented in long format.
* A variable called `Parliament` was created from the original data set to record the session of Parliament in long form.
* Additional variables, namely `Election_Date` and `Election_Type`, were created from the original data set to record the date (i.e., Election_Date as yyyy-mm-dd) of each general election in long form.
* New variables (i.e., `Last_Name`, `First_Name`, and `Middle_Names`) were created to identify each candidate's first, middle, and last names. These variables were used to correct for errors in EC's record.

## Credit and Copyright 

All of the data in this repository come from Elections Canada. The use of this repository is, therefore, subject to the same terms and conditions as those outlined on Elections Canada's website. Terms and conditions may, therefore, also be subject to change. 

The following conditions can be found on Elections Canada's website [HERE](https://www.elections.ca/content.aspx?section=pri&document=index&lang=e#archive). A select section of the copyright is also reproduced below:

### *Copyright/Permission to Reproduce Notices*

*Materials on this website were produced and/or compiled by Elections Canada for the purpose of providing Canadians with direct access to information about the programs and services offered by Elections Canada. You may use and reproduce the materials as follows:
Non-commercial Reproduction*

*Unless otherwise specified, you may reproduce the materials in whole or in part for non-commercial purposes, and in any format, without charge or further permission from Elections Canada, provided you do the following:*

* *Exercise due diligence in ensuring the accuracy of the materials reproduced;*
* *Indicate both the complete title of the materials reproduced, as well as the author (where available);*
* *Indicate that the reproduction is a copy of the version available at [URL where original document is available]; and*
* *Not use a method of downloading information that would place Elections Canada's network at risk. Elections Canada will take all necessary steps to protect its information technology assets from those who extract content from this website in a manner that affects its performance or places it at risk.*

### *Commercial Reproduction*

*Unless otherwise specified, you may not reproduce materials on this website, in whole or in part, for the purposes of commercial redistribution without prior written permission from Elections Canada.*

## Disclaimer 

This repository makes no warranties regarding the accuracy of this information and disclaims any liability for damages resulting from its use. The data contained herein are subject to Elections Canada's terms of use and may be subject to change.