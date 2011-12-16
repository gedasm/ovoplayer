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
unit AudioEngine_MPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Process, UTF8Process, Song, AudioEngine;

type

  { TAudioEngineMPlayer }
  PConfigParamMplayer = ^TConfigParamMPlayer;
  TConfigParamMPlayer = record
    PlayerPath: ShortString;
  end;

  TAudioEngineMPlayer = class(TAudioEngine)
  private
    fMainVolume: integer;
    FPaused: boolean;
    fPlayerProcess: TProcessUTF8;
    fPlayerState: TEngineState;
    FPlayRunningI: boolean;
    fPosition: integer;
    fTimer: TTimer;
    fMuted: boolean;
    procedure RunAndPlay(Filename: String);
    procedure SetPaused(const AValue: boolean);
    procedure SendMPlayerCommand(Cmd: string);
    procedure TimerEvent(Sender: TObject);
  protected
    function GetMainVolume: integer; override;
    procedure SetMainVolume(const AValue: integer); override;
    function GetMaxVolume: integer; override;
    function GetSongPos: integer; override;
    procedure SetSongPos(const AValue: integer); override;
    procedure DoPlay(Song: TSong; offset:Integer); override;
    function GetState: TEngineState; override;
    procedure SetMuted(const AValue: boolean);  override;
    Function GetMuted: boolean; override;
    procedure ReceivedCommand(Sender: TObject; Command: TEngineCommand; Param: integer = 0); override;
    // see: mplayer -input cmdlist and http://www.mplayerhq.hu/DOCS/tech/slave.txt

  public
    class Function GetEngineName: String; override;
    Class Function IsAvalaible(ConfigParam: TStrings): boolean; override;

    constructor Create; override;
    procedure Activate; override;
    destructor Destroy; override;
    procedure Pause; override;
    function Playing: boolean; override;
    procedure PostCommand(Command: TEngineCommand; Param: integer); override;
    function Running: boolean; override;
    procedure Seek(Seconds: integer; SeekAbsolute: boolean); override;
    procedure Stop; override;
    procedure UnPause; override;

  end;

implementation


uses strutils, FileUtil, lclproc;

const
  TIMEPOSOUT = 'A: ';
  EXITING = 'Exiting...';

  {$IFDEF WINDOWS}
    fMPlayerPath = 'mplayer.exe';
  {$ELSE}
    fMPlayerPath = 'mplayer';
  {$ENDIF}


var
  EngFormat: TFormatSettings;
  fProgramPath:string;

{ TAudioEngineMPlayer }

procedure TAudioEngineMPlayer.TimerEvent(Sender: TObject);
var
  NoMoreOutput: boolean;

  procedure DoStuffForProcess;
  var
    Buffer:     string;
    BytesAvailable: DWord;
    BytesRead:  longint;
    ProcessStr: string;
    cmdPos:     integer;
    tmpPos:     double;
  begin
    if Running then
      begin
      BytesAvailable := fPlayerProcess.Output.NumBytesAvailable;
      BytesRead      := 0;
      while BytesAvailable > 0 do
        begin
        SetLength(Buffer, BytesAvailable);
        BytesRead  := fPlayerProcess.OutPut.Read(Buffer[1], BytesAvailable);
        ProcessStr := copy(Buffer, 1, BytesRead);
        if AnsiStartsStr(TIMEPOSOUT,ProcessStr) then
          begin
            ProcessStr := trim(Copy(ProcessStr, 3, 7));
            if not TryStrToFloat(ProcessStr, tmpPos, EngFormat) then
              fPosition := 0
            else
              fPosition := trunc(tmpPos * 1000);
          end;
        BytesAvailable := fPlayerProcess.Output.NumBytesAvailable;
        NoMoreOutput   := False;
        end;
      end
  end;

begin
  DoStuffForProcess;
  repeat
    NoMoreOutput := True;
    DoStuffForProcess;
  until noMoreOutput or (not Running);

  if not Running then
    begin
      fTimer.enabled := false;
      PostCommand(ecNext,0);
    end;

end;

function TAudioEngineMPlayer.GetMainVolume: integer;
begin
  Result := fMainVolume;
  ;
end;

function TAudioEngineMPlayer.GetSongPos: integer;
begin
  Result := trunc(fPosition);
end;

procedure TAudioEngineMPlayer.SetMainVolume(const AValue: integer);
begin
  if AValue = fMainVolume then
    exit;
  fMainVolume := AValue;
  SendMPlayerCommand('volume ' + IntToStr(fMainVolume) + ' 1');
end;

function TAudioEngineMPlayer.GetMaxVolume: integer;
begin
  Result:= 255;
end;


procedure TAudioEngineMPlayer.SetPaused(const AValue: boolean);
begin
  if FPaused = AValue then
    exit;
  if Running then
    begin
    FPaused := AValue;
    SendMPlayerCommand('pause');
    end;
end;

procedure TAudioEngineMPlayer.SetSongPos(const AValue: integer);
begin
  Seek(AValue, True);
end;

procedure TAudioEngineMPlayer.SendMPlayerCommand(Cmd: string);
const
  LineEnding = #10;
begin
  if Cmd = '' then
    exit;
  if not Running then
    exit;
  if Cmd[length(Cmd)] <> LineEnding then
    Cmd := Cmd + LineEnding;
  fPlayerProcess.Input.Write(Cmd[1], length(Cmd));
end;

