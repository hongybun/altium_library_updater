{***************************************************************************
  BulkReplaceFromTransfers.pas

  Purpose:
    Replace same-named schematic components and PCB footprints in local
    Altium libraries using authoritative versions from:

      C:\Users\hon\ee-hardware\altium_libs\transfers.SchLib
      C:\Users\hon\ee-hardware\altium_libs\transfers.PcbLib

  Targets:
    1. All *.SchLib and *.PcbLib under:
         C:\Users\hon\ee-hardware\altium_libs

    2. Project-local libraries:
         C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_schlib.SchLib
         C:\Users\hon\ee-hardware\projects\turret_v2\BF2_motherboard\BF2_motherboard_rev2\motherboard_pcblib.PcbLib

  Policy:
    - Replace same-named items only.
    - Do not add transfer-only components to target libraries.
    - Do not modify transfers.SchLib or transfers.PcbLib.

  Before running:
    - Commit or copy-backup all libraries.
    - Close other Altium documents if possible.
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
        'C:\Users\hon\ee-hardware\bulk_transfer_replace_log.txt';

    // Set True for a report-only run.
    DRY_RUN = False;

var
    LogLines : TStringList;


{***************************************************************************
  General utilities
***************************************************************************}

function LowerStr(S : String) : String;
begin
    Result := AnsiLowerCase(S);
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

function FileExtIs(FileName, Ext : String) : Boolean;
begin
    Result := LowerStr(ExtractFileExt(FileName)) = LowerStr(Ext);
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

procedure CollectFilesRecursive(Folder, Ext : String; List : TStringList);
var
    SR : TSearchRec;
    Path : String;
begin
    Path := IncludeTrailingPathDelimiter(Folder);

    if FindFirst(Path + '*.*', faAnyFile, SR) = 0 then
    begin
        repeat
            if (SR.Name <> '.') and (SR.Name <> '..') then
            begin
                if (SR.Attr and faDirectory) <> 0 then
                begin
                    CollectFilesRecursive(Path + SR.Name, Ext, List);
                end
                else
                begin
                    if FileExtIs(SR.Name, Ext) then
                        AddUniqueFile(List, Path + SR.Name);
                end;
            end;
        until FindNext(SR) <> 0;

        FindClose(SR);
    end;
end;


{***************************************************************************
  Document open/save helpers
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

    // Project-local schematic library.
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

    // Project-local PCB library.
    AddUniqueFile(List, EXTRA_TARGET_PCBLIB);
end;

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

procedure BuildSourceSchComponentList(SourceLib : ISch_Lib; Names : TStringList);
var
    It   : ISch_Iterator;
    Comp : ISch_Component;
begin
    Names.Clear;

    It := SourceLib.SchLibIterator_Create;
    if It = Nil then
        Exit;

    try
        It.AddFilter_ObjectSet(MkSet(eSchComponent));

        Comp := It.FirstSchObject;
        while Comp <> Nil do
        begin
            if Comp.LibReference <> '' then
                Names.Add(Comp.LibReference);

            Comp := It.NextSchObject;
        end;
    finally
        SourceLib.SchIterator_Destroy(It);
    end;
end;

procedure ReplaceOneSchComponent(SourceLib, TargetLib : ISch_Lib; LibRef : String);
var
    SourceComp : ISch_Component;
    TargetComp : ISch_Component;
    NewComp    : ISch_Component;
begin
    SourceComp := FindSchComponentByLibRef(SourceLib, LibRef);
    TargetComp := FindSchComponentByLibRef(TargetLib, LibRef);

    if SourceComp = Nil then
    begin
        Log('SCH source missing unexpectedly: ' + LibRef);
        Exit;
    end;

    if TargetComp = Nil then
    begin
        Log('SCH skip, no matching target component: ' + LibRef);
        Exit;
    end;

    Log('SCH replace: ' + LibRef);

    if DRY_RUN then
        Exit;

    SchServer.ProcessControl.PreProcess(TargetLib, '');

    {
      Most Altium schematic primitives support Replicate.
      If your AD 2026 install reports that Replicate is unavailable for
      ISch_Component, replace this block with the copy/paste-process fallback.
    }
    NewComp := SourceComp.Replicate;
    NewComp.LibReference := SourceComp.LibReference;

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

procedure ProcessOneSchLib(SourceSchDoc : IServerDocument;
                           SourceLib    : ISch_Lib;
                           TargetFile   : String);
var
    TargetDoc : IServerDocument;
    TargetLib : ISch_Lib;
    Names     : TStringList;
    i         : Integer;
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

    Names := TStringList.Create;
    try
        BuildSourceSchComponentList(SourceLib, Names);

        for i := 0 to Names.Count - 1 do
            ReplaceOneSchComponent(SourceLib, TargetLib, Names.Strings[i]);

        SaveFocusedDocument;
        Log('SCH saved: ' + TargetFile);
    finally
        Names.Free;
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
        Log('PCB skip, no matching target footprint: ' + FootprintName);
        Exit;
    end;

    Log('PCB replace: ' + FootprintName);

    if DRY_RUN then
        Exit;

    PCBServer.PreProcess;

    {
      Most PCB objects support Replicate.
      If AD 2026 reports that Replicate is unavailable for IPCB_LibComponent,
      use Altium's copy/paste process fallback or manually copy child
      primitives from SourceComp to NewComp.
    }
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

procedure RunBulkReplaceFromTransfers;
var
    SchTargets : TStringList;
    PcbTargets : TStringList;

    SourceSchDoc : IServerDocument;
    SourcePcbDoc : IServerDocument;

    SourceSchLib : ISch_Lib;
    SourcePcbLib : IPCB_Library;

    i : Integer;
begin
    LogLines := TStringList.Create;
    SchTargets := TStringList.Create;
    PcbTargets := TStringList.Create;

    try
        Log('Bulk replacement started.');
        Log('DRY_RUN = ' + BoolToStr(DRY_RUN, True));

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
          Schematic libraries
        -------------------------}
        SourceSchDoc := OpenDocumentByKind('SCHLIB', SOURCE_SCHLIB);
        if SourceSchDoc = Nil then
            Exit;

        SourceSchLib := GetCurrentSchLib;
        if SourceSchLib = Nil then
            Exit;

        for i := 0 to SchTargets.Count - 1 do
            ProcessOneSchLib(SourceSchDoc, SourceSchLib, SchTargets.Strings[i]);

        {-------------------------
          PCB libraries
        -------------------------}
        SourcePcbDoc := OpenDocumentByKind('PCBLIB', SOURCE_PCBLIB);
        if SourcePcbDoc = Nil then
            Exit;

        SourcePcbLib := GetCurrentPcbLib;
        if SourcePcbLib = Nil then
            Exit;

        for i := 0 to PcbTargets.Count - 1 do
            ProcessOnePcbLib(SourcePcbDoc, SourcePcbLib, PcbTargets.Strings[i]);

        Log('Bulk replacement complete.');
        SaveLog;

        ShowMessage('Bulk transfer replacement complete.' + #13#10 +
                    'Log written to:' + #13#10 + LOG_FILE);
    finally
        SaveLog;
        SchTargets.Free;
        PcbTargets.Free;
        LogLines.Free;
    end;
end;
