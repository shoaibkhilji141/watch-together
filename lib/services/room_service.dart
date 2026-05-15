class Room {
  final String id;
  final String name;

  Room({
    required this.id,
    required this.name,
  });
}

class RoomService {
  // Temporary in-memory implementation for UI wiring.
  Future<Room> createRoom({required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Room(id: id, name: name);
  }

  Future<bool> joinRoom({required String code}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Always allow join for now; replace with real validation.
    return code.trim().isNotEmpty;
  }
}

