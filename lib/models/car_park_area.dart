class CarParkArea {
  final String fcmTopic;
  final String name;
  final double latitude;
  final double longitude;
  final String imageUrl;
  bool enable;

  CarParkArea({
    this.fcmTopic,
    this.name,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.enable = false,
  });
}
