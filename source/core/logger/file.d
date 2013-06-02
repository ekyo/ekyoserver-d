/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.logger.file;

public import core.logger.logger;
import std.stdio, std.file;

/+ Log in a text file
 +/
class FileLogger {
  public {
    this(string logFile = "log.txt") {
      this.logFile = logFile;
      firstLog = true;
    }

    void log(LogData log) {
      if (firstLog) {
        logFile.append(format("--------------------------------------------------------------------------------\r\nversion:%s\r\n",log.ver));
        firstLog = false;
      }

      logFile.append(format("%s%s,pid:%s,threadid:%s,fiberid:%s,%s:%s,%s:%s\r\n",
                            (log.time.toISOExtString() ~ ",").leftJustify(29),
                            EnumValueAsString(log.level).rightJustify(9),
                            log.pid,
                            log.threadid,
                            log.fiberid,
                            log.file,
                            log.line,
                            log.category,
                            log.txt));
    }
  }

  private {
    string logFile;
    bool firstLog;
  }
}
