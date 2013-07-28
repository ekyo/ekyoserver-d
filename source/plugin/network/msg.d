/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module plugin.network.msg;
public import std.string, util.enums, plugin.network.serviceenum;

enum RouteType {
  Request,
  Response,
  Error,
  OrderedRequest,
  OrderedResponse,
  OrderedError,
  Notification,
  AuthRequest,
  AuthResponse,
  AuthError
}

enum EncodingType {
  Raw,
  Json,
  MsgPack
}

struct MsgHeader {
  RouteType type;
  ubyte serviceId;
  ubyte routeId;
  EncodingType encoding;
}

struct NetworkMsg2 {
  NetworkMsg raw;
  NetworkMsg json;

  static NetworkMsg2 create(T...)(ubyte serviceId,
                                  ubyte routeId,
                                  RouteType type,
                                  string[] format,
                                  T data) {
    NetworkMsg2 msg;
    msg.raw = NetworkMsg.create!T(serviceId, routeId,
                                  type, EncodingType.Raw,
                                  format, data);
    msg.json = NetworkMsg.create!T(serviceId, routeId,
                                   type, EncodingType.Json,
                                   format, data);
    return msg;
  }

  NetworkMsg get(EncodingType type) {
    switch(type) {
    case EncodingType.Raw:
      return raw;
    case EncodingType.Json:
      return json;
    default:
      return json;
    }
  }
}

struct NetworkMsg {
  MsgHeader header;
  ubyte[] data;

  string toString() {
    try {
      return format("%s %s:%s encoding:%s data:%s",
                    EnumValueAsString(header.type),
                    getServiceName(header.serviceId),
                    getRouteName(header.serviceId, header.routeId),
                    EnumValueAsString(header.encoding),
                    cast(string)data);
    } catch {
      return format("%s %s:%s encoding:%s data:%s",
                    EnumValueAsString(header.type),
                    header.serviceId,
                    header.routeId,
                    EnumValueAsString(header.encoding),
                    data);
    }
  }

  static NetworkMsg create(T...)(ubyte serviceId,
                                 ubyte routeId,
                                 RouteType type,
                                 EncodingType encoding,
                                 string[] format,
                                 T data) {
    NetworkMsg msg;
    msg.header.serviceId = serviceId;
    msg.header.routeId = routeId;
    msg.header.type = type;
    msg.header.encoding = encoding;

    switch(encoding) {
    case EncodingType.Raw:
      foreach(int i, Type; T) {
        rawEncode!Type(msg.data, data[i]);
      }
      break;
    case EncodingType.Json:
      Json json = Json.EmptyObject;
      foreach(int i, val; data)
        json[format[i]] = val;
      msg.data = cast(ubyte[]) json.toString();
      break;
    default:
      break;
    }

    return msg;
  }

  static void rawEncode(T)(ref ubyte[] buf, T val) {
    static if (is(T == string)) {
      buf ~= cast(ubyte) val.length;
      buf ~= cast(ubyte[]) val;
    } else {
      static if (T.sizeof == 1) {
        buf ~= to!ubyte(val);
      } else {
        buf ~= *cast(ubyte[T.sizeof]*)(&val);
      }
    }
  }
  static void rawDecode(T)(in ubyte[] buf, ref ulong c, out T var) {
    static if(is(T==string)) {
      ulong l = cast(ulong) buf[c]; c+=1;
      var = cast(string) buf[c .. c+l]; c+=l;
    } else {
      static if(T.sizeof == 1) {
        var = to!T(buf[c]); ++c;
      } else {
        var = *cast(T*)(buf[c .. c+T.sizeof]); c+=T.sizeof;
      }
    }
  }
}
