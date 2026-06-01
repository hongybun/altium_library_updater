# Altium Library Updater

Two scripts are provided: `UpdateLibrariesFromTransfersByName.pas` only checks the names of the components in `.SchLib` and `.PcbLib` files, and `UpdateLibrariesFromTransfersByMPN.pas` checks the manufacturer part numbers of the components `.SchLib` files but only checks the name of the components in `.PcbLib` files, as footprints typically don't have manufacturer part numbers associated with them.

These scripts are tested and confirmed working on Altium Designer Agile 26.6.0 with Windows 11 Pro 25H2 running on an Asus NUC13ANK.

## Running the scripts

In Altium Designer, these `.pas` script files can either be dragged directly into the Project sidebar, or a new Script Project can be created by navigating to File > New > Script > Script Project and the files added to that.

Once the desired script is open in Altium, save it. Then edit the file paths in the script to the relevant ones for the current project.

To run the script, go to Run > Set Project Startup Procedure, then in the pop-up window, select the item that starts with `RunBulkReplaceFromTransfers` and select Okay. Then go to Run > Run or press F9 to run the script.

After the script is done running, right click the Libraries folder in the Projects tab in Altium, then select Save All to ensure that all the changes are saved.

## Push the changes to the current Altium project

Open the top level schematic (`SchDoc`), then go to Tools > Update from Libraries. In the pop-up window, make sure that everything is selected and click Finish. In the following Engineering Change Order (ECO) window, make sure that all the components are selected and click Execute Changes. After that completes, close the ECO window and navigate to Design > Update PCB Document [project_name].PcbDoc. In the pop-up ECO window, select Execute Changes.

Open the layout (`.PcbDoc`) and go to Tools > Update From PCB Libraries. In the pop-up options window, make sure all of the layers are selected, then click Update All Footprints (Create ECO). In the new ECO window, make sure that all the components are selected and click Execute Changes.

The Altium project should now have all of its components updated with the parts from the new library.
