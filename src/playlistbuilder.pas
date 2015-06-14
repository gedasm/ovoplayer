unit playlistbuilder;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, GeneralFunc, fgl;

type

 EditorKind =(ekText,ekDate,ekRating,ekNumber);

  FieldRec = record
    Id : integer;
    FieldName : string;
    FieldLabel : string;
    Kind : EditorKind;
  end;

  { TPlayListBuilder }

  { TFieldFilter }

  TFieldFilter = class
  private
    FFieldID: integer;
    FIdx: integer;

    function GetFilterNumber: string;
    function GetFilterRating: string;
    function GetFilterText: string;
    procedure SetFieldID(AValue: integer);

  public
    TestIndex : integer;
    StringValue : string;
    IntegerValue: int64;
    FloatValue : Double;
    Property FieldID : integer read FFieldID write SetFieldID;
    function isExecutable: boolean;
    function GetFilter: string;
  end;
  TIntPlayListBuilder = specialize TFPGObjectList<TFieldFilter>;

  TPlayListBuilder = class (TIntPlayListBuilder)
  public
    constructor Create;
    Destructor Destroy; override;
  end;


ResourceString
  // Diplay label for fields
  RS_Filename     = 'File Name';
  RS_TrackString  = 'Track String';
  RS_Track        = 'Track';
  RS_Title        = 'Title';
  RS_Album        = 'Album';
  RS_Artist       = 'Artist';
  RS_AlbumArtist  = 'Album Artist';
  RS_Genre        = 'Genre';
  RS_year         = 'Year';
  RS_Duration     = 'Duration';
  RS_Playcount    = 'Play count';
  RS_Rating       = 'Rating';
  RS_LastPlay     = 'Date Last Played';
  RS_Added        = 'Date Added';
  RS_FileSize     = 'File Size';
  RS_FileDate     = 'File Date';

  RS_EqualTo      = 'equal to';
  RS_NotEqualTo   = 'not equal to';
  RS_BiggerThan   = 'bigger than';
  RS_NotRated     = 'not rated';
  RS_Is = 'is';
  RS_IsNot = 'is not';
  RS_Contains = 'contains';
  RS_NotContains = 'not contains';
  RS_IsEmpty = 'is empty';
  RS_IsNotEmpty = 'is not empty';
  RS_LessThan = 'less than';

const
   FieldCount = 16;
   FieldArray : array [0..FieldCount-1] of FieldRec =  (
   (ID : 1; FieldName : 'Filename'; FieldLabel : RS_Filename; Kind: ekText),
   (ID : 2; FieldName : 'TrackString'; FieldLabel :RS_TrackString; Kind: ekText),
   (ID : 3; FieldName : 'Track'; FieldLabel : RS_Track; Kind: ekNumber),
   (ID : 4; FieldName : 'Title'; FieldLabel : RS_Title; Kind: ekText),
   (ID : 5; FieldName : 'Album'; FieldLabel : RS_Album; Kind: ekText),
   (ID : 6; FieldName : 'Artist'; FieldLabel : RS_Artist ; Kind: ekText),
   (ID : 7; FieldName : 'AlbumArtist'; FieldLabel : RS_AlbumArtist; Kind: ekText ),
   (ID : 8; FieldName : 'Genre'; FieldLabel : RS_Genre; Kind: ekText),
   (ID : 9; FieldName : 'year'; FieldLabel : RS_year;  Kind: ekNumber),
   (ID :10; FieldName : 'Duration'; FieldLabel : RS_Duration; Kind: ekNumber),
   (ID :11; FieldName : 'Playcount'; FieldLabel : RS_Playcount; Kind: ekNumber ),
   (ID :12; FieldName : 'Rating'; FieldLabel : RS_Rating;  Kind: EKRating),
   (ID :13; FieldName : 'LastPlay'; FieldLabel : RS_LastPlay; Kind: EkDate),
   (ID :14; FieldName : 'Added'; FieldLabel : RS_Added; Kind: EkDate),
   (ID :15; FieldName : 'FileSize'; FieldLabel : RS_FileSize;  Kind: ekNumber),
   (ID :16; FieldName : 'FileDate'; FieldLabel :RS_FileDate; Kind: EkDate)
   );

