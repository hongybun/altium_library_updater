# Altium Library Updater

Two scripts are provided: `UpdateLibrariesFromTransfersByName.pas` only checks the names of the components in `.SchLib`s and `.PcbLib`s, and `UpdateLibrariesFromTransfersByMPN.pas` checks the manufacturer part numbers of the components `.SchLib`s but only checks the name of the components in `.PcbLib`s, as footprints typically don't have manufacturer part numbers associated with them.

These scripts are tested and confirmed working on Altium Designer Agile 26.6.0 with Windows 11 Pro 25H2 running on an Asus NUC13ANK.

