/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.logger.named;

public import core.logger.logger;
import std.datetime;

class NamedLogger : Logger {
  this(string name, Logger logger, LogLevel level = LogLevel.Silly) {
    _name = name;
    _level = level;
    _logger = logger;
    mute = false;
  }

  bool mute;

  void log(LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    if (level <= _level && !mute)
      _logger.log(level, _name, txt, file, line);
  }

  void log(LogLevel level,
           string category,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    if (level <= _level)
      _logger.log(level, _name, txt, file, line);
  }

  private {
    string _name;
    LogLevel _level;
    Logger _logger;
  }
}