Procedure SortFields;

Function FindIndexByID(const ID: Integer): Integer;

implementation

function MyCompare (const Item1, Item2: integer): Integer;
  begin
    result := CompareText(FieldArray[item1].FieldLabel, FieldArray[item2].FieldLabel);
  end;

procedure SortFields;
type
  myArr = specialize TSortArray<FieldRec>;
begin
  myArr.Sort(FieldArray, @MyCompare);
end;

function FindIndexByID(const ID:Integer): Integer;
var
  i: integer;
begin
  for i := 0 to FieldCount -1 do
    begin
      if FieldArray[i].Id = id then
        begin
          result:= i;
          exit;
        end;
    end;
 Result:= -1;

end;


function TFieldFilter.GetFilterText: string;
var
  op : string;
  Value: string;
  NeedWildcards: boolean;
begin
  result:='';
  case TestIndex of
    0: begin op := 'like';     NeedWildcards:= true;  end; // contains
    1: begin op := 'not like'; NeedWildcards:= true;  end; // not contains
    2: begin op := '=';        NeedWildcards:= false; end; // is
    3: begin op := '<>';       NeedWildcards:= false; end; // is not
    4: begin op := '=';        NeedWildcards:= false; end; // is empty
    5: begin op := '<>';       NeedWildcards:= false; end; // is not empty
  else
    exit;
  end;

  if TestIndex < 4 then
     begin
     if StringValue = EmptyStr then
        exit;
     end;

  if NeedWildcards then
     Value :=  QuotedStr('%'+StringValue+'%')
  else
     Value :=  QuotedStr(StringValue);

  result := format(' %s %s %s',[FieldArray[FIdx].FieldName, op, Value]);

end;

procedure TFieldFilter.SetFieldID(AValue: integer);
begin
  if FFieldID=AValue then Exit;
  FFieldID:=AValue;
  FIdx:= FindIndexByID(FFieldID);
end;

function TFieldFilter.GetFilterNumber: string;
var
  op : string;
  Value: string;
begin
  result:='';

  case TestIndex of
    0: begin op := '=';  end; // equal to
    1: begin op := '<>'; end; // not equal to
    2: begin op := '>';  end; // bigger than
    3: begin op := '<';  end; // less than
  else
    exit;
  end;

  Value := IntToStr(IntegerValue);

  result := format(' %s %s %s',[FieldArray[FIdx].FieldName, op, Value]);

end;

function TFieldFilter.GetFilterRating: string;
var
  op : string;
  Value: string;
begin
  result:='';

  case TestIndex of
    0: begin op := '=';  end; // equal to
    1: begin op := '<>'; end; // not equal to
    2: begin op := '>';  end; // bigger than
    3: begin op := '<';  end; // less than
    4: begin op := 'is null';  end; // equal to

  else
    exit;
  end;

  if TestIndex = 4 then
    Value := ''
  else
    Value := IntToStr(IntegerValue + 1);


  result := format(' %s %s %s',[FieldArray[FIdx].FieldName, op, Value]);

end;

function TFieldFilter.GetFilter: string;
begin
 Result := EmptyStr;
 if FIdx  < 0 then exit;
 case  FieldArray[FIdx].Kind of
   ekText : result := GetFilterText;
   ekDate : ;
   ekNumber : result := GetFilterNumber;
   ekRating : result := GetFilterRating;

 end;
end;

function TFieldFilter.isExecutable: boolean;
begin
 Result := False;
 if FIdx < 0 then exit;
 case  FieldArray[FIdx].Kind of
   ekText : result := (TestIndex > 3) or
                      ((TestIndex < 4) and (StringValue <> EmptyStr) )   ;

   ekDate : ;
   ekNumber : Result := True;
   ekRating : result := True;
 end;
end;

{ TPlayListBuilder }

constructor TPlayListBuilder.Create;
begin
  Inherited Create(True);
end;

destructor TPlayListBuilder.Destroy;
begin
  inherited Destroy;
end;

end.

