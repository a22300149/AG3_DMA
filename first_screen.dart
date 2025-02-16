import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'nuevo_reg.dart';
import 'busqueda.dart';

class FirstScreen extends StatefulWidget {
  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _user;
  final DatabaseReference _booksRef = FirebaseDatabase.instance.ref("libros");
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadBooks();
  }

  void _loadUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  void _loadBooks() {
    _booksRef.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        setState(() {
          _books = [];
          _isLoading = false;
        });
        return;
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map;
      List<Map<String, dynamic>> booksList = [];

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          booksList.add({...value, 'id': key});
        }
      });

      booksList.sort((a, b) => a['titulo'].toString().compareTo(b['titulo'].toString())); // Ordena alfabéticamente

      setState(() {
        _books = booksList;
        _isLoading = false;
      });
    }, onError: (error) {
      print("Error al cargar los libros: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _editBook(String bookId, String currentTitle, String currentAuthor, String currentGenre, String currentImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(
          bookId: bookId,
          currentTitle: currentTitle,
          currentAuthor: currentAuthor,
          currentGenre: currentGenre,
          currentImage: currentImage,
        ),
      ),
    );
  }

  void _deleteBook(String bookId) {
    _booksRef.child(bookId).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Libro eliminado")));
      _loadBooks();  // Recargar los libros después de eliminar
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar el libro")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Catálogo de libros"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Tarjeta de bienvenida
            Card(
              child: SizedBox(
                height: 150,
                width: 350,
                child: Center(
                  child: Text(
                    _user != null
                        ? "¡Bienvenido, ${_user!.displayName}!"
                        : "¡Bienvenido al catálogo de libros!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Lista de libros
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _books.isEmpty
                ? Center(child: Text("No hay libros disponibles"))
                : Container(
              height: 500, // Ajusta el tamaño según lo que quepa en tu pantalla
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  var book = _books[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: book['imagen'] != null
                          ? Image.network(book['imagen'], width: 45, height: 70, fit: BoxFit.cover)
                          : Icon(Icons.book),
                      title: Text(book['titulo'] ?? "Sin título"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book['autor'] ?? "Autor desconocido"),
                          Text(book['genero'] ?? "Desconocido"), // Mostrar género
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _editBook(
                              book['id'],
                              book['titulo'] ?? "",
                              book['autor'] ?? "",
                              book['genero'] ?? "",
                              book['imagen'] ?? "",
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBook(book['id']),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Al presionar la tarjeta, navegar a la página de detalles del libro
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsPage(
                              title: book['titulo'] ?? "Sin título",
                              author: book['autor'] ?? "Autor desconocido",
                              genre: book['genero'] ?? "Desconocido",
                              imageUrl: book['imagen'] ?? "",
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_user?.displayName ?? "Invitado"),
              accountEmail: Text(_user?.email ?? "No hay sesión activa"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
            ),
            ListTile(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  _scaffoldKey.currentState?.closeDrawer();
                },
              ),
            ),
            ListTile(
              title: Text("Inicio"),
              leading: Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Nuevo registro"),
              leading: Icon(Icons.add),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => NuevoPage()));
              },
            ),
            ListTile(
              title: Text("Búsqueda"),
              leading: Icon(Icons.search),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => BuscarPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BookDetailsPage extends StatelessWidget {
  final String title;
  final String author;
  final String genre;
  final String imageUrl;

  BookDetailsPage({required this.title, required this.author, required this.genre, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detalles del libro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: imageUrl.isEmpty
                  ? Icon(Icons.image, size: 150)
                  : Image.network(imageUrl, width: 100, height: 150, fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            Text("Título: $title", style: TextStyle(fontSize: 22)),
            SizedBox(height: 10),
            Text("Autor: $author", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text("Género: $genre", style: TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  final String bookId;
  final String currentTitle;
  final String currentAuthor;
  final String currentGenre;
  final String currentImage;

  EditPage({required this.bookId, required this.currentTitle, required this.currentAuthor, required this.currentGenre, required this.currentImage});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;  // Controlador para el género
  final ImagePicker _picker = ImagePicker();
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _authorController = TextEditingController(text: widget.currentAuthor);
    _genreController = TextEditingController(text: widget.currentGenre); // Inicializar con el género actual
    _imageUrl = widget.currentImage;
  }

  void _saveBook() {
    // Actualizar los datos en Firebase
    FirebaseDatabase.instance.ref('libros/${widget.bookId}').update({
      'titulo': _titleController.text,
      'autor': _authorController.text,
      'genero': _genreController.text,  // Guardar el género
      'imagen': _imageUrl,
    }).then((_) {
      Navigator.pop(context);  // Regresar a la pantalla anterior
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Libro actualizado")));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar el libro")));
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Subir la imagen a Firebase Storage
      final Reference storageReference = FirebaseStorage.instance.ref().child('libros/${widget.bookId}');
      final UploadTask uploadTask = storageReference.putFile(File(pickedFile.path));
      uploadTask.whenComplete(() async {
        final String downloadUrl = await storageReference.getDownloadURL();
        setState(() {
          _imageUrl = downloadUrl;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Libro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(  // Centrar la imagen
                child: _imageUrl.isEmpty
                    ? Icon(Icons.image, size: 100)
                    : Image.network(_imageUrl, width: 100, height: 150, fit: BoxFit.cover),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(labelText: "Autor"),
            ),
            TextField(
              controller: _genreController, // Campo de género
              decoration: InputDecoration(labelText: "Género"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBook,
              child: Text("Guardar cambios"),
            ),
          ],
        ),
      ),
    );
  }
}

class NuevoPage extends StatefulWidget {
  @override
  _NuevoPageState createState() => _NuevoPageState();
}

class _NuevoPageState extends State<NuevoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _generoController = TextEditingController(); // Campo de género
  final TextEditingController _autorController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('libros');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false; // Estado para indicar si la imagen se está subiendo

  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String bookId) async {
    if (_image == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      Reference ref = _storage.ref().child("libros/$bookId.jpg");
      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return imageUrl;
    } catch (e) {
      print("Error al subir imagen: $e");
      setState(() {
        _isUploading = false;
      });
      return null;
    }
  }

  void _clearForm() {
    _tituloController.clear();
    _generoController.clear();
    _autorController.clear();
    setState(() {
      _image = null;
    });
  }

  void _saveToFirebase() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor seleccione una imagen antes de registrar el libro')),
        );
        return;
      }

      final titulo = _tituloController.text;
      final genero = _generoController.text; // Obtener género
      final autor = _autorController.text;

      DatabaseReference newBookRef = _database.push();
      String bookId = newBookRef.key!;

      String? imageUrl = await _uploadImage(bookId);

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen. Inténtelo de nuevo.')),
        );
        return;
      }

      await newBookRef.set({
        'titulo': titulo,
        'genero': genero, // Guardar género en Firebase
        'autor': autor,
        'imagen': imageUrl,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Libro registrado con éxito')),
        );
        _clearForm();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar libro: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro de libro"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el título';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _generoController,
                decoration: InputDecoration(labelText: 'Género'), // Campo para Género
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el género';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _autorController,
                decoration: InputDecoration(labelText: 'Autor'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el autor';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectImage,
                child: Text('Seleccionar Imagen'),
              ),
              SizedBox(height: 10),
              _image != null
                  ? Image.file(_image!, width: 150, height: 150, fit: BoxFit.cover)
                  : Text('No se ha seleccionado ninguna imagen'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _saveToFirebase,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Registrar Libro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
