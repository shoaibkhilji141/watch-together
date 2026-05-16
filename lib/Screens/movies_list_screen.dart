import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/movies_service.dart';
import '../utils/app_palette.dart';
import 'watch_screen.dart';

class MoviesListScreen extends StatefulWidget {
  final String roomId;

  /// When true, returns to [WatchScreen] after picking (host changing movie).
  final bool pickOnly;

  const MoviesListScreen({
    super.key,
    required this.roomId,
    this.pickOnly = false,
  });

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  final _searchController = TextEditingController();
  final _moviesService = MoviesService();

  List<Movie> _allMovies = [];
  String _searchQuery = '';
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isSelecting = false;
  String? _error;

  List<Movie> get _filteredMovies =>
      MoviesService.filterByTitle(_allMovies, _searchQuery);

  int get _totalPages => MoviesService.totalPages(_filteredMovies.length);

  List<Movie> get _pageMovies =>
      MoviesService.pageSlice(_filteredMovies, _currentPage);

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final movies = await _moviesService.fetchAllMovies();
      if (!mounted) return;
      setState(() {
        _allMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load movies. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onMovieSelected(Movie movie) async {
    if (_isSelecting || movie.videoUrl.isEmpty) return;

    setState(() => _isSelecting = true);

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'videoType': 'direct',
        'videoUrl': movie.videoUrl,
        'movieTitle': movie.title,
        'movieImageUrl': movie.imageUrl,
        'videoSource': 'catalog',
        'isPlaying': false,
        'currentTime': 0,
      });

      if (!mounted) return;

      if (widget.pickOnly) {
        Navigator.pop(context, movie);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WatchScreen(
            roomId: widget.roomId,
            roomName: movie.title,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Failed to start movie.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  void _showSnack(String message) {
    final p = AppPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
        content: Text(
          message,
          style: TextStyle(color: p.textPrimary, fontSize: 13.5),
        ),
      ),
    );
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page.clamp(0, _totalPages - 1));
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.gold.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _MoviesTopBar(
                    roomId: widget.roomId,
                    pickOnly: widget.pickOnly,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Text(
                    widget.pickOnly ? 'Change movie' : 'Choose a movie',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: Text(
                    'Pick what everyone will watch in room ${widget.roomId}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: p.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchField(
                    controller: _searchController,
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildBody(p)),
                _PaginationBar(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  totalItems: _filteredMovies.length,
                  onPrevious: _currentPage > 0
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                  onNext: _currentPage < _totalPages - 1
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
          if (_isSelecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(p.gold),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Starting movie…',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: p.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(p.gold),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadMovies,
              child: Text('Retry', style: TextStyle(color: p.gold)),
            ),
          ],
        ),
      );
    }

    if (_filteredMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, color: p.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No movies in catalog yet.'
                  : 'No movies match your search.',
              style: TextStyle(color: p.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _pageMovies.length,
      itemBuilder: (context, index) {
        final movie = _pageMovies[index];
        return _MovieCard(
          movie: movie,
          onTap: () => _onMovieSelected(movie),
        );
      },
    );
  }
}

class _MoviesTopBar extends StatelessWidget {
  final String roomId;
  final bool pickOnly;
  final VoidCallback onBack;

  const _MoviesTopBar({
    required this.roomId,
    required this.pickOnly,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.border),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: p.textSecondary,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: p.gold,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.play_arrow_rounded, color: p.bg, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            pickOnly ? 'Movie catalog' : 'Room $roomId',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(color: p.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by title…',
          hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: p.textSecondary, size: 22),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: p.textSecondary, size: 20),
                  onPressed: widget.onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: movie.imageUrl.isNotEmpty
                    ? Image.network(
                        movie.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: p.surfaceAlt,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(p.gold),
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _PosterPlaceholder(p: p),
                      )
                    : _PosterPlaceholder(p: p),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Text(
                movie.title,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  final AppPalette p;

  const _PosterPlaceholder({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: p.surfaceAlt,
      child: Center(
        child: Icon(Icons.movie_outlined, color: p.gold.withValues(alpha: 0.5), size: 36),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final start = totalItems == 0 ? 0 : currentPage * MoviesService.pageSize + 1;
    final end = ((currentPage + 1) * MoviesService.pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: onPrevious != null,
            onTap: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                if (totalItems > 0)
                  Text(
                    'Showing $start–$end of $totalItems',
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
              ],
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: onNext != null,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? p.surfaceAlt : p.surfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
        ),
        child: Icon(
          icon,
          color: enabled ? p.gold : p.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
