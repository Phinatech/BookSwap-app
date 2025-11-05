import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';

class PostBookScreen extends StatefulWidget {
  final Map<String, dynamic>? editing;
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
  XFile? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final b = widget.editing;
    if (b != null) {
      _title.text = b['title'] ?? '';
      _author.text = b['author'] ?? '';
      _swapFor.text = b['swapFor'] ?? '';
      _condition = b['condition'] ?? 'New';
    }
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery, 
      imageQuality: kIsWeb ? 50 : 85,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (x != null) setState(() => _image = x);
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
            DropdownButtonFormField<String>(
              initialValue: _condition,
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
                ),
                child: _image != null
                    ? FutureBuilder<Widget>(
                        future: _buildImagePreview(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data!;
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      )
                    : const Center(child: Text('Tap to add cover image (optional)')),
              ),
            ),
            const SizedBox(height: 24),
_loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;

                      setState(() => _loading = true);
                      
                      try {
                        if (editing == null) {
                          await prov.create(
                            title: _title.text.trim(),
                            author: _author.text.trim(),
                            condition: _condition,
                            swapFor: _swapFor.text.trim(),
                            imageFile: _image,
                          );
                        } else {
                          await prov.update(
                            id: editing['id'],
                            title: _title.text.trim(),
                            author: _author.text.trim(),
                            condition: _condition,
                            swapFor: _swapFor.text.trim(),
                            imageFile: _image,
                            currentImageUrl: editing['imageUrl'] as String?,
                          );
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(editing == null ? 'Book posted successfully!' : 'Book updated successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                    child: Text(editing == null ? 'Post' : 'Save'),
                  ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<Widget> _buildImagePreview() async {
    if (_image == null) return const SizedBox();
    
    try {
      if (kIsWeb) {
        return Image.network(_image!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_image!.path), fit: BoxFit.cover);
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
