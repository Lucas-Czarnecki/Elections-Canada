# Raw Data from Elections Canada (1997 to the Present)

The source of data for this repository all comes from Elections Canada's website. The data are found across multiple pages. Links to these data are found on [Elections Canada's Official Reports page](https://www.elections.ca/content.aspx?section=res&dir=rep/off&document=index&lang=e). Data are available for general elections between 1997 to the present.

How data are presented depends on the election year. In general, however, data are presented in `two formats`:

## 1. Format 1 (pollbypoll_bureauparbureau):

Format 1 `(pollbypoll_bureauparbureau)` "includes an entry for each polling station by candidate in each electoral district. It also provides information on overall vote counts for the poll," [(see source)](https://www.elections.ca/content.aspx?section=res&dir=rep/off/43gedata&document=pollbypoll&lang=e).

The following table is copied from Elections Canada for the 2019 general election.

| Field Name | Description |
| :- | :- |
| Electoral District |	The name of the electoral district. |
| Polling Station Number |	The number assigned to the polling station, for example: 3, 45A, 48-3, 601. |
| Polling Station Name 	| A name that generally represents the locality of the polling division boundary. |
| [Candidate 1 name] | 	The number of valid votes for the first candidate on the ballot at this polling station only. |
| [Candidate 2 name] | 	The number of valid votes for the second candidate on the ballot at this polling station only. |
| [Candidate 3 name] | The number of valid votes for the third candidate on the ballot at this polling station only. |
| [Candidate 4 name] | The number of valid votes for the fourth candidate on the ballot at this polling station only. |
| ... |	... |
| [Candidate 11 name] |	The number of valid votes for the eleventh candidate (if any) on the ballot at this polling station only. |
| Rejected Ballots |	The number of rejected ballots at this polling station. |
| Total Votes  |	The total number of ballots counted at this polling station. |
| Electors | 	The number of electors on the list of electors for this polling station.

<br>

## 2. Format 2 (pollresults_resultatsbureau):

Format 2 `(pollresults_resultatsbureau)` "provides an entry for each candidate by polling station in each electoral district. It includes information on who the candidate is, the candidate’s political party, and the voting results for that candidate at a particular poll," [(see source)](https://www.elections.ca/content.aspx?section=res&dir=rep/off/43gedata&document=pollresults&lang=e).

The following table is copied from Elections Canada for the 2019 general election.

| Field Name | Description |
| :- | :- |
| Electoral District Number |	The electoral district number.|
| Electoral District Name_English |	The English name of the electoral district.|
| Electoral District Name_French |	The French name of the electoral district.|
| Polling Station Number |	The number assigned to the polling station, for example: 3, 45A, 48-3, 601.|
| Polling Station Name |	A name that generally represents the locality of the polling division boundary.|
| Void Poll Indicator |	Indicates that a poll exists but has no electors.|
| No Poll Held Indicator |	Indicates that the returning officer intended to hold this poll, but unforeseen circumstances prevented it.|
| Merge With |	Indicates the number of the polling station with which the results of this poll were merged.|
| Rejected Ballots for Polling Station |	The number of rejected ballots at this polling station.|
| Electors for Polling Station |	The number of electors on the list of electors for this polling station.
| Candidate’s Family Name |	The family name of the candidate.|
| Candidate’s Middle Name |	The middle name of the candidate.|
| Candidate’s First Name |	The first name of the candidate.|
| Political Affiliation Name_English |	The short-form English name of the candidate’s political affiliation.|
| Political Affiliation Name_French |	The short-form French name of the candidate’s political affiliation.|
| Incumbent Indicator |	“Y” if candidate was the incumbent, “N” otherwise.|
| Elected Candidate Indicator |	“Y” if candidate was elected, “N” otherwise.|
| Candidate Poll Votes Count |	The number of valid votes the candidate obtained at this polling station.|

<br>

## Summary Tables

Election Canada also provides summary tables for general elections starting with the 2004 general election. 

### Notes on Raw Data: 
* Data on the 1997 and 2000 general elections are not available in formats 1 or 2. Instead, data are presented as tab-delimited text files. Each .txt file presents results from electoral districts from a given province. 
* Format 2 is not available for the 2004 general election. Elections data are available in format 1 starting with the 2006 general election. 
* Starting with the 2015 general election, Elections Canada also includes data on "Polling Day Registrations". Such data are not included in this respository as they are not pertinent to this project. Researchers can download these data from the same pages as the other election results.