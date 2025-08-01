unit apphelpers;


// -------------------------------------
// Functions-library
// -------------------------------------


interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, Vcl.GraphUtil, Vcl.ClipBrd, Vcl.Dialogs, Vcl.Forms, Vcl.Controls, Winapi.ShellApi,
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX, VirtualTrees, VirtualTrees.BaseTree, VirtualTrees.Types, SynRegExpr, Winapi.Messages, System.Math,
  System.Win.Registry, System.DateUtils, System.Generics.Collections, System.Contnrs, System.StrUtils, System.AnsiStrings, Winapi.TlHelp32, System.Types,
  dbconnection, dbstructures, dbstructures.mysql, SynMemo, Vcl.Menus, Winapi.WinInet, gnugettext, Vcl.Themes,
  System.Character, Vcl.ImgList, System.UITypes, Vcl.ActnList, Winapi.WinSock, System.IOUtils, Vcl.StdCtrls, Vcl.ComCtrls,
  Winapi.CommCtrl, Winapi.KnownFolders, SynUnicode, SynEdit;

type

  TSortItemOrder = (sioAscending, sioDescending);
  TSortItem = class(TPersistent)
    public
      Column: String;
      Order: TSortItemOrder;
      procedure Assign(Source: TPersistent); override;
  end;
  TSortItems = class(TObjectList<TSortItem>)
    public
      function AddNew(Column: String=''; Order: TSortItemOrder=sioAscending): TSortItem;
      function ComposeOrderClause(Connection: TDBConnection): String;
      function FindByColumn(Column: String): TSortItem;
      procedure Assign(Source: TSortItems);
  end;

  TLineBreaks = (lbsNone, lbsWindows, lbsUnix, lbsMac, lbsWide, lbsMixed);

  TUTF8NoBOMEncoding = class(TUTF8Encoding)
    public
      function GetPreamble: TBytes; override;
  end;

  TDBObjectEditor = class(TFrame)
    private
      FModified: Boolean;
      procedure SetModified(Value: Boolean);
    protected
      FMainSynMemo: TSynMemo; // Main editor in case of routine, view, trigger or event
      FMainSynMemoPreviousTopLine: Integer;
      function ObjectExists: Boolean;
    public
      DBObject: TDBObject;
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Init(Obj: TDBObject); virtual;
      function DeInit: TModalResult; virtual;
      property Modified: Boolean read FModified write SetModified;
      function ApplyModifications: TModalResult; virtual; abstract;
  end;
  TDBObjectEditorClass = class of TDBObjectEditor;

  TSQLBatch = class;
  TSQLSentence = class(TObject)
    private
      FOwner: TSQLBatch;
      function GetSize: Integer;
      function GetSQL: String;
      function GetSQLWithoutComments: String;
    public
      LeftOffset, RightOffset: Integer;
      constructor Create(Owner: TSQLBatch);
      property SQL: String read GetSQL;
      property SQLWithoutComments: String read GetSQLWithoutComments;
      property Size: Integer read GetSize;
  end;
  TSQLBatch = class(TObjectList<TSQLSentence>)
    private
      FSQL: String;
      procedure SetSQL(Value: String);
      function GetSize: Integer;
      function GetSQLWithoutComments: String; overload;
    public
      class function GetSQLWithoutComments(FullSQL: String): String; overload;
      property Size: Integer read GetSize;
      property SQL: String read FSQL write SetSQL;
      property SQLWithoutComments: String read GetSQLWithoutComments;
  end;

  // Download
  THttpDownload = class(TObject)
    private
      FOwner: TComponent;
      FURL: String;
      FLastContent: String;
      FBytesRead: Integer;
      FContentLength: Integer;
      FTimeOut: Cardinal;
      FOnProgress: TNotifyEvent;
    public
      constructor Create(Owner: TComponent);
      procedure SendRequest(Filename: String);
      property OnProgress: TNotifyEvent read FOnProgress write FOnProgress;
      property URL: String read FURL write FURL;
      property TimeOut: Cardinal read FTimeOut write FTimeOut;
      property BytesRead: Integer read FBytesRead;
      property ContentLength: Integer read FContentLength;
      property LastContent: String read FLastContent;
  end;

  // Extended string list with support for empty values
  TExtStringList = class(TStringList)
    private
      function GetValue(const Name: string): string;
      procedure SetValue(const Name, Value: string); reintroduce;
    public
      property Values[const Name: string]: string read GetValue write SetValue;
  end;

  // Threading stuff
  TQueryThread = class(TThread)
  private
    FConnection: TDBConnection;
    FBatch: TSQLBatch;
    FTabNumber: Integer;
    FBatchInOneGo: Boolean;
    FStopOnErrors: Boolean;
    FAborted: Boolean;
    FErrorMessage: String;
    FBatchPosition: Integer;
    FQueriesInPacket: Integer;
    FQueryStartedAt: TDateTime;
    FQueryTime: Cardinal;
    FQueryNetTime: Cardinal;
    FRowsAffected: Int64;
    FRowsFound: Int64;
    FWarningCount: Int64;
  public
    property Connection: TDBConnection read FConnection;
    property Batch: TSQLBatch read FBatch;
    property TabNumber: Integer read FTabNumber;
    property BatchPosition: Integer read FBatchPosition;
    property QueriesInPacket: Integer read FQueriesInPacket;
    property QueryStartedAt: TDateTime read FQueryStartedAt;
    property QueryTime: Cardinal read FQueryTime;
    property QueryNetTime: Cardinal read FQueryNetTime;
    property RowsAffected: Int64 read FRowsAffected;
    property RowsFound: Int64 read FRowsFound;
    property WarningCount: Int64 read FWarningCount;
    property Aborted: Boolean read FAborted write FAborted;
    property ErrorMessage: String read FErrorMessage;
    constructor Create(Connection: TDBConnection; Batch: TSQLBatch; TabNumber: Integer);
    procedure Execute; override;
    procedure LogFromThread(Msg: String; Category: TDBLogCategory);
  end;

  TSqlTranspiler = class(TObject)
    class function CreateTable(SQL: String; SourceDb, TargetDb: TDBConnection): String;
  end;

  TClipboardHelper = class helper for TClipboard
  private
    function GetTryAsText: String;
    procedure SetTryAsText(AValue: String);
  public
    property TryAsText: String read GetTryAsText write SetTryAsText;
  end;

  TWinControlHelper = class helper for TWinControl
  public
    procedure TrySetFocus;
  end;

  //TSimpleKeyValuePairs = TDictionary<String, String>;

  TAppSettingDataType = (adInt, adBool, adString);
  TAppSettingIndex = (asHiddenColumns, asFilter, asSort, asDisplayedColumnsSorted, asLastSessions,
    asLastActiveSession, asAutoReconnect, asRestoreLastUsedDB, asLastUsedDB, asTreeBackground, asIgnoreDatabasePattern, asLogFileDdl, asLogFileDml, asLogFilePath,
    asFontName, asFontSize, asTabWidth, asDataFontName, asDataFontSize, asDataLocalNumberFormat, asLowercaseHex, asHintsOnResultTabs, asHightlightSameTextBackground,
    asShowRowId,
    asLogsqlnum, asLogsqlwidth, asSessionLogsDirectory, asLogHorizontalScrollbar, asSQLColActiveLine,
    asSQLColMatchingBraceForeground, asSQLColMatchingBraceBackground,
    asMaxColWidth, asDatagridMaximumRows, asDatagridRowsPerStep, asGridRowLineCount, asColumnHeaderClick, asReuseEditorConfiguration,
    asLogToFile, asMainWinMaximized, asMainWinLeft, asMainWinTop, asMainWinWidth,
    asMainWinHeight, asMainWinOnMonitor, asCoolBandIndex, asCoolBandBreak, asCoolBandWidth, asToolbarShowCaptions, asQuerymemoheight, asDbtreewidth,
    asDataPreviewHeight, asDataPreviewEnabled, asLogHeight, asQueryhelperswidth, asProjectManagerWidth, asProjectManagerVisible, asStopOnErrorsInBatchMode,
    asWrapLongLines, asCodeFolding, asDisplayBLOBsAsText, asSingleQueries, asMemoEditorWidth, asMemoEditorHeight, asMemoEditorMaximized,
    asMemoEditorWrap, asMemoEditorHighlighter, asMemoEditorAlwaysFormatCode, asDelimiter, asSQLHelpWindowLeft, asSQLHelpWindowTop, asSQLHelpWindowWidth,
    asSQLHelpWindowHeight, asSQLHelpPnlLeftWidth, asSQLHelpPnlRightTopHeight, asHost,
    asUser, asPassword, asCleartextPluginEnabled, asWindowsAuth, asLoginPrompt, asPort, asLibrary, asAllProviders,
    asSSHtunnelActive, asPlinkExecutable, asSshExecutable, asSSHtunnelHost, asSSHtunnelHostPort, asSSHtunnelPort, asSSHtunnelUser,
    asSSHtunnelPassword, asSSHtunnelTimeout, asSSHtunnelPrivateKey, asSSLActive, asSSLKey,
    asSSLCert, asSSLCA, asSSLCipher, asSSLVerification, asSSLWarnUnused, asNetType, asCompressed, asLocalTimeZone, asQueryTimeout, asKeepAlive,
    asStartupScriptFilename, asDatabases, asComment, asDatabaseFilter, asTableFilter, asFilterVT, asExportSQLCreateDatabases,
    asExportSQLCreateTables, asExportSQLDataHow, asExportSQLDataInsertSize, asExportSQLFilenames, asExportZIPFilenames, asExportSQLDirectories,
    asExportSQLDatabase, asExportSQLServerDatabase, asExportSQLOutput, asExportSQLAddComments, asExportSQLRemoveAutoIncrement, asExportSQLRemoveDefiner,
    asGridExportWindowWidth, asGridExportWindowHeight, asGridExportOutputCopy, asGridExportOutputFile,
    asGridExportFilename, asGridExportRecentFiles, asGridExportEncoding, asGridExportFormat, asGridExportSelection,
    asGridExportColumnNames, asGridExportIncludeAutoInc, asGridExportIncludeQuery, asGridExportRemoveLinebreaks,
    asGridExportSeparator, asGridExportEncloser, asGridExportTerminator, asGridExportNull,

    asGridExportClpColumnNames, asGridExportClpIncludeAutoInc, asGridExportClpRemoveLinebreaks,
    asGridExportClpSeparator, asGridExportClpEncloser, asGridExportClpTerminator, asGridExportClpNull,

    asCSVImportSeparator, asCSVImportEncloser, asCSVImportTerminator, asCSVImportFieldEscaper, asCSVImportWindowWidth, asCSVImportWindowHeight,
    asCSVImportFilename, asCSVImportFieldsEnclosedOptionally, asCSVImportIgnoreLines, asCSVImportLowPriority, asCSVImportLocalNumbers,
    asCSVImportDuplicateHandling, asCSVImportParseMethod, asCSVKeepDialogOpen,
    asUpdatecheck, asUpdatecheckBuilds, asUpdatecheckInterval, asUpdatecheckLastrun, asUpdateCheckWindowWidth, asUpdateCheckWindowHeight,
    asTableToolsWindowWidth, asTableToolsWindowHeight, asTableToolsTreeWidth,
    asTableToolsFindTextTab, asTableToolsFindText, asTableToolsFindSQL, asTableToolsDatatype, asTableToolsFindCaseSensitive, asTableToolsFindMatchType, asFileImportWindowWidth, asFileImportWindowHeight,
    asEditVarWindowWidth, asEditVarWindowHeight, asUsermanagerWindowWidth, asUsermanagerWindowHeight, asUsermanagerListWidth,
    asSelectDBOWindowWidth, asSelectDBOWindowHeight,
    asSessionManagerListWidth, asSessionManagerWindowWidth, asSessionManagerWindowHeight, asSessionManagerWindowLeft, asSessionManagerWindowTop,
    asCopyTableWindowHeight, asCopyTableWindowWidth, asCopyTableColumns, asCopyTableKeys, asCopyTableForeignKeys,
    asCopyTableData, asCopyTableRecentFilter, asServerVersion, asServerVersionFull, asLastConnect,
    asConnectCount, asRefusedCount, asSessionCreated, asDoUsageStatistics,
    asLastUsageStatisticCall, asWheelZoom, asDisplayBars, asMySQLBinaries, asCustomSnippetsDirectory,
    asPromptSaveFileOnTabClose, asRestoreTabs, asTabCloseOnDoubleClick, asTabCloseOnMiddleClick, asTabsInMultipleLines, asTabIconsGrayscaleMode,
    asWarnUnsafeUpdates, asQueryGridLongSortRowNum,
    asCompletionProposal, asCompletionProposalInterval, asCompletionProposalSearchOnMid, asCompletionProposalWidth, asCompletionProposalNbLinesInWindow, asAutoUppercase,
    asTabsToSpaces, asFilterPanel, asAllowMultipleInstances, asFindDialogSearchHistory, asGUIFontName, asGUIFontSize,
    asTheme, asIconPack, asWebSearchBaseUrl,
    asFindDialogReplaceHistory, asMaxQueryResults, asLogErrors,
    asLogUserSQL, asLogSQL, asLogInfos, asLogDebug, asLogScript, asLogTimestamp, asFieldColorNumeric,
    asFieldColorReal, asFieldColorText, asFieldColorBinary, asFieldColorDatetime, asFieldColorSpatial,
    asFieldColorOther, asFieldEditorBinary, asFieldEditorDatetime, asFieldEditorDatetimePrefill, asFieldEditorEnum,
    asFieldEditorSet, asFieldNullBackground, asRowBackgroundEven, asRowBackgroundOdd, asGroupTreeObjects, asDisplayObjectSizeColumn, asSQLfile,
    asActionShortcut1, asActionShortcut2, asHighlighterForeground, asHighlighterBackground, asHighlighterStyle,
    asListColWidths, asListColsVisible, asListColPositions, asListColSort, asSessionFolder,
    asRecentFilter, asTimestampColumns, asDateTimeEditorCursorPos, asAppLanguage, asAutoExpand, asDoubleClickInsertsNodeText, asForeignDropDown,
    asIncrementalSearch, asQueryHistoryEnabled, asQueryHistoryKeepDays,
    asColumnSelectorWidth, asColumnSelectorHeight, asDonatedEmail, asFavoriteObjects, asFavoriteObjectsOnly, asFullTableStatus, asLineBreakStyle,
    asPreferencesWindowWidth, asPreferencesWindowHeight,
    asFileDialogEncoding,
    asThemePreviewWidth, asThemePreviewHeight, asThemePreviewTop, asThemePreviewLeft,
    asCreateDbCollation, asRealTrailingZeros,
    asSequalSuggestWindowWidth, asSequalSuggestWindowHeight, asSequalSuggestPrompt, asSequalSuggestRecentPrompts,
    asReformatter, asReformatterNoDialog, asAlwaysGenerateFilter,
    asGenerateDataNumRows, asGenerateDataNullAmount, asWebOnceAction,
    asProjectManagerHeight,
    asUnused);
  TAppSetting = record
    Name: String;
    Session: Boolean;
    DefaultInt, CurrentInt: Integer;
    DefaultBool, CurrentBool: Boolean;
    DefaultString, CurrentString: String;
    Synced: Boolean;
  end;
  TAppSettings = class(TObject)
    private
      FReads, FWrites: Integer;
      FBasePath: String;
      FSessionPath: String;
      FStoredPath: String;
      FRegistry: TRegistry;
      FPortableMode: Boolean;
      FPortableModeReadOnly: Boolean;
      FRestoreTabsInitValue: Boolean;
      FSettingsFile: String;
      FSettings: Array[TAppSettingIndex] of TAppSetting;
      const FPortableLockFileBase: String='portable.lock';
      procedure InitSetting(Index: TAppSettingIndex; Name: String;
        DefaultInt: Integer=0; DefaultBool: Boolean=False; DefaultString: String='';
        Session: Boolean=False);
      procedure SetSessionPath(Value: String);
      procedure PrepareRegistry;
      procedure Read(Index: TAppSettingIndex; FormatName: String;
        DataType: TAppSettingDataType; var I: Integer; var B: Boolean; var S: String;
        DI: Integer; DB: Boolean; DS: String);
      procedure Write(Index: TAppSettingIndex; FormatName: String;
        DataType: TAppSettingDataType; I: Integer; B: Boolean; S: String);
    public
      constructor Create;
      destructor Destroy; override;
      function ReadInt(Index: TAppSettingIndex; FormatName: String=''; Default: Integer=0): Integer;
      function ReadIntDpiAware(Index: TAppSettingIndex; AControl: TControl; FormatName: String=''; Default: Integer=0): Integer;
      function ReadBool(Index: TAppSettingIndex; FormatName: String=''; Default: Boolean=False): Boolean;
      function ReadString(Index: TAppSettingIndex; FormatName: String=''; Default: String=''): String; overload;
      function ReadString(ValueName: String): String; overload;
      procedure WriteInt(Index: TAppSettingIndex; Value: Integer; FormatName: String='');
      procedure WriteIntDpiAware(Index: TAppSettingIndex; AControl: TControl; Value: Integer; FormatName: String='');
      procedure WriteBool(Index: TAppSettingIndex; Value: Boolean; FormatName: String='');
      procedure WriteString(Index: TAppSettingIndex; Value: String; FormatName: String=''); overload;
      procedure WriteString(ValueName, Value: String); overload;
      function GetDefaultInt(Index: TAppSettingIndex): Integer;
      function GetDefaultBool(Index: TAppSettingIndex): Boolean;
      function GetDefaultString(Index: TAppSettingIndex): String;
      function GetValueName(Index: TAppSettingIndex): String;
      function GetValueNames: TStringList;
      function GetKeyNames: TStringList;
      function GetSessionNames(ParentPath: String; var Folders: TStringList): TStringList;
      procedure GetSessionPaths(ParentPath: String; var Sessions: TStringList);
      function DeleteValue(Index: TAppSettingIndex; FormatName: String=''): Boolean; overload;
      function DeleteValue(ValueName: String): Boolean; overload;
      procedure DeleteCurrentKey;
      procedure MoveCurrentKey(TargetPath: String);
      function ValueExists(Index: TAppSettingIndex): Boolean;
      function SessionPathExists(SessionPath: String): Boolean;
      function IsEmptyKey: Boolean;
      procedure ResetPath;
      procedure StorePath;
      procedure RestorePath;
      property SessionPath: String read FSessionPath write SetSessionPath;
      property PortableMode: Boolean read FPortableMode;
      property PortableModeReadOnly: Boolean read FPortableModeReadOnly write FPortableModeReadOnly;
      property Writes: Integer read FWrites;
      procedure ImportSettings(Filename: String);
      function ExportSettings(Filename: String): Boolean; overload;
      function ExportSettings: Boolean; overload;
      // Common directories
      function DirnameUserAppData: String;
      function DirnameUserDocuments: String;
      function DirnameSnippets: String;
      function DirnameBackups: String;
      function DirnameHighlighters: String;
      // "Static" options, initialized in OnCreate only. For settings which need a restart to take effect.
      property RestoreTabsInitValue: Boolean read FRestoreTabsInitValue;
  end;

