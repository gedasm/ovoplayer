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
unit netprotocol;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, base64, BaseTypes;

Const
  CATEGORY_ACTION = 'action';
    COMMAND_PLAY = 'play';
    COMMAND_STOP = 'stop';
    COMMAND_PAUSE = 'pause' ;
    COMMAND_PLAYPAUSE = 'playpause';
    COMMAND_NEXT = 'next';
    COMMAND_PREVIOUS = 'previous';
    COMMAND_SEEK_P = 'seek+';
    COMMAND_SEEK_M = 'seek-';

  CATEGORY_FILE = 'file';
    COMMAND_ENQUEUE = 'e';
    COMMAND_CLEAR_AND_PLAY = 'p';
    COMMAND_ENQUEUE_AND_PLAY = 'x';

  CATEGORY_APP = 'App';
    COMMAND_ACTIVATE = 'activate';
    COMMAND_QUIT = 'quit';

  CATEGORY_COMMAND_SEPARATOR = ':';
  CATEGORY_PARAM_SEPARATOR = '=';
  IPC_SEPARATOR = '|'; // used by communication based on SimpleIPC

{
My personal implementation of a netstrings-like protocol, where each string
is prefixed by it's length.

To avoid sending binary data, length is defined as a 24 bit unsigned integer.
This 3-byte integer is then encoded in Base64, so it became a 4 byte ASCII string
}

function EncodeSize(Size:Integer):string;
function DecodeSize(Size:string):integer;
Function EncodeString(S:String): string;

function BuildCommand(Category: string; Command: string; Param:string=''; IPCSeparator:boolean=false):string;
Function SplitCommand(ACommand:string): RExternalCommand;

implementation
uses strutils;

function EncodeSize(Size:Integer):string;
var
  s : RawByteString;
  v:integer;
begin
  SetLength(s,3);
  s[1] := AnsiChar((Size and $ff0000 ) shr 16);
  s[2] := AnsiChar((Size and $00ff00) shr 8);
  s[3] := AnsiChar((Size and $0000ff));
  Result := base64.EncodeStringBase64(s);
end;

function DecodeSize(Size: String): integer;
var
  s : RawByteString;
  v:integer;
begin
  try
    s:= DecodeStringBase64(Size, True);

    Result := (byte(s[1]) shl 16) or
              (byte(s[2]) shl 8) or
              (byte(s[3]));
  except
    result := -1;
  end;
end;

Function EncodeString(S:String): string;
begin
  Result := EncodeSize(Length(s))+s;
end;

function BuildCommand(Category: string; Command: string; Param: string;
  IPCSeparator: boolean): string;
begin
  Result := Category +
            CATEGORY_COMMAND_SEPARATOR+
            Command;

  if Param <> '' then
     Result := Result +
               CATEGORY_PARAM_SEPARATOR +
               Param;
  if IPCSeparator then
     Result := Result + IPC_SEPARATOR;
end;

function SplitCommand(ACommand: string): RExternalCommand;
var
  pColon, pEqual: integer;
  tmpstr: string;
  cmdlength: integer;
begin
  Result.Category:=EmptyStr;
  Result.Param:=EmptyStr;
  cmdlength := Length(ACommand);

  if (cmdlength >0 ) and (ACommand[cmdlength] = IPC_SEPARATOR) then
     dec(cmdlength);

  pColon:= pos(CATEGORY_COMMAND_SEPARATOR,ACommand);
  if pColon < 1 then
    Result.Command:=ACommand
  else
    begin
      Result.Category:=copy(ACommand, 1,pColon-1);
      pEqual:= PosEx(CATEGORY_PARAM_SEPARATOR,ACommand,pColon+1);
      if pEqual < 1 then
        Result.Command:=Copy(ACommand,pColon+1, cmdlength)
      else
        begin
           Result.Command:=copy(ACommand, pColon+1,pEqual -pColon -1);
           Result.Param:= copy(ACommand, pEqual+1, cmdlength);
        end;
    end;
end;


end.
