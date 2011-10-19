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
unit file_wma;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, basetag, tag_wma;

type
  { TWMAReader }

  TWMAReader = class(TTagReader)
  private
    fTags: TWmaTags;
    fDuration: int64;
  protected
    function GetTags: TTags; override;
    function GetDuration: int64; override;
    Function DumpInfo: TMediaProperty; override;
  public
    function LoadFromFile(FileName: Tfilename): boolean; override;
  end;

implementation

type
  TObjectHeader = packed record
    ObjectID :  TGuid;
    ObjectSize: QWord;
  end;

  TWMAHeader = packed record
    ObjectHeader : TObjectHeader;
    ObjectCount: DWord;
    Reserved: Word;
  end;

  TWMAFileProperty =  packed record
    FileHeader : TObjectHeader;
    CreationDate : Qword;
    DataPacketsCount :  QWORD;
    PlayDuration : QWORD;
    SendDuration :  QWORD;
    Preroll :  QWORD;
    Flags :  DWORD;
    MinDataPacketSize:  DWORD;
    MaxDataPacketSize:  DWORD;
    MaxBitrate:  DWORD;
  end;

const

  WMA_HEADER_ID :TGUID = '{75B22630-668E-11CF-A6D9-00AA0062CE6C}';
  WMA_CONTENT_DESCRIPTION :TGUID = '{75B22633-668E-11CF-A6D9-00AA0062CE6C}';
  WMA_EXTENDED_CONTENT_DESCRIPTION :TGUID = '{D2D0A440-E307-11D2-97F0-00A0C95EA850}';
  WMA_FILE_PROPERTIES :TGUID = '{8CABDCA1-A947-11CF-8EE4-00C00C205365}';
{ TWMAReader }

function TWMAReader.GetTags: TTags;
begin
  Result := fTags;
end;

function TWMAReader.GetDuration: int64;
begin
  Result:=fDuration;
end;

function TWMAReader.DumpInfo: TMediaProperty;
begin
  Result:=inherited DumpInfo;
end;

function TWMAReader.LoadFromFile(FileName: Tfilename): boolean;
var
  fStream: TFileStream;
  Header : TWMaHeader;
  SubObjHeader : TObjectHeader;
  FileProperty :TWMAFileProperty;
  i:     Integer;
begin
  Result := Inherited LoadFromFile(FileName);

  try
    fStream := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);

    fStream.ReadBuffer(Header, SizeOf(Header));
    ftags:=nil;
    if not IsEqualGUID(Header.ObjectHeader.ObjectID, WMA_HEADER_ID) then
       exit;

    for i := 0 to Header.ObjectCount do
      begin
        fStream.Read(SubObjHeader, SizeOf(SubObjHeader));
        //if SubObjHeader.ObjectID = WMA_CONTENT_DESCRIPTION then
        //   begin
        //
        //   end
        //else
        if IsEqualGUID(SubObjHeader.ObjectID, WMA_FILE_PROPERTIES) then
           begin
             fStream.Read(FileProperty, SizeOf(TWMAFileProperty));
             fDuration := (FileProperty.PlayDuration div 10000) - FileProperty.Preroll;
           end
        else
        if IsEqualGUID(SubObjHeader.ObjectID, WMA_EXTENDED_CONTENT_DESCRIPTION) then
           begin
             fTags := TWMATags.Create;
             fTags.ReadFromStream(fStream);
           end
        else
           begin
             fStream.Seek(SubObjHeader.ObjectSize - SizeOf(SubObjHeader), soFromCurrent);
           end;
    end;

  finally
    fStream.Free;
  end;
  result:= (Tags <> nil) and (tags.count > 0);

end;

end.

