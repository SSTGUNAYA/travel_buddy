class BusRoute {
  final String routeNo;
  final String from;
  final String to;
  final List<String> stops;
  final String estimatedTime;

  BusRoute({
    required this.routeNo,
    required this.from,
    required this.to,
    required this.stops,
    required this.estimatedTime,
  });
}

final List<BusRoute> busRoutes = [
  BusRoute(
    routeNo: "138",
    from: "Pettah",
    to: "Homagama",
    stops: ["Pettah", "Nugegoda", "Maharagama", "Homagama"],
    estimatedTime: "75 min",
  ),

  BusRoute(
    routeNo: "120",
    from: "Pettah",
    to: "Horana",
    stops: ["Pettah", "Maharagama", "Kottawa", "Horana"],
    estimatedTime: "90 min",
  ),

  BusRoute(
    routeNo: "177",
    from: "Colombo",
    to: "Kaduwela",
    stops: ["Colombo", "Rajagiriya", "Battaramulla", "Kaduwela"],
    estimatedTime: "60 min",
  ),
];
