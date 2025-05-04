import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();
  List<String> notes = [];
  bool _isSaving = false;
  int? _selectedNoteIndex;

  // Material 3 color scheme
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedNotes = prefs.getStringList('profit_notes');
    if (savedNotes != null) {
      setState(() {
        notes = savedNotes;
      });
    }
  }

  Future<void> saveNote() async {
    if (noteController.text.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_selectedNoteIndex != null) {
        // Update existing note
        setState(() {
          notes[_selectedNoteIndex!] = noteController.text;
          _selectedNoteIndex = null;
        });
      } else {
        // Add new note
        setState(() {
          notes.insert(0,
              '${noteController.text} • ${DateFormat('MMM d, yyyy').format(DateTime.now())}');
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('profit_notes', notes);

      noteController.clear();
      noteFocusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_selectedNoteIndex != null ? 'Note updated' : 'Note saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _colorScheme.primary,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> deleteNote(int index) async {
    setState(() {});

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        notes.removeAt(index);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('profit_notes', notes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {});
  }

  void _editNote(int index) {
    // Extract just the note text without the timestamp
    final noteParts = notes[index].split(' • ');
    final noteText = noteParts.length > 1 ? noteParts[0] : notes[index];

    setState(() {
      _selectedNoteIndex = index;
      noteController.text = noteText;
      noteFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Notes'),
        actions: [
          if (_selectedNoteIndex != null)
            IconButton(
              icon: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : saveNote,
              tooltip: 'Save note',
            ),
        ],
      ),
      body: Column(
        children: [
          // Note input section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: noteController,
                focusNode: noteFocusNode,
                decoration: InputDecoration(
                  labelText: _selectedNoteIndex != null
                      ? 'Editing note'
                      : 'Add new note',
                  hintText: 'Type your investment notes here...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.note_add),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: (value) => setState(() {}),
                onSubmitted: (value) => saveNote(),
              ),
            ),
          ),

          // Save button
          if (noteController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : saveNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Note'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _colorScheme.primary,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Notes list
          Expanded(
            child: notes.isEmpty ? _buildEmptyState() : _buildNotesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notes Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first investment note above',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final noteParts = notes[index].split(' • ');
        final noteText = noteParts[0];
        final noteDate = noteParts.length > 1 ? noteParts[1] : '';

        return Dismissible(
          key: Key('${notes[index]}$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          confirmDismiss: (direction) async {
            await deleteNote(index);
            return false; // We handle deletion in deleteNote()
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editNote(index),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noteText,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            noteDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editNote(index),
                            color: _colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
