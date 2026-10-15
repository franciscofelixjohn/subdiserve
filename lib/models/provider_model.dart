class ProviderModel {
  final String id;
  final String name;
  final String email;
  final String role;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory ProviderModel.fromMap(String id, Map<String, dynamic> data) {
    return ProviderModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}