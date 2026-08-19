import 'trips.dart';

class TripManager {
  static final List<BusTrip> trips = [];

  // ------------------------------------------------------------
  // ADD TRIP
  // ------------------------------------------------------------
  static void addTrip(BusTrip trip) {
    final index = trips.indexWhere(
      (existingTrip) => existingTrip.tripId == trip.tripId,
    );

    if (index == -1) {
      trips.add(trip);
    } else {
      trips[index] = trip;
    }
  }

  // ------------------------------------------------------------
  // UPDATE TRIP
  // ------------------------------------------------------------
  static void updateTrip(BusTrip trip) {
    final index = trips.indexWhere(
      (existingTrip) => existingTrip.tripId == trip.tripId,
    );

    if (index != -1) {
      trips[index] = trip;
    } else {
      trips.add(trip);
    }
  }

  // ------------------------------------------------------------
  // FIND ACTIVE TRIP BY BUS NUMBER
  // Scheduled or Live
  // ------------------------------------------------------------
  static BusTrip? getActiveTripByBusNumber(String busNumber) {
    try {
      return trips.firstWhere(
        (trip) =>
            trip.busNumber == busNumber &&
            (trip.status == 'Scheduled' || trip.status == 'Live'),
      );
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // FIND TRIP BY ID
  // ------------------------------------------------------------
  static BusTrip? getTripById(String tripId) {
    try {
      return trips.firstWhere((trip) => trip.tripId == tripId);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // GET ALL TRIPS
  // ------------------------------------------------------------
  static List<BusTrip> getAllTrips() {
    return List.unmodifiable(trips);
  }

  // ------------------------------------------------------------
  // GET SCHEDULED TRIPS
  // ------------------------------------------------------------
  static List<BusTrip> getScheduledTrips() {
    return trips.where((trip) => trip.status == 'Scheduled').toList();
  }

  // ------------------------------------------------------------
  // GET LIVE TRIPS
  // ------------------------------------------------------------
  static List<BusTrip> getLiveTrips() {
    return trips.where((trip) => trip.status == 'Live').toList();
  }

  // ------------------------------------------------------------
  // GET TRIPS BY ROUTE
  // ------------------------------------------------------------
  static List<BusTrip> getTripsByRoute(String routeNo) {
    return trips.where((trip) => trip.routeNo == routeNo).toList();
  }

  // ------------------------------------------------------------
  // GET TRIPS BY BUS NUMBER
  // ------------------------------------------------------------
  static List<BusTrip> getTripsByBusNumber(String busNumber) {
    return trips.where((trip) => trip.busNumber == busNumber).toList();
  }

  // ------------------------------------------------------------
  // GET TRIPS BY DIRECTION
  // ------------------------------------------------------------
  static List<BusTrip> getTripsByDirection(String from, String to) {
    return trips.where((trip) => trip.from == from && trip.to == to).toList();
  }
}
