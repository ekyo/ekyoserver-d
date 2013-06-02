/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module core.logger.mongo;

public import core.logger.logger;
import std.conv, std.stdio;
import vibe.db.mongo.mongo;

/+ Log in a mongo database
 +/
class MongoLogger {
  public {
    this(string host, ushort port, string database, string collection = "logs") {
      auto client = connectMongoDB(host, port);
      auto db = client.getDatabase(database);
      coll = db[collection];
    }

    void log(LogData log) {
      coll.insert(["LogLevel": EnumValueAsString(log.level),
                   "Time": log.time.toISOExtString(),
                   "Hostname": log.hostname,
                   "ProcessId": text(log.pid),
                   "ThreadId": text(log.threadid),
                   "FiberId": text(log.fiberid),
                   "File": log.file,
                   "Line": text(log.line),
                   "Version": log.ver,
                   "Category": log.category,
                   "Text": log.txt
                   ]);
    }
  }

  private {
    MongoCollection coll;
  }
}
