# Scripts 

All data processing and cleaning is achieved through R (version 3.6.2). The scripts in these folders each serve specific roles in preparing election results from a myriad of inconsistent formats into a researcher-friendly repository with consistent nomenclature and file types. 

### EC Paths 

Specifies the file paths where raw data are stored on the local computer. This assumes the data have been cloned from GitHub. Running the script will return character vectors of the names of files in each folder where raw data are present. 

### EC Functions 

Includes customized functions for processing data from Elections Canada. Running this script will load these functions into R's global environment. Functions include customized tools for loading .csv and .txt files into R as well as a function for cleaning the names of parties and candidates. 

### EC Processing 

This is the main script responsible for cleaning, wrangling, and exporting data. When run it will `source()` the above scripts and transform Elections Canada's data from its various formats into cleaner and more user-friendly files. The results are saved in the [processed folder](https://github.com/Lucas-Czarnecki/Elections-Canada/tree/master/data/processed).

