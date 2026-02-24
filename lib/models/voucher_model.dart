class Voucher {
  final String empresa;
  final String logo;
  final String ruc;
  final String direccion;
  final List items;
  final double total;

  Voucher({
    required this.empresa,
    required this.logo,
    required this.ruc,
    required this.direccion,
    required this.items,
    required this.total,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      empresa: json['empresa'],
      logo: json['logo'],
      ruc: json['ruc'],
      direccion: json['direccion'],
      items: json['items'],
      total: json['total'].toDouble(),
    );
  }
}
