class ParkingSpace {
  final String id;
  final String name;
  final String location;
  final bool isAvailable;

  ParkingSpace({
    required this.id,
    required this.name,
    required this.location,
    this.isAvailable = true,
  });

  factory ParkingSpace.fromMap(Map<String, dynamic> map) {
    return ParkingSpace(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
    );
  }

  ParkingSpace copyWith({bool? isAvailable}) {
    return ParkingSpace(
      id: id,
      name: name,
      location: location,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}