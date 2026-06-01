# Altium Library Updater

Update multiple Altium schematic and PCB library files with the components in two specified `.schlib` and `.pcblib` files.

Two scripts are provided: `UpdateLibrariesFromTransfersByName.pas` only checks the names of the components in `.SchLib` and `.PcbLib` files, and `UpdateLibrariesFromTransfersByMPN.pas` checks the manufacturer part numbers of the components `.SchLib` files but only checks the name of the components in `.PcbLib` files, as footprints typically don't have manufacturer part numbers associated with them.

These scripts are tested and confirmed working on Altium Designer Agile 26.6.0 with Windows 11 Pro 25H2 running on an Asus NUC13ANK.

## Modifying the scripts

The paths in the `const` section should be updated to match the primary library locations of the project. The paths `BuildHardcodedSchTargets` and `BuildHardcodedPcbTargets` should be updated accordingly as well with the library file names.

`ALTIUM_LIB_ROOT`: Primary folder where the libraries are stored

`SOURCE_SCHLIB`: The `.schlib` file that contains the updated components being pushed to the project libraries.

`SOURCE_PCBLIB`: The `.pcblib` file that contains the updated components being pushed to the project libraries.

`EXTRA_TARGET_SCHLIB`: Additional `.schlib` file to be updated if need be.

`EXTRA_TARGET_PCBLIB`: Additional `.pcblib` file to be updated if need be.

`LOG_FILE`: Path to store log file of updates.

### Additional parameters for `UpdateLibrariesFromTransfersByMPN.pas`:

`DRY_RUN`: Set to `True` to simulate a run and output a log file without actually making any changes. Good to confirm what would be changed by the script.

`PRESERVE_TARGET_LIBREF`: After replacing the original component with the updated one, make sure that the reference designator remains the same for the project to avoid breaking parts that have already been placed. Recommended: `True`

`USE_PART_NUMBER_AS_MPN_FALLBACK`:  Set `True` only if the project libraries consistently use generic "Part Number" as manufacturer part number. Leaving this `False` avoids false matches.

## Running the scripts

In Altium Designer, these `.pas` script files can either be dragged directly into the Project sidebar, or a new Script Project can be created by navigating to File > New > Script > Script Project and the files added to that.

Once the desired script is open in Altium, save it. Then edit the file paths in the script to the relevant ones for the current project.

To run the script, go to Run > Set Project Startup Procedure, then in the pop-up window, select the item that starts with `RunBulkReplaceFromTransfers` and select Okay. Then go to Run > Run or press F9 to run the script.

After the script is done running, right click the Libraries folder in the Projects tab in Altium, then select Save All to ensure that all the changes are saved.

## Push the changes to the current Altium project

Open the top level schematic (`SchDoc`), then go to Tools > Update from Libraries. In the pop-up window, make sure that everything is selected and click Finish. In the following Engineering Change Order (ECO) window, make sure that all the components are selected and click Execute Changes. After that completes, close the ECO window and navigate to Design > Update PCB Document [project_name].PcbDoc. In the pop-up ECO window, select Execute Changes.

Open the layout (`.PcbDoc`) and go to Tools > Update From PCB Libraries. In the pop-up options window, make sure all of the layers are selected, then click Update All Footprints (Create ECO). In the new ECO window, make sure that all the components are selected and click Execute Changes.

The Altium project should now have all of its components updated with the parts from the new library.
