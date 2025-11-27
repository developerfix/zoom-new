
class Connection {
  final String id;
  final int fromCardIndex;
  final int toCardIndex;
  final PortSide fromSide;
  final PortSide toSide;
  final int? fromPortIndex;
  final int? toPortIndex;

  Connection({
    required this.id,
    required this.fromCardIndex,
    required this.toCardIndex,
    required this.fromSide,
    required this.toSide,
    this.fromPortIndex,
    this.toPortIndex,
  });

  Connection copy() {
    return Connection(
      id: id,
      fromCardIndex: fromCardIndex,
      toCardIndex: toCardIndex,
      fromSide: fromSide,
      toSide: toSide,
      fromPortIndex: fromPortIndex,
      toPortIndex: toPortIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCardIndex': fromCardIndex,
      'toCardIndex': toCardIndex,
      'fromSide': fromSide.name,
      'toSide': toSide.name,
      'fromPortIndex': fromPortIndex,
      'toPortIndex': toPortIndex,
    };
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      fromCardIndex: json['fromCardIndex'],
      toCardIndex: json['toCardIndex'],
      fromSide: PortSide.values.firstWhere((e) => e.name == json['fromSide']),
      toSide: PortSide.values.firstWhere((e) => e.name == json['toSide']),
      fromPortIndex: json['fromPortIndex'],
      toPortIndex: json['toPortIndex'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Connection &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum PortSide {
  left,
  right,
}