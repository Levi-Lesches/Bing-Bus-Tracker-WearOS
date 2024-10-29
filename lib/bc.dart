import "dart:convert";

import "package:http/http.dart";
import "package:spot/api.dart";

const stopID = 421;
const stopUrl = "https://bctransit.doublemap.com/map/v2/eta?stop=$stopID";

class BcApi extends BusApi {
  final _client = Client();

  @override
  Future<void> init() async { }

  @override
  void dispose() => _client.close();

  @override
  Future<Duration?> getEta() async {
    final response = await _client.get(Uri.parse(stopUrl));
    final responseData = jsonDecode(response.body);
    final etas = responseData["etas"]["$stopID"]["etas"] as List;
    if (etas.isEmpty) return null;
    final eta = etas.first as Map;
    final minutes = eta["avg"] as int;
    return Duration(minutes: minutes);
  }
}
