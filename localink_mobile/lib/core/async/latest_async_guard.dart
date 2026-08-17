/// Sequence-number guard so the latest async request always wins.
class LatestAsyncGuard {
  int _id = 0;

  int next() => ++_id;

  bool isLatest(int id) => id == _id;

  void invalidate() => _id++;
}
