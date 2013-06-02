/**
   Never really tried it in windows.
*/

module util.color;

version(Windows)
{
  import std.c.windows.windows, std.algorithm, std.stdio;

  enum Color : ushort
  {
    Black   = 0,
      Blue    = 1,
      Green   = 2,
      Azure   = 3,
      Red     = 4,
      Purple  = 5,
      Yellow  = 6,
      Silver  = 7,

      /*Gray      = 8,
        Blue        = 9,
        Green       = 10,
        Aqua        = 11,
        Red         = 12,
        Pink        = 13,
        Yellow      = 14,
        White       = 15,*/

      Default     = 256
      }

  static this()
  {
    hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

    // Get current colors
    CONSOLE_SCREEN_BUFFER_INFO info;
    GetConsoleScreenBufferInfo( hConsole, &info );
    defBg = cast(Color)(info.wAttributes & (0b11110000));
    defFg = cast(Color)(info.wAttributes & (0b00001111));

    fg = Color.Default;
    bg = Color.Default;
  }

  package static
    {
      extern(C) HANDLE hConsole = null;

      shared Color fg, bg, defFg, defBg;
      shared bool isHighlighted;
    }


  private ushort buildColor(Color fg, Color bg)
  {
    if(fg == Color.Default) {
      fg = defFg;
    }

    if(bg == Color.Default) {
      bg = defBg;
    }

    if(isHighlighted)
      {
        if(fg != Color.Default) {
          fg = cast(Color)( min(fg + 8, 15) );
        } else {
          fg = cast(Color)( min(defFg + 8, 15) );
        }
      }

    return cast(ushort)(fg | bg << 4);
  }

  Color getConsoleForeground()
  {
    return fg;
  }

  Color getConsoleBackground()
  {
    return bg;
  }

  void setFontHighlight(bool enable)
  {
    isHighlighted = enable;
    setConsoleForeground(fg);
    setConsoleBackground(bg);
  }

  bool isFontHighlighted()
  {
    return isHighlighted;
  }

  void setConsoleForeground(Color color)
  {
    stdout.flush();
    SetConsoleTextAttribute(hConsole, buildColor(color, bg));
    fg = color;
  }

  void setConsoleBackground(Color color)
  {
    stdout.flush();
    SetConsoleTextAttribute(hConsole, buildColor(fg, color));
    bg = color;
  }

}
 else version(Posix)
 {
   import std.stdio;

   extern(C) int isatty(int);

   enum Color : ushort
   {
     Black   = 30,
       Red     = 31,
       Green   = 32,
       Orange  = 33,
       Blue    = 34,
       Pink    = 35,
       Aqua    = 36,
       White   = 37,

       Default = 0
       }

   static
   {
     shared Color fg = Color.Default;
     shared Color bg = Color.Default;

     shared bool isHighlighted;
   }

   private bool isRedirected()
   {
     return isatty( fileno(stdout.getFP) ) == 1;
   }

   void setConsoleForeground(Color color)
   {
     if(!isRedirected()) {
       return;
     }

     if(color == Color.Default)
       {
         writef("\033[%dm", isHighlighted ? 1 : 0);
         fg = Color.Default;

         // Because all colors were reseted, bring back BG color
         if(bg != Color.Default)
           {
             setConsoleBackground(bg);
           }
       }
     else
       {
         writef("\033[%d;%dm", isHighlighted ? 1 : 0, cast(int)color);
         fg = color;
       }
   }

   void setConsoleBackground(Color color)
   {
     if(!isRedirected()) {
       return;
     }

     if(color == Color.Default)
       {
         writef("\033[%dm", isHighlighted ? 1 : 0);
         bg = Color.Default;

         // Because all colors were reseted, bring back FG color
         if(fg != Color.Default)
           {
             setConsoleForeground(fg);
           }
       }
     else
       {
         writef("\033[%d;%dm", isHighlighted ? 1 : 0, cast(int)color + 10);
         bg = color;
       }
   }

   void setFontHighlight(bool enable)
   {
     isHighlighted = enable;
     setConsoleForeground(fg);
     setConsoleBackground(bg);
   }

   bool isFontHighlighted()
   {
     return isHighlighted;
   }

   Color getConsoleForeground()
   {
     return fg;
   }

   Color getConsoleBackground()
   {
     return bg;
   }
 }


void setFontColor(Color foreground = Color.Default,
                  Color background = Color.Default,
                  bool highlight = false) {
  setConsoleBackground(background);
  setConsoleForeground(foreground);
  setFontHighlight(highlight);
}
