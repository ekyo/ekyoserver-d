/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.daemon;
public import std.parallelism, std.stdio, std.signals;
public import vibe.db.mongo.mongo, vibe.db.redis.redis, vibe.core.core;
public import core.logger.console, core.logger.file, core.logger.mongo, core.plugin;
import std.path;
import util.enums;
import vibe.core.log; // Only used to disable vibe logs

core.logger.logger.LogLevel getLogLevel(Config config,
                                        core.logger.logger.LogLevel defaultLogLevel,
                                        string[] keys ...) {
  try {
    return EnumValueFromString!(core.logger.logger.LogLevel)
      (config.get!(string)(keys));
  } catch {
    return defaultLogLevel;
  }
}

class Daemon : Plugin {
  this(string[] args) {
    auto launchtime = Clock.currTime();

    setDefaults();
    auto config = loadConfig();

    parseArgs(args);

    auto logger = setupLogger(config);

    // Setup self
    super(logger, config, "Daemon");

    // Setup persistance database
    setupMongo(config);

    // Setup distributed cache
    setupRedis(config);

    foreach (PluginConstructor plugin; toLoad)
      plugin(logger, config);

    foreach (Plugin plugin; plugins)
      plugin.init();

    // Send the 'ready' event. - cue for generators to output.
    Silly("Sending 'ready' event");
    emit("ready");

    // For each Plugin
    // - run unit tests
    // - adjust minimum version.

    //displayLogo();

    Silly(format("CPU cores available: %s", totalCPUs));
    // Output the boot sequence duration.
    bootTime = Clock.currTime();
    Notice("Server Up in " ~ (bootTime - launchtime).fracSec.toString());

    // Launch event loop
    // If a timeout is specified: die on timeout.
    // Only ends on:
    // - timeout (if one is specified in command line args)
    // - SIGTERM
    // - SIGSEV
    // - exit == true (set by other plugins to force a clean exit)
  }

  // Events that should be received by all plugins/services go trough here
  mixin std.signals.Signal!(string);

  void setDefaults() {
    setLogLevel(vibe.core.log.LogLevel.None); // vibe log level
    configPath = "config";
    configFiles = ["dev", "default"];
    defaultLogLevel = core.logger.logger.LogLevel.Silly;
  }

  Config loadConfig() {
    string[] files;
    foreach(file; configFiles) {
      files ~= defaultExtension(buildPath(configPath, file), "yaml");
    }
    return new Config(files);
  }

  LoggerAdapter setupLogger(Config config) {
    defaultLogLevel = config.getLogLevel(defaultLogLevel, "logLevel");

    string currentVersion = "0"; // Version string, should be git commit hash

    LoggerAdapter logger = new LoggerAdapter(currentVersion);

    setupConsoleLogger(logger, config);
    setupFileLogger(logger, config);
    //setupMongoLogger(logger, config);

    return logger;
  }

  void setupConsoleLogger(LoggerAdapter logger, Config config) {
    bool silent = config.tryGet!(bool)(false, "logs", "console", "silent");
    if(!silent) {
      bool showTime = config.tryGet!(bool)(true,
                                           "logs", "console", "showTime");
      consoleLogger = new ConsoleLogger(showTime);
      auto logLevel = config.getLogLevel(defaultLogLevel,
                                         "logs", "console", "logLevel");
      logger.register("Console", &consoleLogger.displayLog, logLevel);
    }
  }

  void setupFileLogger(LoggerAdapter logger, Config config) {
    bool silent = config.tryGet!(bool)(false,
                                  "logs", "file", "silent");
    if(!silent) {
      string file = config.tryGet!(string)("logs/log.txt",
                                           "logs", "file", "path");
      fileLogger = new core.logger.file.FileLogger(file);

      auto logLevel = config.getLogLevel(defaultLogLevel,
                                         "logs", "file", "logLevel");
      logger.register("File", &fileLogger.log, logLevel);
    }
  }

  void setupMongoLogger(LoggerAdapter logger, Config config) {
    bool silent = config.tryGet!(bool)(false,
                                  "logs", "mongo", "silent");
    if(!silent) {
      string[] hosts = config.getArray!(string)("logs", "mongo", "host");
      if (hosts.length == 0)
        hosts = config.getArray!(string)("global", "mongo", "host");

      string db = config.tryGet!(string)("server",
                                         "logs", "mongo", "db");
      string coll = config.tryGet!(string)("logs",
                                           "logs", "mongo", "collection");

      string link = (hosts.length == 0) ? "localhost" :  hosts[0];

      if (hosts.length > 0)
        foreach (host; hosts[1..$]) {
          link ~= "," ~ host;
        }

      logger.Silly("Connecting to mongo at " ~ link);

      try {
        string username;
        username = config.get!string("logs", "mongo", "username");
        string password;
        password = config.get!string("logs", "mongo", "password");

        link = username ~ ":" ~ password ~ "@" ~ link;
      }
      catch (Exception e) {
        logger.Warn("No Authentication provided for Mongo Connection");
      }

      mongoLogger = new MongoLogger(link, 27017, db, coll);

      auto logLevel = config.getLogLevel(defaultLogLevel,
                                         "logs", "mongo", "logLevel");

      logger.register("Mongo", &mongoLogger.log, logLevel);
    }
  }

  void setupMongo(Config config) {
    // MongoDB
    string[] hosts = config.getArray!(string)(this.name, "mongo", "host");
    if (hosts.length == 0)
      hosts = config.getArray!(string)("global", "mongo", "host");

    string mongoHost;
    if (hosts.length == 0) mongoHost = "localhost";
    else {
      mongoHost = hosts[0];
      if (hosts.length > 1)
        foreach (h; hosts[1..$]) {
          mongoHost ~= "," ~ h;
        }
    }

    string auth = "";
    try {
      string username;
      username = config.get!string("mongo", "username");
      string password;
      password = config.tryGet!string("", "mongo", "password");

      auth = username ~ ":" ~ password ~ "@";
    } catch (Exception e) {
      Warn("No authentication provided for Mongo Connection");
    }

    string database = "/server";

    string options;
    bool safe = config.tryGet!bool(true, "mongo", "options", "safe");
    if (safe)
      options = "?safe=true";

    string link = "mongodb://" ~ auth ~ mongoHost ~ database ~ options;
    Debug("Connecting to " ~ link);

    _mongoDB = connectMongoDB(link);
  }

  void setupRedis(Config config) {
    string redisHost = config.tryGet!(string)("127.0.0.1",
                                              this.name, "redis", "host");
    ushort redisPort = config.tryGet!(ushort)(6379,
                                              this.name, "redis", "port");
    Debug(format("Connecting to redis at %s:%s", redisHost, redisPort));
    _redis = new RedisClient(redisHost, redisPort);
  }

  void displayLogo() {
    coloredwrite(r"    ______
   / __/ /____ _____
  / _//  '_/ // / _ \
 /___/_/\_\\_, /\___/
          /___/           © Simon Kérouack 2013

", Color.Green, Color.Default, false);
  }

  string configPath;
  string[] configFiles;

  SysTime bootTime;
  MongoClient _mongoDB;
  RedisClient _redis;
  core.logger.file.FileLogger fileLogger;
  ConsoleLogger consoleLogger;
  MongoLogger mongoLogger;

}
