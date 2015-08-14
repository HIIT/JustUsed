# JustUsed

JustUsed currently tracks two things: “Used” files and Safari history

## Used files

Uses the Spotlight API (```NSMetadataQuery```) to detect files which have a value of ```kMDItemLastUsedDate``` greater (more recent) than the time the application was opened. Files added to the list of items are added to a table (and displayed back). This approach is very lightweight.

To see additional data that could be used as input to the spotlight api tri ```mdls somefile``` in Terminal. Any of the returned keys can be used to initiate spotlight queries.

## Safari history

Safari keeps history in SQLite database files in ```~/Library/Safari/History.db*```. This data can't be tracked by spotlight so JustUsed monitors for changes in these file every *x* seconds (defined in ```SafariHistoryFetcher.kSafariHistoryCheckTime```). Since FMDB can't read this data directly, if a modification was found the files are copied to a temporary directly in order to be read (and history data extracted). The temporary files are deleted immediately afterwards.

JustUsed tracks the database 

# Addional software

The following GitHub projects are incorporated into JustUsed (no additional download needed). Both were released under the MIT license.

- [FMDB version 2.5](https://github.com/ccgus/fmdb/releases/tag/v2.5) - to track Safari's SQLite database
- [XCGLogger version 2.2](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_2.2) - To output logs to terminal and files
