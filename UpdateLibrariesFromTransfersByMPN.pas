{***************************************************************************
  BulkReplaceFromTransfers_ByMPN.pas

  Purpose:
    Replace schematic components in local Altium SchLib libraries using
    components from transfers.SchLib when the Manufacturer Part Number matches,
    even if the component library names / LibReferences are different.

    Replace PCB footprints from transfers.PcbLib by footprint name.

  Source libraries:
      C:\Users\hon\ee-hardware\altium_libs\transfers.SchLib
      C:\Users\hon\ee-hardware\altium_libs\transfers.PcbLib

  Target schematic libraries:
      C:\Users\hon\ee-hardware\altium_libs\analog_ics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\capacitors.SchLib
      C:\Users\hon\ee-hardware\altium_libs\connectors.SchLib
      C:\Users\hon\ee-hardware\altium_libs\digital_ics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\diodes.SchLib
      C:\Users\hon\ee-hardware\altium_libs\magnetics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\mcu_ics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\miscellaneous.SchLib
      C:\Users\hon\ee-hardware\altium_libs\modules.SchLib
      C:\Users\hon\ee-hardware\altium_libs\power_ics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\resistors.SchLib
      C:\Users\hon\ee-hardware\altium_libs\sensor_ics.SchLib
      C:\Users\hon\ee-hardware\altium_libs\transistors.SchLib
      C:\Users\hon\ee-hardware\altium_libs\wiring_harness.SchLib
      C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_schlib.SchLib

  Target PCB libraries:
      C:\Users\hon\ee-hardware\altium_libs\connectors.PcbLib
      C:\Users\hon\ee-hardware\altium_libs\discretes.PcbLib
      C:\Users\hon\ee-hardware\altium_libs\integratedckts.PcbLib
      C:\Users\hon\ee-hardware\altium_libs\miscellaneous.PcbLib
      C:\Users\hon\ee-hardware\altium_libs\modules.PcbLib
      C:\Users\hon\ee-hardware\altium_libs\passives.PcbLib
      C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_pcblib.PcbLib

  Schematic matching policy:
    - Source component MPN matches target component MPN.
    - Component names do not need to match.
    - Target component name is preserved by default.

  PCB matching policy:
    - Footprints are replaced by footprint name.
    - MPN-based PCB footprint replacement is not reliable unless your
      PcbLib footprints carry explicit MPN parameters.

  Before running:
    - Commit or copy-backup all libraries.
    - Run once with DRY_RUN = True.
    - Inspect LOG_FILE.
    - Then run with DRY_RUN = False.
***************************************************************************}

const
    ALTIUM_LIB_ROOT =
        'C:\Users\hon\ee-hardware\altium_libs';

    SOURCE_SCHLIB =
        'C:\Users\hon\ee-hardware\altium_libs\transfers.SchLib';

    SOURCE_PCBLIB =
        'C:\Users\hon\ee-hardware\altium_libs\transfers.PcbLib';

    EXTRA_TARGET_SCHLIB =
        'C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_schlib.SchLib';

    EXTRA_TARGET_PCBLIB =
        'C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_pcblib.PcbLib';

    LOG_FILE =
        'C:\Users\hon\ee-hardware\bulk_transfer_replace_by_mpn_log.txt';

    // Set True for a report-only run.
    DRY_RUN = False;

    // Recommended True:
    // The updated schematic component from transfers.SchLib is copied into
    // the target library, but its LibReference is changed back to the original
    // target component name. This helps avoid breaking existing placed parts.
    PRESERVE_TARGET_LIBREF = True;

    // Set True only if your libraries consistently use generic "Part Number"
    // as manufacturer part number. Leaving this False avoids false matches.
    USE_PART_NUMBER_AS_MPN_FALLBACK = False;

var
    LogLines : TStringList;


{***************************************************************************
  General utilities
***************************************************************************}

function LowerStr(S : String) : String;
begin
    Result := AnsiLowerCase(S);
end;

function UpperStr(S : String) : String;
begin
    Result := AnsiUpperCase(S);
end;

function TrimStr(S : String) : String;
begin
    Result := Trim(S);
end;

