class Home {
  final int idx;
  final String title;
  final String? description;
  final String? location;
  final String? address;
  final String? thumbnail;
  final int costBasic;
  final int? costExpen;
  final String? homeType;
  final int maxPeople;
  final int? room;
  final int? bath;
  final int? bed;
  final int? checkIn;
  final int? checkOut;

  Home({
    required this.idx,
    required this.title,
    this.description,
    this.location,
    this.address,
    this.thumbnail,
    required this.costBasic,
    this.costExpen,
    this.homeType,
    required this.maxPeople,
    this.room,
    this.bath,
    this.bed,
    this.checkIn,
    this.checkOut,
  });

  factory Home.fromJson(Map<String, dynamic> j) => Home(
    idx: j['idx'] ?? j['id'] ?? 0,
    title: j['title'] ?? '',
    description: j['description'],
    location: j['location'],
    address: j['address'],
    thumbnail: j['thumbnail'],
    costBasic: j['costBasic'] ?? 0,
    costExpen: j['costExpen'],
    homeType: j['homeType']?.toString(),
    maxPeople: j['maxPeople'] ?? 0,
    room: j['room'],
    bath: j['bath'],
    bed: j['bed'],
    checkIn: j['checkIn'],
    checkOut: j['checkOut'],
  );
}
