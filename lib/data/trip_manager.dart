import 'trips.dart';

class TripManager {
  static final List<BusTrip> trips = [];

  // Add a new trip
  static void addTrip(BusTrip trip) {
    trips.add(trip);
  }

  // Update an existing trip
  static void updateTrip(BusTrip trip) {
    final index = trips.indexWhere((existingTrip) => existingTrip == trip);

    if (index != -1) {
      trips[index] = trip;
    }
  }

  // Get all trips
  static List<BusTrip> getAllTrips() {
    return List.unmodifiable(trips);
  }

  // Get scheduled trips
  static List<BusTrip> getScheduledTrips() {
    return trips.where((trip) => trip.status == 'Scheduled').toList();
  }

  // Get live trips
  static List<BusTrip> getLiveTrips() {
    return trips.where((trip) => trip.status == 'Live').toList();
  }

  // Find trips by route number
  static List<BusTrip> getTripsByRoute(String routeNo) {
    return trips.where((trip) => trip.routeNo == routeNo).toList();
  }

  // Find trips by From and To
  static List<BusTrip> getTripsByDirection(String from, String to) {
    return trips.where((trip) => trip.from == from && trip.to == to).toList();
  }
}
