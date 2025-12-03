class Buyer {
  final String id;
  final String name;

  Buyer({required this.id, required this.name});

  factory Buyer.fromMap(Map<String, dynamic> map) =>
      Buyer(id: map['id'], name: map['name']);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}
