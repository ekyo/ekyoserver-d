/**
   Copyright: © 2013 Simon Kérouack.
   License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
   Authors: Simon Kérouack
*/
module util.enums;

public import std.traits;
import std.file, std.stdio, std.algorithm, std.format, std.string;

/+ Get a string representation of an enum value.
 +/
string EnumValueAsString(T)(T e)
  if (is(T == enum)) {
    foreach(i, member; EnumMembers!T)
      if (e == member)
        return  __traits(allMembers, T)[i];
    assert(0, "Not an enum member");
  }

private void delegate()[] saveMethods;
void saveEnums() {
  foreach(method; saveMethods)
    method();
}

T EnumValueFromString(T)(string e)
  if (is(T == enum)) {
    foreach(i, member; EnumMembers!T)
      if (__traits(allMembers, T)[i] == e)
        return member;
    assert(0, e ~ " is not an enum member");
  }

class Enum(T) {
  this() {}

  this(string enumName) {
    saveMethods ~= { save(); };
    _enumName = enumName;
    _filename = "generated/cs/" ~ _enumName ~ "Enum.cs";

    if(!exists(_filename))
      return;
    auto file = File(_filename, "r");
    bool inEnum = false;
    foreach(line; file.byLine)
      if(inEnum) {
        if(countUntil(line,"}") != -1)
          inEnum = false;
        else {
          string l = cast(string)line.strip();
          string name;
          char end;
          T value;
          formattedRead(l, "%s = %s%s", &name, &value, &end);
          if (end == ';') {
            inEnum = false;
            _last = value;
          }
          _names[value] = name;
          _values[name] = value;
        }
      } else if(countUntil(line,"{") != -1)
        inEnum = true;
  }

  T opCall(string name) {
    if (name !in _values)
      return add(name);
    else
      return _values[name];
  }

  @property T opDispatch(string name)() {
    return opCall(name);
  }

  string toString() {
    string str;
    foreach(k, v; _values)
      str ~= format("%s: %s\n", k, v);
    if(str.length != 0)
      str = str[0..$-1];
    return str;
  }

  string name(T value) { return _names[value]; }

  bool exist(string name) {
    return (name in _values) ? true : false;
  }
  bool existValue(T value) {
    return (value in _names) ? true: false;
  }

  private {
    string _filename;
    string _enumName;
    T[string] _values;
    string[T] _names;
    T _last;

    T add(string name) {
      T value = ++_last;
      _names[value] = name;
      _values[name] = value;
      return value;
    }

    void save() {
      _values.rehash();
      _names.rehash();
      T[] values = _names.keys;

      if(values.length == 0) return;

      sort(values);
      auto last = values[$-1];

      auto file = File(_filename, "w");

      char end = ',';
      file.writeln("// Generated");
      file.writeln("public enum " ~ _enumName);
      file.writeln("{");
      foreach(v; values) {
        if (v == last)
          end = ';';
        file.writefln("\t%s = %s%s", _names[v], v, end);
      }
      file.writeln("};");
    }
  }
}
