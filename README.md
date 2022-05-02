# OpenComputer IntelliSense
A simple Visual Studio Code extension that enables IntelliSense for OpenComputer by setting up a Code Completion connection to Visual Studio Code in your target machine!

## Features

- Remote connection to your OpenComputer target machine directly to get the 

## Known Issues

- Since Variables are not static typed, there's currently no variable auto complete support.
- Method's return values are not static typed, you won't be able to auto complete a function's returned table properties/methods.

## Setup
In-order to setup the OpenComputer IntelliSense, you have to run a script in your target Open Computer machine with components you wanted installed.

```sh
#### Inside OpenComputer machine ####
# Download the latest version from GitHub
wget https://raw.githubusercontent.com/fan87/OpenComputer-IntelliSense/master/lua/vscode-intellisense.lua


# Start the IntelliSense client
./vscode-intellisense.lua -host <Host>:<Port that the VSCode has given>
```


## Release Notes
### 1.0.0
Initial release.
