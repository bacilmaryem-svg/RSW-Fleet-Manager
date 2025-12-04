class Cistern {
  String id;
  String tank;
  String start;
  String end;
  String water;
  String buyer;
  String weightIn;
  String weightOut;
  String netWeight;
  String tripId;

  Cistern({
    required this.id,
    required this.tank,
    required this.start,
    required this.end,
    required this.water,
    required this.buyer,
    required this.weightIn,
    required this.weightOut,
    required this.netWeight,
    this.tripId = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tank': tank,
    'start': start,
    'end': end,
    'water': water,
    'buyer': buyer,
    'weightIn': weightIn,
    'weightOut': weightOut,
    'netWeight': netWeight,
    'tripId': tripId,
  };

  factory Cistern.fromMap(Map<String, dynamic> map) => Cistern(
    id: map['id'] ?? '',
    tank: map['tank'] ?? '',
    start: map['start'] ?? '',
    end: map['end'] ?? '',
    water: map['water'] ?? '',
    buyer: map['buyer'] ?? '',
    weightIn: map['weightIn'] ?? '',
    weightOut: map['weightOut'] ?? '',
    netWeight: map['netWeight'] ?? '',
    tripId: map['tripId'] ?? '',
  );

  Cistern copyWith({
    String? id,
    String? tank,
    String? start,
    String? end,
    String? water,
    String? buyer,
    String? weightIn,
    String? weightOut,
    String? netWeight,
    String? tripId,
  }) {
    return Cistern(
      id: id ?? this.id,
      tank: tank ?? this.tank,
      start: start ?? this.start,
      end: end ?? this.end,
      water: water ?? this.water,
      buyer: buyer ?? this.buyer,
      weightIn: weightIn ?? this.weightIn,
      weightOut: weightOut ?? this.weightOut,
      netWeight: netWeight ?? this.netWeight,
      tripId: tripId ?? this.tripId,
    );
  }
}
