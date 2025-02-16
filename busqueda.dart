import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BuscarPage extends StatefulWidget {
  @override
  _BuscarPageState createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("libros");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchBooks() {
    String searchText = _searchController.text.trim().toLowerCase();

    if (searchText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    _databaseRef.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map;
      List<Map<String, dynamic>> results = [];

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          String titulo = (value['titulo'] ?? '').toString().toLowerCase();
          String autor = (value['autor'] ?? '').toString().toLowerCase();
          String genero = (value['genero'] ?? '').toString().toLowerCase();

          if (titulo.contains(searchText) || autor.contains(searchText) || genero.contains(searchText)) {
            results.add({...value, 'id': key});
          }
        }
      });

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }, onError: (error) {
      print("Error al buscar libros: $error");
      setState(() => _isLoading = false);
    });
  }

  Future<void> _pickAndUploadImage(String bookId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String fileName = "libros/$bookId.jpg";
    Reference ref = _storage.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(file);

    try {
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await _databaseRef.child(bookId).update({'imagen': imageUrl});
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Imagen actualizada correctamente")),
      );
    } catch (e) {
      print("Error al subir imagen: $e");
    }
  }

  void _deleteBook(String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar Libro"),
        content: Text("¿Estás seguro de que deseas eliminar este libro?"),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _databaseRef.child(bookId).remove();
              await _storage.ref().child("libros/$bookId.jpg").delete().catchError((_) {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Libro eliminado correctamente")),
              );
            },
          ),
        ],
      ),
    );
  }

  void _editBook(String bookId, String currentTitle, String currentAuthor, String currentGenre) {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController authorController = TextEditingController(text: currentAuthor);
    TextEditingController genreController = TextEditingController(text: currentGenre);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar Libro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: "Autor"),
            ),
            TextField(
              controller: genreController,
              decoration: InputDecoration(labelText: "Género"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Guardar", style: TextStyle(color: Colors.green)),
            onPressed: () async {
              await _databaseRef.child(bookId).update({
                'titulo': titleController.text,
                'autor': authorController.text,
                'genero': genreController.text,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Libro actualizado correctamente")),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.image, color: Colors.blue),
            onPressed: () => _pickAndUploadImage(bookId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Buscar Libros")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Buscar por título, autor o género",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Center(child: Text("No se encontraron resultados"))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final libro = _searchResults[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: libro['imagen'] != null
                          ? Image.network(libro['imagen'], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 50, color: Colors.grey),
                      title: Text(libro['titulo'] ?? "Sin título"),
                      subtitle: Text(
                        '${libro['autor'] ?? "Autor desconocido"} | ${libro['genero'] ?? "Género desconocido"}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _editBook(
                              libro['id'],
                              libro['titulo'] ?? "",
                              libro['autor'] ?? "",
                              libro['genero'] ?? "",
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBook(libro['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
