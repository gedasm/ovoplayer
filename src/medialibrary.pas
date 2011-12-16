{
This file is part of OvoPlayer
Copyright (C) 2011 Marco Caselli

OvoPlayer is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

}
{$I ovoplayer.inc}
unit MediaLibrary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, sqlite3conn, sqldb, lclproc, basetag;

type

  { TMediaLibrary }
  TMediaLibrary = class;

  { TDirectoryScanner }

  TDirectoryScanner = class(TThread)
  private
    tags:     TCommonTags;
    FileList: TStringList;
    Medialibrary: TMediaLibrary;
    CurrentPaths: TStringList;
    procedure CallBack; register;

  protected
    procedure Execute; override;
  public
    constructor CreateScanner(Paths: TStrings; Owner: TmediaLibrary);
    destructor Destroy;  override;
  end;

  TScanComplete = procedure(Sender: TObject; Added, Updated, Removed, Failed : integer) of object;

  TExtendedInfo = record
    PlayCount : Integer;
    Rating :Integer;
    Added : TDateTime;
    LastPlay : TDateTime;
  end;

  TMediaLibrary = class
  private
    fDB:    TSQLite3Connection;
    FOnScanComplete: TScanComplete;
    FOnScanStart: TNotifyEvent;
    fTR:    TSQLTransaction;
    fSong: TSQLQuery;
    fInsertSong: TSQLQuery;
    fUpdateSong: TSQLQuery;
    fLoadTable: TSQLQuery;
    fWorkQuery: TSQLQuery;
    procedure AfterScan;
    procedure BeforeScan;
    procedure EndScan(AObject: TObject);
    procedure SetOnScanComplete(const AValue: TScanComplete);
    procedure SetOnScanStart(const AValue: TNotifyEvent);
    procedure SetupDBConnection;
    procedure CheckDBStructure;
    function TagsFromTable(Table: TSQLQuery): TCommonTags;
  public
    fAdded, fUpdated, fRemoved, fFailed: integer;
    constructor Create;
    destructor Destroy; override;
    procedure Add(Tags: TCommonTags);
    procedure Scan(paths: TStrings);
    Procedure RemoveMissing;

    procedure ReadBegin(Order: string; Filter: string);
    function ReadItem: TCommonTags;
    function NextItem: boolean;
    function ReadComplete: boolean;
    procedure ReadEnd;
    function FullNameFromID(ID: integer): string;
    function IDFromFullName(FileName: TFileName): integer;
    function SetSongPlayed(ID: integer): string;
    function TagsFromID(ID: integer): TCommonTags;
    function InfoFromID(ID: integer): TExtendedInfo;

    property OnScanComplete: TScanComplete read FOnScanComplete write SetOnScanComplete;
    property OnScanStart: TNotifyEvent read FOnScanStart write SetOnScanStart;
  end;


implementation

uses AppConsts, FilesSupport, AudioTag;

