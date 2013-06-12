/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module util.semver;
import std.string, std.regex, std.conv;

// Semantic Versioning for API.
struct Version {
  uint major;
  uint minor;
  uint patch;

  this(uint major, uint minor, uint patch) {
    this.major = major;
    this.minor = minor;
    this.patch = patch;
  }
  
  this(string ver) {
    string[] values = std.regex.split(ver, regex(`\.`));
    major = to!uint(values[0]);
    minor = to!uint(values[1]);
    patch = to!uint(values[2]);
  }

  string toString() {
    return format("%s.%s.%s",
           major,
           minor,
           patch);
  }

  // When breaking backward compatibility,
  // 0 if the project hasn't reached a stable state yet.
  void incrMajor() {
    major++;
    minor = 0;
    patch = 0;
  }

  // Incremented when new, backwards compatible functionality is introduced.
  void incrMinor() {
    minor++;
    patch = 0;
  }

  // Incremented when backwards compatible bug fixes are introduced.
  void incrPatch() {
    patch++;
  }

  int opCmp(ref const Version v) const pure {
    if (major == v.major)
      if(minor == v.minor)
        if(patch == v.patch)
          return 0;
        else return patch < v.patch ? -1 : 1;
      else return minor < v.minor ? -1 : 1;
    else return major < v.major ? -1 : 1;
  }

  bool opEquals()(auto ref const Version v) const pure {
    return major == v.major && minor == v.minor && patch == v.patch;
  }
}
