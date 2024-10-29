import "dart:convert";
import "package:http/http.dart";

import "package:spot/api.dart";

const routesUrl   = "https://binghamtonupublic.etaspot.net/service.php?service=get_routes";
const vehiclesUrl = "https://binghamtonupublic.etaspot.net/service.php?service=get_vehicles&includeETAData=1&orderedETAArray=1";
const stopsUrl    = "https://binghamtonupublic.etaspot.net/service.php?service=get_stops";
const stopName    = "UCLUB";
const routeName   = "UCLUB";

class SpotApi extends BusApi {
  final client = Client();
  late int stopId;
  late Set<int> routes;

  @override
  Future<void> init() async {
    final stopsResponse = await client.get(Uri.parse(stopsUrl));
    final stopsData = jsonDecode(stopsResponse.body);
    stopId = [
      for (final stop in stopsData["get_stops"])
        if (stop["name"].contains(stopName))
          stop["id"],
    ].first;

    final routesResponse = await client.get(Uri.parse(routesUrl));
    final routesData = jsonDecode(routesResponse.body);
    routes = {
      for (final route in routesData["get_routes"])
        if (route["name"].contains(routeName))
          route["id"],
    };
  }

  @override
  void dispose() => client.close();

  @override
  Future<Duration?> getEta() async {
    final vehiclesResponse = await client.get(Uri.parse(vehiclesUrl));
    final vehiclesData = jsonDecode(vehiclesResponse.body);
    final vehicles = [
      for (final vehicle in vehiclesData["get_vehicles"])
        if (routes.contains(vehicle["routeID"]))
          vehicle,
    ];

    final etas = [
      for (final vehicle in vehicles) [
        for (final eta in vehicle["minutesToNextStops"])
          if (eta["stopID"] == stopId)
            eta["minutes"],
      ],
    ];

    final minutes = [
      for (final sublist in etas)
        if (sublist.isNotEmpty)
          Duration(minutes: sublist.first),
    ];

    return minutes.nullIfEmpty?.reduce((a, b) => a < b ? a : b);
  }
}

extension <E> on Iterable<E> {
  Iterable<E>? get nullIfEmpty => isEmpty ? null : this;
}