const
  CREATESONGTABLE = 'CREATE TABLE songs ('
                 + ' "ID" INTEGER primary key,'
                 + ' "Filename" VARCHAR COLLATE NOCASE,'
                 + ' "TrackString" VARCHAR COLLATE NOCASE,'
                 + ' "Track" INTEGER COLLATE NOCASE,'
                 + ' "Title" VARCHAR COLLATE NOCASE,'
                 + ' "Album" VARCHAR COLLATE NOCASE,'
                 + ' "Artist" VARCHAR COLLATE NOCASE,'
                 + ' "AlbumArtist" VARCHAR COLLATE NOCASE,'
                 + ' "Genre" VARCHAR COLLATE NOCASE,'
                 + ' "year" VARCHAR COLLATE NOCASE,'
                 + ' "Duration" INTEGER default 0,'
                 + ' "Playcount" INTEGER,'
                 + ' "Rating" INTEGER ,'
                 + ' "LastPlay" DATE,'
                 + ' "Added" DATE,'
                 + ' "elabflag" CHAR(1) COLLATE NOCASE);';

  INSERTINTOSONG = 'INSERT INTO songs ('
                 + ' Filename, TrackString, Track, Title, Album, Artist,'
                 + ' AlbumArtist, Genre, year, elabflag, Duration,'
                 + ' Playcount, Rating, LastPlay, Added'
                 + ')'
                 + ' VALUES ('
                 + ' :Filename, :TrackString, :Track, :Title, :Album, :Artist,'
                 + ' :AlbumArtist, :Genre, :year, :elabflag, :Duration,'
                 + ' :Playcount, :Rating, :LastPlay, :Added'
                 + ')';

  UPDATESONG     =  'update songs'
                 + ' set Filename = :Filename'
                 + ' ,Track = :Track'
                 + ' ,TrackString = :TrackString'
                 + ' ,Title = :Title'
                 + ' ,Album = :Album'
                 + ' ,Artist = :Artist'
                 + ' ,AlbumArtist = :AlbumArtist'
                 + ' ,Genre = :Genre'
                 + ' ,year  = :year'
                 + ' ,elabflag = :elabflag'
                 + ' ,Duration = :Duration'
//                 + ' ,Playcount = :Playcount'
//                 + ' ,Rating  = :Rating'
//                 + ' ,LastPlay = :LastPlay'
//                 + ' ,Added = :Added'
                 + ' where ID = :ID';

  CREATESONGINDEX1 = 'CREATE INDEX "idx_artist" on songs (Artist ASC);';
  CREATESONGINDEX2 = 'CREATE UNIQUE INDEX "idx_filename" on songs (Filename ASC);';

  PRAGMAS_COUNT = 3;
  PRAGMAS : array [1..PRAGMAS_COUNT] of string =
            (
//            'PRAGMA locking_mode = EXCLUSIVE;',
            'PRAGMA temp_store = MEMORY;',
            'PRAGMA count_changes = 0;',
            'PRAGMA encoding = "UTF-8";'
            );


{ TDirectoryScanner }

constructor TDirectoryScanner.CreateScanner(Paths: TStrings; Owner: TmediaLibrary);
begin
  inherited Create(True);
  Priority     := tpIdle;
  Medialibrary := Owner;
  CurrentPaths := TStringList.create;
  CurrentPaths.Assign(Paths);
  FreeOnTerminate := True;

end;

destructor TDirectoryScanner.Destroy;
begin

  CurrentPaths.Free;
  Inherited Destroy;
end;

procedure TDirectoryScanner.CallBack;
begin
  Medialibrary.Add(Tags);
end;

procedure TDirectoryScanner.Execute;
var
  i: integer;
begin
  FileList := TStringList.Create;

  for i:= 0 to CurrentPaths.Count -1 do
    begin
      BuildFileList(IncludeTrailingPathDelimiter(CurrentPaths[i]) + AudioTag.SupportedExtension,
                    faAnyFile, FileList, True);
    end;

  for I := 0 to FileList.Count - 1 do
    begin
      tags := AudioTag.ExtractTags(FileList[i]);
      if trim(tags.Title) = '' then
         tags.Title := ChangeFileExt(ExtractFileName(FileList[i]), '');
      Synchronize(@Callback);
    end;
  FileList.free;
end;

{ TMediaLibrary }
procedure TMediaLibrary.SetupDBConnection;
var
  i: integer;
begin
  fDB := TSQLite3Connection.Create(nil);
  fDB.DatabaseName := GetConfigDir + MediaLibraryName;
  ftr := TSQLTransaction.Create(nil);

  fTR.DataBase := fDB;

  for i := 1 to PRAGMAS_COUNT do
    fdb.ExecuteDirect(PRAGMAS[i]);

  fdb.Connected := True;

  fTR.Active := True;

end;

