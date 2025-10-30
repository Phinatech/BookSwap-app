import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class PostBookScreen extends StatefulWidget {
  final Book? editing;
  const PostBookScreen({super.key, this.editing});

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _swapFor = TextEditingController();
  String _condition = 'New';
  File? _image;

  @override
  void initState() {
    super.initState();
    final b = widget.editing;
    if (b != null) {
      _title.text = b.title;
      _author.text = b.author;
      _swapFor.text = b.swapFor;
      _condition = b.condition;
    }
  }

  Future<void> _pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (p != null) setState(() => _image = File(p.path));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<BookProvider>();
    final editing = widget.editing;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Post a Book' : 'Edit Book')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _title, validator: _req, decoration: const InputDecoration(labelText: 'Book Title')),
            const SizedBox(height: 12),
            TextFormField(controller: _author, validator: _req, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 12),
            TextFormField(controller: _swapFor, decoration: const InputDecoration(labelText: 'Swap For')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 'New', child: Text('New')),
                DropdownMenuItem(value: 'Like New', child: Text('Like New')),
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Used', child: Text('Used')),
              ],
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  image: _image != null
                      ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                      : (editing?.imageUrl.isNotEmpty == true)
                          ? DecorationImage(image: NetworkImage(editing!.imageUrl), fit: BoxFit.cover)
                          : null,
                ),
                child: _image == null && (editing?.imageUrl.isEmpty ?? true)
                    ? const Center(child: Text('Tap to add cover image'))
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                if (editing == null) {
                  await prov.create(
                    title: _title.text.trim(),
                    author: _author.text.trim(),
                    condition: _condition,
                    swapFor: _swapFor.text.trim(),
                    cover: _image,
                  );
                } else {
                  await prov.update(
                    id: editing.id,
                    title: _title.text.trim(),
                    author: _author.text.trim(),
                    condition: _condition,
                    swapFor: _swapFor.text.trim(),
                    cover: _image,
                    currentImageUrl: editing.imageUrl,
                  );
                }
                if (mounted) Navigator.pop(context);
              },
              child: Text(editing == null ? 'Post' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}