import 'dart:io';
import 'package:files_gallery/storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GalleryWidget extends StatelessWidget {
  GalleryWidget({super.key});

  // Correct image file extensions
  final types = ["png", "jpg", "jpeg", "webp"];

  // Function to filter the files based on the types
  List<FileSystemEntity> filter(List<FileSystemEntity> files) {
    return files.where((file) {
      final split = file.path.split(".");
      final type = split.last.toLowerCase();
      return types.contains(type);
    }).toList();
  }

  // Function to get files from Downloads folder
  Future<List<FileSystemEntity>> getFilesFromDownloads() async {
    final directory = await ExternalStorage.getExternalStoragePath();
    final downloadsFolder = Directory("${directory.path}/Download");
    if (downloadsFolder.existsSync()) {
      return filter(downloadsFolder.listSync());
    } else {
      return [];
    }
  }

  // Function to get files from Pictures folder
  Future<List<FileSystemEntity>> getFilesFromPictures() async {
    final picturesFolder = Directory("/storage/emulated/0/Pictures");
    if (picturesFolder.existsSync()) {
      return filter(picturesFolder.listSync());
    } else {
      return [];
    }
  }

  // Fetch files from both albums
  Future<Map<String, List<FileSystemEntity>>> getAlbumFiles() async {
    final downloadsFiles = await getFilesFromDownloads();
    final picturesFiles = await getFilesFromPictures();

    return {
      'Downloads': downloadsFiles,
      'Pictures': picturesFiles,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Albums')),
      body: FutureBuilder<Map<String, List<FileSystemEntity>>>(
        future: getAlbumFiles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading albums'),
            );
          } else if (snapshot.hasData) {
            final albumData = snapshot.data!;
            if (albumData.values.every((album) => album.isEmpty)) {
              return const Center(
                child: Text('No images found in any album'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (albumData['Downloads']!.isNotEmpty)
                  _buildAlbumTile(context, 'Downloads', albumData['Downloads']!),
                if (albumData['Pictures']!.isNotEmpty)
                  _buildAlbumTile(context, 'Pictures', albumData['Pictures']!),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  // Widget to build each album tile
  Widget _buildAlbumTile(BuildContext context, String albumName, List<FileSystemEntity> images) {
    return ListTile(
      leading: Icon(Icons.image, color: Colors.blueAccent),
      title: Text(albumName),
      subtitle: Text('${images.length} images'),
      onTap: () {
        // Navigate to the gallery of that album
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumGalleryPage(
              albumName: albumName,
              images: images,
            ),
          ),
        );
      },
    );
  }
}

class AlbumGalleryPage extends StatelessWidget {
  final String albumName;
  final List<FileSystemEntity> images;

  AlbumGalleryPage({required this.albumName, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$albumName Gallery')),
      body: GridView.builder(
        itemCount: images.length,
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            // Navigate to full-screen view with swipe functionality
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  images: images,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Hero(
            tag: 'imageHero_${albumName}_$index',
            child: Image.file(
              File(images[index].path),
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatefulWidget {
  final List<FileSystemEntity> images;
  final int initialIndex;

  FullScreenImagePage({required this.images, required this.initialIndex});

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  // Example function to handle icon button presses
  void onIconPressed(String action) {
    // Handle different actions like share, edit, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action pressed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the gallery
          },
        ),
      ),
      body: Stack(
        children: [
          // PageView for swiping through images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close full screen on tap
                },
                child: Hero(
                  tag: 'imageHero_${widget.images[index].path}_$index',
                  child: Image.file(
                    File(widget.images[index].path),
                    fit: BoxFit.contain, // Fit image nicely in the screen
                  ),
                ),
              );
            },
          ),
          // Positioned bottom action bar with icons
          Positioned(
            bottom: 20, // Adjust this value if needed
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.white),
                    onPressed: () => onIconPressed('Share'),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: () => onIconPressed('Edit'),
                  ),
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () => onIconPressed('Like'),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () => onIconPressed('Delete'),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => onIconPressed('More'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}