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
unit gstreamer;

{$mode objfpc}{$H+}

interface

const
  GST_STATE_VOID_PENDING        = 0;
  GST_STATE_NULL                = (1 shl 0);
  GST_STATE_READY               = (1 shl 1);
  GST_STATE_PAUSED              = (1 shl 2);
  GST_STATE_PLAYING             = (1 shl 3);

type

  GstElementState = dword;
  pTimeVal = ^word;

  gst_init_check_t = function (argc: Integer; args: PPAnsiChar):Boolean; cdecl;
  gst_element_factory_make_t = function (const factoryname: PChar;const name: PChar): Pointer{GstElement*}; cdecl;
  gst_bin_new_t = FUNCTION (const name: PChar): Pointer{GstElement*}; cdecl;
  gst_bin_add_t = function (bin: Pointer;element: Pointer{GstElement*}): Boolean; cdecl;
  gst_bin_add_many_t = procedure(bin: Pointer;element_1: Pointer{GstElement*};additional: array of const); cdecl;
  gst_element_link_many_t = function (element_1: Pointer{GstElement*};element_2: Pointer{GstElement*};additional: array of const): Boolean; cdecl;
  gst_element_set_state_t = function (element: Pointer{GstElement*};state: GstElementState): GstElementState; cdecl;
  gst_element_get_state_T = function (element: Pointer{GstElement*};var state: GstElementState ; var pending: GstElementState;timeout: pTimeVal): GstElementState; cdecl;


var
  libgst_dynamic_dll_error: string;

  gst_init_check :gst_init_check_t;
  gst_element_factory_make : gst_element_factory_make_t;
  gst_bin_new : gst_bin_new_t;
  gst_bin_add : gst_bin_add_t;
  gst_bin_add_many : gst_bin_add_many_t;
  gst_element_link_many : gst_element_link_many_t;
  gst_element_set_state : gst_element_set_state_t;
  gst_element_get_state : gst_element_get_state_T;


  procedure libGST_dynamic_dll_init;
  procedure libGST_dynamic_dll_done;
implementation
uses
  Classes, SysUtils, dynlibs;

const
{$IFDEF WINDOWS}
libgst_name = 'libgstcoreelements.so';
{$ENDIF WINDOWS}
{$IFDEF LINUX}
libgst_name = 'libgstbase-0.10.so';
{$ENDIF LINUX}

var
libgst_handle: THandle;

function libGST_dll_get_proc_addr(var addr: Pointer; const name: PAnsiChar): Boolean;
begin
  addr := GetProcedureAddress(libGST_handle, name);
  Result := (addr <> NIL);
  if not Result then
  begin
    libGST_dynamic_dll_error := 'Procedure "' + name + '" not found!';
  end;
end;

procedure libGST_dynamic_dll_init();
var
  cdir: string;
begin
  if (libGST_handle <> 0) then exit;

  libGST_handle := LoadLibrary(PAnsiChar(libGST_name));

  // exit, report error
  if (libGST_handle = 0) then
  begin
    libGST_dynamic_dll_error :=
      'Library not found ' + libGST_name + ', '+
      'GetLastError() = ' + IntToStr(GetLastOSError);
    exit;
  end;

  if not libGST_dll_get_proc_addr(pointer(gst_element_factory_make),  'gst_element_factory_make') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_init_check),  'gst_init') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_bin_new),  'gst_bin_new') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_bin_add),  'gst_bin_add') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_bin_add_many),  'gst_bin_add_many') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_element_link_many),  'gst_element_link_many') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_element_set_state),  'gst_element_set_state') then   exit;
  if not libGST_dll_get_proc_addr(pointer(gst_element_get_state),  'gst_element_get_state') then   exit;
end;

procedure libgst_dynamic_dll_done();
begin
  if (libgst_handle <> 0) then FreeLibrary(libgst_handle);
end;

initialization

  libgst_handle := 0;

finalization

end.