procedure TMediaLibrary.CheckDBStructure;
var
  TableList: TStringList;
begin
  TableList := TStringList.Create;
    try
    fDB.GetTableNames(TableList, False);
    if TableList.IndexOf('songs') < 0 then
      begin
      fDB.ExecuteDirect(CREATESONGTABLE);
      fDB.ExecuteDirect(CREATESONGINDEX1);
      fDB.ExecuteDirect(CREATESONGINDEX2);
      ftr.CommitRetaining;
      end;

    finally
    TableList.Free;
    end;

end;

constructor TMediaLibrary.Create;
begin
  SetupDBConnection;
  CheckDBStructure;

  fSong := TSQLQuery.Create(fDB);
  fInsertSong := TSQLQuery.Create(fDB);
  fUpdateSong := TSQLQuery.Create(fDB);

  fSong.DataBase := fDB;
  fSong.Transaction := fTR;

  fInsertSong.DataBase := fDB;
  fInsertSong.Transaction := fTR;

  fUpdateSong.DataBase := fDB;
  fUpdateSong.Transaction := fTR;

  fSong.SQL.Text := 'Select * from songs';

  fInsertSong.ParseSQL:=true;
  fInsertSong.SQL.Text := INSERTINTOSONG;


  fInsertSong.ParseSQL:=true;
  fUpdateSong.SQL.Text := UPDATESONG;

  fSong.Open;

  fSong.FieldByName('ID').ProviderFlags := fSong.FieldByName('ID').ProviderFlags + [pfInKey];
  fSong.FieldByName('Filename').ProviderFlags := fSong.FieldByName('Filename').ProviderFlags + [pfInKey];
  fSong.UpdateMode := upWhereKeyOnly;

  fWorkQuery := TSQLQuery.Create(fDB);
  fWorkQuery.DataBase := fDB;
  fWorkQuery.Transaction := fTR;

  fLoadTable := nil;
  ;

end;

destructor TMediaLibrary.Destroy;
begin
  FreeAndNil(fSong);
  FreeAndNil(fInsertSong);
  FreeAndNil(fUpdateSong);
  FreeAndNil(fLoadTable);
  FreeAndNil(fWorkQuery);
  ftr.Commit;
  fDB.Transaction := nil;
  fDB.Connected   := False;
  fTR.Free;
  fDB.Free;
  inherited Destroy;
end;

procedure TMediaLibrary.Add(Tags: TCommonTags);
var
  wrkSong : TSQLQuery;
  ID:Integer;
  tmpTags: TCommonTags;

begin
  ID := IDFromFullName(UTF8Encode(Tags.FileName));
  if ID  <> -1 then
    begin
      tmpTags := TagsFromID(ID);
      Tags.ID := ID;
      if Tags = tmpTags then
         begin
           fDB.ExecuteDirect('update songs set elabflag = null where id = '+IntToStr(ID));
           exit;

         end;
      wrkSong := fUpdateSong;
      wrkSong.Params.ParamByName('ID').AsInteger := Id;
      inc(fUpdated)
    end
  else
    begin
       wrkSong := fInsertSong;
       wrkSong.Params.ParamByName('PlayCount').AsInteger:= 0;
       wrkSong.Params.ParamByName('Added').AsDateTime := Now;
       inc(fAdded)
    end;

  wrkSong.Params.ParamByName('Filename').AsString    := UTF8Encode(Tags.FileName);
  wrkSong.Params.ParamByName('TrackString').AsString := Tags.TrackString;
  wrkSong.Params.ParamByName('Track').AsInteger      := Tags.Track;
  wrkSong.Params.ParamByName('Title').AsString       := UTF8Encode(Tags.Title);
  wrkSong.Params.ParamByName('Album').AsString       := UTF8Encode(Tags.Album);
  wrkSong.Params.ParamByName('Artist').AsString      := UTF8Encode(Tags.Artist);
  wrkSong.Params.ParamByName('AlbumArtist').AsString := UTF8Encode(Tags.AlbumArtist);
  wrkSong.Params.ParamByName('Genre').AsString       := Tags.Genre;
  wrkSong.Params.ParamByName('year').AsString        := Tags.Year;
  wrkSong.Params.ParamByName('Duration').AsInteger   := Tags.Duration;
  wrkSong.Params.ParamByName('elabflag').AsString    := '';
  wrkSong.ExecSQL;