function SamePath(A, B : String) : Boolean;
begin
    Result := LowerStr(ExpandFileName(A)) = LowerStr(ExpandFileName(B));
end;

procedure Log(S : String);
begin
    LogLines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' + S);
end;

procedure SaveLog;
begin
    LogLines.SaveToFile(LOG_FILE);
end;

function NormalizeMpn(S : String) : String;
begin
    // Conservative normalization:
    // - trim leading/trailing whitespace
    // - compare case-insensitively
    // Do not remove hyphens, slashes, dots, or internal spaces.
    Result := UpperStr(TrimStr(S));
end;

function IsBlank(S : String) : Boolean;
begin
    Result := TrimStr(S) = '';
end;

function ListContains(List : TStringList; S : String) : Boolean;
var
    i : Integer;
begin
    Result := False;

    for i := 0 to List.Count - 1 do
    begin
        if SamePath(List.Strings[i], S) then
        begin
            Result := True;
            Exit;
        end;
    end;
end;

procedure AddUniqueFile(List : TStringList; FileName : String);
begin
    if not FileExists(FileName) then
    begin
        Log('WARNING: target file does not exist: ' + FileName);
        Exit;
    end;

    if not ListContains(List, FileName) then
    begin
        List.Add(FileName);
        Log('Added target: ' + FileName);
    end;
end;


{***************************************************************************
  Hardcoded target libraries
***************************************************************************}

procedure BuildHardcodedSchTargets(List : TStringList);
begin
    List.Clear;

    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\analog_ics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\capacitors.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\connectors.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\digital_ics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\diodes.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\magnetics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\mcu_ics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\miscellaneous.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\modules.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\power_ics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\resistors.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\sensor_ics.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\transistors.SchLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\wiring_harness.SchLib');

    AddUniqueFile(List, EXTRA_TARGET_SCHLIB);
end;

procedure BuildHardcodedPcbTargets(List : TStringList);
begin
    List.Clear;

    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\connectors.PcbLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\discretes.PcbLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\integratedckts.PcbLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\miscellaneous.PcbLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\modules.PcbLib');
    AddUniqueFile(List, ALTIUM_LIB_ROOT + '\passives.PcbLib');

    AddUniqueFile(List, EXTRA_TARGET_PCBLIB);
end;


{***************************************************************************
  Document open/save helpers
***************************************************************************}

function OpenDocumentByKind(Kind, FileName : String) : IServerDocument;
begin
    Result := Client.OpenDocument(Kind, FileName);

    if Result <> Nil then
    begin
        Client.ShowDocument(Result);
    end
    else
    begin
        Log('ERROR: could not open ' + FileName);
    end;
end;

procedure SaveFocusedDocument;
begin
    if DRY_RUN then
        Exit;

    Client.SendMessage('WorkspaceManager:Save', 'ObjectKind=Document', 255, Client.CurrentView);
end;


{***************************************************************************
  Schematic library helpers
***************************************************************************}

function GetCurrentSchLib : ISch_Lib;
var
    Doc : ISch_Document;
begin
    Result := Nil;

    if SchServer = Nil then
    begin
        Log('ERROR: SchServer is nil.');
        Exit;
    end;

    Doc := SchServer.GetCurrentSchDocument;

    if Doc = Nil then
    begin
        Log('ERROR: current schematic document is nil.');
        Exit;
    end;

    if Doc.ObjectID <> eSchLib then
    begin
        Log('ERROR: current document is not a schematic library.');
        Exit;
    end;

    Result := Doc;
end;

function FindSchComponentByLibRef(Lib : ISch_Lib; LibRef : String) : ISch_Component;
var
    It   : ISch_Iterator;
    Comp : ISch_Component;
begin
    Result := Nil;

    if Lib = Nil then
        Exit;

    It := Lib.SchLibIterator_Create;
    if It = Nil then
        Exit;

    try
        It.AddFilter_ObjectSet(MkSet(eSchComponent));

        Comp := It.FirstSchObject;
        while Comp <> Nil do
        begin
            if LowerStr(Comp.LibReference) = LowerStr(LibRef) then
            begin
                Result := Comp;
                Break;
            end;

            Comp := It.NextSchObject;
        end;
    finally
        Lib.SchIterator_Destroy(It);
    end;
end;

