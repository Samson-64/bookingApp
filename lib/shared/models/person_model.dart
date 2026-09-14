class Person {
  final String id;
  final String name;
  final String position;

  Person({required this.id, required this.name, required this.position});

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      position: map['position']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'position': position};
}