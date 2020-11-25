# Cleaning Election Canada's Data: From 1996 to 2019 

This README details the data processing and cleaning operations used to modify Elections Canada's (EC) raw data into formats that better lend themselves to scientific analysis. 

## Cleaning Party Names 

Elections Canada nomenclature is inconsistent across election years. Political party names were, therefore, cleaned to enforce a consistent naming scheme across EC's files. The chosen naming scheme was also applied to enforce consistency with other repositories in this collection such as data from the Library of Canadian Parliament in the [`Canadian-Federal-Elections`](https://github.com/Lucas-Czarnecki/Canadian-Federal-Elections) repository. 

 Note that candidates `Political_Affiliation` may record "Independent" or "No affiliation to a recognised party". While there is no substantive difference between candidates registered as having "no affiliation" and those who run as "Independents", the Elections Act bestows individuals with the choice to register with one or the other. The Elections Act 66(1)(v), for example, states that candidates' nomination paper will include "the name of the political party that has endorsed the prospective candidate or, if none, the prospective **candidate’s choice** to either have the word “independent” or no designation of political affiliation under his or her name in election documents," (Canadian Elections Act, 2000) [emphasis added].