function GetSchParameterValue(Comp : ISch_Component; ParamName : String) : String;
var
    It    : ISch_Iterator;
    Param : ISch_Parameter;
begin
    Result := '';

    if Comp = Nil then
        Exit;

    It := Comp.SchIterator_Create;
    if It = Nil then
        Exit;

    try
        It.AddFilter_ObjectSet(MkSet(eParameter));

        Param := It.FirstSchObject;
        while Param <> Nil do
        begin
            if LowerStr(TrimStr(Param.Name)) = LowerStr(TrimStr(ParamName)) then
            begin
                Result := TrimStr(Param.Text);
                Break;
            end;

            Param := It.NextSchObject;
        end;
    finally
        Comp.SchIterator_Destroy(It);
    end;
end;

function GetComponentMPN(Comp : ISch_Component) : String;
begin
    Result := '';

    // Most preferred names first.
    Result := GetSchParameterValue(Comp, 'Manufacturer Part Number');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'ManufacturerPartNumber');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Manufacturer Part No');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Manufacturer Part #');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Mfr Part Number');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Mfr Part No');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Mfr Part #');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'MFG Part Number');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'MFG PN');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'MPN');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'Manufacturer PN');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'MfgPN');
    if not IsBlank(Result) then Exit;

    Result := GetSchParameterValue(Comp, 'MfrPN');
    if not IsBlank(Result) then Exit;

    if USE_PART_NUMBER_AS_MPN_FALLBACK then
    begin
        Result := GetSchParameterValue(Comp, 'Part Number');
        if not IsBlank(Result) then Exit;

        Result := GetSchParameterValue(Comp, 'PartNumber');
        if not IsBlank(Result) then Exit;
    end;
end;

procedure BuildSourceSchMPNMap(SourceLib : ISch_Lib; Map : TStringList);
var
    It       : ISch_Iterator;
    Comp     : ISch_Component;
    RawMPN   : String;
    KeyMPN   : String;
    Existing : String;
begin
    Map.Clear;
    Map.CaseSensitive := False;
    Map.Sorted := False;

    It := SourceLib.SchLibIterator_Create;
    if It = Nil then
        Exit;

    try
        It.AddFilter_ObjectSet(MkSet(eSchComponent));

        Comp := It.FirstSchObject;
        while Comp <> Nil do
        begin
            RawMPN := GetComponentMPN(Comp);
            KeyMPN := NormalizeMpn(RawMPN);

            if IsBlank(KeyMPN) then
            begin
                Log('SCH source has no MPN, skipping source component: ' + Comp.LibReference);
            end
            else
            begin
                Existing := Map.Values[KeyMPN];

                if not IsBlank(Existing) then
                begin
                    Log('WARNING: duplicate source MPN "' + RawMPN + '". Existing source="' +
                        Existing + '", duplicate source="' + Comp.LibReference +
                        '". Keeping existing.');
                end
                else
                begin
                    Map.Values[KeyMPN] := Comp.LibReference;
                    Log('SCH source MPN map: "' + RawMPN + '" -> ' + Comp.LibReference);
                end;
            end;

            Comp := It.NextSchObject;
        end;
    finally
        SourceLib.SchIterator_Destroy(It);
    end;
end;

procedure BuildTargetSchComponentMPNList(TargetLib : ISch_Lib; List : TStringList);
var
    It       : ISch_Iterator;
    Comp     : ISch_Component;
    RawMPN   : String;
    KeyMPN   : String;