end;

procedure TMediaLibrary.EndScan(AObject: TObject);
begin

  AfterScan;

  if Assigned(FOnScanComplete) then
    FOnScanComplete(Self, fAdded, fUpdated, fRemoved, fFailed);
end;

procedure TMediaLibrary.SetOnScanComplete(const AValue: TScanComplete);
begin
  if FOnScanComplete = AValue then
    exit;
  FOnScanComplete := AValue;
end;

procedure TMediaLibrary.SetOnScanStart(const AValue: TNotifyEvent);
begin
  if FOnScanStart = AValue then
    exit;
  FOnScanStart := AValue;
end;

procedure TMediaLibrary.BeforeScan;
begin
  fDB.ExecuteDirect('update songs set elabflag = ''S''');
end;

procedure TMediaLibrary.AfterScan;
var
  qtmp : TSQLQuery;
begin
  fRemoved:=0;
  qtmp:=TSQLQuery.Create(fDB);
  try
    qtmp.DataBase:=fDB;
    qtmp.SQL.Add('DELETE from songs where elabflag = ''S''');
    qtmp.ExecSQL;
    fRemoved:=qtmp.RowsAffected;
  finally
    qtmp.Free;
  end;

end;

procedure TMediaLibrary.Scan(paths: TStrings);
var
  Scanner: TDirectoryScanner;
begin
  fAdded   := 0;
  fFailed  := 0;
  fUpdated := 0;
  if Assigned(FOnScanStart) then
     FOnScanStart(self);
  BeforeScan;
  Scanner := TDirectoryScanner.CreateScanner(Paths, self);
  Scanner.OnTerminate := @EndScan;
  Scanner.Start;
end;

procedure TMediaLibrary.RemoveMissing;
var
  qtmp : TSQLQuery;
  Tags:TcommonTags;
begin
  fAdded   := 0;
  fFailed  := 0;
  fUpdated := 0;
  qtmp:=TSQLQuery.Create(fDB);
  try
    if Assigned(FOnScanStart) then
       FOnScanStart(self);

    ReadBegin('','');

    qtmp.DataBase:=fDB;
    qtmp.SQL.Add('update songs set elabflag = ''S'' where id = :id');

    while not ReadComplete do
      begin
        Tags:=ReadItem;
        if Not FileExists(Tags.Filename) then
          begin
             qtmp.Params.Items[0].AsInteger:=Tags.ID;
             qtmp.ExecSQL;
          end;
        NextItem;
      end;
    ReadEnd;
    AfterScan;

  finally
    qtmp.free;
  end;
  if Assigned(FOnScanComplete) then
    FOnScanComplete(Self, 0, 0, fRemoved, 0);

end;

procedure TMediaLibrary.ReadBegin(Order: string; Filter: string);
begin
  if not Assigned(fLoadTable) then
    fLoadTable := TSQLQuery.Create(fDB);

  fLoadTable.Close;
  fLoadTable := TSQLQuery.Create(fDB);
  fLoadTable.DataBase := fDB;
  fLoadTable.Transaction := fTR;
  fLoadTable.SQL.Text := 'Select * from songs';
  if filter <> '' then
    fLoadTable.SQL.Add('where ' + filter);

  if order <> '' then
    fLoadTable.SQL.Add('order by ' + Order);

  fLoadTable.Open;
  fLoadTable.First;

end;

function TMediaLibrary.ReadItem: TCommonTags;
begin
  Result:= TagsFromTable(fLoadTable);
