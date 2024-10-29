// ignore_for_file: avoid_print

import "package:spot/bc.dart";
// import "package:spot/spot.dart";

void main() async {
  final api = BcApi();
  await api.init();
  final eta = await api.getEta();
  print(eta == null ? "No bus" : "Bus arrives in ${eta.inMinutes} minutes");
  api.dispose();
}
