class BusTrip {
  final String routeNo;
  final String tripId;
  final String busNumber;
  final String from;
  final String to;
  final List<String> stops;
  final DateTime departureDate;
  final String departureTime;
  String status;

  BusTrip({
    required this.tripId,
    required this.routeNo,
    required this.busNumber,
    required this.from,
    required this.to,
    required this.stops,
    required this.departureDate,
    required this.departureTime,
    required this.status,
  });
}