end;

function TMediaLibrary.TagsFromTable(Table:TSQLQuery): TCommonTags;
begin
  Result.ID          := Table.FieldByName('ID').AsInteger;
  Result.FileName    := UTF8Decode(Table.FieldByName('Filename').AsString);
  Result.Track       := Table.FieldByName('Track').AsInteger;
  Result.TrackString := UTF8Decode(Table.FieldByName('TrackString').AsString);
  Result.Title       := UTF8Decode(Table.FieldByName('Title').AsString);
  Result.Album       := UTF8Decode(Table.FieldByName('Album').AsString);
  Result.AlbumArtist := UTF8Decode(Table.FieldByName('AlbumArtist').AsString);
  Result.Artist      := UTF8Decode(Table.FieldByName('Artist').AsString);
  Result.Genre       := Table.FieldByName('Genre').AsString;
  Result.Year        := Table.FieldByName('year').AsString;
  Result.Duration    := Table.FieldByName('Duration').AsInteger;

end;

function TMediaLibrary.NextItem: boolean;
begin
  Result := False;
  if fLoadTable.EOF then
    exit;
  fLoadTable.Next;
  Result := fLoadTable.EOF;
end;

function TMediaLibrary.ReadComplete: boolean;
begin
  Result := fLoadTable.EOF;
end;

procedure TMediaLibrary.ReadEnd;
begin
  fLoadTable.Close;
end;

function TMediaLibrary.FullNameFromID(ID: integer): string;
begin
  fWorkQuery.Close;
  fWorkQuery.SQL.Text := 'select filename from songs where id =' + IntToStr(ID);
  fWorkQuery.Open;
  Result := UTF8Decode(fWorkQuery.Fields[0].AsString);
  fWorkQuery.Close;
end;

function TMediaLibrary.IDFromFullName(FileName: TFileName): integer;
begin
  fWorkQuery.Close;
  fWorkQuery.SQL.Text := 'select ID from songs where filename =' + quotedstr(FileName);
  fWorkQuery.Open;
  if fWorkQuery.RecordCount > 0 then
     Result := fWorkQuery.Fields[0].AsInteger
  else
     Result := -1;
  fWorkQuery.Close;

end;

function TMediaLibrary.SetSongPlayed(ID: integer): string;
begin
  fWorkQuery.Close;
  fWorkQuery.SQL.Text := 'update songs set '
                       + '  Playcount = Playcount + 1'
                       + ' ,lastplay = datetime(''now'')'
                       + 'where id =' + IntToStr(ID);
  fWorkQuery.ExecSQL;
  Result := '';
  fWorkQuery.Close;
end;

function TMediaLibrary.TagsFromID(ID: integer): TCommonTags;
begin
  fWorkQuery.Close;
  fWorkQuery.SQL.Text := 'select * from songs where id =' + IntToStr(ID);
  fWorkQuery.Open;
  if fWorkQuery.RecordCount = 0 then
      Result.ID := -1
  else
       Result:=TagsFromTable(fWorkQuery);

  fWorkQuery.Close;
end;

function TMediaLibrary.InfoFromID(ID: integer): TExtendedInfo;
begin
  fWorkQuery.Close;
  fWorkQuery.SQL.Text := 'select * from songs where id =' + IntToStr(ID);
  fWorkQuery.Open;
  if fWorkQuery.RecordCount = 0 then
     result.PlayCount:= -1
  else
     begin
       Result.PlayCount:=fWorkQuery.FieldByName('PlayCount').AsInteger;
       Result.Added:=fWorkQuery.FieldByName('Added').AsDateTime;
       Result.LastPlay:=fWorkQuery.FieldByName('LastPlay').AsDateTime;
       Result.Rating:=fWorkQuery.FieldByName('Rating').AsInteger;
     end;

  fWorkQuery.Close;

end;

end.