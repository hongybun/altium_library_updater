# Altium Library Updater

Two scripts are provided: `UpdateLibrariesFromTransfersByName.pas` only checks the names of the components in `.SchLib` and `.PcbLib` files, and `UpdateLibrariesFromTransfersByMPN.pas` checks the manufacturer part numbers of the components `.SchLib` files but only checks the name of the components in `.PcbLib` files, as footprints typically don't have manufacturer part numbers associated with them.

These scripts are tested and confirmed working on Altium Designer Agile 26.6.0 with Windows 11 Pro 25H2 running on an Asus NUC13ANK.

## Running the scripts

In Altium Designer, these `.pas` script files can either be dragged directly into the Project sidebar, or a new Script Project can be created by navigating to File > New > Script > Script Project and the files added to that.

Once the script is open in Altium, 
