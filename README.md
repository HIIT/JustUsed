# JustUsed

JustUsed currently tracks two things: “Used” files and Safari history

## Used files

Uses the Spotlight API (`NSMetadataQuery`) to detect `*.sfl` files which have a value of `kMDItemFSContentChangeDate` greater (more recent) than the time the JustUsed was launched. SFL (SharedFileList) files are used by OS X El Capitan (they are called differently in previous versions of OS X) to track the most recently opened documents in any application that uses standard OS X libraries. JustUsed then finds the most recent document found in the most recently changed sfl file, and assumes it was the most recently opened document.

This approach has drawbacks: if one opens the most recent document from within the same application multiple times, it will not be reported as recently opened. The alternative would be using Spotlight to find items which have a recent `kMDItemLastUsedDate`, however this approach doesn't work in two scenarios:

1. When a file is downloaded from the internet (an attribute called `com.apple.quarantine` gets set on downloaded items).
2. When a file is opened from within an application (i.e. without using Finder).

These two bugs have been reported to Apple.

## Safari history

Safari keeps history in SQLite database files in ```~/Library/Safari/History.db*```. This data can't be tracked by spotlight so JustUsed monitors for changes in these file every *x* seconds (defined in ```SafariHistoryFetcher.kSafariHistoryCheckTime```). Since FMDB can't read this data directly, if a modification was found the files are copied to a temporary directly in order to be read (and history data extracted). The temporary files are deleted immediately afterwards.

JustUsed tracks the database 

# Addional software

## Git submodules

The following GitHub projects are linked as git submodules. Please make sure you checkout the correct version in the submodule and that the deployment version of the submodule is correct (at the moment, 10.10)

[Alamofire version 2.0.2](https://github.com/Alamofire/Alamofire/releases/tag/2.0.2) - For easier DiMe API calls. The correct version should be already checked out as a submodule (in case it's not, do `git checkout tags/2.0.2` in the Alamofire subfolder).

## Embedded

The following GitHub projects are incorporated into JustUsed (no additional download needed). Both were released under the MIT license.

- [Swifty JSON version 2.3.0](https://github.com/SwiftyJSON/SwiftyJSON/releases/tag/2.3.0) - To easily parse and manage JSON objects pushed to DiMe.

- [FMDB version 2.5](https://github.com/ccgus/fmdb/releases/tag/v2.5) - to track Safari's SQLite database

- [XCGLogger version 3.0](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.0) - To output logs to terminal and files
