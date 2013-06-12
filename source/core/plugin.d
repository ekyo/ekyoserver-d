/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.plugin;
public import std.string, std.traits, std.functional, std.conv, std.exception;
public import core.logger.logger, core.logger.named, core.logger.console;
public import util.config, util.args;

alias Plugin function(Logger, Config) PluginConstructor;
PluginConstructor[] toLoad;

abstract class Plugin : NamedLogger {
  this(Logger logger,
       Config config,
       string name,
       bool register = true) {
    string level = config.tryGet!string(EnumValueAsString(defaultLogLevel),
                                        name, "logLevel");

    super(name, logger, EnumValueFromString!LogLevel(level));
    _name = name;
    if(register) registerPlugin(_name);
  }

  void setup(Config config) { }
  void init() { Silly("Ready"); }
  @property string name() { return _name; }

  static T getPlugin(T)(string name) {
    if (name in plugins)
      return cast(T) plugins[name];
    else
      throw new Exception("No such plugin: " ~ name);
  }

  void registerPlugin(string name = _name) {
    if (name in plugins)
      throw new Exception("Plugin already loaded: " ~ name);
    else {
      plugins[name] = this;
      if (name != _name) Verbose("Plugin registered as '" ~ name ~ "'");
      else Verbose("Plugin registered");
    }
  }

  private {
    string _name;
  }
}

mixin template PluginMixin() {
  public this(Logger logger,
              Config conf,
              string name = "",
              bool register = true) {
    if(name.length == 0) name = typeof(this).stringof[0..$-6];
    super(logger,conf,name,register);

    setup(conf);
  }

  static this() {
    toLoad ~= (Logger logger, Config config) => new typeof(this)(logger,config);
  }
}

__gshared Plugin[string] plugins;
