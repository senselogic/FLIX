/*
    This file is part of the Flix distribution.

    https://github.com/senselogic/FLIX

    Copyright (C) 2022 Eric Pelzer (ecstatic.coder@gmail.com)

    Flix is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Flix is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Flix.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import std.algorithm : countUntil;
import std.conv : to;
import std.file : dirEntries, exists, rename, SpanMode;
import std.path : extension, setExtension;
import std.stdio : writeln, File;
import std.string : startsWith;

// -- VARIABLES

bool
    PreviewOptionIsEnabled;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    Exception exception
    )
{
    PrintError( message );
    PrintError( exception.msg );

    exit( -1 );
}

// ~~

string[] GetFileExtensionArray(
    string file_path
    )
{
    File
        file;
    ubyte[4]
        file_header;

    if ( file_path.exists() )
    {
        try
        {
            file = File( file_path, "rb" );
            file.rawRead( file_header[] );
        }
        catch ( Exception exception )
        {
            writeln( "Can't read file : ", file_path );

            return null;
        }

        if ( file_header[ 0 .. 2 ] == [ 0xff, 0xd8 ] )
        {
            return [ ".jpg", ".jpeg" ];
        }
        else if ( file_header[ 0 .. 4 ] == [ 0x89, 0x50, 0x4E, 0x47 ] )
        {
            return [ ".png" ];
        }
    }

    return null;
}

// ~~

void ProcessFiles(
    string folder_path
    )
{
    string
        file_extension,
        fixed_file_path;
    string[]
        file_extension_array;

    try
    {
        foreach ( file_path; dirEntries( folder_path, SpanMode.depth ) )
        {
            file_extension = file_path.extension();

            if ( file_extension == ".jpg"
                 || file_extension == ".jpeg"
                 || file_extension == ".png" )
            {
                file_extension_array = GetFileExtensionArray( file_path );

                if ( file_extension_array.countUntil( file_extension ) < 0 )
                {
                    writeln( "Invalid extension : ", file_path );

                    if ( file_extension_array.length > 0 )
                    {
                        fixed_file_path = file_path.setExtension( file_extension_array[ 0 ] );

                        writeln( "Fixing extension : ", fixed_file_path );

                        if ( fixed_file_path.exists() )
                        {
                            PrintError( "Can't rename file : " ~ file_path );
                        }
                        else if ( !PreviewOptionIsEnabled )
                        {
                            try
                            {
                                file_path.rename( fixed_file_path );
                            }
                            catch ( Exception exception )
                            {
                                PrintError( "Can't rename file : " ~ file_path );
                            }
                        }
                    }
                }
            }
        }
    }
    catch ( Exception exception )
    {
        Abort( "Can't process files", exception );
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    long
        argument_count;
    string
        option;

    argument_array = argument_array[ 1 .. $ ];

    PreviewOptionIsEnabled = false;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--preview" )
        {
            PreviewOptionIsEnabled = true;
        }
        else
        {
            break;
        }
    }

    if ( argument_array.length == 1 )
    {
        ProcessFiles( argument_array[ 0 ] );
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    flix [options] FOLDER_PATH/" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
