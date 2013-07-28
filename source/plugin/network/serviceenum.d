/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module plugin.network.serviceenum;
public import util.enums;

Enum!ubyte services;
Enum!ubyte routes[ubyte];


string getServiceName(ubyte id) {
  return services.name(id);
}

ubyte getServiceId(string name) {
  return services(name);
}

ubyte getRouteId(ubyte serviceId, string route) {
  if(serviceId !in routes)
    routes[serviceId] =
      new Enum!ubyte(getServiceName(serviceId)~"Route");
  return routes[serviceId](route);
}

string getRouteName(ubyte serviceId, ubyte routeId) {
  if(serviceId !in routes)
    routes[serviceId] =
      new Enum!ubyte(getServiceName(serviceId)~"Route");
  return routes[serviceId].name(routeId);
}

static this() {
  services = new Enum!ubyte("Service");
}
