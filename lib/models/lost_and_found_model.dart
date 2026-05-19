class LostAndFoundModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String location;
  final String date;
  final String postedBy;
  final String userId;
  final String contactNumber; // ✅ NEW
  final DateTime createdAt;

  LostAndFoundModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.date,
    required this.postedBy,
    required this.userId,
    required this.contactNumber, // ✅ NEW
    required this.createdAt,
  });

  factory LostAndFoundModel.fromMap(Map<String, dynamic> map, String id) {
    return LostAndFoundModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'lost',
      location: map['location'] ?? '',
      date: map['date'] ?? '',
      postedBy: map['postedBy'] ?? '',
      userId: map['userId'] ?? '',
      contactNumber: map['contactNumber'] ?? '', 
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'location': location,
      'date': date,
      'postedBy': postedBy,
      'userId': userId,
      'contactNumber': contactNumber, 
      'createdAt': createdAt,
    };
  }
}