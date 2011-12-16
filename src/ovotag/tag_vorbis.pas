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
unit tag_vorbis;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, baseTag;

type

  { TVorbisFrame }

  TVorbisFrame = class(TFrameElement)
  Private
    fValue :string;
  protected
    function GetAsString: string;  override;
    procedure SetAsString(AValue: string); override;
  public
    function ReadFromStream(AStream: TStream): boolean; override;
  end;

  { TVorbisTags }

  TVorbisTags = class(TTags)
  public
    Vendor: string;
    function ReadImageFromStream(AStream: TStream): boolean;
    Function GetCommonTags: TCommonTags; override;
    function ReadFromStream(AStream: TStream): boolean; override;
  end;


implementation
{ TVorbisFrame }

function TVorbisFrame.GetAsString: string;
begin
  Result:=fValue;
end;

procedure TVorbisFrame.SetAsString(AValue: string);
begin
  fValue:= AValue;
end;

function TVorbisFrame.ReadFromStream(AStream: TStream): boolean;
var
  fSize:Cardinal;
  Data: array of char;
  iSep :Integer;
begin
  Result := false;
  fSize:= AStream.ReadDWord;
  SetLength(Data, fSize+1);
  AStream.Read(Data[0], fSize);
  iSep := pos('=',String(data));
  if iSep > 0 then
     begin
      ID :=UpperCase(Copy(string(Data), 1, iSep - 1));
      fValue := UTF8Decode(Copy(string(Data), iSep + 1, MaxInt));
      Result:=true;
     end;
end;



{ TVorbisTags }

function TVorbisTags.ReadImageFromStream(AStream: TStream): boolean;
var
  img : TImageElement;
  size: DWord;
  tmpstr: array of Ansichar;
begin
  img := TImageElement.Create;
  img.PictureType:= BetoN(AStream.ReadDWord);

  Size := BetoN(AStream.ReadDWord);
  SetLength(tmpstr, size);
  AStream.read(tmpstr[0], size);
  img.MIMEType:= strpas(@tmpstr[0]);

  Size := BetoN(AStream.ReadDWord);
  SetLength(tmpstr, size);
  AStream.read(tmpstr[0], size);
  img.Description:=Utf8ToAnsi(strpas(@tmpstr[0]));

  AStream.ReadDWord; // width
  AStream.ReadDWord; // heigth
  AStream.ReadDWord; // Color depth
  AStream.ReadDWord; // number of color

  Size := BetoN(AStream.ReadDWord);
  img.Image.CopyFrom(AStream, Size);
  AddImage(img);
  Result:= true;
end;

function TVorbisTags.GetCommonTags: TCommonTags;
begin
  Result:=inherited GetCommonTags;

  Result.Album := GetFrameValue('ALBUM');
  Result.AlbumArtist := GetFrameValue('ALBUMARTIST');
  Result.Artist := GetFrameValue('ARTIST');
  Result.Comment := GetFrameValue('COMMENT');
  Result.Genre := GetFrameValue('GENRE');
  Result.Title := GetFrameValue('TITLE');
  Result.Track := StrToIntDef(GetFrameValue('TRACKNUMBER'),0);;
  Result.TrackString := GetFrameValue('TRACKNUMBER');
  Result.Year := GetFrameValue('DATE');

  if Result.AlbumArtist = '' then
     Result.AlbumArtist := result.Artist;
end;

function TVorbisTags.ReadFromStream(AStream: TStream): boolean;
var
  fSize: cardinal;
  Data: array of char;
  FrameCount: cardinal;
  i: cardinal;
  Frame: TVorbisFrame;
begin
  Clear;
  fSize := AStream.ReadDWord;
  SetLength(Data, fSize);
  AStream.Read(Data[0], fSize);
  Vendor := string(Data);

  FrameCount := AStream.ReadDWord;

  for i := 0 to FrameCount - 1 do
  begin
    Frame := TVorbisFrame.Create;
    if Frame.ReadFromStream(AStream) then
       add(Frame)
    else
      FreeAndNil(Frame);
  end;
  Result := Count > 0;
end;

end.
