# JustUsed

JustUsed is the codename for DiMe's Mac Desktop Tracker. DiMe (DigitalMe) (part of the [Re:Know project](http://www.reknow.fi)), is a platform aimed at collecting user data, for the user, under full control of the user. More information, including DiMe's source code, can be found here: http://hiit.github.io/dime-server/.

## Tracking

JustUsed tracks the following items and sends their information to DiMe:

- Opened files
- Calendar
- Browser activity (deprecated in favour of Browser extension, which can be found [here](http://hiit.github.io/dime-server/))

Calendar tracking requires permission to access your calendar and on Contacts on OS X >= El Capitan (to retrieve details regarding participants to events, such as email).

## Installation

To install the tracker, download the latest dmg from the [relases page](https://github.com/HIIT/JustUsed/releases).

## Development

You can clone the xcode project using git

```
git clone --recursive https://github.com/HIIT/JustUsed
```

(the recursive option automatically sets up the Alamofire submodule)

Once cloned, you can run JustUsed by opening `JustUsed.xcodeproj` in xcode (version 7 or above recommended).

# Implementation details

## Used files

Uses the Spotlight API (`NSMetadataQuery`) to detect `*.sfl` files which have a value of `kMDItemFSContentChangeDate` greater (more recent) than the time the JustUsed was launched. SFL (SharedFileList) files are used by OS X El Capitan (they are called differently in previous versions of OS X) to track the most recently opened documents in any application that uses standard OS X libraries. JustUsed then finds the most recent document found in the most recently changed sfl file, and assumes it was the most recently opened document.

This approach has drawbacks: if one opens the most recent document from within the same application multiple times, it will not be reported as recently opened. The alternative would be using Spotlight to find items which have a recent `kMDItemLastUsedDate`, however this approach doesn't work in two scenarios:

1. When a file is downloaded from the internet (an attribute called `com.apple.quarantine` gets set on downloaded items). This bug has been reported to Apple, awaiting response.
2. When a file is opened from within an application (i.e. without using Finder). Apple is currently working on this issue.

## Safari history

Safari keeps history in SQLite database files in ```~/Library/Safari/History.db*```. This data can't be tracked by spotlight so JustUsed monitors for changes in these file every *x* seconds (defined in ```SafariHistoryFetcher.kSafariHistoryCheckTime```). Since FMDB can't read this data directly, if a modification was found the files are copied to a temporary directly in order to be read (and history data extracted). The temporary files are deleted immediately afterwards.

## Other browsers

Chrome and Firefox are also tracked in a similar way.

# Additional software

## Git submodules

The following GitHub projects are linked as git submodules.

[Alamofire version 3.3.0](https://github.com/Alamofire/Alamofire/releases/tag/3.3.0) - For easier DiMe API calls. The correct version should be already checked out as a submodule. `git status` in the Alamofire subfolder should return `HEAD detached at 268a22b`. (In case the Alamofire submodule was not cloned, do `git submodule init` followed by `git submodule update` in the JustUsed folder).

## Embedded

The following GitHub projects are incorporated into JustUsed (no additional download needed). Both were released under the MIT license.

- [Swifty JSON version 2.3.1](https://github.com/SwiftyJSON/SwiftyJSON/releases/tag/2.3.1) - To easily parse and manage JSON objects pushed to DiMe.

- [FMDB version 2.6.2](https://github.com/ccgus/fmdb/releases/tag/2.6.2) - to track Safari's SQLite database

- [XCGLogger version 3.3](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.3) - To output logs to terminal and files
