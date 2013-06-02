/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.logger.console;

public import core.logger.logger, util.color;
import std.stdio;

class ConsoleLogger {
  public {
    this(bool showTime = true) {
      this._showTime = showTime;
      this._bufswitch = true;
    }

    /+ Log Function for Console
     + Note that it does not log the hostname nor the version.
     +/
    void displayLog(LogData log) {
      log.level.useColor();
      if(_showTime)
        writef("%s%s ",
               log.time.toISOExtString().leftJustify(29),
               ("["~EnumValueAsString(log.level)~"]").rightJustify(9));
      else
        writef("[%s]: ", EnumValueAsString(log.level));
      log.level.useColor(true);
      if (log.category.length != 0) write(log.category ~ ": ");
      log.level.useColor();
      writeln(log.txt);
      if (log.level <= LogLevel.Error)writeln(format("\t➜  %s:%s ", log.file, log.line));
      setFontColor();
    }

    void storeLog(LogData log) {
      if (_bufswitch)
        _buf1 ~= log;
      else
        _buf2 ~= log;
    }

    void displayLogs() {
      _bufswitch = !_bufswitch;
      if (_bufswitch) {
        foreach(log; _buf2) displayLog(log);
        _buf2.clear();
      } else {
        foreach(log; _buf1) displayLog(log);
        _buf1.clear();
      }
    }
  }

  private {
    bool _showTime;
    shared bool _bufswitch;
    LogData[] _buf1, _buf2;
  }
}

struct FontColor {
  Color front;
  Color back;

  this(Color f, Color b) {
    front = f;
    back = b;
  }
}

FontColor[LogLevel] fontColor;
void setColor(LogLevel level, Color front, Color back) {
  fontColor[level] = FontColor(front, back);
}

void useColor(LogLevel level, bool highlight = false) {
  if(level in fontColor) {
    auto font = fontColor[level];
    setFontColor(font.front, font.back, highlight);
  } else {
    final switch(level) {
    case LogLevel.Emergency:
      setFontColor(Color.White, Color.Red, highlight);
      break;
    case LogLevel.Alert:
      setFontColor(Color.White, Color.Red, highlight);
      break;
    case LogLevel.Critical:
      setFontColor(Color.White, Color.Red, highlight);
      break;
    case LogLevel.Error:
      setFontColor(Color.Red, Color.Default, highlight);
      break;
    case LogLevel.Warn:
      setFontColor(Color.Orange, Color.Default, highlight);
      break;
    case LogLevel.Notice:
      setFontColor(Color.Default, Color.Default, highlight);
      break;
    case LogLevel.Info:
      setFontColor(Color.Default, Color.Default, highlight);
      break;
    case LogLevel.Debug:
      setFontColor(Color.Green, Color.Default, highlight);
      break;
    case LogLevel.Verbose:
      setFontColor(Color.Blue, Color.Default, highlight);
      break;
    case LogLevel.Silly:
      setFontColor(Color.Pink, Color.Default, highlight);
      break;
    }
  }
}

void coloredwriteln(string msg,
                    Color front = Color.Default,
                    Color back = Color.Default,
                    bool highlight = false) nothrow {
  try {
    setFontColor(front, back, highlight);
    writeln(msg);
    setFontColor();
  } catch (Exception e) {
    debug assert(false, e.msg);
  }
}

void coloredwrite(string msg,
                  Color front = Color.Default,
                  Color back = Color.Default,
                  bool highlight = false) nothrow {
  try {
    setFontColor(front, back, highlight);
    write(msg);
    setFontColor();
  } catch (Exception e) {
    debug assert(false, e.msg);
  }
}
