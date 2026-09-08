class BusTrip {
  final String routeNo;
  final String tripId;
  final String busNumber;
  final String busCategory;
  final String from;
  final String to;
  final List<String> stops;
  final DateTime departureDate;
  final String departureTime;
  String status;

  // GPS DATA
  double? latitude;
  double? longitude;
  double? accuracy;

  BusTrip({
    required this.tripId,
    required this.routeNo,
    required this.busNumber,
    required this.busCategory,
    required this.from,
    required this.to,
    required this.stops,
    required this.departureDate,
    required this.departureTime,
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracy,
  });
}
