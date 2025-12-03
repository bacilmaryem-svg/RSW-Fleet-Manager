class Trip {
  final String id;
  String tripCode;
  String tripDate;
  String vessel;

  Trip({
    required this.id,
    required this.tripCode,
    required this.tripDate,
    required this.vessel,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tripCode': tripCode,
    'tripDate': tripDate,
    'vessel': vessel,
  };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
    id: map['id'],
    tripCode: map['tripCode'],
    tripDate: map['tripDate'],
    vessel: map['vessel'],
  );
}
