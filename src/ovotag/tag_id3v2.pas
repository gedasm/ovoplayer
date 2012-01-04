{
This file is part of OvoTag
Copyright (C) 2011 Marco Caselli

OvoTag is free software; you can redistribute it and/or
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
{$I ovotag.inc}
unit tag_id3v2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, basetag;

type

  TID3V1Record = record
    Header:  array [1..3] of char;
    Title:   array [1..30] of char;
    Artist:  array [1..30] of char;
    Album:   array [1..30] of char;
    Year:    array [1..4] of char;
    Comment: array [1..28] of char;
    Stopper : char;
    Track : byte;
    Genre:   byte;
  end;

  TID3Tags = class;

  { TID3Frame }

  TID3Frame = class(TFrameElement)
  private
    fSize: Integer;
    Data: Array of Ansichar;
    function IsValid: Boolean;
  public
    Tags: TID3Tags;
    Property Size: Integer read fSize;
  public
    Destructor Destroy; override;
    function GetAsString: string; override;
    procedure SetAsString(AValue: string); override;
    function ReadFromStream(AStream: TStream): boolean; override;
  end;


  { TID3Tags }

  TID3Tags = class(TTags)
  private
    fSize: Integer;
    procedure DecodeFrameToImage(Frame: TID3Frame; Image: TImageElement);
    function GetBestMatch(Index1, Index2: Integer; NewFrame: boolean): String;
    function ImportFromID3V1(AStream: TStream): boolean;
  public
    Version: word;
    FromV1 : boolean;
  public
    Property Size: Integer read fSize;
    Function GetCommonTags: TCommonTags; override;
    function ReadFromStream(AStream: TStream): boolean; override;
  end;


implementation

uses CommonFunctions, ID3v1Genres;
type

    { TID3Frame }
  TID3Header = packed record
    Marker: array[0..2] of ansichar;
    Version: word;
    Flags: byte;
    size: dword;
  end;

  TID3FrameHeader = record
    ID: array [0..3] of char;
    Size: DWord;
    Flags: Word;
  end;

  TID3FrameHeaderOld = record
    ID: array [0..2] of char;
    Size: array [0..2] of byte;
  end;

const
  ID3_HEADER_MARKER = 'ID3';
  ID3_FOOTER_MARKER = '3DI';

  TAG_VERSION_2_2 = 2;
  TAG_VERSION_2_3 = 3;
  TAG_VERSION_2_4 = 4;
  ID3V2_FRAME_COUNT = 18;

  { Names of supported tag frames (ID3v2.3.x & ID3v2.4.x) }
  ID3V2_KNOWNFRAME: array [1..ID3V2_FRAME_COUNT, Boolean] of string =(
    ('TIT2', 'TT2'),
    ('TPE1', 'TP1'),
    ('TALB', 'TAL'),
    ('TRCK', 'TRK'),
    ('TYER', 'TYE'),
    ('TCON', 'TCO'),
    ('COMM', 'COM'),
    ('TCOM', 'TCM'),
    ('TENC', 'TEN'),
    ('TCOP', 'TCR'),
    ('TLAN', 'TLA'),
    ('WXXX', 'WXX'),
    ('TDRC', 'TOR'),
    ('TOPE', 'TOA'),
    ('TIT1', 'TT1'),
    ('TOAL', 'TOT'),
    ('TSIZ', 'TSI'),
    ('TPE2',  'TP2')
     );

{ TID3Tags }

function TID3Tags.GetBestMatch(Index1,Index2:Integer; NewFrame:boolean):String;
begin
   Result := GetFrameValue(ID3V2_KNOWNFRAME[Index1,  NewFrame]);
  if Result = '' then
    Result := GetFrameValue(ID3V2_KNOWNFRAME[Index2,  NewFrame]);

end;

function TID3Tags.ImportFromID3V1(AStream: TStream): boolean;
var
  V1Rec : TID3V1Record;
  Frame : TID3Frame;
begin
  fSize:=0;
  result := false;
  AStream.Seek(AStream.Size - SizeOf(V1Rec), soFromBeginning);
  AStream.Read(V1Rec,  SizeOf(V1Rec));
  if V1Rec.Header <> 'TAG' then
    exit;

  version := 0;
  if trim(V1Rec.Artist) <> '' then
    begin
      Frame := TID3Frame.Create('TPE1');
      Frame.Tags := Self;
      Frame.AsString := trim(V1Rec.Artist);
      Add(Frame);
    end;

  if trim(V1Rec.Album) <> '' then
     begin
       Frame := TID3Frame.Create('TALB');
       Frame.Tags := Self;
       Frame.AsString := trim(V1Rec.Album);
       Add(Frame);
     end;

  if trim(V1Rec.Title) <> '' then
     begin
      Frame := TID3Frame.Create('TIT2');
      Frame.Tags := Self;
      Frame.AsString := trim(V1Rec.Title);
      Add(Frame);
    end;

  if trim(V1Rec.Year) <> '' then
    begin
      Frame := TID3Frame.Create('TYER');
      Frame.Tags := Self;
      Frame.AsString := trim(V1Rec.Year);
      Add(Frame);
    end;

  if V1Rec.Genre < 147 then
    begin
      Frame := TID3Frame.Create('TCON');
      Frame.Tags := Self;
      Frame.AsString := v1Genres[V1Rec.Genre];
      Add(Frame);
    end;

  if V1Rec.Stopper = #00 then
    begin
      if trim(V1Rec.Comment) <> '' then
        begin
          Frame := TID3Frame.Create('COMM');
          Frame.Tags := Self;
          Frame.AsString := trim(V1Rec.Comment);
          Add(Frame);
        end;

      Frame := TID3Frame.Create('TRCK');
      Frame.Tags := Self;
      Frame.AsString := inttostr(v1rec.track);
      Add(Frame);

    end
  else
  begin
    if trim(V1Rec.Comment + V1Rec.stopper + char(V1Rec.track)) <> '' then
      begin
        Frame := TID3Frame.Create('COMM');
        Frame.Tags := Self;
        Frame.AsString := trim(V1Rec.Comment + V1Rec.stopper + char(V1Rec.track));
        Add(Frame);
      end;
  end;
  result:=true;

end;

function TID3Tags.GetCommonTags: TCommonTags;
var
  UseOldTag: boolean;
begin
  Result:=inherited GetCommonTags;
  UseOldTag := (Version <= TAG_VERSION_2_2) and not FromV1;

  Result.Artist := GetBestMatch(2, 14, UseOldTag);
  Result.Title := GetBestMatch(1, 15, UseOldTag);
  Result.Album := GetBestMatch(3, 16, UseOldTag);
  Result.Year := GetBestMatch(5, 13, UseOldTag);
  Result.AlbumArtist := GetContent(GetFrameValue(ID3V2_KNOWNFRAME[18, UseOldTag]), Result.Artist);
  result.Track:=  ExtractTrack(GetFrameValue(ID3V2_KNOWNFRAME[4, UseOldTag]));
  result.TrackString := GetFrameValue(ID3V2_KNOWNFRAME[4, UseOldTag]);
  result.Comment:= GetFrameValue(ID3V2_KNOWNFRAME[7, UseOldTag]);
  result.Genre:= ExtractGenre(GetFrameValue(ID3V2_KNOWNFRAME[6, UseOldTag]));
  Result.HasImage:=ImageCount > 0;

end;

Procedure TID3Tags.DecodeFrameToImage(Frame:TID3Frame; Image:TImageElement);
var
  wData : pchar;
  wDatasize :Dword;
begin
  image.FrameRef := Frame;
  wData:= pchar(Frame.Data);
  wDatasize:= Frame.fSize;
  inc(wData);
  dec(wDatasize);
  image.MIMEType:= pAnsiChar(wData);
  Inc(wData, Length(image.MIMEType)+1);
  Dec(wDataSize, Length(image.MIMEType)+1);

  if Version > TAG_VERSION_2_2 then
     begin
       Image.PictureType:=pByte(wData)^;
       inc(wData);
       dec(wDatasize);
     end;

  image.Description:= pAnsiChar(wData);
  Inc(wData, Length(image.Description)+1);
  Dec(wDataSize, Length(image.Description)+1);

  Image.Image.WriteBuffer(wData[0], wDatasize);
  image.Image.Position := 0;
end;

function TID3Tags.ReadFromStream(AStream: TStream): boolean;
var
  header: TID3Header;
  Transferred: DWord;
  Frame : TID3Frame;
  Image : TImageElement;
  Stop:boolean;
begin
  Result := False;
  FromV1:=false;;
  AStream.Read(header, SizeOf(header));
  if header.Marker <> ID3_HEADER_MARKER then
     begin
       FromV1 := ImportFromID3V1(AStream);
       result:= FromV1;
       exit;
     end;

  Version := header.Version;
  fSize := SyncSafe_Decode(header.size, version);
  Stop := false;
  if (Version in [TAG_VERSION_2_2..TAG_VERSION_2_4]) and (fSize > 0)  then
      while (AStream.Position < (fSize + SizeOf(header))) and not stop do
      begin
        Frame := TID3Frame.Create;
        Frame.Tags:=self;
        if Frame.ReadFromStream(AStream) then
          begin
             Add(Frame);
             if (Frame.ID = 'APIC') or (Frame.ID = 'PIC') then
               begin
                 image:= TImageElement.Create;
                 DecodeFrameToImage(Frame, Image);
                 AddImage(Image);
               end;
          end
        else
          begin
            FreeAndNil(Frame);
            Stop:=true;
          end;
      end;
  Result:= Count > 0;

end;

{ TID3Frame }

function TID3Frame.GetAsString: string;
begin
  if ID[1] in ['T','C','W'] then
     Result := ExtractString(pByte(Data), size)
  else
     Result := '?';
end;


procedure TID3Frame.SetAsString(AValue: string);
begin
  fSize :=  Length(AValue);
  if fSize = 0 then
     begin
       SetLength(Data, 0);
       exit;
     end;

  SetLength(Data, fSize + 2);
  Data[0] := #00;
  StrPCopy(@(Data[1]), AValue);

end;

function TID3Frame.IsValid: Boolean;
var
  C: Char;
begin
  Result := False;
  if length(Id) < 3 then
     exit;   // Corruption protection

  for C in ID do
    if not (C in ['A'..'Z', '0'..'9']) then
      Exit;   // Corruption protection

  Result := True;
end;

destructor TID3Frame.Destroy;
begin
  self.Tags:= nil;
  inherited Destroy;
end;


function TID3Frame.ReadFromStream(AStream: TStream): boolean;
var
  Header: TID3FrameHeader;
  HeaderOld: TID3FrameHeaderOld;
  DataSize: Dword;
begin
  Result := False;
  if Tags.Version < TAG_VERSION_2_3 then
    begin
      AStream.Read(HeaderOld, SizeOf(HeaderOld));
      id:=string(HeaderOld.ID);
      if not IsValid then
         exit; // Corruption protection
      DataSize := HeaderOld.Size[0] shl 16 + HeaderOld.Size[1] shl 8 + HeaderOld.Size[2];
    end
  else
    begin
      AStream.Read(Header, 10);
      id:=string(Header.ID);
      if not IsValid then
         exit; // Corruption protection

      DataSize := SyncSafe_Decode(Header.Size, Tags.version);
    end;

  if DataSize > Tags.size then
    exit; // Corruption protection

  SetLength(Data, DataSize + 1);
  FillByte(Data[0],DataSize + 1, 0);
  AStream.Read(Data[0], DataSize);
  fSize:= DataSize;
  Result:=true;
end;

end.

