abstract class BusApi {
  Future<void> init();
  void dispose();
  Future<Duration?> getEta();
}
