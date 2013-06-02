/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.logger.logger;

public import std.string, util.enums, std.datetime;
import std.array, std.functional,
  std.exception, std.process,
  core.thread;

__gshared LogLevel defaultLogLevel = LogLevel.Info;

/+ Log Levels, by importance.
 +/
enum LogLevel {
  Emergency, // System is unusable
  Alert,     // Action Required Immediately
  Critical,  // A Critical Error Occured
  Error,     // An Error occured
  Warn,      // Conditions may cause error to occur
  Notice,    // Significant Informative Log
  Info,      // Informative Log
  Debug,     // Debug Log
  Verbose,   // Overly Informative Log
  Silly,     // Would be Silly to log that
}

/+ Generate Code for Simple Log Functions for any specific LogLevel.
 +/
string SimpleLogs() pure {
  string result = "";
  foreach (level; __traits(allMembers, LogLevel)) {
    result ~= "void " ~ level ~ "(T...)(lazy string txt,
        string file = __FILE__,
        size_t line = __LINE__) nothrow {
        log(LogLevel." ~ level ~ ", txt, file, line);
    } ";
  }
  return result;
}

/+ Generic Interface for logger usage
 +/
interface Logger {
  void log(LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow;

  void log(LogLevel level,
           string category,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow;

  mixin(SimpleLogs());
}

/+ Logger so lazy it does not even log.
 + Use only if you want to turn off logging.
 +/
class NullLogger : Logger {
  void log(LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {}
  void log(LogLevel level,
           string category,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {}
}

/+ Data Passed to Log Delegates
 +/
struct LogData {
  LogLevel level;   // LogLevel
  SysTime time;     // Time in UTC
  string hostname;  // Hostname, to differentiate multiple hosts logging on the same service.
  ulong pid;        // Process ID
  ulong threadid;   // Thread ID
  ulong fiberid;    // Fiber Id
  string file;      // Filename of the source file the log comes from
  size_t line;      // Line number in the source file
  string ver;       // Version set in the logger for the application. Usually the git commit hash.
  string category;
  string txt;       // Txt to log
}

/+ Function to get the current git commit hash, to be optionally used as version in logs
 + Must be in a git repository or will crash and generate noise in the shell.
 +
 + TODO: Test if currently in a git repository and return appropriate exception.
 +/
string gitCommitHash() {
  return chomp(shell("git rev-parse HEAD"));
}

alias void delegate(LogData log) LogDelegate;
alias void function(LogData log) LogFunction;

/+ The Logger Adapter, logDelegates are registered to it per logLevel (as transports)
 + it formats and dispatch logs to all appropriate transports.
 +/
class LoggerAdapter : Logger {
  private {
    struct Transport {
      LogDelegate method;

      this(LogDelegate method) {
        this.method=method;
      }
    }

    Transport[string][LogLevel] _transports;
    string _version;
  }

  this(string ver = "") {
    _version = ver;
  }

  string getVersion() {
    return _version;
  }

  void setVersion(string ver) {
    _version = ver;
    log(LogLevel.Info, format("Version set to %s", ver));
  }

  /+ Unregister a transport by name, from all logLevels
   +/
  void unregister(string name) {
    foreach(ref Transport[string] transports; _transports) {
      transports.remove(name);
    }
  }

  /+ Unregister a transport by name, from specified logLevels
   +/
  void unregister(string name, LogLevel[] levels ...) {
    foreach(LogLevel level; levels) {
      if(level in _transports)
        _transports[level].remove(name);
    }
  }


  /+ Register a transport by name for specified logLevels
   +/
  void registerSpecific(string name, LogDelegate logHandler, LogLevel[] levels ...) {
    foreach(LogLevel level; levels) {
      _transports[level][name] = Transport(logHandler);
    }
  }
  /+ Same as above.
   +/
  void registerSpecific(string name, LogFunction logHandler, LogLevel[] levels ...) {
    registerSpecific(name, toDelegate(logHandler), levels);
  }

  /+ Register a transport by name for all logLevels.
   +/
  void register(string name, LogDelegate logHandler) {
    foreach(level; EnumMembers!LogLevel) {
      register(name, logHandler, level);
    }
  }
  /+ Same as above.
   +/
  void register(string name, LogFunction logHandler) {
    register(name, toDelegate(logHandler));
  }

  /+ Register a transport by name for logLevels higher or equal to specified level
   +/
  void register(string name, LogDelegate logHandler, LogLevel level) {
    foreach(logLevel; EnumMembers!LogLevel) {
      _transports[logLevel][name] = Transport(logHandler);
      if(logLevel == level)
        return;
    }
  }
  /+ Same as above.
   +/
  void register(string name, LogFunction logHandler, LogLevel level) {
    register(name, toDelegate(logHandler), level);
  }

  /+ Log to a specific transport directly
   +/
  void log(LogDelegate logHandler,
           LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    try {
      LogData log;
      log.level = level;
      log.time = Clock.currTime(UTC());
      log.hostname = "";
      log.pid = getpid();
      log.threadid = cast(ulong) cast(void*) Thread.getThis();
      log.fiberid = cast(ulong) cast(void*) Fiber.getThis();
      log.threadid ^= log.threadid >> 32;
      log.fiberid ^= log.fiberid >> 32;
      log.file = file;
      log.line = line;
      log.ver = _version;
      log.txt = txt;
      logHandler(log);
    } catch(Exception e) {
      debug assert(false, e.msg);
    }
  }
  /+ Same as above.
   +/
  void log(LogFunction logHandler,
           LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    log(toDelegate(logHandler), level, txt, file, line);
  }

  /+ Log the text trough all registered transports for the logLevel.
   +/
  void log(LogLevel level,
           string category,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    try {
      if(level !in _transports || _transports[level].length == 0) return;

      LogData log;
      log.level = level;
      log.time = Clock.currTime(UTC());
      log.hostname = "";
      log.pid = getpid();
      log.threadid = cast(ulong) cast(void*) Thread.getThis();
      log.fiberid = cast(ulong) cast(void*) Fiber.getThis();
      log.threadid ^= log.threadid >> 32;
      log.fiberid ^= log.fiberid >> 32;
      log.file = file;
      log.line = line;
      log.ver = _version;
      log.txt = txt;
      log.category = category;

      foreach(Transport transport; _transports[level]) {
        transport.method(log);
      }
    } catch(Exception e) {
      debug assert(false, e.msg);
    }
  }

  /+ Log the text trough all registered transports for the logLevel.
   +/
  void log(LogLevel level,
           lazy string txt,
           string file = __FILE__,
           size_t line = __LINE__) nothrow {
    log(level, "Logger", txt, file, line);
  }

  /+ Log method apropriate to be registered as a transport in another LoggerAdapter.
   +/
  void log(LogData log) {
    if(log.level !in _transports || _transports[log.level].length == 0) return;

    foreach(Transport transport; _transports[log.level]) {
      transport.method(log);
    }
  }
}