constructor TAudioEngineMPlayer.Create;
begin
  inherited Create;
  fMainVolume := 127;
  fTimer := TTimer.Create(nil);
  fTimer.Enabled:=false;
  fTimer.Interval :=150;
  fTimer.OnTimer  := @TimerEvent;

end;

procedure TAudioEngineMPlayer.Pause;
begin
  SetPaused(True);
end;

procedure TAudioEngineMPlayer.Stop;
begin
  SendMPlayerCommand('stop');
  fPlayerProcess.Terminate(0);
end;

procedure TAudioEngineMPlayer.DoPlay(Song: TSong; offset:Integer);
var
  Params: string;
begin
  if not Assigned(Song) then
    exit;

  Activate;

  Params := StringReplace(Song.FullName, '\', '/', [rfReplaceall]);
  if not Running then
     RunAndPlay(Params)
  else
     SendMPlayerCommand('loadfile "' + Params + '"');

  fPlayerState := ENGINE_PLAY;
  FPlayRunningI := True;
  Seek(offset, true);
  fTimer.Enabled:=true;

  if Assigned(OnSongStart) then
    OnSongStart(self);

end;
procedure TAudioEngineMPlayer.Activate;
begin

end;

procedure TAudioEngineMPlayer.RunAndPlay(Filename:String);
var
  ExePath: string;
  Params:  string;
begin
  if Running and Paused then
    begin
    Paused := False;
    exit;
    end;

  if Playing then
    exit;

  ExePath := fProgramPath;
  if not FilenameIsAbsolute(ExePath) then
    ExePath := FindDefaultExecutablePath(ExePath);
  if not FileExistsUTF8(ExePath) then
    raise Exception.Create('mplayer not found');

  FPlayRunningI := True;
  fPlayerProcess := TProcessUTF8.Create(nil);
  Params := ' -slave -nofs -nomouseinput -noquiet '; //  -priority abovenormal -really-quiet -identify
  Params := Params + ' -volume ' + IntToStr(Self.MainVolume) + ' -softvol -softvol-max 255';
  fPlayerProcess.Options := fPlayerProcess.Options + [poUsePipes, poNoConsole];
  fPlayerProcess.CommandLine :=ExePath + ' ' + Params + ' "' +Filename+'"';
  fPlayerProcess.Execute;

end;

function TAudioEngineMPlayer.GetState: TEngineState;
begin
  Result := fPlayerState;
end;

procedure TAudioEngineMPlayer.SetMuted(const AValue: boolean);
begin
  if AValue = fMuted then
     exit;
  if fMuted then
     begin
        SendMPlayerCommand('mute 1');
        fMuted:=true;
     end
 else
     begin
        SendMPlayerCommand('mute 0');
        fMuted:=true;
     end;

end;

function TAudioEngineMPlayer.GetMuted: boolean;
begin
  Result := fMuted;
end;

class function TAudioEngineMPlayer.GetEngineName: String;
begin
  Result:='MPlayer';
end;

procedure TAudioEngineMPlayer.ReceivedCommand(Sender: TObject;
  Command: TEngineCommand; Param: integer);
begin
    case Command of
    ecNext: if Assigned(OnSongEnd) then
        OnSongEnd(Self);

    ecSeek: Seek(Param, True);

    end;
end;

class function TAudioEngineMPlayer.IsAvalaible(ConfigParam: TStrings): boolean;
var
  AProcess : TProcessUTF8;
  APath :string;
begin
  Result:= false;
  if Assigned(ConfigParam) then
    begin
      APath:= ConfigParam.Values['Path'];
      if trim(APath) = '' then
         APath := fMPlayerPath;
    end
  else
    APath := fMPlayerPath;;

  AProcess := TProcessUTF8.Create(nil);
  AProcess.Options := AProcess.Options + [poUsePipes, poNoConsole];

  try
    if APath = '' then
       begin
          result:= false;
          exit;
       end;
    AProcess.CommandLine:= APath;
    fProgramPath:=APath;
    try
      AProcess.Execute;
      Result:=true;
    Except
      Result := false;
    end;

  finally
    AProcess.Terminate(0);
    AProcess.free;
  end;

end;

procedure TAudioEngineMPlayer.PostCommand(Command: TEngineCommand;
  Param: integer);
begin
  ReceivedCommand(Self, Command, Param);
end;


procedure TAudioEngineMPlayer.UnPause;
begin
  SetPaused(False);
end;

function TAudioEngineMPlayer.Running: boolean;
begin
  Result := (fPlayerProcess <> nil) and fPlayerProcess.Running;
end;

function TAudioEngineMPlayer.Playing: boolean;
begin
  Result := (fPlayerProcess <> nil) and fPlayerProcess.Running and (Not Paused);
end;

procedure TAudioEngineMPlayer.Seek(Seconds: integer; SeekAbsolute: boolean);
var
  st: string;
begin
  if Running then
    begin
      st := 'seek ' + IntToStr(Seconds div 1000);
      if SeekAbsolute then
        st := st + ' 2'
      else
        st := st + ' 0';
      SendMPlayerCommand(st);
      fPlayerProcess.Output.Seek(MaxInt, soCurrent);
    end;

end;

destructor TAudioEngineMPlayer.Destroy;
begin
  SendMPlayerCommand('quit');
  if Running then
     fPlayerProcess.Terminate(0);

  inherited Destroy;
end;

initialization
  EngFormat := DefaultFormatSettings;
  EngFormat.DecimalSeparator := '.';
  EngFormat.ThousandSeparator := ',';

  RegisterEngineClass(TAudioEngineMPlayer, 2, true, false);

end.