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

Const
  CATEGORY_CONFIG = 'cfg';  // client --> server
    COMMAND_PIN = 'pin';
    COMMAND_KEEP = 'keep'; // keep connection open
    COMMAND_SIZEMODE = 'size'; // param  0: length of messages is computed in bytes
                               //        1: length of messages is computed in UTF8 codepoints (for Android mode)
    COMMAND_WANTPOS = 'autopos'; // auto send current position events

  CATEGORY_ACTION = 'act';  // client --> server
    COMMAND_PLAY = 'play';
    COMMAND_STOP = 'stop';
    COMMAND_PAUSE = 'pause' ;
    COMMAND_PLAYPAUSE = 'playpause';
    COMMAND_NEXT = 'next';
    COMMAND_PREVIOUS = 'previous';
    COMMAND_SEEK_P = 'seek+';
    COMMAND_SEEK_M = 'seek-';
    COMMAND_SEEK = 'seek';  // param is new position (seconds)
    COMMAND_SETVOL = 'vol'; // param is new volume in range 1..256
    COMMAND_MUTE = 'mute';
    COMMAND_UNMUTE = 'unmute';
    COMMAND_LOOPING = 'loop';

  CATEGORY_FILE = 'fil';   // client --> server
    COMMAND_ENQUEUE = 'e';           //   \
    COMMAND_CLEAR_AND_PLAY = 'p';    //    | --> required param = filename
    COMMAND_ENQUEUE_AND_PLAY = 'x';  //   /

  CATEGORY_APP = 'app';  // client --> server
    COMMAND_ACTIVATE = 'activate';
    COMMAND_QUIT = 'quit';
    COMMAND_CLOSE = 'close';

  CATEGORY_INFORMATION = 'inf'; // server --> client
  CATEGORY_REQUEST = 'req'; //  client --> server
    INFO_ENGINE_STATE = 'state';
    INFO_POSITION = 'pos';
    INFO_VOLUME = 'vol';
    INFO_METADATA = 'meta';  // optional param playlist item number
    INFO_PLAYLISTCOUNT = 'count';
    INFO_PLAYLISTINDEX = 'index';
    INFO_COVERURL = 'coverurl';
    INFO_COVERIMG = 'coverimg'; // Base64 encoding of cover image
    INFO_FULLPLAYLIST = 'playlist';
    INFO_PLAYLISTCHANGE = 'plchange'; // change on current playlist
    INFO_LOOPING = 'loop'; // changed repeat mode
    INFO_MUTE = 'mute';

  CATEGORY_HEART = 'hrt';
    COMMAND_BEAT = 'beat';

  CATEGORY_COMMAND_SEPARATOR = ':';
  CATEGORY_PARAM_SEPARATOR = '=';
  IPC_SEPARATOR = '|'; // used by communication based on SimpleIPC

{
My personal implementation of a netstrings-like protocol, where each string
is prefixed by it's length.

To avoid sending binary data, length is defined as a 24 bit unsigned integer.
This 3-byte integer is then encoded in Base64, so it became a 4 byte ASCII string
This means that max message size is 16 Mb, I think this is a fair limit.
}


implementation


end.