begin
    List.Clear;

    It := TargetLib.SchLibIterator_Create;
    if It = Nil then
        Exit;

    try
        It.AddFilter_ObjectSet(MkSet(eSchComponent));

        Comp := It.FirstSchObject;
        while Comp <> Nil do
        begin
            RawMPN := GetComponentMPN(Comp);
            KeyMPN := NormalizeMpn(RawMPN);

            if IsBlank(KeyMPN) then
            begin
                Log('SCH target has no MPN, skipping target component: ' + Comp.LibReference);
            end
            else
            begin
                // Store as:
                // target LibReference + tab + normalized MPN + tab + raw MPN
                List.Add(Comp.LibReference + #9 + KeyMPN + #9 + RawMPN);
            end;

            Comp := It.NextSchObject;
        end;
    finally
        TargetLib.SchIterator_Destroy(It);
    end;
end;

function FieldFromTabbedLine(Line : String; FieldIndex : Integer) : String;
var
    Temp : TStringList;
begin
    Result := '';

    Temp := TStringList.Create;
    try
        Temp.Delimiter := #9;
        Temp.StrictDelimiter := True;
        Temp.DelimitedText := Line;

        if (FieldIndex >= 0) and (FieldIndex < Temp.Count) then
            Result := Temp.Strings[FieldIndex];
    finally
        Temp.Free;
    end;
end;

procedure ReplaceOneSchComponentByMPN(SourceLib     : ISch_Lib;
                                      TargetLib     : ISch_Lib;
                                      SourceLibRef  : String;
                                      TargetLibRef  : String;
                                      RawTargetMPN  : String);
var
    SourceComp       : ISch_Component;
    TargetComp       : ISch_Component;
    NewComp          : ISch_Component;
    FinalLibRef      : String;
    OriginalTargetRef: String;
begin
    SourceComp := FindSchComponentByLibRef(SourceLib, SourceLibRef);
    TargetComp := FindSchComponentByLibRef(TargetLib, TargetLibRef);

    if SourceComp = Nil then
    begin
        Log('SCH source missing unexpectedly: ' + SourceLibRef);
        Exit;
    end;

    if TargetComp = Nil then
    begin
        Log('SCH target missing unexpectedly: ' + TargetLibRef);
        Exit;
    end;

    OriginalTargetRef := TargetComp.LibReference;

    if PRESERVE_TARGET_LIBREF then
        FinalLibRef := OriginalTargetRef
    else
        FinalLibRef := SourceComp.LibReference;

    Log('SCH replace by MPN "' + RawTargetMPN + '": target="' +
        OriginalTargetRef + '", source="' + SourceComp.LibReference +
        '", final LibReference="' + FinalLibRef + '"');

    if DRY_RUN then
        Exit;

    SchServer.ProcessControl.PreProcess(TargetLib, '');

    NewComp := SourceComp.Replicate;
    NewComp.LibReference := FinalLibRef;

    TargetLib.RemoveSchComponent(TargetComp);
    TargetLib.AddSchComponent(NewComp);

    SchServer.RobotManager.SendMessage(
        Nil,
        c_BroadCast,
        SCHM_PrimitiveRegistration,
        NewComp.I_ObjectAddress
    );

    SchServer.ProcessControl.PostProcess(TargetLib, '');
    TargetLib.GraphicallyInvalidate;
end;

procedure ProcessOneSchLibByMPN(SourceSchDoc : IServerDocument;
                                SourceLib    : ISch_Lib;
                                SourceMap    : TStringList;
                                TargetFile   : String);
var
    TargetDoc       : IServerDocument;
    TargetLib       : ISch_Lib;
    TargetItems     : TStringList;
    i               : Integer;
    TargetLibRef    : String;
    KeyMPN          : String;
    RawMPN          : String;
    SourceLibRef    : String;
begin
    if SamePath(TargetFile, SOURCE_SCHLIB) then
    begin
        Log('SCH skip source library: ' + TargetFile);
        Exit;
    end;

    Log('SCH target open: ' + TargetFile);

    TargetDoc := OpenDocumentByKind('SCHLIB', TargetFile);
    if TargetDoc = Nil then
        Exit;

    TargetLib := GetCurrentSchLib;
    if TargetLib = Nil then
        Exit;

    TargetItems := TStringList.Create;
    try
        BuildTargetSchComponentMPNList(TargetLib, TargetItems);

        for i := 0 to TargetItems.Count - 1 do
        begin
            TargetLibRef := FieldFromTabbedLine(TargetItems.Strings[i], 0);
            KeyMPN       := FieldFromTabbedLine(TargetItems.Strings[i], 1);
            RawMPN       := FieldFromTabbedLine(TargetItems.Strings[i], 2);

            SourceLibRef := SourceMap.Values[KeyMPN];

            if IsBlank(SourceLibRef) then
            begin
                Log('SCH skip, no source component with matching MPN "' +
                    RawMPN + '" for target component: ' + TargetLibRef);
            end
            else
            begin
                ReplaceOneSchComponentByMPN(
                    SourceLib,
                    TargetLib,
                    SourceLibRef,
                    TargetLibRef,
                    RawMPN
                );
            end;
        end;

        SaveFocusedDocument;
        Log('SCH saved: ' + TargetFile);
    finally
        TargetItems.Free;
    end;
end;


{***************************************************************************
  PCB library helpers
***************************************************************************}

function GetCurrentPcbLib : IPCB_Library;
begin
    Result := Nil;

    if PCBServer = Nil then
    begin
        Log('ERROR: PCBServer is nil.');
        Exit;
    end;

    Result := PCBServer.GetCurrentPCBLibrary;

    if Result = Nil then
        Log('ERROR: current document is not a PCB library.');
end;

function FindPcbFootprintByName(Lib : IPCB_Library; FootprintName : String) : IPCB_LibComponent;
var
    It   : IPCB_LibraryIterator;
    Comp : IPCB_LibComponent;
begin
    Result := Nil;

    if Lib = Nil then
        Exit;

    It := Lib.LibraryIterator_Create;
    if It = Nil then
        Exit;

    Comp := It.FirstPCBObject;
    while Comp <> Nil do
    begin
        if LowerStr(Comp.Name) = LowerStr(FootprintName) then
        begin
            Result := Comp;
            Break;
        end;

        Comp := It.NextPCBObject;
    end;

    Lib.LibraryIterator_Destroy(It);
end;

procedure BuildSourcePcbFootprintList(SourceLib : IPCB_Library; Names : TStringList);
var
    It   : IPCB_LibraryIterator;
    Comp : IPCB_LibComponent;
begin
    Names.Clear;

    It := SourceLib.LibraryIterator_Create;
    if It = Nil then
        Exit;

    Comp := It.FirstPCBObject;
    while Comp <> Nil do
    begin
        if Comp.Name <> '' then
            Names.Add(Comp.Name);

        Comp := It.NextPCBObject;
    end;

    SourceLib.LibraryIterator_Destroy(It);
end;

procedure ReplaceOnePcbFootprint(SourceLib, TargetLib : IPCB_Library; FootprintName : String);
var
    SourceComp : IPCB_LibComponent;
    TargetComp : IPCB_LibComponent;
    NewComp    : IPCB_LibComponent;
begin
    SourceComp := FindPcbFootprintByName(SourceLib, FootprintName);
    TargetComp := FindPcbFootprintByName(TargetLib, FootprintName);

    if SourceComp = Nil then
    begin
        Log('PCB source missing unexpectedly: ' + FootprintName);
        Exit;
    end;

    if TargetComp = Nil then
    begin
        Log('PCB skip, no matching target footprint by name: ' + FootprintName);
        Exit;
    end;

    Log('PCB replace by footprint name: ' + FootprintName);

    if DRY_RUN then
        Exit;

    PCBServer.PreProcess;

    NewComp := SourceComp.Replicate;
    NewComp.Name := SourceComp.Name;

    TargetLib.RemoveComponent(TargetComp);
    TargetLib.RegisterComponent(NewComp);

    PCBServer.SendMessageToRobots(
        TargetLib.I_ObjectAddress,
        c_Broadcast,
        PCBM_BoardRegisteration,
        NewComp.I_ObjectAddress
    );

    PCBServer.PostProcess;
end;

procedure ProcessOnePcbLib(SourcePcbDoc : IServerDocument;
                           SourceLib    : IPCB_Library;
                           TargetFile   : String);
var
    TargetDoc : IServerDocument;
    TargetLib : IPCB_Library;
    Names     : TStringList;
    i         : Integer;
begin
    if SamePath(TargetFile, SOURCE_PCBLIB) then
    begin
        Log('PCB skip source library: ' + TargetFile);
        Exit;
    end;

    Log('PCB target open: ' + TargetFile);

    TargetDoc := OpenDocumentByKind('PCBLIB', TargetFile);
    if TargetDoc = Nil then
        Exit;

    TargetLib := GetCurrentPcbLib;
    if TargetLib = Nil then
        Exit;

    Names := TStringList.Create;
    try
        BuildSourcePcbFootprintList(SourceLib, Names);

        for i := 0 to Names.Count - 1 do
            ReplaceOnePcbFootprint(SourceLib, TargetLib, Names.Strings[i]);

        SaveFocusedDocument;
        Log('PCB saved: ' + TargetFile);
    finally
        Names.Free;
    end;
end;


{***************************************************************************
  Main
***************************************************************************}

procedure RunBulkReplaceFromTransfersByMPN;
var
    SchTargets   : TStringList;
    PcbTargets   : TStringList;
    SourceMPNMap : TStringList;

    SourceSchDoc : IServerDocument;
    SourcePcbDoc : IServerDocument;

    SourceSchLib : ISch_Lib;
    SourcePcbLib : IPCB_Library;

    i : Integer;
begin
    LogLines := TStringList.Create;
    SchTargets := TStringList.Create;
    PcbTargets := TStringList.Create;
    SourceMPNMap := TStringList.Create;

    try
        Log('Bulk replacement by MPN started.');
        Log('DRY_RUN = ' + BoolToStr(DRY_RUN, True));
        Log('PRESERVE_TARGET_LIBREF = ' + BoolToStr(PRESERVE_TARGET_LIBREF, True));
        Log('USE_PART_NUMBER_AS_MPN_FALLBACK = ' + BoolToStr(USE_PART_NUMBER_AS_MPN_FALLBACK, True));

        if not FileExists(SOURCE_SCHLIB) then
        begin
            ShowError('Missing source schematic library: ' + SOURCE_SCHLIB);
            Exit;
        end;

        if not FileExists(SOURCE_PCBLIB) then
        begin
            ShowError('Missing source PCB library: ' + SOURCE_PCBLIB);
            Exit;
        end;

        BuildHardcodedSchTargets(SchTargets);
        BuildHardcodedPcbTargets(PcbTargets);

        Log('SCH target count: ' + IntToStr(SchTargets.Count));
        Log('PCB target count: ' + IntToStr(PcbTargets.Count));

        Log('Hardcoded SCH targets:');
        for i := 0 to SchTargets.Count - 1 do
            Log('  SCH: ' + SchTargets.Strings[i]);

        Log('Hardcoded PCB targets:');
        for i := 0 to PcbTargets.Count - 1 do
            Log('  PCB: ' + PcbTargets.Strings[i]);

        {-------------------------
          Source schematic library
        -------------------------}
        SourceSchDoc := OpenDocumentByKind('SCHLIB', SOURCE_SCHLIB);
        if SourceSchDoc = Nil then
            Exit;

        SourceSchLib := GetCurrentSchLib;
        if SourceSchLib = Nil then
            Exit;

        BuildSourceSchMPNMap(SourceSchLib, SourceMPNMap);

        Log('Source schematic MPN map count: ' + IntToStr(SourceMPNMap.Count));

        {-------------------------
          Target schematic libraries
        -------------------------}
        for i := 0 to SchTargets.Count - 1 do
            ProcessOneSchLibByMPN(SourceSchDoc, SourceSchLib, SourceMPNMap, SchTargets.Strings[i]);

        {-------------------------
          Source PCB library
        -------------------------}
        SourcePcbDoc := OpenDocumentByKind('PCBLIB', SOURCE_PCBLIB);
        if SourcePcbDoc = Nil then
            Exit;

        SourcePcbLib := GetCurrentPcbLib;
        if SourcePcbLib = Nil then
            Exit;

        {-------------------------
          Target PCB libraries
        -------------------------}
        for i := 0 to PcbTargets.Count - 1 do
            ProcessOnePcbLib(SourcePcbDoc, SourcePcbLib, PcbTargets.Strings[i]);

        Log('Bulk replacement by MPN complete.');
        SaveLog;

        ShowMessage('Bulk transfer replacement by MPN complete.' + #13#10 +
                    'Log written to:' + #13#10 + LOG_FILE);
    finally
        SaveLog;
        SchTargets.Free;
        PcbTargets.Free;
        SourceMPNMap.Free;
        LogLines.Free;
    end;
end;


{***************************************************************************
  Script entry point
***************************************************************************}

begin
    RunBulkReplaceFromTransfersByMPN;
end.
