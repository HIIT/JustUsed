# JustUsed

JustUsed currently tracks two things: “Used” files and Safari history

## Used files

Uses the Spotlight API (```NSMetadataQuery```) to detect files which have a value of ```kMDItemLastUsedDate``` greater (more recent) than the time the application was opened. Files added to the list of items are added to a table (and displayed back). This approach is very lightweight.

To see additional data that could be used as input to the spotlight api tri ```mdls somefile``` in Terminal. Any of the returned keys can be used to initiate spotlight queries.

## Safari history

Safari keeps history in SQLite database files in ```~/Library/Safari/History.db*```. This data can't be tracked by spotlight so JustUsed monitors for changes in these file every *x* seconds (defined in ```SafariHistoryFetcher.kSafariHistoryCheckTime```). Since FMDB can't read this data directly, if a modification was found the files are copied to a temporary directly in order to be read (and history data extracted). The temporary files are deleted immediately afterwards.

JustUsed tracks the database 

# Addional software

## Git submodules

The following GitHub projects are linked as git submodules. Please make sure you checkout the correct version in the submodule and that the deployment version of the submodule is correct (at the moment, 10.10)

[Alamofire version 2.0.2](https://github.com/Alamofire/Alamofire/releases/tag/2.0.2) - For easier DiMe API calls. The correct version should be already checked out as a submodule (in case it's not, do `git checkout tags/2.0.2` in the Alamofire subfolder). Make sure the correct version is selected in the subproject for OS X deployment (10.10).

## Embedded

The following GitHub projects are incorporated into JustUsed (no additional download needed). Both were released under the MIT license.

- [Swifty JSON version 2.3.0](https://github.com/SwiftyJSON/SwiftyJSON/releases/tag/2.3.0) - To easily parse and manage JSON objects pushed to DiMe.

- [FMDB version 2.5](https://github.com/ccgus/fmdb/releases/tag/v2.5) - to track Safari's SQLite database

- [XCGLogger version 3.0](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.0) - To output logs to terminal and files