{$I const.inc}

  function Implode(Separator: String; a: TStrings): String;
  function Explode(Separator, Text: String) :TStringList;
  procedure ExplodeQuotedList(Text: String; var List: TStringList);
  function StrEllipsis(const S: String; MaxLen: Integer; FromLeft: Boolean=True): String;
  function isUnicode(str: String): Boolean;
  function encryptUnicode(str: String): String;
  function decryptUnicode(str: String): String;
  function encrypt(str: String): String;
  function decrypt(str: String): String;
  function HTMLSpecialChars(str: String): String;
  function EncodeURLParam(const Value: String): String;
  procedure StreamWrite(S: TStream; Text: String = '');
  function _GetFileSize(Filename: String): Int64;
  function DeleteFileWithUndo(sFileName: String): Boolean;
  function MakeInt(Str: String) : Int64;
  function MakeFloat(Str: String): Extended;
  function RoundCommercial(e: Extended): Int64;
  function CleanupNumber(Str: String): String;
  function IsInt(Str: String): Boolean;
  function IsFloat(Str: String): Boolean;
  function ScanLineBreaks(Text: String): TLineBreaks;
  function fixNewlines(txt: String): String;
  procedure StripNewLines(var txt: String; Replacement: String=' ');
  function GetLineBreak(LineBreakIndex: TLineBreaks): String;
  procedure RemoveNullChars(var Text: String; var HasNulls: Boolean);
  function GetShellFolder(FolderId: TGUID): String;
  function ValidFilename(Str: String): String;
  function FormatNumber( str: String; Thousands: Boolean=True): String; Overload;
  function UnformatNumber(Val: String): String;
  function FormatNumber( int: Int64; Thousands: Boolean=True): String; Overload;
  function FormatNumber( flt: Double; decimals: Integer = 0; Thousands: Boolean=True): String; Overload;
  procedure ShellExec(cmd: String; path: String=''; params: String=''; RunHidden: Boolean=False);
  function getFirstWord(text: String; MustStartWithWordChar: Boolean=True): String;
  function RegExprGetMatch(Expression: String; var Input: String; ReturnMatchNum: Integer; DeleteFromSource, CaseInsensitive: Boolean): String; Overload;
  function RegExprGetMatch(Expression: String; Input: String; ReturnMatchNum: Integer): String; Overload;
  function ExecRegExprI(const ARegExpr, AInputStr: RegExprString): Boolean;
  function FormatByteNumber( Bytes: Int64; Decimals: Byte = 1 ): String; Overload;
  function FormatByteNumber( Bytes: String; Decimals: Byte = 1 ): String; Overload;
  function FormatTimeNumber(Seconds: Double; DisplaySeconds: Boolean; MilliSecondsPrecision: Integer=1): String;
  function GetTempDir: String;
  procedure SaveUnicodeFile(Filename: String; Text: String; Encoding: TEncoding);
  procedure OpenTextFile(const Filename: String; out Stream: TFileStream; var Encoding: TEncoding);
  function DetectEncoding(Stream: TStream): TEncoding;
  function ReadTextfileChunk(Stream: TFileStream; Encoding: TEncoding; ChunkSize: Int64 = 0): String;
  function ReadTextfile(Filename: String; Encoding: TEncoding): String;
  function ReadBinaryFile(Filename: String; MaxBytes: Int64): AnsiString;
  procedure StreamToClipboard(Text, HTML: TStream);
  function WideHexToBin(text: String): AnsiString;
  function BinToWideHex(bin: AnsiString): String;
  procedure FixVT(VT: TVirtualStringTree; MultiLineCount: Word=1);
  function GetTextHeight(Font: TFont): Integer;
  function ColorAdjustBrightness(Col: TColor; Shift: SmallInt): TColor;
  procedure DeInitializeVTNodes(Sender: TBaseVirtualTree);
  function FindNode(VT: TVirtualStringTree; idx: Int64; ParentNode: PVirtualNode): PVirtualNode;
  function SelectNode(VT: TVirtualStringTree; idx: Int64; ParentNode: PVirtualNode=nil): Boolean; overload;
  function SelectNode(VT: TVirtualStringTree; Node: PVirtualNode; ClearSelection: Boolean=True): Boolean; overload;
  procedure GetVTSelection(VT: TVirtualStringTree; var SelectedCaptions: TStringList; var FocusedCaption: String);
  procedure SetVTSelection(VT: TVirtualStringTree; SelectedCaptions: TStringList; FocusedCaption: String);
  function GetNextNode(Tree: TVirtualStringTree; CurrentNode: PVirtualNode; Selected: Boolean=False): PVirtualNode;
  function GetPreviousNode(Tree: TVirtualStringTree; CurrentNode: PVirtualNode; Selected: Boolean=False): PVirtualNode;
  function DateBackFriendlyCaption(d: TDateTime): String;
  function DateTimeToStrDef(DateTime: TDateTime; Default: String): String;
  function TruncDef(X: Real; Default: Int64): Int64;
  function GetLightness(AColor: TColor): Byte;
  function ParamBlobToStr(lpData: Pointer): String;
  function ParamStrToBlob(out cbData: DWORD): Pointer;
  function CheckForSecondInstance: Boolean;
  function GetParentFormOrFrame(Comp: TWinControl): TWinControl;
  function KeyPressed(Code: Integer): Boolean;
  function GeneratePassword(Len: Integer): String;
  procedure InvalidateVT(VT: TVirtualStringTree; RefreshTag: Integer; ImmediateRepaint: Boolean);
  function CharAtPos(Str: String; Pos: Integer): Char;
  function CompareAnyNode(Text1, Text2: String): Integer;
  function StringListCompareAnythingAsc(List: TStringList; Index1, Index2: Integer): Integer;
  function StringListCompareAnythingDesc(List: TStringList; Index1, Index2: Integer): Integer;
  function StringListCompareByValue(List: TStringList; Index1, Index2: Integer): Integer;
  function StringListCompareByLength(List: TStringList; Index1, Index2: Integer): Integer;
  function GetImageLinkTimeStamp(const FileName: string): TDateTime;
  function IsEmpty(Str: String): Boolean;
  function IsNotEmpty(Str: String): Boolean;
  function MessageDialog(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer; overload;
  function MessageDialog(const Title, Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; KeepAskingSetting: TAppSettingIndex=asUnused; FooterText: String=''): Integer; overload;
  function ErrorDialog(Msg: string): Integer; overload;
  function ErrorDialog(const Title, Msg: string): Integer; overload;
  function GetLocaleString(const ResourceId: Integer): WideString;
  function GetHTMLCharsetByEncoding(Encoding: TEncoding): String;
  procedure ParseCommandLine(CommandLine: String; var ConnectionParams: TConnectionParameters; var FileNames: TStringList; var RunFrom: String);
  function f_(const Pattern: string; const Args: array of const): string;
  function GetOutputFilename(FilenameWithPlaceholders: String; DBObj: TDBObject): String;
  function GetOutputFilenamePlaceholders: TStringList;
  function GetSystemImageList: TImageList;
  function GetSystemImageIndex(Filename: String): Integer;
  function GetExecutableBits: Byte;
  procedure Help(Sender: TObject; Anchor: String);
  function PortOpen(Port: Word): Boolean;
  function IsValidFilePath(FilePath: String): Boolean;
  function FileIsWritable(FilePath: String): Boolean;
  function GetProductInfo(dwOSMajorVersion, dwOSMinorVersion, dwSpMajorVersion, dwSpMinorVersion: DWORD; out pdwReturnedProductType: DWORD): BOOL stdcall; external kernel32 delayed;
  function GetCurrentPackageFullName(out Len: Cardinal; Name: PWideChar): Integer; stdcall; external kernel32 delayed;
  function GetThemeColor(Color: TColor): TColor;
  function ThemeIsDark(ThemeName: String=''): Boolean;
  function ProcessExists(pid: Cardinal; ExeNamePattern: String): Boolean;
  procedure ToggleCheckBoxWithoutClick(chk: TCheckBox; State: Boolean);
  function SynCompletionProposalPrettyText(ImageIndex: Integer; LeftText, CenterText, RightText: String; LeftColor: TColor=-1; CenterColor: TColor=-1; RightColor: TColor=-1): String;
  function PopupComponent(Sender: TObject): TComponent;
  function IsWine: Boolean;
  function DirSep: Char;
  procedure FindComponentInstances(BaseForm: TComponent; ClassType: TClass; var List: TObjectList);
  function WebColorStrToColorDef(WebColor: string; Default: TColor): TColor;
  function UserAgent(OwnerComponent: TComponent): String;
  function CodeIndent(Steps: Integer=1): String;
  function EscapeHotkeyPrefix(Text: String): String;

var
  AppSettings: TAppSettings;
  MutexHandle: THandle = 0;
  SystemImageList: TImageList = nil;
  mtCriticalConfirmation: TMsgDlgType = mtCustom;
  ConfirmIcon: TIcon;
  NumberChars: TSysCharSet;
  LibHandleUser32: THandle;
  UTF8NoBOMEncoding: TUTF8NoBOMEncoding;
  DateTimeNever: TDateTime;
  IsWineStored: Integer = -1;

implementation

uses main, extra_controls;



function WideHexToBin(text: String): AnsiString;
var
  buf: AnsiString;
begin
  buf := AnsiString(text);
  SetLength(Result, Length(text) div 2);
  HexToBin(PAnsiChar(buf), @Result[1], Length(Result));
end;

function BinToWideHex(bin: AnsiString): String;
var
  buf: AnsiString;
begin
  SetLength(buf, Length(bin) * 2);
  BinToHex(@bin[1], PAnsiChar(buf), Length(bin));
  Result := String(buf);
end;


{***
  Convert a TStringList to a string using a separator-string

  @todo Look at each caller to see if escaping is necessary.
  @param string Separator
  @param a TStringList Containing strings
  @return string
}
function Implode(Separator: String; a: TStrings): String;
var
  i : Integer;
begin
  Result := '';
  for i:=0 to a.Count-1 do
  begin
    Result := Result + a[i];
    if i < a.Count-1 then
      Result := Result + Separator;
  end;
end;


function Explode(Separator, Text: String): TStringList;
var
  i: Integer;
  Item: String;
begin
  // Explode a string by separator into a TStringList
  Result := TStringList.Create;
  while true do begin
    i := Pos(Separator, Text);
    if i = 0 then begin
      // Last or only segment: Add to list if it's the last. Add also if it's not empty and list is empty.
      // Do not add if list is empty and text is also empty.
      if (Result.Count > 0) or (Text <> '') then
        Result.Add(Text);
      break;
    end;
    Item := Copy(Text, 1, i-1);
    Result.Add(Item);
    Delete(Text, 1, i-1+Length(Separator));
  end;
end;


{***
  Shorten string to length len and append 3 dots

  @param string String to shorten
  @param integer Wished Length of string
  @return string
}
function StrEllipsis(const S: String; MaxLen: Integer; FromLeft: Boolean=True): String;
begin
  Result := S;
  if Length(Result) <= MaxLen then
    Exit;
  if FromLeft then begin
    SetLength(Result, MaxLen);
    Result[MaxLen] := '.';
  end else begin
    Result := Copy(Result, Length(Result)-MaxLen, Length(Result));
    Result := '…' + Result;
  end;
end;



{***
  Check if string is Unicode

  @param string String to check
  @return boolean
}
function isUnicode(str: String): Boolean;
var i: integer;
begin
  result := false;
  for i := 1 to length(str) do begin
    result := ord(str[i]) > 255;
    if result then exit;
  end;
end;


{***
  Password-encryption, used to store session-passwords in registry
  Unicode (UTF-16) version, support up to 0xFFFF

  @param string Text to encrypt
  @return string Encrypted Text
}
function encryptUnicode(str: String): String;
var
  i, salt, nr: integer;
  h: String;
begin
  randomize();
  result := '';
  salt := random(9) + 1;
  for i := 1 to length(str) do begin
    nr := (ord(str[i]) + salt) mod 65536;
    h := IntToHex(nr, 4);  // 4 hex-symbols
    result := result + h;
  end;
  // Adding Unicode flag
  result := result + IntToStr(salt) + '0';
end;


{***
  Password-decryption, used to restore session-passwords from registry
  Unicode (UTF-16) version, support up to 0xFFFF

  @param string Text to decrypt
  @return string Decrypted Text
}
function decryptUnicode(str: String): String;
var
  j, salt, nr: integer;
begin
  result := '';
  if str = '' then exit;
  salt := StrToIntDef(str[length(str)], -1);

  // Salt is NAN
  if salt < 0 then exit;

  j := 1;
  while j < length(str) do begin
    nr := StrToInt('$' + copy(str, j, 4)) - salt;
    if nr < 0 then
      nr := nr + 65536;
    result := result + chr(nr);
    inc(j, 4);
  end;
end;


{***
  Password-encryption, used to store session-passwords in registry

  @param string Text to encrypt
  @return string Encrypted Text
}
function encrypt(str: String) : String;
var
  i, salt, nr : integer;
  h : String;
begin
  if isUnicode(str) then begin
    result := encryptUnicode(str);
    exit;
  end;

  randomize();
  result := '';
  salt := random(9) + 1;
  for i:=1 to length(str) do begin
    nr := ord(str[i])+salt;
    if nr > 255 then
      nr := nr - 255;
    h := inttohex(nr,0);
    if length(h) = 1 then
      h := '0' + h;
    result := result + h;
  end;
  result := result + inttostr(salt);
end;


{***
  Password-decryption, used to restore session-passwords from registry

  @param string Text to decrypt
  @return string Decrypted Text
}
function decrypt(str: String) : String;
var
  j, salt, nr : integer;
begin
  result := '';
  if str = '' then exit;
  salt := StrToIntDef(str[length(str)], -1);

  // Salt is NAN - error
  if salt < 0 then exit;

  // Salt is Unicode flag - Unicode logic
  if salt = 0 then begin
    // Removing Unicode flag
    result := decryptUnicode(copy(str, 1, length(str) - 1));
    exit;
  end;

  // Salt is... salt - ANSI logic
  j := 1;
  while j < length(str)-1 do begin
    nr := StrToInt('$' + str[j] + str[j+1]) - salt;
    if nr < 0 then
      nr := nr + 255;
    result := result + chr(nr);
    inc(j, 2);
  end;
end;


function HTMLSpecialChars(str: String) : String;
begin
  // Convert critical HTML-characters to entities. Used in grid export.
  result := StringReplace(str, '&', '&amp;', [rfReplaceAll]);
  result := StringReplace(result, '<', '&lt;', [rfReplaceAll]);
  result := StringReplace(result, '>', '&gt;', [rfReplaceAll]);
end;


function EncodeURLParam(const Value: String): String;
var
  c: Char;
const
  UnsafeChars: String = '*<>#%"{}|\^[]`?&+;';
begin
  // Encode critical chars in url parameter
  Result := '';
  for c in Value do begin
    if (Pos(c, UnsafeChars)>0) or (Ord(c) < 33) or (Ord(c) > 128) then
      Result := Result + '%'+IntToHex(Ord(c), 2)
    else
      Result := Result + c;
  end;
end;


{**
  Write some UTF8 text to a file- or memorystream
}
procedure StreamWrite(S: TStream; Text: String = '');
var
  utf8: AnsiString;
begin
  utf8 := Utf8Encode(Text);
  S.Write(utf8[1], Length(utf8));
end;


{***
  Return filesize of a given file
  Partly taken from https://www.delphipraxis.net/194137-getfilesize-welches-ist-die-bessere-funktion-2.html
  @param string Filename
  @return int64 Size in bytes
}
function _GetFileSize(Filename: String): Int64;
var
  Attr: TWin32FileAttributeData;
begin
  FillChar(Attr, SizeOf(Attr), 0);
  if GetFileAttributesEx(PChar(Filename), GetFileExInfoStandard, @Attr) then
  begin
    Result := Int64(Attr.nFileSizeHigh) shl 32 + Int64(Attr.nFileSizeLow);
  end
  else
    Result := -1;
end;


function DeleteFileWithUndo(sFileName: string): Boolean;
var
  fos: TSHFileOpStruct;
begin
  FillChar(fos, SizeOf(fos), 0);
  fos.wFunc := FO_DELETE;
  fos.pFrom := PChar(sFileName + #0);
  fos.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  Result := (0 = ShFileOperation(fos));
end;


{***
  Convert a string-number to an integer-number

  @param string String-number
  @return int64
}
function MakeInt(Str: String): Int64;
begin
  // Result has to be of integer type
  try
    Result := Trunc(MakeFloat(Str));
  except
    Result := 0;
  end;
end;


function CleanupNumber(Str: String): String;
var
  i: Integer;
  HasDecimalSep: Boolean;
begin
  // Ensure the passed string contains a valid number, which is convertable by StrToFloat afterwards
  // Return it as string again, as there are callers which need to handle unsigned bigint's somehow -
  // there is no unsigned 64 bit integer type in Delphi.
  Result := '';

  // Unformatted float coming in? Detect by order of thousand and decimal char
  if ((Pos(',', Str) > 0) and (Pos(',', Str) < Pos('.', Str)))
    or ((Pos('.', Str) > 0) and (Pos('.', ReverseString(Str)) <> 4))
    then begin
    Str := StringReplace(Str, '.', '*', [rfReplaceAll]);
    Str := StringReplace(Str, ',', FormatSettings.ThousandSeparator, [rfReplaceAll]);
    Str := StringReplace(Str, '*', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  end;

  HasDecimalSep := False;
  for i:=1 to Length(Str) do begin
    if CharInSet(Str[i], NumberChars) or ((Str[i] = '-') and (Result='')) then
    begin
      // Avoid confusion and AV in StrToFloat()
      if (FormatSettings.ThousandSeparator = FormatSettings.DecimalSeparator) and (Str[i] = FormatSettings.DecimalSeparator) then
        continue;
      // Ensure only 1 decimalseparator is left
      if (Str[i] = FormatSettings.DecimalSeparator) and HasDecimalSep then
        continue;
      if Str[i] = FormatSettings.DecimalSeparator then
        HasDecimalSep := True;
      if Str[i] = FormatSettings.ThousandSeparator then
        Continue;
      Result := Result + Str[i];
    end else
      Break;
  end;
  if (Result = '') or (Result = '-') then
    Result := '0';
end;


function IsInt(Str: String): Boolean;
begin
  Result := IntToStr(MakeInt(Str)) = Str;
end;


function IsFloat(Str: String): Boolean;
begin
  Result := FloatToStr(MakeFloat(Str)) = Str;
end;


{***
  Convert a string-number to an floatingpoint-number

  @param String text representation of a number
  @return Extended
}
function MakeFloat(Str: String): Extended;
var
  p_kb, p_mb, p_gb, p_tb, p_pb : Integer;
begin
  // Convert result to a floating point value to ensure
  // we don't discard decimal digits for the next step
  Result := StrToFloat(CleanupNumber(Str));

  // Detect if the string was previously formatted by FormatByteNumber
  // and convert it back by multiplying it with its byte unit
  p_kb := Pos(NAME_KB, Str);
  p_mb := Pos(NAME_MB, Str);
  p_gb := Pos(NAME_GB, Str);
  p_tb := Pos(NAME_TB, Str);
  p_pb := Pos(NAME_PB, Str);

  if (p_kb > 0) and (p_kb = Length(Str)-Length(NAME_KB)+1) then
    Result := Result * SIZE_KB
  else if (p_mb > 0) and (p_mb = Length(Str)-Length(NAME_MB)+1) then
    Result := Result * SIZE_MB
  else if (p_gb > 0) and (p_gb = Length(Str)-Length(NAME_GB)+1) then
    Result := Result * SIZE_GB
  else if (p_tb > 0) and (p_tb = Length(Str)-Length(NAME_TB)+1) then
    Result := Result * SIZE_TB
  else if (p_pb > 0) and (p_pb = Length(Str)-Length(NAME_PB)+1) then
    Result := Result * SIZE_PB;
end;


function RoundCommercial(e: Extended): Int64;
begin
  // "Kaufmännisch runden"
  // In contrast to Delphi's Round() which rounds *.5 to the next even number
  Result := Trunc(e);
  if Frac(e) >= 0.5 then
    Result := Result + 1;
end;


{***
  SynEdit removes all newlines and semi-randomly decides a
  new newline format to use for any text edited.
  See also: Delphi's incomplete implementation of TTextLineBreakStyle in System.pas

  @param string Text to test
  @return TLineBreaks
}
function ScanLineBreaks(Text: String): TLineBreaks;
var
  i, SeekSize: Integer;
  c: Char;
  procedure SetResult(Style: TLineBreaks);
  begin
    // Note: Prefer "(foo <> a) and (foo <> b)" over "not (foo in [a, b])" in excessive loops
    // for performance reasons - there is or was a Delphi bug leaving those inline SETs in memory
    // after usage. Unfortunately can't remember which bug id it was and if it still exists.
    if (Result <> lbsNone) and (Result <> Style) then
      Result := lbsMixed
    else
      Result := Style;
  end;
begin
  Result := lbsNone;
  SeekSize := Min(Length(Text), SIZE_MB);
  if SeekSize = 0 then
    Exit;
  i := 1;
  repeat
    c := Text[i];
    if c = #13 then begin
      if (i < SeekSize) and (Text[i+1] = #10) then begin
        Inc(i);
        SetResult(lbsWindows);
      end else
        SetResult(lbsMac);
    end else if c = LB_UNIX then
      SetResult(lbsUnix)
    else if c = LB_WIDE then
      SetResult(lbsWide);
    i := i + 1;
    // No need to do more checks after detecting mixed style
    if Result = lbsMixed then
      break;
  until i > SeekSize;
end;


{***
  Unify CR's and LF's to CRLF

  @param string Text to fix
  @return string
}
function fixNewlines(txt: String): String;
begin
  txt := StringReplace(txt, CRLF, #10, [rfReplaceAll]);
  txt := StringReplace(txt, #13, #10, [rfReplaceAll]);
  txt := StringReplace(txt, #10, CRLF, [rfReplaceAll]);
  result := txt;
end;

procedure StripNewLines(var txt: String; Replacement: String=' ');
begin
  txt := StringReplace(txt, #13#10, Replacement, [rfReplaceAll]);
  txt := StringReplace(txt, #13, Replacement, [rfReplaceAll]);
  txt := StringReplace(txt, #10, Replacement, [rfReplaceAll]);
end;

function GetLineBreak(LineBreakIndex: TLineBreaks): String;
begin
  case LineBreakIndex of
    lbsUnix: Result := LB_UNIX;
    lbsMac: Result := LB_MAC;
    else Result := CRLF;
  end;
end;


{***
  Mangle input text so that SynEdit can load it.
}
procedure RemoveNullChars(var Text: String; var HasNulls: Boolean);
var
  i, Len: Integer;
begin
  HasNulls := False;
  Len := Length(Text);
  for i:=1 to Len do begin
    if Text[i] = #0 then begin
      Text[i] := #32; // space
      HasNulls := True;
    end;
  end;
end;


{***
  Get the path of a Windows(r)-shellfolder, specified by a KNOWNFOLDERID constant
  @see https://docs.microsoft.com/en-us/windows/win32/shell/knownfolderid
  @param TGUID constant
  @return string Path
}
function GetShellFolder(FolderId: TGUID): String;
var
  Path: PWideChar;
begin
  if Succeeded(SHGetKnownFolderPath(FolderId, 0, 0, Path)) then begin
    Result := Path;
  end else begin
    Result := EmptyStr;
  end;
end;



{***
  Remove special characters from a filename

  @param string Filename
  @return string
}
function ValidFilename(Str: String): String;
var
  c: Char;
begin
  Result := Str;
  for c in TPath.GetInvalidFileNameChars do begin
    Result := StringReplace(Result, c, '_', [rfReplaceAll]);
  end;
end;


{**
  Unformat a formatted integer or float. Used for CSV export and composing WHERE clauses for grid editing.
}
function UnformatNumber(Val: String): String;
var
  i: Integer;
  HasDecim: Boolean;
  c: Char;
const
  Numbers = ['0'..'9'];
begin
  Result := '';
  HasDecim := False;
  for i:=1 to Length(Val) do begin
    c := Val[i];
    if (c = '-') and (i = 1) then
      Result := Result + c
    else if CharInSet(c, Numbers) then begin
      if (c = '0') and (Result = '') then
        // remove zeropadding
      else
        Result := Result + c
    end else if (c = FormatSettings.DecimalSeparator) and (not HasDecim) then begin
      if Result = '' then
        Result := '0';
      Result := Result + '.';
      HasDecim := True;
    end else if c <> FormatSettings.ThousandSeparator then
      break;
  end;
  if Result = '' then
    Result := '0';
end;


{***
  Return a formatted integer or float from a string
  @param string Text containing a number
  @return string
}
function FormatNumber(str: String; Thousands: Boolean=True): String; Overload;
var
  i, p, Left: Integer;
begin
  Result := StringReplace(str, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  if Thousands then begin
    // Do not add thousand separators to zerofilled numbers
    if ((Length(Result) >= 1) and (Result[1] = '0'))
      or ((Length(Result) >= 2) and (Result[1] = '-') and (Result[2] = '0'))
    then
      Exit;
    p := Pos(FormatSettings.DecimalSeparator, Result);
    if p = 0 then p := Length(Result)+1;
    Left := 2;
    if (Length(Result) >= 1) and (Result[1] = '-') then
      Left := 3;
    if p > 0 then for i:=p-1 downto Left do begin
      if (p-i) mod 3 = 0 then
        Insert(FormatSettings.ThousandSeparator, Result, i);
    end;
  end;
end;



{***
  Return a formatted number from an integer

  @param int64 Number to format
  @return string
}
function FormatNumber(int: Int64; Thousands: Boolean=True): String; Overload;
begin
  result := FormatNumber(IntToStr(int), Thousands);
end;



{***
  Return a formatted number from a float
  This function is called by two overloaded functions

  @param double Number to format
  @param integer Number of decimals
  @return string
}
function FormatNumber(flt: Double; decimals: Integer = 0; Thousands: Boolean=True): String; Overload;
begin
  Result := Format('%10.'+IntToStr(decimals)+'f', [flt]);
  Result := Trim(Result);
  Result := FormatNumber(Result, Thousands);
end;


{***
  Open URL or execute system command

  @param string Command or URL to execute
  @param string Working directory, only usefull is first param is a system command
}
procedure ShellExec(cmd: String; path: String=''; params: String=''; RunHidden: Boolean=False);
var
  Msg: String;
  ShowCmd: Integer;
begin
  ShowCmd := IfThen(RunHidden, SW_HIDE, SW_SHOWNORMAL);
  Msg := 'Executing shell command: "'+cmd+'"';
  if not path.IsEmpty then
    Msg := Msg + ' path: "'+path+'"';
  if not params.IsEmpty then
    Msg := Msg + ' params: "'+params+'"';
  MainForm.LogSQL(Msg, lcDebug);
  ShellExecute(0, 'open', PChar(cmd), PChar(params), PChar(path), ShowCmd);
end;



{***
  Returns first word of a given text
  @param string Given text
  @return string First word-boundary
}
function getFirstWord(text: String; MustStartWithWordChar: Boolean=True): String;
var
  i : Integer;
  wordChars, wordCharsFirst : TSysCharSet;
begin
  result := '';
  text := trim( text );
  // First char in word must not be numerical. Fixes queries like
  // /*!40000 SHOW ENGINES */ to be recognized as "result"-queries
  // while not breaking getFirstWord in situations where the second
  // or later char can be a number (fx the collation in createdatabase).
  wordChars := ['a'..'z', 'A'..'Z', '0'..'9', '_', '-'];
  if MustStartWithWordChar then
    wordCharsFirst := wordChars - ['0'..'9']
  else
    wordCharsFirst := wordChars;
  i := 1;

  // Find beginning of the first word, ignoring non-alphanumeric chars at the very start
  // @see bug #1692828
  while i < Length(text) do
  begin
    if CharInSet(text[i], wordCharsFirst) then
    begin
      // Found beginning of word!
      break;
    end;
    if i = Length(text)-1 then
    begin
      // Give up in the very last loop, reset counter
      // and break. We can't find the start of a word
      i := 1;
      break;
    end;
    inc(i);
  end;

  // Add chars as long as they're alpha-numeric
  while i <= Length(text) do
  begin
    if ((result = '') and CharInSet(text[i], wordCharsFirst)) or CharInSet(text[i], wordChars) then
    begin
      result := result + text[i];
    end
    else
    begin
      // Stop here because we found a non-alphanumeric char.
      // This applies to all different whitespaces, brackets, commas etc.
      break;
    end;
    inc(i);
  end;
end;


function RegExprGetMatch(Expression: String; var Input: String; ReturnMatchNum: Integer; DeleteFromSource, CaseInsensitive: Boolean): String;
var
  rx: TRegExpr;
begin
  Result := '';
  rx := TRegExpr.Create;
  rx.ModifierI := CaseInsensitive;
  rx.Expression := Expression;
  if rx.Exec(Input) then begin
    if rx.SubExprMatchCount >= ReturnMatchNum then begin
      Result := rx.Match[ReturnMatchNum];
      if DeleteFromSource then begin
        Delete(Input, rx.MatchPos[ReturnMatchNum], rx.MatchLen[ReturnMatchNum]);
        Input := Trim(Input);
      end;
    end;
  end;
  rx.Free;
end;


function RegExprGetMatch(Expression: String; Input: String; ReturnMatchNum: Integer): String;
begin
  // Version without possibility to delete captured match from input
  Result := RegExprGetMatch(Expression, Input, ReturnMatchNum, False, False);
end;


function ExecRegExprI(const ARegExpr, AInputStr: RegExprString): Boolean;
var
  r: TRegExpr;
begin
  Result := False;
  r := TRegExpr.Create;
  r.ModifierI := True;
  try
    r.Expression := ARegExpr;
    Result := r.Exec(AInputStr);
  finally
    r.Free;
  end;
end;


{**
  Format a filesize to automatically use the best fitting expression
  16 100 000 Bytes -> 16,1 MB
  4 500 Bytes -> 4,5 KB
  @param Int64 Number of Bytes
  @param Byte Decimals to display when bytes is bigger than 1M
}
function FormatByteNumber( Bytes: Int64; Decimals: Byte = 1 ): String; Overload;
begin
  if Bytes >= FSIZE_PB then
    Result := FormatNumber( Bytes / SIZE_PB, Decimals ) + NAME_PB
  else if Bytes >= FSIZE_TB then
    Result := FormatNumber( Bytes / SIZE_TB, Decimals ) + NAME_TB
  else if Bytes >= FSIZE_GB then
    Result := FormatNumber( Bytes / SIZE_GB, Decimals ) + NAME_GB
  else if Bytes >= FSIZE_MB then
    Result := FormatNumber( Bytes / SIZE_MB, Decimals ) + NAME_MB
  else if Bytes >= FSIZE_KB then
    Result := FormatNumber( Bytes / SIZE_KB, Decimals ) + NAME_KB
  else
    Result := FormatNumber( Bytes ) + NAME_BYTES
end;


{**
  An overloaded function of the previous one which can
  take a string as input
}
function FormatByteNumber( Bytes: String; Decimals: Byte = 1 ): String; Overload;
begin
  Result := FormatByteNumber( MakeInt(Bytes), Decimals );
end;


{**
  Format a number of seconds to a human readable time format
  @param Cardinal Number of seconds
  @result String 12:34:56.7
}
function FormatTimeNumber(Seconds: Double; DisplaySeconds: Boolean; MilliSecondsPrecision: Integer=1): String;
var
  d, h, m, s, ms: Integer;
  msStr: String;
begin
  s := TruncDef(Seconds, 0);
  ms := TruncDef((Seconds - s) * Power(10, MilliSecondsPrecision), 0); // Milliseconds, with variable precision/digits
  msStr := IntToStr(ms).PadLeft(MilliSecondsPrecision, '0');
  d := s div (60*60*24);
  s := s mod (60*60*24);
  h := s div (60*60);
  s := s mod (60*60);
  m := s div 60;
  s := s mod 60;
  if d > 0 then begin
    if DisplaySeconds then begin
      Result := Format('%d '+_('days')+', %.2d:%.2d:%.2d', [d, h, m, s]);
      Result := Result + '.' + msStr; // Append milliseconds
    end
    else begin
      Result := Format('%d '+_('days')+', %.2d:%.2d h', [d, h, m]);
    end;
  end else begin
    if DisplaySeconds then begin
      Result := Format('%.2d:%.2d:%.2d', [h, m, s]);
      Result := Result + '.' + msStr; // Append milliseconds
    end
    else begin
      Result := Format('%.2d:%.2d h', [h, m]);
    end;
  end;
end;


function GetTempDir: String;
var
  TempPath: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, PChar(@TempPath));
  Result := StrPas(TempPath);
end;


{**
  Save a textfile with unicode
}
procedure SaveUnicodeFile(Filename: String; Text: String; Encoding: TEncoding);
var
  Writer: TStreamWriter;
begin
  // Encoding may be nil when previously loaded via auto-detection
  if not Assigned(Encoding) then
    Encoding := UTF8NoBOMEncoding;
  Writer := TStreamWriter.Create(Filename, False, Encoding);
  Writer.Write(Text);
  Writer.Free;
end;


procedure OpenTextFile(const Filename: String; out Stream: TFileStream; var Encoding: TEncoding);
var
  Header: TBytes;
  BomLen: Integer;
begin
  // Open a textfile and return a stream. Detect its encoding if not passed by the caller
  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  if Encoding = nil then
    Encoding := DetectEncoding(Stream);
  // If the file contains a BOM, advance the stream's position
  BomLen := 0;
  if Length(Encoding.GetPreamble) > 0 then begin
    SetLength(Header, Length(Encoding.GetPreamble));
    Stream.ReadBuffer(Pointer(Header)^, Length(Header));
    if CompareMem(Header, Encoding.GetPreamble, SizeOf(Header)) then
      BomLen := Length(Encoding.GetPreamble);
  end;
  Stream.Position := BomLen;
end;


{**
  Detect stream's content encoding through SynEdit's GetEncoding. Result can be:
    UTF-16 BE with BOM
    UTF-16 LE with BOM
    UTF-8 with or without BOM
    ANSI
  Aimed to work better than WideStrUtils.IsUTF8String() which didn't work in any test case here.
  @see http://en.wikipedia.org/wiki/Byte_Order_Mark
  Could also do that with TEncoding.GetBufferEncoding, but that relies on the file having a BOM
}
function DetectEncoding(Stream: TStream): TEncoding;
var
  SynEnc: TSynEncoding;
  WithBOM: Boolean;
begin
  SynEnc := SynUnicode.GetEncoding(Stream, WithBOM);
  case SynEnc of
    seUTF8: begin
      if WithBOM then
        Result := TEncoding.UTF8
      else
        Result := UTF8NoBOMEncoding;
    end;
    seUTF16LE: Result := TEncoding.Unicode;
    seUTF16BE: Result := TEncoding.BigEndianUnicode;
    seAnsi: Result := TEncoding.ANSI;
    else Result := UTF8NoBOMEncoding;
  end;
end;


function ReadTextfileChunk(Stream: TFileStream; Encoding: TEncoding; ChunkSize: Int64 = 0): String;
const
  BufferPadding = 1;
var
  DataLeft, StartPosition: Int64;
  LBuffer: TBytes;
  i: Integer;
begin
  // Read a chunk or the complete contents out of a textfile, opened by OpenTextFile()
  if Stream.Size = 0 then begin
    Result := '';
    Exit;
  end;

  StartPosition := Stream.Position;
  DataLeft := Stream.Size - Stream.Position;
  if (ChunkSize = 0) or (ChunkSize > DataLeft) then
    ChunkSize := DataLeft;

  i := 0;
  while True do begin
    Inc(i);
    try
      SetLength(LBuffer, ChunkSize);
      Stream.ReadBuffer(Pointer(LBuffer)^, ChunkSize);
      LBuffer := Encoding.Convert(Encoding, TEncoding.Unicode, LBuffer);
      // Success, exit loop
      Break;
    except
      on E:EEncodingError do begin
        if i=10 then // Give up
          Raise;
        Stream.Position := StartPosition;
        Inc(ChunkSize, BufferPadding);
      end;
    end;
  end;

  Result := TEncoding.Unicode.GetString(LBuffer);
end;


function ReadTextfile(Filename: String; Encoding: TEncoding): String;
var
  Stream: TFileStream;
begin
  // Read a text file into memory
  OpenTextfile(Filename, Stream, Encoding);
  Result := ReadTextfileChunk(Stream, Encoding);
  Stream.Free;
end;


function ReadBinaryFile(Filename: String; MaxBytes: Int64): AnsiString;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  Stream.Position := 0;
  if (MaxBytes < 1) or (MaxBytes > Stream.Size) then MaxBytes := Stream.Size;
  SetLength(Result, MaxBytes);
  Stream.Read(PAnsiChar(Result)^, Length(Result));
  Stream.Free;
end;


procedure StreamToClipboard(Text, HTML: TStream);
var
  TextContent, HTMLContent, HTMLHeader, NullPos: AnsiString;
  GlobalMem: HGLOBAL;
  lp: PChar;
  ClpLen: Integer;
  CF_HTML: Word;
  StartHTML, EndHTML, StartFragment, EndFragment: Integer;
const
  PosFormat: AnsiString = '%.10d';

  procedure ReplacePos(Name: AnsiString; Value: Integer);
  var NewPos: AnsiString;
  begin
    NewPos := Format(PosFormat, [Value]);
    HTMLContent := StringReplace(HTMLContent, Name+':'+NullPos, Name+':'+NewPos, []);
  end;
begin
  // Copy unicode text to clipboard
  if Assigned(Text) then begin
    SetLength(TextContent, Text.Size);
    Text.Position := 0;
    Text.Read(PAnsiChar(TextContent)^, Text.Size);
    Clipboard.TryAsText := Utf8ToString(TextContent);
    SetString(TextContent, nil, 0);
  end;

  if Assigned(HTML) then begin
    // If wanted, add a HTML portion, so formatted text can be pasted in WYSIWYG
    // editors (mostly MS applications).
    // Note that the content is UTF8 encoded ANSI. Using unicode variables results in raw
    // text pasted in editors. TODO: Find out why and optimize redundant code away by a loop.
    OpenClipBoard(0);
    CF_HTML := RegisterClipboardFormat('HTML Format');
    SetLength(HTMLContent, HTML.Size);
    HTML.Position := 0;
    HTML.Read(PAnsiChar(HTMLContent)^, HTML.Size);
    if Pos(AnsiString('Version:'), HTMLContent) = 0 then begin
      // Only required if header was not already prepended by SynEdit, e.g. in grid export of SQL Inserts
      NullPos := Format(PosFormat, [0]);
      HTMLHeader := 'Version:0.9' + sLineBreak +
        'StartHTML:' + NullPos + sLineBreak +
        'EndHTML:' + NullPos + sLineBreak +
        'StartFragment:' + NullPos + sLineBreak +
        'EndFragment:' + NullPos + sLineBreak;
      StartHTML := Length(HTMLHeader);
      HTMLContent := HTMLHeader + HTMLContent;
      EndHTML := Length(HTMLContent);
      StartFragment := Pos(AnsiString('<body>'), HTMLContent) + 6;
      EndFragment := Pos(AnsiString('</body'), HTMLContent)-1;
      ReplacePos('StartHTML', StartHTML);
      ReplacePos('EndHTML', EndHTML);
      ReplacePos('StartFragment', StartFragment);
      ReplacePos('EndFragment', EndFragment);
    end;
    ClpLen := Length(HTMLContent) + 1;
    GlobalMem := GlobalAlloc(GMEM_DDESHARE + GMEM_MOVEABLE, ClpLen);
    lp := GlobalLock(GlobalMem);
    Move(PAnsiChar(HTMLContent)^, lp[0], ClpLen);
    SetString(HTMLContent, nil, 0);
    GlobalUnlock(GlobalMem);
    SetClipboardData(CF_HTML, GlobalMem);
    CloseClipboard;
  end;
end;


procedure FixVT(VT: TVirtualStringTree; MultiLineCount: Word=1);
var
  SingleLineHeight: Integer;
  Node: PVirtualNode;
begin
  // This is called either in some early stage, or from preferences dialog
  VT.BeginUpdate;
  SingleLineHeight := GetTextHeight(VT.Font) + 7;
  // Multiline nodes?
  VT.DefaultNodeHeight := SingleLineHeight * MultiLineCount;
  VT.Header.Height := SingleLineHeight;
  // Apply new height to multi line grid nodes
  Node := VT.GetFirstInitialized;
  while Assigned(Node) do begin
    VT.NodeHeight[Node] := VT.DefaultNodeHeight;
    // Nodes have vsMultiLine through InitNode event
    VT.MultiLine[Node] := MultiLineCount > 1;
    Node := VT.GetNextInitialized(Node);
  end;
  VT.EndUpdate;
  // Disable hottracking in non-Vista mode, looks ugly in XP, but nice in Vista
  if (toUseExplorerTheme in VT.TreeOptions.PaintOptions) and (Win32MajorVersion >= 6) then
    VT.TreeOptions.PaintOptions := VT.TreeOptions.PaintOptions + [toHotTrack]
  else
    VT.TreeOptions.PaintOptions := VT.TreeOptions.PaintOptions - [toHotTrack];
  VT.OnGetHint := MainForm.AnyGridGetHint;
  VT.OnScroll := MainForm.AnyGridScroll;
  VT.OnMouseWheel := MainForm.AnyGridMouseWheel;
  VT.ShowHint := True;

  if toGridExtensions in VT.TreeOptions.MiscOptions then
    VT.HintMode := hmHint // Show cell contents with linebreakds in datagrid and querygrid's
  else
    VT.HintMode := hmTooltip; // Just a quick tooltip for clipped nodes
  // Apply case insensitive incremental search event
  if VT.IncrementalSearch <> VirtualTrees.Types.isNone then
    VT.OnIncrementalSearch := Mainform.AnyGridIncrementalSearch;
  VT.OnStartOperation := Mainform.AnyGridStartOperation;
  VT.OnEndOperation := Mainform.AnyGridEndOperation;
end;


function GetTextHeight(Font: TFont): Integer;
var
  DC: HDC;
  SaveFont: HFont;
  SysMetrics, Metrics: TTextMetric;
begin
  // Code taken from StdCtrls.TCustomEdit.AdjustHeight
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  Result := Metrics.tmHeight;
end;


function ColorAdjustBrightness(Col: TColor; Shift: SmallInt): TColor;
var
  Lightness: Byte;
begin
  // If base color is bright, make bg color darker (grey), and vice versa, so that
  // colors work with high contrast mode for accessibility
  Lightness := GetLightness(Col);
  if (Lightness < 128) and (Shift < 0) then
    Shift := Abs(Shift)
  else if (Lightness > 128) and (Shift > 0) then
    Shift := 0 - Abs(Shift);
  Result := ColorAdjustLuma(Col, Shift, true);
end;


procedure DeInitializeVTNodes(Sender: TBaseVirtualTree);
var
  Node: PVirtualNode;
begin
  // Forces a VirtualTree to (re-)initialize its nodes.
  // I wonder why this is not implemented in VirtualTree.
  Node := Sender.GetFirstInitialized;
  while Assigned(Node) do begin
    Node.States := Node.States - [vsInitialized];
    Node := Sender.GetNextInitialized(Node);
  end;
end;


function FindNode(VT: TVirtualStringTree; idx: Int64; ParentNode: PVirtualNode): PVirtualNode;
var
  Node: PVirtualNode;
begin
  // Helper to find a node by its index
  Result := nil;
  Node := nil;
  try
    if Assigned(ParentNode) then
      Node := VT.GetFirstChild(ParentNode)
    else
      Node := VT.GetFirst;
  except
    // Sporadically, TBaseVirtualTree.GetFirst throws an exception when reading FRoot.FirstChild
    // Tab restoring is sometimes crashing for that reason.
  end;
  while Assigned(Node) do begin
    // Note: Grid.RootNodeCount is unfortunately Cardinal, not UInt64.
    if Node.Index = idx then begin
      Result := Node;
      break;
    end;
    Node := VT.GetNextSibling(Node);
  end;
end;


function SelectNode(VT: TVirtualStringTree; idx: Int64; ParentNode: PVirtualNode=nil): Boolean; overload;
var
  Node: PVirtualNode;
begin
  // Helper to focus and highlight a node by its index
  Node := FindNode(VT, idx, ParentNode);
  if Assigned(Node) then
    Result := SelectNode(VT, Node)
  else
    Result := False;
end;


function SelectNode(VT: TVirtualStringTree; Node: PVirtualNode; ClearSelection: Boolean=True): Boolean; overload;
var
  OldFocus: PVirtualNode;
  MinimumColumnIndex: TColumnIndex;
begin
  if Node = VT.RootNode then
    Node := nil;
  OldFocus := VT.FocusedNode;
  Result := True;
  if (Node <> OldFocus) and Assigned(VT.OnFocusChanging) then begin
    VT.OnFocusChanging(VT, OldFocus, Node, VT.FocusedColumn, VT.FocusedColumn, Result);
  end;
  if Result then begin
    if ClearSelection then
      VT.ClearSelection;
    VT.FocusedNode := Node;
    MinimumColumnIndex := VT.Header.Columns.GetFirstVisibleColumn(True);
    if VT.FocusedColumn < MinimumColumnIndex then
      VT.FocusedColumn := MinimumColumnIndex;
    VT.Selected[Node] := True;
    VT.ScrollIntoView(Node, False);
    if (OldFocus = Node) and Assigned(VT.OnFocusChanged) then
      VT.OnFocusChanged(VT, Node, VT.FocusedColumn);
  end;
end;


procedure GetVTSelection(VT: TVirtualStringTree; var SelectedCaptions: TStringList; var FocusedCaption: String);
var
  Node: PVirtualNode;
  InvalidationTag: Integer;
begin
  // Return captions of selected nodes
  InvalidationTag := vt.Tag;
  vt.Tag := VTREE_LOADED;
  SelectedCaptions.Clear;
  Node := GetNextNode(VT, nil, true);
  while Assigned(Node) do begin
    SelectedCaptions.Add(VT.Text[Node, VT.Header.MainColumn]);
    if Node = VT.FocusedNode then begin
      FocusedCaption := VT.Text[Node, VT.Header.MainColumn];
    end;
    Node := GetNextNode(VT, Node, true);
  end;
  vt.Tag := InvalidationTag;
end;


procedure SetVTSelection(VT: TVirtualStringTree; SelectedCaptions: TStringList; FocusedCaption: String);
var
  Node: PVirtualNode;
  idx: Integer;
  DoFocusChange: Boolean;
begin
  // Restore selected nodes based on captions list
  DoFocusChange := False;
  Node := GetNextNode(VT, nil, false);
  while Assigned(Node) do begin
    idx := SelectedCaptions.IndexOf(VT.Text[Node, VT.Header.MainColumn]);
    if idx > -1 then
      VT.Selected[Node] := True;
    if (not FocusedCaption.IsEmpty) and (VT.Text[Node, VT.Header.MainColumn] = FocusedCaption) then begin
      VT.FocusedNode := Node;
      DoFocusChange := True;
    end;
    Node := GetNextNode(VT, Node, false);
  end;
  // Fire focus change event if there was a focused one before
  if DoFocusChange and Assigned(VT.OnFocusChanged) then begin
    VT.OnFocusChanged(VT, VT.FocusedNode, VT.FocusedColumn);
  end;
end;


function GetNextNode(Tree: TVirtualStringTree; CurrentNode: PVirtualNode; Selected: Boolean=False): PVirtualNode;
begin
  // Get next visible + selected node. Not possible with VTree's own functions.
  Result := CurrentNode;
  while True do begin
    if Selected then begin
      if not Assigned(Result) then
        Result := Tree.GetFirstSelected
      else
        Result := Tree.GetNextSelected(Result);
    end else begin
      if not Assigned(Result) then
        Result := Tree.GetFirst
      else
        Result := Tree.GetNext(Result);
    end;
    if (not Assigned(Result)) or Tree.IsVisible[Result] then
      break;
  end;
end;


function GetPreviousNode(Tree: TVirtualStringTree; CurrentNode: PVirtualNode; Selected: Boolean=False): PVirtualNode;
begin
  // Get previous visible + selected node.
  Result := CurrentNode;
  while True do begin
    if Selected then begin
      if not Assigned(Result) then begin
        Result := Tree.GetLast;
        if not Tree.Selected[Result] then
          Result := Tree.GetPreviousSelected(Result);
      end else
        Result := Tree.GetPreviousSelected(Result);
    end else begin
      if not Assigned(Result) then
        Result := Tree.GetLast
      else
        Result := Tree.GetPrevious(Result);
    end;
    if (not Assigned(Result)) or Tree.IsVisible[Result] then
      break;
  end;
end;


function DateBackFriendlyCaption(d: TDateTime): String;
var
  MonthsAgo, DaysAgo, HoursAgo, MinutesAgo: Int64;
begin
  MonthsAgo := MonthsBetween(Now, d);
  DaysAgo := DaysBetween(Now, d);
  HoursAgo := HoursBetween(Now, d);
  MinutesAgo := MinutesBetween(Now, d);
  if MonthsAgo = 1 then Result := f_('%s month ago', [FormatNumber(MonthsAgo)])
  else if MonthsAgo > 1 then Result := f_('%s months ago', [FormatNumber(MonthsAgo)])
  else if DaysAgo = 1 then Result := f_('%s day ago', [FormatNumber(DaysAgo)])
  else if DaysAgo > 1 then Result := f_('%s days ago', [FormatNumber(DaysAgo)])
  else if HoursAgo = 1 then Result := f_('%s hour ago', [FormatNumber(HoursAgo)])
  else if HoursAgo > 1 then Result := f_('%s hours ago', [FormatNumber(HoursAgo)])
  else if MinutesAgo = 1 then Result := f_('%s minute ago', [FormatNumber(MinutesAgo)])
  else if MinutesAgo > 0 then Result := f_('%s minutes ago', [FormatNumber(MinutesAgo)])
  else Result := _('less than a minute ago');
end;


function DateTimeToStrDef(DateTime: TDateTime; Default: String) : String;
begin
  try
    if DateTime = 0 then
      Result := Default
    else
      Result := DateTimeToStr(DateTime);
  except
    on EInvalidOp do Result := Default;
  end;
end;


function TruncDef(X: Real; Default: Int64): Int64;
begin
  try
    Result := Trunc(X);
  except
    on EInvalidOp do Result := Default;
  end;
end;


procedure ExplodeQuotedList(Text: String; var List: TStringList);
var
  i: Integer;
  Quote: Char;
  Opened, Closed: Boolean;
  Item: String;
begin
  Text := Trim(Text);
  if Length(Text) > 0 then
    Quote := Text[1]
  else
    Quote := '`';
  Opened := False;
  Closed := True;
  Item := '';
  for i:=1 to Length(Text) do begin
    if Text[i] = Quote then begin
      Opened := not Opened;
      Closed := not Closed;
      if Closed then begin
        List.Add(Item);
        Item := '';
      end;
      Continue;
    end;
    if Opened and (not Closed) then
      Item := Item + Text[i];
  end;
end;


function GetLightness(AColor: TColor): Byte;
var
  R, G, B: Byte;
  MaxValue, MinValue: Double;
  Lightness: Double;
begin
  R := GetRValue(ColorToRGB(AColor));
  G := GetGValue(ColorToRGB(AColor));
  B := GetBValue(ColorToRGB(AColor));
  MaxValue := Max(Max(R,G),B);
  MinValue := Min(Min(R,G),B);
  Lightness := (((MaxValue + MinValue) * 240) + 255 ) / 510;
  Result := Round(Lightness);
end;



{ *** TSortItem }

procedure TSortItem.Assign(Source: TPersistent);
var
  SourceItem: TSortItem;
begin
  if Source is TSortItem then begin
    SourceItem := Source as TSortItem;
    Column := SourceItem.Column;
    Order := SourceItem.Order;
  end
  else
    Inherited;
end;


{ *** TSortItems }

function TSortItems.AddNew(Column: String=''; Order: TSortItemOrder=sioAscending): TSortItem;
begin
  Result := TSortItem.Create;
  Result.Column := Column;
  Result.Order := Order;
  Add(Result);
end;


function TSortItems.ComposeOrderClause(Connection: TDBConnection): String;
var
  SortItem: TSortItem;
  SortOrder: String;
begin
  // Concat all sort options to an ORDER BY clause
  Result := '';
  for SortItem in Self do begin
    if Result <> '' then
      Result := Result + ', ';
    if SortItem.Order = sioAscending then
      SortOrder := Connection.GetSQLSpecifity(spOrderAsc)
    else
      SortOrder := Connection.GetSQLSpecifity(spOrderDesc);
    Result := Result + Connection.QuoteIdent(SortItem.Column) + ' ' + SortOrder;
  end;
end;


function TSortItems.FindByColumn(Column: String): TSortItem;
var
  SortItem: TSortItem;
begin
  Result := nil;
  for SortItem in Self do begin
    if SortItem.Column = Column then begin
      Result := SortItem;
      Break;
    end;
  end;
end;


procedure TSortItems.Assign(Source: TSortItems);
var
  Item, ItemCopy: TSortItem;
begin
  Clear;
  for Item in Source do begin
    ItemCopy := AddNew;
    ItemCopy.Assign(Item);
  end;
end;


{ *** TDBObjectEditor }

constructor TDBObjectEditor.Create(AOwner: TComponent);
begin
  inherited;
  // Do not set alClient via DFM! In conjunction with ExplicitXXX properties that
  // repeatedly breaks the GUI layout when you reload the project
  Align := alClient;
  FMainSynMemo := nil;
  DBObject := nil;
  TranslateComponent(Self);
end;

destructor TDBObjectEditor.Destroy;
begin
  inherited;
end;

procedure TDBObjectEditor.SetModified(Value: Boolean);
begin
  FModified := Value;
end;

function TDBObjectEditor.ObjectExists: Boolean;
begin
  Result := not DBObject.Name.IsEmpty;
end;

procedure TDBObjectEditor.Init(Obj: TDBObject);
var
  editName: TWinControl;
  SynMemo: TSynMemo;
  popup: TPopupMenu;
  Item: TMenuItem;
  i: Integer;
  IsRefresh: Boolean;
begin
  Mainform.ShowStatusMsg(_('Initializing editor ...'));
  Mainform.LogSQL(Self.ClassName+'.Init, using object "'+Obj.Name+'"', lcDebug);
  TExtForm.FixControls(Self);
  IsRefresh := Assigned(DBObject) and DBObject.IsSameAs(Obj);
  if IsRefresh and Assigned(FMainSynMemo) then
    FMainSynMemoPreviousTopLine := FMainSynMemo.TopLine
  else
    FMainSynMemoPreviousTopLine := 0;
  DBObject := TDBObject.Create(Obj.Connection);
  DBObject.Assign(Obj);
  Mainform.UpdateEditorTab;
  Screen.Cursor := crHourglass;
  // Enable user to start typing immediately when creating a new object
  if DBObject.Name = '' then begin
    editName := FindComponent('editName') as TWinControl;
    if Assigned(editName) and editName.CanFocus then
      editName.SetFocus;
  end;

  for i:=0 to ComponentCount-1 do begin
    if not(Components[i] is TSynMemo) then
      Continue;

    SynMemo := Components[i] as TSynMemo;
    if (not Assigned(SynMemo)) or Assigned(SynMemo.PopupMenu) then
      Continue;

    popup := TPopupMenu.Create(Self);
    popup.Images := MainForm.VirtualImageListMain;

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actCopy;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actCut;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actPaste;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actSelectAll;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actSaveSynMemoToTextfile;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actToggleComment;
    popup.Items.Add(Item);

    Item := TMenuItem.Create(popup);
    Item.Action := MainForm.actReformatSQL;
    popup.Items.Add(Item);

    SynMemo.PopupMenu := popup;

  end;

end;

function TDBObjectEditor.DeInit: TModalResult;
var
  Msg, ObjType: String;
begin
  // Ask for saving modifications
  Result := mrOk;
  if Modified then begin
    ObjType := _(LowerCase(DBObject.ObjType));
    // Todo: no save button for objects without minimum requirements, such as name. See #1134
    if DBObject.Name <> '' then
      Msg := f_('Save modified %s "%s"?', [ObjType, DBObject.Name])
    else
      Msg := f_('Save new %s?', [ObjType]);
    Result := MessageDialog(Msg, mtConfirmation, [mbYes, mbNo, mbCancel]);
    case Result of
      mrYes: Result := ApplyModifications;
      mrNo: Modified := False;
    end;
  end;
end;




// Following code taken from OneInst.pas, http://assarbad.net/de/stuff/!import/nico.old/
// Slightly modified to better integrate that into our code, comments translated from german.

// Fetch and separate command line parameters into strings
function ParamBlobToStr(lpData: Pointer): String;
var
  pStr: PChar;
begin
  pStr := lpData;
  Result := string(pStr);
end;

// Pack current command line parameters
function ParamStrToBlob(out cbData: DWORD): Pointer;
var
  cmd: String;
begin
  cmd := GetCommandLine;
  cbData := Length(cmd)*2 + 3;
  Result := PChar(cmd);
end;

procedure HandleSecondInstance;
var
  Run: DWORD;
  Now: DWORD;
  Msg: TMsg;
  Wnd: HWND;
  Dat: TCopyDataStruct;
begin
  // MessageBox(0, 'already running', nil, MB_ICONINFORMATION);
  // Send a message to all main windows (HWND_BROADCAST) with the identical,
  // previously registered message id. We should only get reply from 0 or 1
  // instances.
  // (Broadcast should only be called with registered message ids!)

  SendMessage(HWND_BROADCAST, SecondInstMsgId, GetCurrentThreadId, 0);

  // Waiting for reply by first instance. For those of you which didn't knew:
  // Threads have message queues too ;o)
  Wnd := 0;
  Run := GetTickCount;
  while True do
  begin
    if PeekMessage(Msg, 0, SecondInstMsgId, SecondInstMsgId, PM_NOREMOVE) then
    begin
      GetMessage(Msg, 0, SecondInstMsgId, SecondInstMsgId);
      if Msg.message = SecondInstMsgId then
      begin
        Wnd := Msg.wParam;
        Break;
      end;
    end;
    Now := GetTickCount;
    if Now < Run then
      Run := Now;  // Avoid overflow, each 48 days.
    if Now - Run > 5000 then
      Break;
  end;

  if (Wnd <> 0) and IsWindow(Wnd) then
  begin
    // As a reply we got a handle to which we now send current parameters
    Dat.dwData := SecondInstMsgId;
    Dat.lpData := ParamStrToBlob(Dat.cbData);
    SendMessage(Wnd, WM_COPYDATA, 0, LPARAM(@Dat));
    // Leads to an AV in 64bit mode. See issue #3475:
    // FreeMemory(Dat.lpData);

    // Bring first instance to front
    if IsIconic(Wnd) then
      ShowWindow(Wnd, SW_RESTORE);
    BringWindowToTop(Wnd);
    SetForegroundWindow(Wnd);
  end;
end;

function CheckForSecondInstance: Boolean;
var
  Loop: Integer;
  MutexName: PChar;
begin
  // Try to create a system wide named kernel object (mutex). And check if that
  // already exists.
  // The name of such a mutex must not be longer than MAX_PATH (260) chars and
  // can contain all chars but not '\'

  Result := False;
  MutexName := PChar(APPNAME);
  for Loop := lstrlen(MutexName) to MAX_PATH - 1 do
  begin
    MutexHandle := CreateMutex(nil, False, MutexName);
    if (MutexHandle = 0) and (GetLastError = INVALID_HANDLE_VALUE) then
      // Looks like there is already a mutex using this name
      // Try to solve that by appending an underscore
      lstrcat(MutexName, '_')
    else
      // At least no naming conflict
      Break;
  end;

  case GetLastError of
    0: begin
        // We created the mutex, so this is the first instance
      end;
    ERROR_ALREADY_EXISTS:
      begin
        // There is already one instance
        try
          HandleSecondInstance;
        finally
          // Terminating is done in .dpr file, before Application.Initialize
          Result := True;
        end;
      end;
  else
    // No clue why we should get here. Oh, maybe Microsoft has changed rules, again.
    // However, we return false and let the application start
  end;
end;


function GetParentFormOrFrame(Comp: TWinControl): TWinControl;
begin
  Result := Comp;
  while True do begin
    try
      Result := Result.Parent;
    except
      on E:EAccessViolation do
        Break;
    end;
    // On a windows shutdown, GetParentForm() seems sporadically unable to find the owner form
    // In that case we would cause an exception when accessing it. Emergency break in that case.
    // See issue #1462
    if (not Assigned(Result)) or (Result is TCustomForm) or (Result is TFrame) then
      break;
  end;
end;


function KeyPressed(Code: Integer): Boolean;
var
  State: TKeyboardState;
begin
  // Checks whether a key is pressed, defined by virtual key code
  GetKeyboardState(State);
  Result := (State[Code] and 128) <> 0;
end;


function GeneratePassword(Len: Integer): String;
var
  i: Integer;
  CharTable: String;
const
  Consos = 'bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ';
  Vocals = 'aeiouAEIOU';
  Numbers = '123456789';
begin
  // Create a random, mnemonic password
  SetLength(Result, Len);
  for i:=1 to Len do begin
    if Random(4) = 1 then
      CharTable := Numbers
    else if i mod 2 = 0 then
      CharTable := Vocals
    else
      CharTable := Consos;
    Result[i] := CharTable[Random(Length(CharTable)-1)+1];
  end;
end;


procedure InvalidateVT(VT: TVirtualStringTree; RefreshTag: Integer; ImmediateRepaint: Boolean);
begin
  // Avoid AVs in OnDestroy events
  if not Assigned(VT) then
    Exit;
  VT.Tag := RefreshTag;
  if ImmediateRepaint then
    VT.Repaint
  else
    VT.Invalidate;
end;


function CharAtPos(Str: String; Pos: Integer): Char;
begin
  // Access char in string without causing access violation
  if Length(Str) < Pos then
    Result := #0
  else
    Result := Str[Pos];
end;


function CompareAnyNode(Text1, Text2: String): Integer;
var
  Number1, Number2 : Extended;
  a1, a2, b1, b2: Char;
  NumberMode: Boolean;
const
  Numbers = ['0'..'9'];
begin
  Result := 0;
  // Apply different comparisons for numbers and text
  a1 := CharAtPos(Text1, 1);
  a2 := CharAtPos(Text1, 2);
  b1 := CharAtPos(Text2, 1);
  b2 := CharAtPos(Text2, 2);
  NumberMode := ((a1='-') and (CharInSet(a2, Numbers)) or CharInSet(a1, Numbers))
    and ((b1='-') and (CharInSet(b2, Numbers)) or CharInSet(b1, Numbers));
  if NumberMode then begin
    // Assuming numeric values
    Number1 := MakeFloat(Text1);
    Number2 := MakeFloat(Text2);
    if Number1 > Number2 then
      Result := 1
    else if Number1 = Number2 then
      Result := 0
    else if Number1 < Number2 then
      Result := -1;
  end;
  if (not NumberMode) or (Result=0) then begin
    // Compare Strings
    Result := CompareText(Text1, Text2);
  end;
end;


function StringListCompareAnythingAsc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  // Sort TStringList items, containing numbers or strings, ascending
  Result := CompareAnyNode(List[Index1], List[Index2]);
end;


function StringListCompareAnythingDesc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  // Sort TStringList items, containing numbers or strings, descending
  Result := CompareAnyNode(List[Index2], List[Index1]);
end;


function StringListCompareByValue(List: TStringList; Index1, Index2: Integer): Integer;
begin
  // Sort TStringList items which are stored as name=value pairs
  Result := CompareAnyNode(List.ValueFromIndex[Index2], List.ValueFromIndex[Index1]);
end;


function StringListCompareByLength(List: TStringList; Index1, Index2: Integer): Integer;
begin
  // Sort TStringList items by their length
  Result := CompareValue(List[Index2].Length, List[Index1].Length);
end;


{**
  Return compile date/time from passed .exe name
  Code taken and modified from Michael Puff
  http://www.michael-puff.de/Programmierung/Delphi/Code-Snippets/GetImageLinkTimeStamp.shtml
}
function GetImageLinkTimeStamp(const FileName: string): TDateTime;
const
  INVALID_SET_FILE_POINTER = DWORD(-1);
  BorlandMagicTimeStamp = $2A425E19; // Delphi 4-6 (and above?)
  FileTime1970: TFileTime = (dwLowDateTime:$D53E8000; dwHighDateTime:$019DB1DE);
type
  PImageSectionHeaders = ^TImageSectionHeaders;
  TImageSectionHeaders = array [Word] of TImageSectionHeader;
type
  PImageResourceDirectory = ^TImageResourceDirectory;
  TImageResourceDirectory = packed record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    NumberOfNamedEntries: Word;
    NumberOfIdEntries: Word;
  end;
var
  FileHandle: THandle;
  BytesRead: DWORD;
  ImageDosHeader: TImageDosHeader;
  ImageNtHeaders: TImageNtHeaders;
  SectionHeaders: PImageSectionHeaders;
  Section: Word;
  ResDirRVA: DWORD;
  ResDirSize: DWORD;
  ResDirRaw: DWORD;
  ResDirTable: TImageResourceDirectory;
  FileTime: TFileTime;
  TimeStamp: DWord;
begin
  TimeStamp := 0;
  Result := 0;
  // Open file for read access
  FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if (FileHandle <> INVALID_HANDLE_VALUE) then try
    // Read MS-DOS header to get the offset of the PE32 header
    // (not required on WinNT based systems - but mostly available)
    if not ReadFile(FileHandle, ImageDosHeader, SizeOf(TImageDosHeader),
      BytesRead, nil) or (BytesRead <> SizeOf(TImageDosHeader)) or
      (ImageDosHeader.e_magic <> IMAGE_DOS_SIGNATURE) then begin
      ImageDosHeader._lfanew := 0;
    end;
    // Read PE32 header (including optional header
    if (SetFilePointer(FileHandle, ImageDosHeader._lfanew, nil, FILE_BEGIN) = INVALID_SET_FILE_POINTER) then
      Exit;
    if not(ReadFile(FileHandle, ImageNtHeaders, SizeOf(TImageNtHeaders), BytesRead, nil) and (BytesRead = SizeOf(TImageNtHeaders))) then
      Exit;
    // Validate PE32 image header
    if (ImageNtHeaders.Signature <> IMAGE_NT_SIGNATURE) then
      Exit;
    // Seconds since 1970 (UTC)
    TimeStamp := ImageNtHeaders.FileHeader.TimeDateStamp;

    // Check for Borland's magic value for the link time stamp
    // (we take the time stamp from the resource directory table)
    if (ImageNtHeaders.FileHeader.TimeDateStamp = BorlandMagicTimeStamp) then
    with ImageNtHeaders, FileHeader, OptionalHeader do begin
      // Validate Optional header
      if (SizeOfOptionalHeader < IMAGE_SIZEOF_NT_OPTIONAL_HEADER) or (Magic <> IMAGE_NT_OPTIONAL_HDR_MAGIC) then
        Exit;
      // Read section headers
      SectionHeaders :=
        GetMemory(NumberOfSections * SizeOf(TImageSectionHeader));
      if Assigned(SectionHeaders) then try
        if (SetFilePointer(FileHandle, SizeOfOptionalHeader - IMAGE_SIZEOF_NT_OPTIONAL_HEADER, nil, FILE_CURRENT) = INVALID_SET_FILE_POINTER) then
          Exit;
        if not(ReadFile(FileHandle, SectionHeaders^, NumberOfSections * SizeOf(TImageSectionHeader), BytesRead, nil) and (BytesRead = NumberOfSections * SizeOf(TImageSectionHeader))) then
          Exit;
        // Get RVA and size of the resource directory
        with DataDirectory[IMAGE_DIRECTORY_ENTRY_RESOURCE] do begin
          ResDirRVA := VirtualAddress;
          ResDirSize := Size;
        end;
        // Search for section which contains the resource directory
        ResDirRaw := 0;
        for Section := 0 to NumberOfSections - 1 do
        with SectionHeaders[Section] do
          if (VirtualAddress <= ResDirRVA) and (VirtualAddress + SizeOfRawData >= ResDirRVA + ResDirSize) then begin
            ResDirRaw := PointerToRawData - (VirtualAddress - ResDirRVA);
            Break;
          end;
        // Resource directory table found?
        if (ResDirRaw = 0) then
          Exit;
        // Read resource directory table
        if (SetFilePointer(FileHandle, ResDirRaw, nil, FILE_BEGIN) = INVALID_SET_FILE_POINTER) then
          Exit;
        if not(ReadFile(FileHandle, ResDirTable, SizeOf(TImageResourceDirectory), BytesRead, nil) and (BytesRead = SizeOf(TImageResourceDirectory))) then
          Exit;
        // Convert from DosDateTime to SecondsSince1970
        if DosDateTimeToFileTime(HiWord(ResDirTable.TimeDateStamp), LoWord(ResDirTable.TimeDateStamp), FileTime) then begin
          // FIXME: Borland's linker uses the local system time
          // of the user who linked the executable image file.
          // (is that information anywhere?)
          TimeStamp := (ULARGE_INTEGER(FileTime).QuadPart - ULARGE_INTEGER(FileTime1970).QuadPart) div 10000000;
        end;
      finally
        FreeMemory(SectionHeaders);
      end;
    end;
  finally
    CloseHandle(FileHandle);
  end;
  Result := UnixToDateTime(TimeStamp);
end;


function IsEmpty(Str: String): Boolean;
begin
  // Alternative version of "Str = ''"
  Result := Str = '';
end;

function IsNotEmpty(Str: String): Boolean;
begin
  // Alternative version of "Str <> ''"
  Result := Str <> '';
end;


function MessageDialog(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer;
begin
  Result := MessageDialog('', Msg, DlgType, Buttons);
end;


function MessageDialog(const Title, Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; KeepAskingSetting: TAppSettingIndex=asUnused; FooterText: String=''): Integer;
var
  m: String;
  Dialog: TTaskDialog;
  Btn: TTaskDialogButtonItem;
  MsgButton: TMsgDlgBtn;
  rx: TRegExpr;
  KeepAskingValue: Boolean;
  Hotkeys: String;
  WebSearchUrl, WebSearchHost: String;

  procedure AddButton(BtnCaption: String; BtnResult: TModalResult; ResourceId: Integer=0);
  var
    i: Integer;
    cap: String;
  begin
    Btn := TTaskDialogButtonItem(Dialog.Buttons.Add);
    cap := '';
    if ResourceId > 0 then begin
      // Prefer string from user32.dll
      // May be empty on Wine!
      cap := GetLocaleString(ResourceId)
    end;
    if cap.IsEmpty then begin
      cap := _(BtnCaption);
      for i:=1 to Length(cap) do begin
        // Auto apply hotkey
        if (Pos(LowerCase(cap[i]), Hotkeys) = 0) and cap[i].IsLetter then begin
          Hotkeys := Hotkeys + LowerCase(cap[i]);
          Insert('&', cap, i);
          break;
        end;
      end;
    end;
    Btn.Caption := cap;
    Btn.ModalResult := BtnResult;
    if (DlgType = mtCriticalConfirmation) and (BtnResult = mrCancel) then
      Btn.Default := True;
  end;
begin
  // Remember current path and restore it later, so the caller does not try to read from the wrong path after this dialog
  AppSettings.StorePath;

  if (Win32MajorVersion >= 6) and StyleServices.Enabled then begin
    // Use modern task dialog on Vista and above
    Dialog := TTaskDialog.Create(nil);
    Dialog.Flags := [tfEnableHyperlinks, tfAllowDialogCancellation];
    Dialog.CommonButtons := [];
    if Assigned(MainForm) then
      Dialog.OnHyperlinkClicked := MainForm.TaskDialogHyperLinkClicked;

    // Caption, title and text
    case DlgType of
      mtWarning: Dialog.Caption := _('Warning');
      mtError: Dialog.Caption := _('Error');
      mtInformation: Dialog.Caption := _('Information');
      mtConfirmation, mtCustom: Dialog.Caption := _('Confirm');
    end;
    if Title <> Dialog.Caption then
      Dialog.Title := Title;
    if Assigned(MainForm) and (MainForm.ActiveConnection <> nil) then
      Dialog.Caption := MainForm.ActiveConnection.Parameters.SessionName + ': ' + Dialog.Caption;
    rx := TRegExpr.Create;
    rx.Expression := 'https?://[^\s"]+';
    if ThemeIsDark then
      Dialog.Text := Msg
    else // See issue #2036
      Dialog.Text := rx.Replace(Msg, '<a href="$0">$0</a>', True);
    rx.Free;

    // Main icon, and footer link
    case DlgType of
      mtWarning:
        Dialog.MainIcon := tdiWarning;
      mtError: begin
        Dialog.MainIcon := tdiError;
        WebSearchUrl := AppSettings.ReadString(asWebSearchBaseUrl);
        WebSearchUrl := StringReplace(WebSearchUrl, '%q', EncodeURLParam(Copy(Msg, 1, 1000)), []);
        rx := TRegExpr.Create;
        rx.Expression := 'https?://(www\.)?([^/]+)/';
        if rx.Exec(WebSearchUrl) then
          WebSearchHost := rx.Match[2]
        else
          WebSearchHost := '[unknown host]';
        rx.Free;
        Dialog.FooterText := IfThen(FooterText.IsEmpty, '', FooterText + sLineBreak + sLineBreak) +
          '<a href="'+WebSearchUrl+'">'+_('Find some help on this error')+' (=> '+WebSearchHost+')</a>';
        Dialog.FooterIcon := tdiInformation;
      end;
      mtInformation:
        Dialog.MainIcon := tdiInformation;
      mtConfirmation, mtCustom: begin
        Dialog.Flags := Dialog.Flags + [tfUseHiconMain];
        Dialog.CustomMainIcon := ConfirmIcon;
      end;
      else
        Dialog.MainIcon := tdiNone;
    end;

    // Add buttons
    for MsgButton in Buttons do begin
      case MsgButton of
        mbYes:       AddButton('Yes', mrYes, 805);
        mbNo:        AddButton('No', mrNo, 806);
        mbOK:        AddButton('OK', mrOk, 800);
        mbCancel:    AddButton('Cancel', mrCancel, 801);
        mbAbort:     AddButton('Abort', mrAbort, 802);
        mbRetry:     AddButton('Retry', mrRetry, 803);
        mbIgnore:    AddButton('Ignore', mrIgnore, 804);
        mbAll:       AddButton('All', mrAll);
        mbNoToAll:   AddButton('No to all', mrNoToAll);
        mbYesToAll:  AddButton('Yes to all', mrYesToAll);
        mbClose:     AddButton('Close', mrClose, 807);
      end;
    end;

    // Checkbox, s'il vous plait?
    KeepAskingValue := True;
    if KeepAskingSetting <> asUnused then begin
      if (not (mbNo in Buttons)) and (Buttons <> [mbOK]) then
        raise Exception.CreateFmt(_('Missing "No" button in %() call'), ['MessageDialog']);
      KeepAskingValue := AppSettings.ReadBool(KeepAskingSetting);
      Dialog.Flags := Dialog.Flags + [tfVerificationFlagChecked];
      if Buttons = [mbOK] then
        Dialog.VerificationText := _('Keep showing this dialog.')
      else
        Dialog.VerificationText := _('Keep asking this question.');
    end;

    // Supress dialog and assume "No" if user disabled this dialog
    if KeepAskingValue then begin
      Dialog.Execute;
      Result := Dialog.ModalResult;
      if (KeepAskingSetting <> asUnused) and (not (tfVerificationFlagChecked in Dialog.Flags)) then
        AppSettings.WriteBool(KeepAskingSetting, False);
    end else
      Result := mrNo;

    Dialog.Free;
  end else begin
    // Backwards compatible dialog on Windows XP
    m := Msg;
    if not Title.IsEmpty then
      m := Title + SLineBreak + SLineBreak + m;
    if not FooterText.IsEmpty then
      m := m + SLineBreak + SLineBreak + FooterText;

    if KeepAskingSetting <> asUnused then
      KeepAskingValue := AppSettings.ReadBool(KeepAskingSetting)
    else
      KeepAskingValue := True;

    if KeepAskingValue then
      Result := MessageDlg(m, DlgType, Buttons, 0)
    else
      Result := mrNo;
  end;

  AppSettings.RestorePath;
end;


function ErrorDialog(Msg: string): Integer;
begin
  Result := MessageDialog('', Msg, mtError, [mbOK]);
end;


function ErrorDialog(const Title, Msg: string): Integer;
begin
  Result := MessageDialog(Title, Msg, mtError, [mbOK]);
end;


function GetLocaleString(const ResourceId: Integer): WideString;
var
  Buffer: WideString;
  BufferLen: Integer;
begin
  Result := '';
  if LibHandleUser32 <> 0 then begin
    SetLength(Buffer, 255);
    BufferLen := LoadStringW(LibHandleUser32, ResourceId, PWideChar(Buffer), Length(Buffer));
    if BufferLen <> 0 then
      Result := Copy(Buffer, 1, BufferLen);
  end;
end;


function GetHTMLCharsetByEncoding(Encoding: TEncoding): String;
begin
  Result := '';
  if Encoding = TEncoding.Default then
    Result := 'Windows-'+IntToStr(GetACP)
  else if Encoding.CodePage = 437 then
    Result := 'ascii'
  else if Encoding = TEncoding.Unicode then
    Result := 'utf-16le'
  else if Encoding = TEncoding.BigEndianUnicode then
    Result := 'utf-16'
  else if Encoding = TEncoding.UTF8 then
    Result := 'utf-8'
  else if Encoding = TEncoding.UTF7 then
    Result := 'utf-7';
end;


procedure ParseCommandLine(CommandLine: String; var ConnectionParams: TConnectionParameters; var FileNames: TStringList; var RunFrom: String);
var
  rx: TRegExpr;
  ExeName, SessName, Host, Lib, Port, User, Pass, Socket, AllDatabases,
  SSLPrivateKey, SSLCACertificate, SSLCertificate, SSLCipher: String;
  NetType, WindowsAuth, WantSSL, CleartextPluginEnabled, SSLVerification: Integer;
  AbsentFiles: TStringList;

  function GetParamValue(ShortName, LongName: String): String;
  begin
    // Return one command line switch. Doublequotes are not mandatory.
    Result := '';
    rx.Expression := '\s(\-'+ShortName+'|\-\-'+LongName+')\s*\=?\s*\"([^\-][^\"]*)\"';
    if rx.Exec(CommandLine) then
      Result := rx.Match[2]
    else begin
      rx.Expression := '\s(\-'+ShortName+'|\-\-'+LongName+')\s*\=?\s*([^\-]\S*)';
      if rx.Exec(CommandLine) then
        Result := rx.Match[2];
    end;
  end;

  procedure GetFileNames(Expression: String);
  begin
    rx.Expression := Expression;
    if rx.Exec(CommandLine) then while true do begin
      if FileExists(rx.Match[1]) then
        FileNames.Add(rx.Match[1])
      else
        AbsentFiles.Add(rx.Match[1]);
      // Remove match from input string, so the second call to GetFileNames without quotes
      // does not detect filenames cut at whitespace
      Delete(CommandLine, rx.MatchPos[1], rx.MatchLen[1]);
      if not rx.ExecNext then
        break;
    end;
  end;

begin
  // Parse command line, probably sent by blocked second application instance.
  // Try to build connection parameters out of it.
  SessName := '';
  FileNames := TStringList.Create;
  AbsentFiles := TStringList.Create;

  // Add leading (and trailing) space, so the regular expressions can request a mandantory space
  // before (and after) each param (and filename) including the first one (and last one)
  ExeName := ExtractFileName(ParamStr(0));
  CommandLine := Copy(CommandLine, Pos(ExeName, CommandLine)+Length(ExeName), Length(CommandLine));
  CommandLine := CommandLine + ' ';
  rx := TRegExpr.Create;

  // --runfrom=scheduler after build update
  RunFrom := GetParamValue('rf', 'runfrom');

  SessName := GetParamValue('d', 'description');
  if SessName <> '' then begin
    try
      ConnectionParams := TConnectionParameters.Create(SessName);
    except
      on E:Exception do begin
        // Session params not found in registry
        MainForm.LogSQL(E.Message);
      end;
    end;
  end;

  // Test if params were passed. If given, override previous values loaded from registry.
  // Enables the user to log into a session with a different, non-stored user: -dSession -uSomeOther
  NetType := StrToIntDef(GetParamValue('n', 'nettype'), 0);
  Host := GetParamValue('h', 'host');
  Lib := GetParamValue('l', 'library');
  User := GetParamValue('u', 'user');
  Pass := GetParamValue('p', 'password');
  CleartextPluginEnabled := StrToIntDef(GetParamValue('cte', 'cleartextenabled'), -1);
  Socket := GetParamValue('S', 'socket');
  Port := GetParamValue('P', 'port');
  AllDatabases := GetParamValue('db', 'databases');
  WindowsAuth := StrToIntDef(GetParamValue('W', 'winauth'), -1);
  WantSSL := StrToIntDef(GetParamValue('ssl', 'ssl'), -1);
  SSLPrivateKey := GetParamValue('sslpk', 'sslprivatekey');
  SSLCACertificate := GetParamValue('sslca', 'sslcacertificate');
  SSLCertificate := GetParamValue('sslcert', 'sslcertificate');
  SSLCipher := GetParamValue('sslcip', 'sslcipher');
  SSLVerification := StrToIntDef(GetParamValue('sslvrf', 'sslverification'), -1);
  // Leave out support for startup script, seems reasonable for command line connecting

  if (Host <> '') or (User <> '') or (Pass <> '') or (Port <> '') or (Socket <> '') or (AllDatabases <> '') then begin
    if not Assigned(ConnectionParams) then begin
      ConnectionParams := TConnectionParameters.Create;
      ConnectionParams.SessionPath := SessName;
    end;
    if NetType <> 0 then ConnectionParams.NetType := TNetType(NetType);
    try
      ConnectionParams.GetNetTypeGroup;
    except
      ConnectionParams.NetType := ntMySQL_TCPIP;
    end;
    if Host <> '' then ConnectionParams.Hostname := Host;
    if Lib <> '' then ConnectionParams.LibraryOrProvider := Lib;
    if ConnectionParams.LibraryOrProvider.IsEmpty then ConnectionParams.LibraryOrProvider := ConnectionParams.DefaultLibrary;
    if User <> '' then ConnectionParams.Username := User;
    if Pass <> '' then ConnectionParams.Password := Pass;
    if CleartextPluginEnabled in [0,1] then
      ConnectionParams.CleartextPluginEnabled := Boolean(CleartextPluginEnabled);
    if Port <> '' then ConnectionParams.Port := StrToIntDef(Port, 0);
    if Socket <> '' then begin
      ConnectionParams.Hostname := Socket;
      ConnectionParams.NetType := ntMySQL_NamedPipe;
    end;
    if AllDatabases <> '' then ConnectionParams.AllDatabasesStr := AllDatabases;
    if WantSSL in [0,1] then
      ConnectionParams.WantSSL := Boolean(WantSSL);
    if SSLPrivateKey <> '' then
      ConnectionParams.SSLPrivateKey := SSLPrivateKey;
    if SSLCACertificate <> '' then
      ConnectionParams.SSLCACertificate := SSLCACertificate;
    if SSLCertificate <> '' then
      ConnectionParams.SSLCertificate := SSLCertificate;
    if SSLCipher <> '' then
      ConnectionParams.SSLCipher := SSLCipher;
    if SSLVerification >= 0 then
      ConnectionParams.SSLVerification := SSLVerification;

    if WindowsAuth in [0,1] then
      ConnectionParams.WindowsAuth := Boolean(WindowsAuth);

    // Ensure we have a session name to pass to InitConnection
    if (ConnectionParams.SessionPath = '') and (ConnectionParams.Hostname <> '') then
      ConnectionParams.SessionPath := ConnectionParams.Hostname;
  end;

  // Check for valid filename(s) in parameters.
  // We support doublequoted and unquoted parameters.
  GetFileNames('\"([^\"]+\.sql)\"');
  GetFileNames('\s([^\s\"]+\.sql)\b');
  if AbsentFiles.Count > 0 then
    ErrorDialog(_('Could not load file(s):'), AbsentFiles.Text);
  AbsentFiles.Free;

  rx.Free;
end;


function f_(const Pattern: string; const Args: array of const): string;
var
  TranslatedPattern: String;
begin
  // Helper for translation, replacement for Format(_())
  try
    TranslatedPattern := _(Pattern);
    Result := Format(TranslatedPattern, Args);
  except
    on E:Exception do begin
      MainForm.LogSQL(E.ClassName+' in translation string with invalid format arguments: "'+TranslatedPattern+'"', lcError);
      Result := Format(Pattern, Args);
    end;
  end;
end;


function GetOutputFilename(FilenameWithPlaceholders: String; DBObj: TDBObject): String;
var
  Arguments: TExtStringList;
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
  i: Integer;
begin
  // Rich format output filename, replace certain markers. See issue #2622
  Arguments := TExtStringList.Create;

  if Assigned(DBObj) then begin
    Arguments.Values['session'] := ValidFilename(DBObj.Connection.Parameters.SessionName);
    Arguments.Values['host'] := ValidFilename(DBObj.Connection.Parameters.Hostname);
    Arguments.Values['u'] := ValidFilename(DBObj.Connection.Parameters.Username);
    Arguments.Values['db'] := ValidFilename(DBObj.Database);
  end;
  Arguments.Values['date'] := ValidFilename(DateTimeToStr(Now));
  DecodeDateTime(Now, Year, Month, Day, Hour, Min, Sec, MSec);
  Arguments.Values['d'] := Format('%.2d', [Day]);
  Arguments.Values['m'] := Format('%.2d', [Month]);
  Arguments.Values['y'] := Format('%.4d', [Year]);
  Arguments.Values['h'] := Format('%.2d', [Hour]);
  Arguments.Values['i'] := Format('%.2d', [Min]);
  Arguments.Values['s'] := Format('%.2d', [Sec]);

  Result := FilenameWithPlaceholders;
  for i:=0 to Arguments.Count-1 do begin
    Result := StringReplace(Result, '%'+Arguments.Names[i], Arguments.ValueFromIndex[i], [rfReplaceAll]);
  end;
  Arguments.Free;
end;


function GetOutputFilenamePlaceholders: TStringList;
begin
  // Return a list with valid placeholder=>description pairs
  Result := TStringList.Create;
  Result.Values['session'] := _('Session name');
  Result.Values['host'] := _('Hostname');
  Result.Values['u'] := _('Username');
  Result.Values['db'] := _('Database');
  Result.Values['date'] := _('Date and time');
  Result.Values['d'] := _('Day of month');
  Result.Values['m'] := _('Month');
  Result.Values['y'] := _('Year');
  Result.Values['h'] := _('Hour');
  Result.Values['i'] := _('Minute');
  Result.Values['s'] := _('Second');
end;


function GetSystemImageList: TImageList;
var
  Info: TSHFileInfo;
  ImageListHandle: Cardinal;
begin
  // Create shared imagelist once and use in TPopupMenu and TVirtualTree or whatever
  if SystemImageList = nil then begin
    ImageListHandle := SHGetFileInfo('', 0, Info, SizeOf(Info), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    if ImageListHandle <> 0 then begin
      SystemImageList := TImageList.Create(MainForm);
      SystemImageList.Handle := ImageListHandle;
      SystemImageList.ShareImages := true;
      SystemImageList.DrawingStyle := dsTransparent;
    end;
  end;
  Result := SystemImageList;
end;


function GetSystemImageIndex(Filename: String): Integer;
var
  Info: TSHFileInfo;
begin
  // Return image index of shared system image list, for a given filename
  SHGetFileInfo(PChar(Filename), 0, Info, SizeOf(Info), SHGFI_SYSICONINDEX or SHGFI_TYPENAME);
  Result := Info.iIcon;
end;


function GetExecutableBits: Byte;
begin
  {$IFDEF WIN64}
  Result := 64;
  {$ELSE}
  Result := 32;
  {$ENDIF}
end;


procedure Help(Sender: TObject; Anchor: String);
var
  Place: String;
begin
  // Go to online help page
  if Sender is TAction then
    Place := (Sender as TAction).ActionComponent.Name
  else if Sender is TControl then
    Place := (Sender as TControl).Name
  else
    Place := 'unhandled-'+Sender.ClassName;
  if not Anchor.IsEmpty then
    Anchor := '#'+Anchor;
  ShellExec(APPDOMAIN+'help.php?place='+EncodeURLParam(Place)+Anchor);
end;


function PortOpen(Port: Word): Boolean;
var
  client: sockaddr_in;
  sock: Integer;
  ret: Integer;
  wsdata: WSAData;
begin
  Result := True;
  ret := WSAStartup($0002, wsdata);
  if ret<>0 then
    Exit;
  try
    client.sin_family := AF_INET;
    client.sin_port := htons(Port);
    client.sin_addr.s_addr := inet_addr(PAnsiChar('127.0.0.1'));
    sock := socket(AF_INET, SOCK_STREAM, 0);
    Result := connect(sock, client, SizeOf(client)) <> 0;
  finally
    WSACleanup;
  end;
end;


function IsValidFilePath(FilePath: String): Boolean;
var
  Pieces: TStringList;
  i: Integer;
begin
  // Check file path for invalid characters. See http://www.heidisql.com/forum.php?t=20873
  Result := True;
  Pieces := TStringList.Create;
  SplitRegExpr('[\\\/]', FilePath, Pieces);
  for i:=1 to Pieces.Count-1 do begin
    Result := Result and TPath.HasValidFileNameChars(Pieces[i], False);
  end;
  Pieces.Free;
end;


function FileIsWritable(FilePath: String): Boolean;
var
  hFile: DWORD;
begin
  // Check if file is writable
  if not FileExists(FilePath) then begin
    // Return true if file does not exist
    Result := True;
  end else begin
    hFile := CreateFile(PChar(FilePath), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
    Result := hFile <> INVALID_HANDLE_VALUE;
    CloseHandle(hFile);
  end;
end;


function GetThemeColor(Color: TColor): TColor;
begin
  // Not required with vcl-style-utils:
  // Result := TStyleManager.ActiveStyle.GetSystemColor(Color);
  Result := Color;
end;


function ThemeIsDark(ThemeName: String=''): Boolean;
const
  DarkThemes: String = 'Amakrits,Aqua Graphite,Auric,Carbon,Charcoal Dark Slate,Cobalt XEMedia,Glossy,Glow,Golden Graphite,Material,Onyx Blue,Ruby Graphite,TabletDark,Windows10 Dark,Windows10 SlateGray';
var
  DarkThemesList: TStringList;
begin
  DarkThemesList := Explode(',', DarkThemes);
  if ThemeName.IsEmpty then
    ThemeName := TStyleManager.ActiveStyle.Name;
  Result := DarkThemesList.IndexOf(ThemeName) > -1;
  DarkThemesList.Free;
end;


function ProcessExists(pid: Cardinal; ExeNamePattern: String): Boolean;
var
  Proc: TProcessEntry32;
  SnapShot: THandle;
  ContinueLoop: Boolean;
begin
  // Check if a given process id exists
  SnapShot := CreateToolhelp32Snapshot(TH32CS_SnapProcess, 0);
  Proc.dwSize := Sizeof(Proc);
  Result := False;
  ContinueLoop := Process32First(SnapShot, Proc);
  while ContinueLoop do begin
    Result := (Proc.th32ProcessID = pid) and ContainsText(Proc.szExeFile, ExeNamePattern);
    if Result then
      Break;
    ContinueLoop := Process32Next(SnapShot, Proc);
  end;
  CloseHandle(Snapshot);
end;


procedure ToggleCheckBoxWithoutClick(chk: TCheckBox; State: Boolean);
var
  ClickEvent: TNotifyEvent;
begin
  ClickEvent := chk.OnClick;
  chk.OnClick := nil;
  chk.Checked := State;
  chk.OnClick := ClickEvent;
end;


function SynCompletionProposalPrettyText(ImageIndex: Integer; LeftText, CenterText, RightText: String;
  LeftColor: TColor=-1; CenterColor: TColor=-1; RightColor: TColor=-1): String;
const
  LineFormat = '\image{%d}\hspace{5}\color{%s}%s\column{}\color{%s}%s\hspace{10}\color{%s}\style{+i}%s';
begin
  // Return formatted item string for a TSynCompletionProposal
  if LeftColor = -1 then LeftColor := clGrayText;
  if CenterColor = -1 then CenterColor := clWindowText;
  if RightColor = -1 then RightColor := clGrayText;
  Result := Format(LineFormat, [ImageIndex, ColorToString(LeftColor), LeftText, ColorToString(CenterColor), CenterText, ColorToString(RightColor), RightText]);
end;


function PopupComponent(Sender: TObject): TComponent;
var
  Menu: TObject;
begin
  // Return owner component of clicked menu item, probably combined with a TAction
  Result := nil;
  Menu := nil;
  if Sender is TAction then
    Sender := (Sender as TAction).ActionComponent;

  if Sender is TMenuItem then
    Menu := (Sender as TMenuItem).GetParentMenu
  else if Sender is TPopupMenu then
    Menu := Sender;

  if Menu is TPopupMenu then
    Result := (Menu as TPopupMenu).PopupComponent;
end;


function IsWine: Boolean;
var
  NTHandle: THandle;
  wine_nt_to_unix_file_name: procedure(p1:pointer; p2:pointer); stdcall;
begin
  // Detect if we're running on Wine, not on native Windows
  // Idea taken from http://ruminatedrumblings.blogspot.com/2008/04/detecting-virtualized-environment.html
  if IsWineStored = -1 then begin
    NTHandle := LoadLibrary('NTDLL.DLL');
    if NTHandle>32 then
      wine_nt_to_unix_file_name := GetProcAddress(NTHandle, 'wine_nt_to_unix_file_name')
    else
      wine_nt_to_unix_file_name := nil;
    IsWineStored := IfThen(Assigned(wine_nt_to_unix_file_name), 1, 0);
    FreeLibrary(NTHandle);
  end;
  Result := IsWineStored = 1;
end;


function DirSep: Char;
begin
  if IsWine then
    Result := '/'
  else
    Result := '\';
end;

procedure FindComponentInstances(BaseForm: TComponent; ClassType: TClass; var List: TObjectList);
var
  i: Integer;
begin
  for i:=0 to BaseForm.ComponentCount-1 do begin
    if BaseForm.Components[i] is ClassType then
      List.Add(BaseForm.Components[i] as ClassType)
    else
      FindComponentInstances(BaseForm.Components[i], ClassType, List);
  end;
end;

function WebColorStrToColorDef(WebColor: string; Default: TColor): TColor;
begin
  try
    Result := WebColorStrToColor(WebColor);
  except
    Result := Default;
  end;
end;


function UserAgent(OwnerComponent: TComponent): String;
var
  OS: String;
begin
  if IsWine then
    OS := 'Linux/Wine'
  else
    OS := 'Windows NT '+IntToStr(Win32MajorVersion)+'.'+IntToStr(Win32MinorVersion);
  Result := APPNAME+'/'+MainForm.AppVersion+' ('+OS+'; '+ExtractFilename(Application.ExeName)+'; '+OwnerComponent.Name+')';
end;


function CodeIndent(Steps: Integer=1): String;
begin
  // Provide tab or spaces for indentation, uniquely used for all SQL statements
  if AppSettings.ReadBool(asTabsToSpaces) then
    Result := StringOfChar(' ', AppSettings.ReadInt(asTabWidth) * Steps)
  else
    Result := StringOfChar(#9, Steps);
end;


function EscapeHotkeyPrefix(Text: String): String;
begin
  // Issue #1992: Escape ampersand in caption of menus and tabs, preventing underlined hotkey generation
  Result := StringReplace(Text, Vcl.Menus.cHotkeyPrefix, Vcl.Menus.cHotkeyPrefix + Vcl.Menus.cHotkeyPrefix, [rfReplaceAll]);
end;


{ Get SID of current Windows user, probably useful in the future
function GetCurrentUserSID: string;
type
  PTOKEN_USER = ^TOKEN_USER;
  _TOKEN_USER = record
     User: TSidAndAttributes;
  end;
  TOKEN_USER = _TOKEN_USER;
var
  hToken: THandle;
  cbBuf: Cardinal;
  ptiUser: PTOKEN_USER;
  bSuccess: Boolean;
  StrSid: PWideChar;
begin
  // Taken from https://stackoverflow.com/a/71730865/4110077
  // SidToString does not exist, prefer WinApi.Windows.ConvertSidToStringSid()
  Result := '';

  // Get the calling thread's access token.
  if not OpenThreadToken(GetCurrentThread(), TOKEN_QUERY, True, hToken) then
  begin
    if (GetLastError <> ERROR_NO_TOKEN) then
      Exit;

    // Retry against process token if no thread token exists.
    if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
      Exit;
  end;
  try
    // Obtain the size of the user information in the token.
    bSuccess := GetTokenInformation(hToken, TokenUser, nil, 0, cbBuf);
    ptiUser  := nil;
    try
      while (not bSuccess) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) do
      begin
        ReallocMem(ptiUser, cbBuf);
        bSuccess := GetTokenInformation(hToken, TokenUser, ptiUser, cbBuf, cbBuf);
      end;
      ConvertSidToStringSid(ptiUser.User.Sid, StrSid);
      Result := StrSid;
    finally
      FreeMem(ptiUser);
    end;
  finally
    CloseHandle(hToken);
  end;
end; }


{ Threading stuff }

constructor TQueryThread.Create(Connection: TDBConnection; Batch: TSQLBatch; TabNumber: Integer);
begin
  inherited Create(False);
  FConnection := Connection;
  FAborted := False;
  FBatch := Batch;
  FTabNumber := TabNumber;
  FBatchPosition := 0;
  FQueryStartedAt := Now;
  FQueryTime := 0;
  FQueryNetTime := 0;
  FRowsAffected := 0;
  FRowsFound := 0;
  FWarningCount := 0;
  FErrorMessage := '';
  FBatchInOneGo := MainForm.actBatchInOneGo.Checked;
  FStopOnErrors := MainForm.actQueryStopOnErrors.Checked;
  FreeOnTerminate := True;
  Priority := tpNormal;
end;


procedure TQueryThread.Execute;
var
  SQL: String;
  i, BatchStartOffset, ResultCount: Integer;
  PacketSize, MaxAllowedPacket: Int64;
  DoStoreResult, ErrorAborted, LogMaxResultsDone: Boolean;
begin
  inherited;

  MaxAllowedPacket := 0;
  i := 0;
  ResultCount := 0;
  ErrorAborted := False;
  LogMaxResultsDone := False;

  while i < FBatch.Count do begin
    SQL := '';
    if not FBatchInOneGo then begin
      SQL := FBatch[i].SQL;
      Inc(i);
    end else begin
      // Concat queries up to a size of max_allowed_packet
      if MaxAllowedPacket = 0 then begin
        FConnection.SetLockedByThread(Self);
        MaxAllowedPacket := FConnection.MaxAllowedPacket;
        FConnection.SetLockedByThread(nil);
        // TODO: Log('Detected maximum allowed packet size: '+FormatByteNumber(MaxAllowedPacket), lcDebug);
      end;
      BatchStartOffset := FBatch[i].LeftOffset;
      while i < FBatch.Count do begin
        PacketSize := FBatch[i].RightOffset - BatchStartOffset + ((i-FBatchPosition) * 20);
        if not SQL.IsEmpty then begin
          if PacketSize >= MaxAllowedPacket then begin
            // TODO: Log('Limiting batch packet size to '+FormatByteNumber(Length(SQL))+' with '+FormatNumber(i-FUserQueryOffset)+' queries.', lcDebug);
            Break;
          end
          else begin
            // Don't append to the very last query. See issue #1583
            SQL := SQL + '; ';
          end;
        end;
        SQL := SQL + FBatch[i].SQL;
        Inc(i);
      end;
      FQueriesInPacket := i - FBatchPosition;
    end;
    Synchronize(procedure begin MainForm.BeforeQueryExecution(Self); end);
    try
      FConnection.SetLockedByThread(Self);
      DoStoreResult := ResultCount < AppSettings.ReadInt(asMaxQueryResults);
      if (not DoStoreResult) and (not LogMaxResultsDone) then begin
        // Inform user about preference setting for limiting result tabs
        FConnection.Log(lcInfo,
          f_('Reached maximum number of result tabs (%d). To display more results, increase setting in Preferences > SQL', [AppSettings.ReadInt(asMaxQueryResults)])
          );
        LogMaxResultsDone := True;
      end;
      FConnection.Query(SQL, DoStoreResult, lcUserFiredSQL);
      Inc(ResultCount, FConnection.ResultCount);
      FBatchPosition := i;
      Inc(FQueryTime, FConnection.LastQueryDuration);
      Inc(FQueryNetTime, FConnection.LastQueryNetworkDuration);
      Inc(FRowsAffected, FConnection.RowsAffected);
      Inc(FRowsFound, FConnection.RowsFound);
      Inc(FWarningCount, FConnection.WarningCount);
    except
      on E:EDbError do begin
        if FStopOnErrors or (i = FBatch.Count - 1) then begin
          FErrorMessage := E.Message;
          ErrorAborted := True;
        end;
      end;
    end;
    FConnection.SetLockedByThread(nil);
    Synchronize(procedure begin MainForm.AfterQueryExecution(Self); end);
    FConnection.ShowWarnings;
    // Check if FAborted is set by the main thread, to avoid proceeding the loop in case
    // FStopOnErrors is set to false
    if FAborted or ErrorAborted then
      break;
  end;

  Synchronize(procedure begin MainForm.FinishedQueryExecution(Self); end);
end;


procedure TQueryThread.LogFromThread(Msg: String; Category: TDBLogCategory);
begin
  Queue(procedure begin FConnection.Log(Category, Msg); end);
end;


{ TSQLSentence }

constructor TSQLSentence.Create(Owner: TSQLBatch);
begin
  // Use a back reference to the parent batch object, so we can extract SQL from it
  FOwner := Owner;
end;


function TSQLSentence.GetSize: Integer;
begin
  Result := RightOffset - LeftOffset;
end;


function TSQLSentence.GetSQL: String;
begin
  // Result := Copy(FOwner.SQL, LeftOffset, RightOffset-LeftOffset);
  // Probably faster than Copy():
  SetString(Result, PChar(FOwner.SQL) +LeftOffset -1, RightOffset-LeftOffset);
end;


function TSQLSentence.GetSQLWithoutComments: String;
begin
  Result := FOwner.GetSQLWithoutComments(GetSQL);
end;


{ TSQLBatch }

function TSQLBatch.GetSize: Integer;
var
  Query: TSQLSentence;
begin
  // Return overall string length of batch
  Result := 0;
  for Query in Self do
    Inc(Result, Query.Size);
end;


procedure TSQLBatch.SetSQL(Value: String);
var
  i, AllLen, DelimLen, DelimStart, LastLeftOffset, RightOffset: Integer;
  c, n, LastStringEncloser: Char;
  Delim, DelimTest, QueryTest: String;
  InString, InComment, InBigComment, InEscape: Boolean;
  Marker: TSQLSentence;
  rx: TRegExpr;
const
  StringEnclosers = ['"', '''', '`'];
  NewLines = [#13, #10];
  WhiteSpaces = NewLines + [#9, ' '];
begin
  // Scan SQL batch for delimiters and store a list with start + end offsets
  FSQL := Value;
  Clear;
  AllLen := Length(FSQL);
  i := 0;
  LastLeftOffset := 1;
  Delim := Mainform.Delimiter;
  InString := False; // Loop in "enclosed string" or `identifier`
  InComment := False; // Loop in one-line comment (# or --)
  InBigComment := False; // Loop in /* multi-line */ or /*! condictional comment */
  InEscape := False; // Previous char was backslash
  LastStringEncloser := #0;
  DelimLen := Length(Delim);
  rx := TRegExpr.Create;
  rx.Expression := '^\s*DELIMITER\s+(\S+)';
  rx.ModifierG := True;
  rx.ModifierI := True;
  rx.ModifierM := False;
  while i < AllLen do begin
    Inc(i);
    // Current and next char
    c := FSQL[i];
    if i < AllLen then n := FSQL[i+1]
    else n := #0;

    // Check for comment syntax and for enclosed literals, so a query delimiter can be ignored
    if (not InComment) and (not InBigComment) and (not InString) and ((c + n = '--') or (c = '#')) then
      InComment := True;
    if (not InComment) and (not InBigComment) and (not InString) and (c + n = '/*') then
      InBigComment := True;
    if InBigComment and (not InComment) and (not InString) and (c + n = '*/') then
      InBigComment := False;
    if (not InEscape) and (not InComment) and (not InBigComment) and CharInSet(c, StringEnclosers) then begin
      if (not InString) or (InString and (c = LastStringEncloser)) then begin
        InString := not InString;
        LastStringEncloser := c;
      end;
    end;
    if (CharInSet(c, NewLines) and (not CharInSet(n, NewLines))) or (i = 1) then begin
      if i > 1 then
        InComment := False;
      if (not InString) and (not InBigComment) and rx.Exec(copy(FSQL, i, 100)) then begin
        Delim := rx.Match[1];
        DelimLen := rx.MatchLen[1];
        Inc(i, rx.MatchLen[0]);
        LastLeftOffset := i;
        continue;
      end;
    end;
    if not InEscape then
      InEscape := c = '\'
    else
      InEscape := False;

    // Prepare delimiter test string
    if (not InComment) and (not InString) and (not InBigComment) then begin
      DelimStart := Max(1, i+1-DelimLen);
      DelimTest := Copy(FSQL, DelimStart, i-Max(i-DelimLen, 0));
    end else
      DelimTest := '';

    // End of query or batch reached. Add query markers to result list if sentence is not empty.
    if (DelimTest = Delim) or (i = AllLen) then begin
      RightOffset := i+1;
      if DelimTest = Delim then
        Dec(RightOffset, DelimLen);
      QueryTest := Trim(Copy(FSQL, LastLeftOffset, RightOffset-LastLeftOffset));
      if (QueryTest <> '') and (QueryTest <> Delim) then begin
        Marker := TSQLSentence.Create(Self);
        while CharInSet(FSQL[LastLeftOffset], WhiteSpaces) do
          Inc(LastLeftOffset);
        Marker.LeftOffset := LastLeftOffset;
        Marker.RightOffset := RightOffset;
        Add(Marker);
        LastLeftOffset := i+1;
      end;
    end;
  end;
end;

function TSQLBatch.GetSQLWithoutComments: String;
begin
  Result := GetSQLWithoutComments(SQL);
end;

class function TSQLBatch.GetSQLWithoutComments(FullSQL: String): String;
var
  InLineComment, InMultiLineComment: Boolean;
  AddCur: Boolean;
  i: Integer;
  Cur, Prev1, Prev2: Char;
begin
  // Strip comments out of SQL sentence
  // TODO: leave quoted string literals and identifiers untouched
  Result := '';
  InLineComment := False;
  InMultiLineComment := False;
  Prev1 := #0;
  Prev2 := #0;
  for i:=1 to Length(FullSQL) do begin
    Cur := FullSQL[i];
    AddCur := True;
    if i > 1 then Prev1 := FullSQL[i-1];
    if i > 2 then Prev2 := FullSQL[i-2];

    if (Cur = '*') and (Prev1 = '/') then begin
      InMultiLineComment := True;
      System.Delete(Result, Length(Result), 1); // Delete comment chars
    end
    else if InMultiLineComment and (Cur = '/') and (Prev1 = '*') then begin
      InMultiLineComment := False;
      System.Delete(Result, Length(Result), 1);
      AddCur := False;
    end;

    if not InMultiLineComment then begin
      if InLineComment and ((Cur = #13) or (Cur = #10)) then begin
        InLineComment := False; // Reset
      end
      else if Cur = '#' then begin
        InLineComment := True;
      end
      else if (Cur = ' ') and (Prev1 = '-') and (Prev2 = '-') then begin
        InLineComment := True;
        System.Delete(Result, Length(Result)-1, 2); // Delete comment chars
      end;
    end;

    if AddCur and (not InLineComment) and (not InMultiLineComment) then begin
      Result := Result + Cur;
    end;
  end;
end;

{ THttpDownload }

constructor THttpDownload.Create(Owner: TComponent);
begin
  FBytesRead := -1;
  FContentLength := -1;
  FOwner := Owner;
  FTimeOut := 10;
end;


procedure THttpDownload.SendRequest(Filename: String);
var
  NetHandle: HINTERNET;
  UrlHandle: HINTERNET;
  Buffer: array[1..4096] of AnsiChar;
  Head: array[1..1024] of Char;
  BytesInChunk, HeadSize, Reserved, TimeOutSeconds: Cardinal;
  LocalFile: File;
  DoStore: Boolean;
  HttpStatus: Integer;
  ContentChunk: UTF8String;
begin
  DoStore := False;
  NetHandle := InternetOpen(PChar(UserAgent(FOwner)), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  // Do not let the user wait 30s
  TimeOutSeconds := FTimeOut * 1000;
  InternetSetOption(NetHandle, INTERNET_OPTION_CONNECT_TIMEOUT, @TimeOutSeconds, SizeOf(TimeOutSeconds));

  UrlHandle := nil;
  FLastContent := '';
  try
    UrlHandle := InternetOpenURL(NetHandle, PChar(FURL), nil, 0, INTERNET_FLAG_RELOAD, 0);
    if (not Assigned(UrlHandle)) and FURL.StartsWith('https:', true) then begin
      // Try again without SSL. See issue #65 and #1209
      MainForm.LogSQL(f_('Could not open %s (%s) - trying again without SSL...', [FURL, SysErrorMessage(GetLastError)]), lcError);
      FURL := ReplaceRegExpr('^https:', FURL, 'http:');
      UrlHandle := InternetOpenURL(NetHandle, PChar(FURL), nil, 0, INTERNET_FLAG_RELOAD, 0);
    end;
    if not Assigned(UrlHandle) then begin
      raise Exception.CreateFmt(_('Could not open %s (%s)'), [FURL, SysErrorMessage(GetLastError)]);
    end;

    // Detect content length
    HeadSize := SizeOf(Head);
    Reserved := 0;
    if HttpQueryInfo(UrlHandle, HTTP_QUERY_CONTENT_LENGTH, @Head, HeadSize, Reserved) then
      FContentLength := StrToIntDef(Head, -1)
    else
      raise Exception.CreateFmt(_('Server did not send required "Content-Length" header: %s'), [FURL]);

    // Check if we got HTTP status 200
    HeadSize := SizeOf(Head);
    Reserved := 0;
    if HttpQueryInfo(UrlHandle, HTTP_QUERY_STATUS_CODE, @Head, HeadSize, Reserved) then begin
      HttpStatus := StrToIntDef(Head, -1);
      if HttpStatus <> 200 then
        raise Exception.CreateFmt(_('Got HTTP status %d from %s'), [HttpStatus, FURL]);
    end;

    // Create local file
    if Filename <> '' then begin
      AssignFile(LocalFile, FileName);
      Rewrite(LocalFile, 1);
      DoStore := True;
    end;

    // Stream contents
    while true do begin
      InternetReadFile(UrlHandle, @Buffer, SizeOf(Buffer), BytesInChunk);
      // Either store as file or in memory variable
      if DoStore then begin
        BlockWrite(LocalFile, Buffer, BytesInChunk)
      end else begin
        SetString(ContentChunk, PAnsiChar(@Buffer[1]), BytesInChunk);
        FLastContent := FLastContent + String(ContentChunk);
      end;
      Inc(FBytesRead, BytesInChunk);
      if Assigned(FOnProgress) then
        FOnProgress(Self);
      if BytesInChunk = 0 then
        break;
    end;

  finally
    if DoStore then
      CloseFile(LocalFile);
    if Assigned(UrlHandle) then
      InternetCloseHandle(UrlHandle);
    if Assigned(NetHandle) then
      InternetCloseHandle(NetHandle);
  end;
end;



{ TExtStringList }
// taken from https://stackoverflow.com/questions/33893377/can-i-prevent-tstringlist-removing-key-value-pair-when-value-set-to-empty

function TExtStringList.GetValue(const Name: string): string;
begin
  Result := Self.GetValue(Name);
end;


procedure TExtStringList.SetValue(const Name, Value: string);
var
  I: Integer;
begin
  I := IndexOfName(Name);
  if I < 0 then I := Add('');
  Put(I, Name + NameValueSeparator + Value);
end;


{ TSqlTranspiler }

class function TSqlTranspiler.CreateTable(SQL: String; SourceDb, TargetDb: TDBConnection): String;
begin
  Result := SQL;

  if SourceDb.Parameters.IsMySQL(False) and TargetDb.Parameters.IsMariaDB then begin
    // Remove COLLATE clause from virtual column definition:
    // `tax_status` varchar(255) COLLATE utf8mb4_unicode_ci GENERATED ALWAYS AS (json_unquote(json_extract(`price`,'$.taxStatus'))) VIRTUAL
    Result := ReplaceRegExpr('\sCOLLATE\s\w+(\s+GENERATED\s)', Result, '$1', [rroModifierI, rroUseSubstitution]);
  end;

end;


{ TClipboardHelper }

function TClipboardHelper.GetTryAsText: String;
var
  AttemptsLeft: Integer;
  Success: Boolean;
  LastError: String;
begin
  AttemptsLeft := 5;
  Result := '';
  Success := False;
  while AttemptsLeft > 0 do begin
    Dec(AttemptsLeft);
    try
      Result := AsText;
      Success := True;
      Break;
    except
      // We could also just catch EClipboardException
      on E:Exception do begin
        LastError := E.Message;
        Sleep(100);
      end;
    end;
  end;
  if not Success then
    MainForm.LogSQL(LastError, lcError);
end;

procedure TClipboardHelper.SetTryAsText(AValue: String);
var
  AttemptsLeft: Integer;
  Success: Boolean;
  LastError: String;
begin
  AttemptsLeft := 5;
  Success := False;
  while AttemptsLeft > 0 do begin
    Dec(AttemptsLeft);
    try
      AsText := AValue;
      Success := True;
      Break;
    except
      // We could also just catch EClipboardException
      on E:Exception do begin
        LastError := E.Message;
        Sleep(100);
      end;
    end;
  end;
  if not Success then
    MainForm.LogSQL(LastError, lcError);
end;


procedure TWinControlHelper.TrySetFocus;
begin
  try
    if Enabled
      and CanFocus then
      SetFocus;
  except
    on E:EInvalidOperation do
      MessageBeep(MB_ICONWARNING);
  end;
end;


{ TAppSettings }

constructor TAppSettings.Create;
var
  rx: TRegExpr;
  i: Integer;
  DefaultSnippetsDirectory: String;
  PortableLockFile: String;
  NewFileHandle: THandle;
begin
  inherited;
  FRegistry := TRegistry.Create;
  FReads := 0;
  FWrites := 0;

  PortableLockFile := ExtractFilePath(ParamStr(0)) + FPortableLockFileBase;

  // Use filename from command line. If not given, use file in directory of executable.
  rx := TRegExpr.Create;
  rx.Expression := '^\-\-?psettings\=(.+)$';
  for i:=1 to ParamCount do begin
    if rx.Exec(ParamStr(i)) then begin
      FSettingsFile := rx.Match[1];
      break;
    end;
  end;
  // Default settings file, if not given per command line
  if FSettingsFile = '' then
    FSettingsFile := ExtractFilePath(ParamStr(0)) + 'portable_settings.txt';
  // Backwards compatibility: only settings file exists, create lock file in that case
  if FileExists(FSettingsFile) and (not FileExists(PortableLockFile)) then begin
    NewFileHandle := FileCreate(PortableLockFile);
    FileClose(NewFileHandle);
  end;

  // Switch to portable mode if lock file exists. File content is ignored.
  FPortableMode := FileExists(PortableLockFile);
  FPortableModeReadOnly := False;

  if FPortableMode then begin
    // Create file if only the lock file exists
    if not FileExists(FSettingsFile) then begin
      NewFileHandle := FileCreate(FSettingsFile);
      FileClose(NewFileHandle);
    end;
    FBasePath := '\Software\' + APPNAME + ' Portable '+IntToStr(GetCurrentProcessId)+'\';
    try
      ImportSettings(FSettingsFile);
    except
      on E:Exception do
        MessageDlg(E.Message, mtError, [mbOK], 0, mbOK);
    end;
  end else begin
    FBasePath := '\Software\' + APPNAME + '\';
    FSettingsFile := '';
  end;

  PrepareRegistry;

  InitSetting(asHiddenColumns,                    'HiddenColumns',                         0, False, '', True);
  InitSetting(asFilter,                           'Filter',                                0, False, '', True);
  InitSetting(asSort,                             'Sort',                                  0, False, '', True);
  InitSetting(asDisplayedColumnsSorted,           'DisplayedColumnsSorted',                0, False);
  InitSetting(asLastSessions,                     'LastSessions',                          0, False, '');
  InitSetting(asLastActiveSession,                'LastActiveSession',                     0, False, '');
  InitSetting(asAutoReconnect,                    'AutoReconnect',                         0, False);
  InitSetting(asRestoreLastUsedDB,                'RestoreLastUsedDB',                     0, True);
  InitSetting(asLastUsedDB,                       'lastUsedDB',                            0, False, '', True);
  InitSetting(asTreeBackground,                   'TreeBackground',                        clNone, False, '', True);
  InitSetting(asIgnoreDatabasePattern,            'IgnoreDatabasePattern',                 0, False, '', True);
  InitSetting(asLogFileDdl,                       'LogFileDdl',                            0, False, '', True);
  InitSetting(asLogFileDml,                       'LogFileDml',                            0, False, '', True);
  InitSetting(asLogFilePath,                      'LogFilePath',                           0, False, DirnameUserAppData + 'Logs\%session\%db\%y%m%d.sql', True);
  if Screen.Fonts.IndexOf('Consolas') > -1 then
    InitSetting(asFontName,                       'FontName',                              0, False, 'Consolas')
  else
    InitSetting(asFontName,                       'FontName',                              0, False, 'Courier New');
  InitSetting(asFontSize,                         'FontSize',                              9);
  InitSetting(asTabWidth,                         'TabWidth',                              3);
  InitSetting(asDataFontName,                     'DataFontName',                          0, False, 'Tahoma');
  InitSetting(asDataFontSize,                     'DataFontSize',                          8);
  InitSetting(asDataLocalNumberFormat,            'DataLocalNumberFormat',                 0, True);
  InitSetting(asLowercaseHex,                     'LowercaseHex',                          0, True);
  InitSetting(asHintsOnResultTabs,                'HintsOnResultTabs',                     0, True);
  InitSetting(asShowRowId,                        'ShowRowId',                             0, True);
  InitSetting(asHightlightSameTextBackground,     'HightlightSameTextBackground',          GetThemeColor(clInfoBk));
  InitSetting(asLogsqlnum,                        'logsqlnum',                             300);
  InitSetting(asLogsqlwidth,                      'logsqlwidth',                           2000);
  InitSetting(asSessionLogsDirectory,             'SessionLogsDirectory',                  0, False, DirnameUserAppData + 'Sessionlogs\');
  InitSetting(asLogHorizontalScrollbar,           'LogHorizontalScrollbar',                0, False);
  InitSetting(asSQLColActiveLine,                 'SQLColActiveLine',                      0, False, 'clNone');
  InitSetting(asSQLColMatchingBraceForeground,    'SQLColMatchingBraceForeground',         0, False, 'clBlack');
  InitSetting(asSQLColMatchingBraceBackground,    'SQLColMatchingBraceBackground',         0, False, 'clAqua');
  InitSetting(asMaxColWidth,                      'MaxColWidth',                           300);
  InitSetting(asDatagridMaximumRows,              'DatagridMaximumRows',                   100000);
  InitSetting(asDatagridRowsPerStep,              'DatagridRowsPerStep',                   1000);
  InitSetting(asGridRowLineCount,                 'GridRowLineCount',                      1);
  InitSetting(asColumnHeaderClick,                'ColumnHeaderClick',                     0, True);
  InitSetting(asReuseEditorConfiguration,         'ReuseEditorConfiguration',              0, True);
  InitSetting(asLogToFile,                        'LogToFile',                             0, False);
  InitSetting(asMainWinMaximized,                 'MainWinMaximized',                      0, False);
  InitSetting(asMainWinLeft,                      'MainWinLeft',                           100);
  InitSetting(asMainWinTop,                       'MainWinTop',                            100);
  InitSetting(asMainWinWidth,                     'MainWinWidth',                          950);
  InitSetting(asMainWinHeight,                    'MainWinHeight',                         600);
  InitSetting(asMainWinOnMonitor,                 'MainWinOnMonitor',                      1);
  InitSetting(asCoolBandIndex,                    'CoolBand%sIndex',                       0);
  InitSetting(asCoolBandBreak,                    'CoolBand%sBreak',                       0, True);
  InitSetting(asCoolBandWidth,                    'CoolBand%sWidth',                       0);
  InitSetting(asToolbarShowCaptions,              'ToolbarShowCaptions',                   0, False);
  InitSetting(asQuerymemoheight,                  'querymemoheight',                       100);
  InitSetting(asDbtreewidth,                      'dbtreewidth',                           270);
  InitSetting(asDataPreviewHeight,                'DataPreviewHeight',                     100);
  InitSetting(asDataPreviewEnabled,               'DataPreviewEnabled',                    0, False);
  InitSetting(asLogHeight,                        'sqloutheight',                          80);
  InitSetting(asQueryhelperswidth,                'queryhelperswidth',                     200);
  InitSetting(asProjectManagerWidth,              'projectmanagerwidth',                   260);
  InitSetting(asProjectManagerVisible,            'projectmanagervisible',                 0, True);
  InitSetting(asStopOnErrorsInBatchMode,          'StopOnErrorsInBatchMode',               0, True);
  InitSetting(asWrapLongLines,                    'WrapLongLines',                         0, False);
  InitSetting(asCodeFolding,                      'CodeFolding',                           0, True);
  InitSetting(asDisplayBLOBsAsText,               'DisplayBLOBsAsText',                    0, True);
  InitSetting(asSingleQueries,                    'SingleQueries',                         0, True);
  InitSetting(asMemoEditorWidth,                  'MemoEditorWidth',                       500);
  InitSetting(asMemoEditorHeight,                 'MemoEditorHeight',                      200);
  InitSetting(asMemoEditorMaximized,              'MemoEditorMaximized',                   0, False);
  InitSetting(asMemoEditorWrap,                   'MemoEditorWrap',                        0, False);
  InitSetting(asMemoEditorHighlighter,            'MemoEditorHighlighter_%s',              0, False, 'General', True);
  InitSetting(asMemoEditorAlwaysFormatCode,       'MemoEditorAlwaysFormatCode',            0, False);
  InitSetting(asDelimiter,                        'Delimiter',                             0, False, ';');
  InitSetting(asSQLHelpWindowLeft,                'SQLHelp_WindowLeft',                    0);
  InitSetting(asSQLHelpWindowTop,                 'SQLHelp_WindowTop',                     0);
  InitSetting(asSQLHelpWindowWidth,               'SQLHelp_WindowWidth',                   600);
  InitSetting(asSQLHelpWindowHeight,              'SQLHelp_WindowHeight',                  400);
  InitSetting(asSQLHelpPnlLeftWidth,              'SQLHelp_PnlLeftWidth',                  150);
  InitSetting(asSQLHelpPnlRightTopHeight,         'SQLHelp_PnlRightTopHeight',             150);
  InitSetting(asHost,                             'Host',                                  0, False, '', True);
  InitSetting(asUser,                             'User',                                  0, False, '', True);
  InitSetting(asPassword,                         'Password',                              0, False, '', True);
  InitSetting(asCleartextPluginEnabled,           'CleartextPluginEnabled',                0, False, '', True);
  InitSetting(asWindowsAuth,                      'WindowsAuth',                           0, False, '', True);
  InitSetting(asLoginPrompt,                      'LoginPrompt',                           0, False, '', True);
  InitSetting(asPort,                             'Port',                                  0, False, '', True);
  InitSetting(asLibrary,                          'Library',                               0, False, '', True); // Gets its default in TConnectionParameters.Create
  InitSetting(asAllProviders,                     'AllProviders',                          0, False);
  InitSetting(asSSHtunnelActive,                  'SSHtunnelActive',                       -1, False, '', True);
  InitSetting(asPlinkExecutable,                  'PlinkExecutable',                       0, False, 'plink.exe'); // Legacy support with global setting
  InitSetting(asSshExecutable,                    'SshExecutable',                         0, False, '', True);
  InitSetting(asSSHtunnelHost,                    'SSHtunnelHost',                         0, False, '', True);
  InitSetting(asSSHtunnelHostPort,                'SSHtunnelHostPort',                     22, False, '', True);
  InitSetting(asSSHtunnelPort,                    'SSHtunnelPort',                         0, False, '', True);
  InitSetting(asSSHtunnelUser,                    'SSHtunnelUser',                         0, False, '', True);
  InitSetting(asSSHtunnelPassword,                'SSHtunnelPassword',                     0, False, '', True);
  InitSetting(asSSHtunnelTimeout,                 'SSHtunnelTimeout',                      4, False, '', True);
  InitSetting(asSSHtunnelPrivateKey,              'SSHtunnelPrivateKey',                   0, False, '', True);
  InitSetting(asSSLActive,                        'SSL_Active',                            0, False, '', True);
  InitSetting(asSSLKey,                           'SSL_Key',                               0, False, '', True);
  InitSetting(asSSLCert,                          'SSL_Cert',                              0, False, '', True);
  InitSetting(asSSLCA,                            'SSL_CA',                                0, False, '', True);
  InitSetting(asSSLCipher,                        'SSL_Cipher',                            0, False, '', True);
  InitSetting(asSSLVerification,                  'SSL_Verification',                      2, False, '', True);
  InitSetting(asSSLWarnUnused,                    'SSL_WarnUnused',                        0, True);
  InitSetting(asNetType,                          'NetType',                               Integer(ntMySQL_TCPIP), False, '', True);
  InitSetting(asCompressed,                       'Compressed',                            0, False, '', True);
  InitSetting(asLocalTimeZone,                    'LocalTimeZone',                         0, False, '', True);
  InitSetting(asQueryTimeout,                     'QueryTimeout',                          30, False, '', True);
  InitSetting(asKeepAlive,                        'KeepAlive',                             20, False, '', True);
  InitSetting(asStartupScriptFilename,            'StartupScriptFilename',                 0, False, '', True);
  InitSetting(asDatabases,                        'Databases',                             0, False, '', True);
  InitSetting(asComment,                          'Comment',                               0, False, '', True);
  InitSetting(asDatabaseFilter,                   'DatabaseFilter',                        0, False, '');
  InitSetting(asTableFilter,                      'TableFilter',                           0, False, '');
  InitSetting(asFilterVT,                         'FilterVTHistory',                       0, False, '');
  InitSetting(asExportSQLCreateDatabases,         'ExportSQL_CreateDatabases',             0, False);
  InitSetting(asExportSQLCreateTables,            'ExportSQL_CreateTables',                0, False);
  InitSetting(asExportSQLDataHow,                 'ExportSQL_DataHow',                     0);
  InitSetting(asExportSQLDataInsertSize,          'ExportSQL_DataInsertSize',              1024);
  InitSetting(asExportSQLFilenames,               'ExportSQL_Filenames',                   0, False, '');
  InitSetting(asExportZIPFilenames,               'ExportSQL_ZipFilenames',                0, False, '');
  InitSetting(asExportSQLDirectories,             'ExportSQL_Directories',                 0, False, '');
  InitSetting(asExportSQLDatabase,                'ExportSQL_Database',                    0, False, '');
  InitSetting(asExportSQLServerDatabase,          'ExportSQL_ServerDatabase',              0, False, '');
  InitSetting(asExportSQLOutput,                  'ExportSQL_Output',                      0);
  InitSetting(asExportSQLAddComments,             'ExportSQLAddComments',                  0, True);
  InitSetting(asExportSQLRemoveAutoIncrement,     'ExportSQLRemoveAutoIncrement',          0, False);
  InitSetting(asExportSQLRemoveDefiner,           'ExportSQLRemoveDefiner',                0, True);
  InitSetting(asGridExportWindowWidth,            'GridExportWindowWidth',                 400);
  InitSetting(asGridExportWindowHeight,           'GridExportWindowHeight',                480);
  InitSetting(asGridExportOutputCopy,             'GridExportOutputCopy',                  0, True);
  InitSetting(asGridExportOutputFile,             'GridExportOutputFile',                  0, False);
  InitSetting(asGridExportFilename,               'GridExportFilename',                    0, False, '');
  InitSetting(asGridExportRecentFiles,            'GridExportRecentFiles',                 0, False, '');
  InitSetting(asGridExportEncoding,               'GridExportEncoding',                    4);
  InitSetting(asGridExportFormat,                 'GridExportFormat',                      0);
  InitSetting(asGridExportSelection,              'GridExportSelection',                   1);
  InitSetting(asGridExportColumnNames,            'GridExportColumnNames',                 0, True);
  InitSetting(asGridExportIncludeAutoInc,         'GridExportAutoInc',                     0, True);
  InitSetting(asGridExportIncludeQuery,           'GridExportIncludeQuery',                0, False);
  InitSetting(asGridExportRemoveLinebreaks,       'GridExportRemoveLinebreaks',            0, False);
  InitSetting(asGridExportSeparator,              'GridExportSeparator',                   0, False, ';');
  InitSetting(asGridExportEncloser,               'GridExportEncloser',                    0, False, '');
  InitSetting(asGridExportTerminator,             'GridExportTerminator',                  0, False, '\r\n');
  InitSetting(asGridExportNull,                   'GridExportNull',                        0, False, '\N');
  // Copy to clipboard defaults:
  InitSetting(asGridExportClpColumnNames,         'GridExportClpColumnNames',              0, True);
  InitSetting(asGridExportClpIncludeAutoInc,      'GridExportClpAutoInc',                  0, True);
  InitSetting(asGridExportClpRemoveLinebreaks,    'GridExportClpRemoveLinebreaks',         0, False);
  InitSetting(asGridExportClpSeparator,           'GridExportClpSeparator',                0, False, ';');
  InitSetting(asGridExportClpEncloser,            'GridExportClpEncloser',                 0, False, '');
  InitSetting(asGridExportClpTerminator,          'GridExportClpTerminator',               0, False, '\r\n');
  InitSetting(asGridExportClpNull,                'GridExportClpNull',                     0, False, '\N');

  InitSetting(asCSVImportSeparator,               'CSVSeparatorV2',                        0, False, ';');
  InitSetting(asCSVImportEncloser,                'CSVEncloserV2',                         0, False, '"');
  InitSetting(asCSVImportTerminator,              'CSVTerminator',                         0, False, '\r\n');
  InitSetting(asCSVImportFieldEscaper,            'CSVImportFieldEscaperV2',               0, False, '"');
  InitSetting(asCSVImportWindowWidth,             'CSVImportWindowWidth',                  530);
  InitSetting(asCSVImportWindowHeight,            'CSVImportWindowHeight',                 550);
  InitSetting(asCSVImportFilename,                'loadfilename',                          0, False, '');
  InitSetting(asCSVImportFieldsEnclosedOptionally, 'CSVImportFieldsEnclosedOptionallyV2',  0, True);
  InitSetting(asCSVImportIgnoreLines,             'CSVImportIgnoreLines',                  1);
  InitSetting(asCSVImportLowPriority,             'CSVImportLowPriority',                  0, True);
  InitSetting(asCSVImportLocalNumbers,            'CSVImportLocalNumbers',                 0, False);
  InitSetting(asCSVImportDuplicateHandling,       'CSVImportDuplicateHandling',            2);
  InitSetting(asCSVImportParseMethod,             'CSVImportParseMethod',                  0);
  InitSetting(asCSVKeepDialogOpen,                'CSVKeepDialogOpen',                     0, False);
  InitSetting(asUpdatecheck,                      'Updatecheck',                           0, False);
  InitSetting(asUpdatecheckBuilds,                'UpdatecheckBuilds',                     0, False);
  InitSetting(asUpdatecheckInterval,              'UpdatecheckInterval',                   3);
  InitSetting(asUpdatecheckLastrun,               'UpdatecheckLastrun',                    0, False, DateToStr(DateTimeNever));
  InitSetting(asUpdateCheckWindowWidth,           'UpdateCheckWindowWidth',                400);
  InitSetting(asUpdateCheckWindowHeight,          'UpdateCheckWindowHeight',               460);
  InitSetting(asTableToolsWindowWidth,            'TableTools_WindowWidth',                800);
  InitSetting(asTableToolsWindowHeight,           'TableTools_WindowHeight',               420);
  InitSetting(asTableToolsTreeWidth,              'TableTools_TreeWidth',                  300);
  InitSetting(asTableToolsFindTextTab,            'TableToolsFindTextTab',                 0);
  InitSetting(asTableToolsFindText,               'TableTools_FindText',                   0, False, '');
  InitSetting(asTableToolsFindSQL,                'TableToolsFindSQL',                     0, False, '');
  InitSetting(asTableToolsDatatype,               'TableTools_Datatype',                   0);
  InitSetting(asTableToolsFindCaseSensitive,      'TableTools_FindCaseSensitive',          0, False);
  InitSetting(asTableToolsFindMatchType,          'TableToolsFindMatchType',               0);
  InitSetting(asFileImportWindowWidth,            'FileImport_WindowWidth',                530);
  InitSetting(asFileImportWindowHeight,           'FileImport_WindowHeight',               530);
  InitSetting(asEditVarWindowWidth,               'EditVar_WindowWidth',                   300);
  InitSetting(asEditVarWindowHeight,              'EditVar_WindowHeight',                  260);
  InitSetting(asUsermanagerWindowWidth,           'Usermanager_WindowWidth',               500);
  InitSetting(asUsermanagerWindowHeight,          'Usermanager_WindowHeight',              400);
  InitSetting(asUsermanagerListWidth,             'Usermanager_ListWidth',                 180);
  InitSetting(asSelectDBOWindowWidth,             'SelectDBO_WindowWidth',                 250);
  InitSetting(asSelectDBOWindowHeight,            'SelectDBO_WindowHeight',                350);
  InitSetting(asSessionManagerListWidth,          'SessionManager_ListWidth',              220);
  InitSetting(asSessionManagerWindowWidth,        'SessionManager_WindowWidth',            700);
  InitSetting(asSessionManagerWindowHeight,       'SessionManager_WindowHeight',           490);
  InitSetting(asSessionManagerWindowLeft,         'SessionManager_WindowLeft',             50);
  InitSetting(asSessionManagerWindowTop,          'SessionManager_WindowTop',              50);
  InitSetting(asCopyTableWindowHeight,            'CopyTable_WindowHeight',                340);
  InitSetting(asCopyTableWindowWidth,             'CopyTable_WindowWidth',                 380);
  InitSetting(asCopyTableColumns,                 'CopyTable_Columns',                     0, True);
  InitSetting(asCopyTableKeys,                    'CopyTable_Keys',                        0, True);
  InitSetting(asCopyTableForeignKeys,             'CopyTable_ForeignKeys',                 0, True);
  InitSetting(asCopyTableData,                    'CopyTable_Data',                        0, True);
  InitSetting(asCopyTableRecentFilter,            'CopyTable_RecentFilter_%s',             0, False, '');
  InitSetting(asServerVersion,                    'ServerVersion',                         0, False, '', True);
  InitSetting(asServerVersionFull,                'ServerVersionFull',                     0, False, '', True);
  InitSetting(asLastConnect,                      'LastConnect',                           0, False, DateToStr(DateTimeNever), True);
  InitSetting(asConnectCount,                     'ConnectCount',                          0, False, '', True);
  InitSetting(asRefusedCount,                     'RefusedCount',                          0, False, '', True);
  InitSetting(asSessionCreated,                   'SessionCreated',                        0, False, '', True);
  InitSetting(asDoUsageStatistics,                'DoUsageStatistics',                     0, False);
  InitSetting(asLastUsageStatisticCall,           'LastUsageStatisticCall',                0, False, DateToStr(DateTimeNever));
  InitSetting(asWheelZoom,                        'WheelZoom',                             0, True);
  InitSetting(asDisplayBars,                      'DisplayBars',                           0, true);
  InitSetting(asMySQLBinaries,                    'MySQL_Binaries',                        0, False, '');
  InitSetting(asSequalSuggestWindowWidth,         'SequalSuggestWindowWidth',              500);
  InitSetting(asSequalSuggestWindowHeight,        'SequalSuggestWindowHeight',             400);
  InitSetting(asSequalSuggestPrompt,              'SequalSuggestPrompt',                   0, False, '');
  InitSetting(asSequalSuggestRecentPrompts,       'SequalSuggestRecentPrompts',            0, False, '');
  InitSetting(asReformatter,                      'Reformatter',                           0);
  InitSetting(asReformatterNoDialog,              'ReformatterNoDialog',                   0);
  InitSetting(asAlwaysGenerateFilter,             'AlwaysGenerateFilter',                  0, False);
  InitSetting(asGenerateDataNumRows,              'GenerateDataNumRows',                   1000);
  InitSetting(asGenerateDataNullAmount,           'GenerateDataNullAmount',                10);

  // Default folder for snippets
  if FPortableMode then
    DefaultSnippetsDirectory := ExtractFilePath(ParamStr(0))
  else
    DefaultSnippetsDirectory := DirnameUserDocuments;
  DefaultSnippetsDirectory := DefaultSnippetsDirectory + 'Snippets\';
  InitSetting(asCustomSnippetsDirectory,          'CustomSnippetsDirectory',               0, False, DefaultSnippetsDirectory);
  InitSetting(asPromptSaveFileOnTabClose,         'PromptSaveFileOnTabClose',              0, True);
  // Restore tabs feature crashes often on old XP systems, see https://www.heidisql.com/forum.php?t=34044
  InitSetting(asRestoreTabs,                      'RestoreTabs',                           0, Win32MajorVersion >= 6);
  InitSetting(asTabCloseOnDoubleClick,            'TabCloseOnDoubleClick',                 0, True);
  InitSetting(asTabCloseOnMiddleClick,            'TabCloseOnMiddleClick',                 0, True);
  InitSetting(asTabsInMultipleLines,              'TabsInMultipleLines',                   0, True);
  InitSetting(asTabIconsGrayscaleMode,            'TabIconsGrayscaleMode',                 1);
  InitSetting(asWarnUnsafeUpdates,                'WarnUnsafeUpdates',                     0, True);
  InitSetting(asQueryGridLongSortRowNum,          'QueryGridLongSortRowNum',               10000);
  InitSetting(asCompletionProposal,               'CompletionProposal',                    0, True);
  InitSetting(asCompletionProposalInterval,       'CompletionProposalInterval',            500);
  InitSetting(asCompletionProposalSearchOnMid,    'CompletionProposalSearchOnMid',         0, True);
  InitSetting(asCompletionProposalWidth,          'CompletionProposalWidth',               350);
  InitSetting(asCompletionProposalNbLinesInWindow,'CompletionProposalNbLinesInWindow',     12);
  InitSetting(asAutoUppercase,                    'AutoUppercase',                         0, True);
  InitSetting(asTabsToSpaces,                     'TabsToSpaces',                          0, False);
  InitSetting(asFilterPanel,                      'FilterPanel',                           0, True);
  InitSetting(asAllowMultipleInstances,           'AllowMultipleInstances',                0, True);
  InitSetting(asFindDialogSearchHistory,          'FindDialogSearchHistory',               0, False, '');
  InitSetting(asFindDialogReplaceHistory,         'FindDialogReplaceHistory',              0, False, '');
  InitSetting(asGUIFontName,                      'GUIFontName',                           0, False, '');
  InitSetting(asGUIFontSize,                      'GUIFontSize',                           8);
  InitSetting(asTheme,                            'Theme',                                 0, False, 'Windows');
  InitSetting(asIconPack,                         'IconPack',                              0, False, 'Icons8');
  InitSetting(asWebSearchBaseUrl,                 'WebSearchBaseUrl',                      0, False, 'https://www.ecosia.org/search?q=%query');
  InitSetting(asMaxQueryResults,                  'MaxQueryResults',                       10);
  InitSetting(asLogErrors,                        'LogErrors',                             0, True);
  InitSetting(asLogUserSQL,                       'LogUserSQL',                            0, True);
  InitSetting(asLogSQL,                           'LogSQL',                                0, True);
  InitSetting(asLogScript,                        'LogScript',                             0, False);
  InitSetting(asLogInfos,                         'LogInfos',                              0, True);
  InitSetting(asLogDebug,                         'LogDebug',                              0, False);
  InitSetting(asLogTimestamp,                     'LogTimestamp',                          0, False);
  InitSetting(asFieldColorNumeric,                'FieldColor_Numeric',                    $00FF0000);
  InitSetting(asFieldColorReal,                   'FieldColor_Real',                       $00FF0048);
  InitSetting(asFieldColorText,                   'FieldColor_Text',                       $00008000);
  InitSetting(asFieldColorBinary,                 'FieldColor_Binary',                     $00800080);
  InitSetting(asFieldColorDatetime,               'FieldColor_Datetime',                   $00000080);
  InitSetting(asFieldColorSpatial,                'FieldColor_Spatial',                    $00808000);
  InitSetting(asFieldColorOther,                  'FieldColor_Other',                      $00008080);
  InitSetting(asFieldEditorBinary,                'FieldEditor_Binary',                    0, True);
  InitSetting(asFieldEditorDatetime,              'FieldEditor_Datetime',                  0, True);
  InitSetting(asFieldEditorDatetimePrefill,       'FieldEditor_Datetime_Prefill',          0, True);
  InitSetting(asFieldEditorEnum,                  'FieldEditor_Enum',                      0, True);
  InitSetting(asFieldEditorSet,                   'FieldEditor_Set',                       0, True);
  InitSetting(asFieldNullBackground,              'Field_NullBackground',                  clNone);
  InitSetting(asRowBackgroundEven,                'RowBackgroundEven',                     clNone);
  InitSetting(asRowBackgroundOdd,                 'RowBackgroundOdd',                      clNone);
  InitSetting(asGroupTreeObjects,                 'GroupTreeObjects',                      0, False);
  InitSetting(asDisplayObjectSizeColumn,          'DisplayObjectSizeColumn',               0, True);
  InitSetting(asActionShortcut1,                  'Shortcut1_%s',                          0);
  InitSetting(asActionShortcut2,                  'Shortcut2_%s',                          0);
  InitSetting(asHighlighterForeground,            'SQL Attr %s Foreground',                0);
  InitSetting(asHighlighterBackground,            'SQL Attr %s Background',                0);
  InitSetting(asHighlighterStyle,                 'SQL Attr %s Style',                     0);
  InitSetting(asSQLfile,                          'SQLFile%s',                             0, False, '');
  InitSetting(asListColWidths,                    'ColWidths_%s',                          0, False, '');
  InitSetting(asListColsVisible,                  'ColsVisible_%s',                        0, False, '');
  InitSetting(asListColPositions,                 'ColPositions_%s',                       0, False, '');
  InitSetting(asListColSort,                      'ColSort_%s',                            0, False, '');
  InitSetting(asSessionFolder,                    'Folder',                                0, False, '', True);
  InitSetting(asRecentFilter,                     '%s',                                    0, False, '', True);
  InitSetting(asTimestampColumns,                 'TimestampColumns',                      0, False, '', True);
  InitSetting(asDateTimeEditorCursorPos,          'DateTimeEditor_CursorPos_Type%s',       0);
  InitSetting(asAppLanguage,                      'Language',                              0, False, '');
  InitSetting(asAutoExpand,                       'AutoExpand',                            0, False);
  InitSetting(asDoubleClickInsertsNodeText,       'DoubleClickInsertsNodeText',            0, True);
  InitSetting(asForeignDropDown,                  'ForeignDropDown',                       0, True);
  InitSetting(asIncrementalSearch,                'IncrementalSearch',                     0, True);
  InitSetting(asQueryHistoryEnabled,              'QueryHistory',                          0, True);
  InitSetting(asQueryHistoryKeepDays,             'QueryHistoryKeeypDays',                 30);
  InitSetting(asColumnSelectorWidth,              'ColumnSelectorWidth',                   200, False, '');
  InitSetting(asColumnSelectorHeight,             'ColumnSelectorHeight',                  270, False, '');
  InitSetting(asDonatedEmail,                     'DonatedEmail',                          0, False, '');
  InitSetting(asFavoriteObjects,                  'FavoriteObjects',                       0, False, '', True);
  InitSetting(asFavoriteObjectsOnly,              'FavoriteObjectsOnly',                   0, False); // No longer used
  InitSetting(asFullTableStatus,                  'FullTableStatus',                       0, True, '', True);
  InitSetting(asLineBreakStyle,                   'LineBreakStyle',                        Integer(lbsWindows));
  InitSetting(asPreferencesWindowWidth,           'PreferencesWindowWidth',                740);
  InitSetting(asPreferencesWindowHeight,          'PreferencesWindowHeight',               500);
  InitSetting(asFileDialogEncoding,               'FileDialogEncoding_%s',                 0);
  InitSetting(asThemePreviewWidth,                'ThemePreviewWidth',                     300);
  InitSetting(asThemePreviewHeight,               'ThemePreviewHeight',                    200);
  InitSetting(asThemePreviewTop,                  'ThemePreviewTop',                       300);
  InitSetting(asThemePreviewLeft,                 'ThemePreviewLeft',                      300);
  InitSetting(asCreateDbCollation,                'CreateDbCollation',                     0, False, '');
  InitSetting(asRealTrailingZeros,                'RealTrailingZeros',                     1);
  InitSetting(asWebOnceAction,                    'WebOnceAction',                         0, False, DateToStr(DateTimeNever));
  InitSetting(asProjectManagerHeight,             'ProjectManagerHeight',                 200);

  // Initialization values
  FRestoreTabsInitValue := ReadBool(asRestoreTabs);

end;


destructor TAppSettings.Destroy;
var
  AllKeys: TStringList;
  i: Integer;
  Proc: TProcessEntry32;
  ProcRuns: Boolean;
  SnapShot: THandle;
  rx: TRegExpr;
begin
  // Export settings into textfile in portable mode.
  if FPortableMode then try
    try
      ExportSettings;
    except
      // do nothing, even ShowMessage or ErrorDialog would trigger timer events followed by crashes;
    end;
    FRegistry.CloseKey;
    FRegistry.DeleteKey(FBasePath);

    // Remove dead keys from instances which didn't close clean, e.g. because of an AV
    SnapShot := CreateToolhelp32Snapshot(TH32CS_SnapProcess, 0);
    Proc.dwSize := Sizeof(Proc);
    FRegistry.OpenKeyReadOnly('\Software\');
    AllKeys := TStringList.Create;
    FRegistry.GetKeyNames(AllKeys);
    rx := TRegExpr.Create;
    rx.Expression := '^' + QuoteRegExprMetaChars(APPNAME) + ' Portable (\d+)$';
    for i:=0 to AllKeys.Count-1 do begin
      if not rx.Exec(AllKeys[i]) then
        Continue;
      ProcRuns := False;
      if Process32First(SnapShot, Proc) then while True do begin
        ProcRuns := rx.Match[1] = IntToStr(Proc.th32ProcessID);
        if ProcRuns or (not Process32Next(SnapShot, Proc)) then
          break;
      end;
      if not ProcRuns then
        FRegistry.DeleteKey(AllKeys[i]);
    end;
    FRegistry.CloseKey;
    CloseHandle(SnapShot);
    AllKeys.Free;
    rx.Free;
  except
    on E:Exception do // Prefer ShowMessage, see http://www.heidisql.com/forum.php?t=14001
      ShowMessage('Error: '+E.Message);
  end;
  FRegistry.Free;
  inherited;
end;


procedure TAppSettings.InitSetting(Index: TAppSettingIndex; Name: String;
  DefaultInt: Integer=0; DefaultBool: Boolean=False; DefaultString: String='';
  Session: Boolean=False);
begin
  FSettings[Index].Name := Name;
  FSettings[Index].Session := Session;
  FSettings[Index].DefaultInt := DefaultInt;
  FSettings[Index].DefaultBool := DefaultBool;
  FSettings[Index].DefaultString := DefaultString;
  FSettings[Index].Synced := False;
end;


procedure TAppSettings.SetSessionPath(Value: String);
begin
  // Following calls may want to read or write some session specific setting
  if Value <> FSessionPath then begin
    FSessionPath := Value;
    PrepareRegistry;
  end;
end;


procedure TAppSettings.ResetPath;
begin
  SessionPath := '';
end;


procedure TAppSettings.StorePath;
begin
  FStoredPath := SessionPath;
end;

procedure TAppSettings.RestorePath;
begin
  SessionPath := FStoredPath;
end;


procedure TAppSettings.PrepareRegistry;
var
  Folder: String;
begin
  // Open the wanted registry path
  Folder := FBasePath;
  if FSessionPath <> '' then
    Folder := Folder + REGKEY_SESSIONS + '\' + FSessionPath;
  if '\'+FRegistry.CurrentPath <> Folder then try
    FRegistry.OpenKey(Folder, True);
  except
    on E:Exception do begin
      // Recreate exception with a more useful message
      E.Message := E.Message + CRLF + CRLF + 'While trying to open registry key "'+Folder+'"';
      raise;
    end;
  end;
end;


function TAppSettings.GetValueNames: TStringList;
begin
  PrepareRegistry;
  Result := TStringList.Create;
  FRegistry.GetValueNames(Result);
end;


function TAppSettings.GetValueName(Index: TAppSettingIndex): String;
begin
  Result := FSettings[Index].Name;
end;


function TAppSettings.GetKeyNames: TStringList;
begin
  PrepareRegistry;
  Result := TStringList.Create;
  FRegistry.GetKeyNames(Result);
end;


function TAppSettings.DeleteValue(Index: TAppSettingIndex; FormatName: String=''): Boolean;
var
  ValueName: String;
begin
  PrepareRegistry;
  ValueName := GetValueName(Index);
  if FormatName <> '' then
    ValueName := Format(ValueName, [FormatName]);
  Result := FRegistry.DeleteValue(ValueName);
  FSettings[Index].Synced := False;
end;


function TAppSettings.DeleteValue(ValueName: String): Boolean;
begin
  Result := FRegistry.DeleteValue(ValueName);
end;


procedure TAppSettings.DeleteCurrentKey;
var
  KeyPath: String;
begin
  // Delete the current registry key
  // Note that, contrary to the documentation, .DeleteKey is done even when this key has subkeys
  PrepareRegistry;
  if FSessionPath.IsEmpty then
    raise Exception.CreateFmt(_('No path set, won''t delete root key %s'), [FRegistry.CurrentPath])
  else begin
    KeyPath := REGKEY_SESSIONS + '\' + FSessionPath;
    ResetPath;
    FRegistry.DeleteKey(KeyPath);
  end;
end;


procedure TAppSettings.MoveCurrentKey(TargetPath: String);
var
  KeyPath: String;
begin
  PrepareRegistry;
  if FSessionPath.IsEmpty then
    raise Exception.CreateFmt(_('No path set, won''t move root key %s'), [FRegistry.CurrentPath])
  else begin
    KeyPath := REGKEY_SESSIONS + '\' + FSessionPath;
    ResetPath;
    FRegistry.MoveKey(KeyPath, TargetPath, True);
  end;
end;


function TAppSettings.ValueExists(Index: TAppSettingIndex): Boolean;
var
  ValueName: String;
begin
  PrepareRegistry;
  ValueName := GetValueName(Index);
  Result := FRegistry.ValueExists(ValueName);
end;


function TAppSettings.SessionPathExists(SessionPath: String): Boolean;
begin
  Result := FRegistry.KeyExists(FBasePath + REGKEY_SESSIONS + '\' + SessionPath);
end;


function TAppSettings.IsEmptyKey: Boolean;
var
  TestList: TStringList;
begin
  TestList := GetValueNames;
  Result := (not FRegistry.HasSubKeys) and (TestList.Count = 0);
  TestList.Free;
end;


function TAppSettings.GetDefaultInt(Index: TAppSettingIndex): Integer;
begin
  // Return default integer value
  Result := FSettings[Index].DefaultInt;
end;


function TAppSettings.GetDefaultBool(Index: TAppSettingIndex): Boolean;
begin
  // Return default boolean value
  Result := FSettings[Index].DefaultBool;
end;


function TAppSettings.GetDefaultString(Index: TAppSettingIndex): String;
begin
  // Return default string value
  Result := FSettings[Index].DefaultString;
end;


procedure TAppSettings.Read(Index: TAppSettingIndex; FormatName: String;
  DataType: TAppSettingDataType; var I: Integer; var B: Boolean; var S: String;
  DI: Integer; DB: Boolean; DS: String);
var
  ValueName: String;
begin
  // Read user setting value from registry
  I := FSettings[Index].DefaultInt;
  B := FSettings[Index].DefaultBool;
  S := FSettings[Index].DefaultString;
  if DI<>0 then I := DI;
  if DB<>False then B := DB;
  if DS<>'' then S := DS;
  ValueName := FSettings[Index].Name;
  if FormatName <> '' then
    ValueName := Format(ValueName, [FormatName]);
  if FSettings[Index].Session and FSessionPath.IsEmpty then
    raise Exception.Create(_('Attempt to read session setting without session path'));
  if (not FSettings[Index].Session) and (not FSessionPath.IsEmpty) then
    SessionPath := ''
  else
    PrepareRegistry;
  if FSettings[Index].Synced then begin
    case DataType of
      adInt: I := FSettings[Index].CurrentInt;
      adBool: B := FSettings[Index].CurrentBool;
      adString: S := FSettings[Index].CurrentString;
      else raise Exception.CreateFmt(_(SUnsupportedSettingsDatatype), [FSettings[Index].Name]);
    end;
  end else if FRegistry.ValueExists(ValueName) then begin
    Inc(FReads);
    case DataType of
      adInt: I := FRegistry.ReadInteger(ValueName);
      adBool: B := FRegistry.ReadBool(ValueName);
      adString: S := FRegistry.ReadString(ValueName);
      else raise Exception.CreateFmt(_(SUnsupportedSettingsDatatype), [FSettings[Index].Name]);
    end;
  end;
  if (FormatName = '') and (FSessionPath = '') then begin
    FSettings[Index].Synced := True;
    FSettings[Index].CurrentInt := I;
    FSettings[Index].CurrentBool := B;
    FSettings[Index].CurrentString := S;
  end;
end;


function TAppSettings.ReadInt(Index: TAppSettingIndex; FormatName: String=''; Default: Integer=0): Integer;
var
  S: String;
  B: Boolean;
begin
  Read(Index, FormatName, adInt, Result, B, S, Default, False, '');
end;


function TAppSettings.ReadIntDpiAware(Index: TAppSettingIndex; AControl: TControl; FormatName: String=''; Default: Integer=0): Integer;
begin
  Result := ReadInt(Index, FormatName, Default);
  Result := Round(Result * AControl.ScaleFactor);
end;


function TAppSettings.ReadBool(Index: TAppSettingIndex; FormatName: String=''; Default: Boolean=False): Boolean;
var
  I: Integer;
  S: String;
begin
  Read(Index, FormatName, adBool, I, Result, S, 0, Default, '');
end;


function TAppSettings.ReadString(Index: TAppSettingIndex; FormatName: String=''; Default: String=''): String;
var
  I: Integer;
  B: Boolean;
begin
  Read(Index, FormatName, adString, I, B, Result, 0, False, Default);
end;


function TAppSettings.ReadString(ValueName: String): String;
begin
  PrepareRegistry;
  Result := FRegistry.ReadString(ValueName);
end;


procedure TAppSettings.Write(Index: TAppSettingIndex; FormatName: String;
  DataType: TAppSettingDataType; I: Integer; B: Boolean; S: String);
var
  ValueName: String;
  SameAsCurrent: Boolean;
begin
  // Write user setting value to registry
  ValueName := FSettings[Index].Name;
  if FormatName <> '' then
    ValueName := Format(ValueName, [FormatName]);
  if FSettings[Index].Session and FSessionPath.IsEmpty then
    raise Exception.Create(_('Attempt to write session setting without session path'));
  if (not FSettings[Index].Session) and (not FSessionPath.IsEmpty) then
    SessionPath := ''
  else
    PrepareRegistry;
  case DataType of
    adInt: begin
      SameAsCurrent := FSettings[Index].Synced and (I = FSettings[Index].CurrentInt);
      if not SameAsCurrent then begin
        FRegistry.WriteInteger(ValueName, I);
        Inc(FWrites);
      end;
      FSettings[Index].CurrentInt := I;
    end;
    adBool:  begin
      SameAsCurrent := FSettings[Index].Synced and (B = FSettings[Index].CurrentBool);
      if not SameAsCurrent then begin
        FRegistry.WriteBool(ValueName, B);
        Inc(FWrites);
      end;
      FSettings[Index].CurrentBool := B;
    end;
    adString: begin
      SameAsCurrent := FSettings[Index].Synced and (S = FSettings[Index].CurrentString);
      if not SameAsCurrent then begin
        FRegistry.WriteString(ValueName, S);
        Inc(FWrites);
      end;
      FSettings[Index].CurrentString := S;
    end;
    else
      raise Exception.CreateFmt(_(SUnsupportedSettingsDatatype), [FSettings[Index].Name]);
  end;
  if (FormatName = '') and (FSessionPath = '') then
    FSettings[Index].Synced := True;
end;


procedure TAppSettings.WriteInt(Index: TAppSettingIndex; Value: Integer; FormatName: String='');
begin
  Write(Index, FormatName, adInt, Value, False, '');
end;


procedure TAppSettings.WriteIntDpiAware(Index: TAppSettingIndex; AControl: TControl; Value: Integer; FormatName: String='');
begin
  Value := Round(Value / AControl.ScaleFactor);
  WriteInt(Index, Value, FormatName);
end;


procedure TAppSettings.WriteBool(Index: TAppSettingIndex; Value: Boolean; FormatName: String='');
begin
  Write(Index, FormatName, adBool, 0, Value, '');
end;


procedure TAppSettings.WriteString(Index: TAppSettingIndex; Value: String; FormatName: String='');
begin
  Write(Index, FormatName, adString, 0, False, Value);
end;


procedure TAppSettings.WriteString(ValueName, Value: String);
begin
  PrepareRegistry;
  FRegistry.WriteString(ValueName, Value);
end;


function TAppSettings.GetSessionNames(ParentPath: String; var Folders: TStringList): TStringList;
var
  i: Integer;
  CurPath: String;
begin
  ResetPath;
  CurPath := FBasePath + REGKEY_SESSIONS + '\' + ParentPath;
  FRegistry.OpenKey(CurPath, False);
  Result := TStringList.Create;
  FRegistry.GetKeyNames(Result);
  for i:=Result.Count-1 downto 0 do begin
    // Issue #1111 describes a recursive endless loop, which may be caused by an empty key name here?
    if Result[i].IsEmpty then
      Continue;
    // ... may also be caused by some non accessible key. Check result of .OpenKey before looking for "Folder" value:
    if FRegistry.OpenKey(CurPath+'\'+Result[i], False) then begin
      if FRegistry.ValueExists(GetValueName(asSessionFolder)) then begin
        Folders.Add(Result[i]);
        Result.Delete(i);
      end;
    end;
  end;
end;


procedure TAppSettings.GetSessionPaths(ParentPath: String; var Sessions: TStringList);
var
  Folders, Names: TStringList;
  i: Integer;
begin
  Folders := TStringList.Create;
  Names := GetSessionNames(ParentPath, Folders);
  for i:=0 to Names.Count-1 do
    Sessions.Add(ParentPath+Names[i]);
  for i:=0 to Folders.Count-1 do
    GetSessionPaths(ParentPath+Folders[i]+'\', Sessions);
  Sessions.Sort;
  Names.Free;
  Folders.Free;
end;


procedure TAppSettings.ImportSettings(Filename: String);
var
  Content, Name, Value, KeyPath: String;
  Lines, Segments: TStringList;
  i: Integer;
  DataType: TRegDataType;
begin
  // Load registry settings from file

  if not FileExists(Filename) then begin
    raise Exception.CreateFmt('File does not exist: %s', [Filename]);
  end;

  Content := ReadTextfile(FileName, UTF8NoBOMEncoding);
  Lines := Explode(CRLF, Content);
  for i:=0 to Lines.Count-1 do begin
    // Each line has 3 segments: reg path | data type | value. Continue if explode finds less or more than 3.
    Segments := Explode(DELIMITER, Lines[i]);
    if Segments.Count <> 3 then
      continue;
    KeyPath := FBasePath + ExtractFilePath(Segments[0]);
    Name := ExtractFileName(Segments[0]);
    DataType := TRegDataType(StrToInt(Segments[1]));
    FRegistry.OpenKey(KeyPath, True);
    if FRegistry.ValueExists(Name) then
      Continue; // Don't touch value if already there
    Value := '';
    if Segments.Count >= 3 then
      Value := Segments[2];
    case DataType of
      rdString: begin
        Value := StringReplace(Value, CHR13REPLACEMENT, #13, [rfReplaceAll]);
        Value := StringReplace(Value, CHR10REPLACEMENT, #10, [rfReplaceAll]);
        FRegistry.WriteString(Name, Value);
      end;
      rdInteger:
        FRegistry.WriteInteger(Name, MakeInt(Value));
      rdBinary, rdUnknown, rdExpandString:
        ErrorDialog(Name+' has an unsupported data type.');
    end;
    Segments.Free;
  end;
  Lines.Free;
end;


function TAppSettings.ExportSettings(Filename: String): Boolean;
var
  Content, Value: String;
  DataType: TRegDataType;

  procedure ReadKeyToContent(Path: String);
  var
    Names: TStringList;
    i: Integer;
    SubPath: String;
  begin
    // Recursively read values in keys and their subkeys into "content" variable
    FRegistry.OpenKey(Path, True);
    SubPath := Copy(Path, Length(FBasePath)+1, MaxInt);
    Names := TStringList.Create;
    FRegistry.GetValueNames(Names);
    for i:=0 to Names.Count-1 do begin
      DataType := FRegistry.GetDataType(Names[i]);
      Content := Content +
        SubPath + Names[i] + DELIMITER +
        IntToStr(Integer(DataType)) + DELIMITER;
      case DataType of
        rdString: begin
          Value := FRegistry.ReadString(Names[i]);
          Value := StringReplace(Value, #13, CHR13REPLACEMENT, [rfReplaceAll]);
          Value := StringReplace(Value, #10, CHR10REPLACEMENT, [rfReplaceAll]);
        end;
        rdInteger:
          Value := IntToStr(FRegistry.ReadInteger(Names[i]));
        rdBinary, rdUnknown, rdExpandString:
          ErrorDialog(Names[i]+' has an unsupported data type.');
      end;
      Content := Content + Value + CRLF;
    end;
    Names.Clear;
    FRegistry.GetKeyNames(Names);
    for i:=0 to Names.Count-1 do
      ReadKeyToContent(Path + Names[i] + '\');
    Names.Free;
  end;

begin
  // Save registry settings to file
  Content := '';
  ReadKeyToContent(FBasePath);
  SaveUnicodeFile(FileName, Content, UTF8NoBOMEncoding);
  Result := True;
end;


function TAppSettings.ExportSettings: Boolean;
begin
  Result := False;
  if not FPortableModeReadOnly then begin
    try
      ExportSettings(FSettingsFile);
      Result := True;
    except
      on E:Exception do begin
        FPortableModeReadOnly := True;
        Raise Exception.Create(E.ClassName + ': ' + E.Message + CRLF + CRLF
          + f_('Switching to read-only mode. Settings won''t be saved. Use the command line parameter %s to use a custom file path.', ['--psettings'])
          );
      end;
    end;
  end;
end;


function TAppSettings.DirnameUserAppData: String;
begin
  // User folder for HeidiSQL's data (<user name>\Application Data)
  Result := GetShellFolder(FOLDERID_RoamingAppData) + '\' + APPNAME + '\';
  if not DirectoryExists(Result) then begin
    ForceDirectories(Result);
  end;
end;


function TAppSettings.DirnameUserDocuments: String;
begin
  // "HeidiSQL" folder under user's documents folder, e.g. c:\Users\Mike\Documents\HeidiSQL\
  Result := GetShellFolder(FOLDERID_Documents) + '\' + APPNAME + '\';
  // Do not auto-create it, as we only use it for snippets which can also have a custom path.
end;


function TAppSettings.DirnameSnippets: String;
begin
  // Folder for snippets
  Result := ReadString(asCustomSnippetsDirectory);
  if Result.IsEmpty then
    Result := GetDefaultString(asCustomSnippetsDirectory);
  Result := IncludeTrailingBackslash(Result);
  if not DirectoryExists(Result) then begin
    ForceDirectories(Result);
  end;
end;


function TAppSettings.DirnameBackups: String;
begin
  // Create backup folder if it does not exist and return it
  if PortableMode then begin
    Result := ExtractFilePath(Application.ExeName) + 'Backups\'
  end else begin
    Result := DirnameUserAppData + 'Backups\';
  end;
  if not DirectoryExists(Result) then begin
    ForceDirectories(Result);
  end;
end;


function TAppSettings.DirnameHighlighters: string;
begin
  if PortableMode then begin
    Result := ExtractFilePath(Application.ExeName) + 'Highlighters\'
  end else begin
    Result := DirnameUserAppData + 'Highlighters\';
  end;
  if not DirectoryExists(Result) then begin
    ForceDirectories(Result);
  end;
end;



{ TUTF8NoBOMEncoding }

function TUTF8NoBOMEncoding.GetPreamble: TBytes;
begin
  SetLength(Result, 0);
end;


initialization

NumberChars := ['0'..'9', FormatSettings.DecimalSeparator, FormatSettings.ThousandSeparator];

LibHandleUser32 := LoadLibrary('User32.dll');

UTF8NoBOMEncoding := TUTF8NoBOMEncoding.Create;

DateTimeNever := MinDateTime;

ConfirmIcon := TIcon.Create;
ConfirmIcon.LoadFromResourceName(hInstance, 'Z_ICONQUESTION');

end.


