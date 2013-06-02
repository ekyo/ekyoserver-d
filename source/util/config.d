/**
   Copyright: © 2013 Simon Kérouack.
   License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
   Authors: Simon Kérouack
*/

module util.config;

public import yaml;
import std.typecons, std.stdio, std.traits;

/**
   Custom constructors for scalar and mappings can be added by tag.
   Ex.: constructor.addConstructorScalar("!tag", &constructTagScalar);
   Ex.: constructor.addConstructorMapping("!tag", &constructTagMapping);

   the tags can be made implicit by adding an implicit resolver.
   resolver.addImplicitResolver("!tag", regex, possibleFirstCharacters);
 */
alias void function(Config) Decorator;
Decorator[] decorators;

class Config {
  static void registerDecorator(Decorator decorator) {
    decorators ~= decorator;
  }

  /**
     Load configuration files in memory.

     The files are to be listed in priority order.

     If a sought value is not found in the first file,
     it will be looked up in the next until it is found.
   */
  this(string[] filenames...) {
    constructor = new Constructor;
    resolver = new Resolver;

    foreach(ref decorator; decorators) {
      decorator(this);
    }

    foreach(ref filename; filenames) {
      auto loader = Loader(filename);
      loader.constructor = constructor;
      loader.resolver = resolver;
      _root ~= loader.load();
    }
  }

  Constructor constructor;
  Resolver resolver;

  /**
     Try to get a value from the config.

     will return an exception if:
     - no configuration contains the value
     - the value's type is invalid
  */
  T get(T)(string[] keys...) {
    Node node = _get(keys);
    try {
      return node.as!T;
    } catch {
      throw new Exception("Invalid Configuration");
    }
  }

  /**
     Same as above, but return a defaultValue instead of exceptions.
   */
  T tryGet(T)(lazy T defaultValue, string[] keys...) {
    try {
      return get!T(keys);
    } catch {
      return defaultValue;
    }
  }

  /**
     Same as above, but uses Nullable instead of exceptions.
  */
  Nullable!T nullGet(T)(string[] keys...) {
    Nullable!T value;
    try {
      value = get!T(keys);
    } catch {}

    return value;
  }

  /**
     Extract an array from the config.
   */
  T[] getArray(T)(string[] keys...) {
    T[] output;
    Node node;

    try {
      node = _get(keys);
    } catch (Exception e) {
      return output;
    }

    try {
      foreach(T e; node)
        output ~= e;
      
      return output;
    } catch {
      throw new Exception("Invalid Configuration");
    }
  }

  /**
     Force the config to always return a set value for a given path.
   */
  Node overwrite(T)(T value, string[] keys...) {
    _overrides[_getPath(keys)] = Node(value);
  }

  private {
    /**
       Gets the first "Node" corresponding to search criteria.
     */
    Node _get(string[] keys...) {
      string path = _getPath(keys);
      if (path in _overrides)
        return _overrides[path];

      foreach(i, root; _root) {
        try {
          return _get(root, keys);
        } catch (Exception e) {
        }
      }

      throw new Exception("missing from Configuration");
    }

    /**
       Gets the exact node matching our key-path, for a specific config tree.
       throws exceptions when it cannot.
     */
    Node _get(Node tree, string[] keys...) {
      Node now = tree[keys[0]];
      return (keys.length == 1) ? now : _get(now, keys[1..$]);
    }

    /**
       Convert a path from multiple strings to a single one delimited by '/'
     */
    string _getPath(string[] keys) {
      auto path = "";
      foreach(i, key; keys) {
        if (i > 0) path ~= "/";
        path ~= key;
      }
      return path;
    }

    Node[] _root; // The loaded config trees.
    Node[string] _overrides; // The overriden values.
    
  }  // End of private
}
