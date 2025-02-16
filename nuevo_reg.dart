import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class NuevoPage extends StatefulWidget {
  @override
  _NuevoPageState createState() => _NuevoPageState();
}

class _NuevoPageState extends State<NuevoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
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
      final genero = _generoController.text;
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
        'genero': genero,
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
                decoration: InputDecoration(labelText: 'Género'),
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
