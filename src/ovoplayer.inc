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
// Master include File for OVOPlayer Apps
//
{$IFDEF WINDOWS}
  {$DEFINE SUPPORT_SHAPING} // seems to work only on windows
{$ENDIF WINDOWS}

//if release is defined, try to be quiet and efficient...
{$IFDEF RELEASE}
  {$HINTS OFF}
  {$INLINE ON}
{$ENDIF RELEASE}

{$IFDEF UNIX}
  {$DEFINE NEEDCFGSUBDIR} // Need to add a sub-directory to configuration files directory
  {$DEFINE ASKMMKEYSMODE} // Ask for multimedia keys capture mode
  {.$DEFINE GSTREAMER} // GStreamer need glib
{$ENDIF UNIX}

{$DEFINE VLC} //
{$DEFINE XINE} //
{$DEFINE BASS} //



