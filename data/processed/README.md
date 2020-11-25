# Cleaning Election Canada's Data: From 1996 to 2019 

This README details the data processing and cleaning operations used to modify Elections Canada's (EC) raw data into formats that better lend themselves to scientific analysis. 

Raw data were processed using a tidy format, which makes it possible for the user to study election results on a given election or even across time. As Elections Canada did not include any unique identifiers in their csv files to record the election or parliamentary session, processed data have been assigned new variables such as `Election_Date` and `Parliament` to identify each election. Furthermore, general inconsistencies, such as column names containing different characters across election years, inconsistent file encodings, and other inconsistencies, have all been corrected (to the best of my knowledge). 

Below is a summary of each folder and the data contained therein:

> TODO

## Cleaning Party Names 

Elections Canada nomenclature is inconsistent across election years. Political party names were, therefore, cleaned to enforce a consistent naming scheme across EC's files. The chosen naming scheme was also applied to enforce consistency with other repositories in this collection such as data from the Library of Canadian Parliament in the [`Canadian-Federal-Elections`](https://github.com/Lucas-Czarnecki/Canadian-Federal-Elections) repository. 

 Note that candidates `Political_Affiliation` may record "Independent" or "No affiliation to a recognised party". While there is no substantive difference between candidates registered as having "no affiliation" and those who run as "Independents", the Elections Act bestows individuals with the choice to register with one or the other. The Elections Act 66(1)(v), for example, states that candidates' nomination paper will include "the name of the political party that has endorsed the prospective candidate or, if none, the prospective **candidate’s choice** to either have the word “independent” or no designation of political affiliation under his or her name in election documents," (Canadian Elections Act, 2000) [emphasis added].

