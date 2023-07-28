import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(PuzzleGameApp());
}

class PuzzleGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzle Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PuzzleSizeSelectionScreen(),
                  ),
                );
              },
              child: Text('Oyna'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Uygulamadan çıkış yapılıyor.
                SystemNavigator.pop();
              },
              child: Text('Çıkış'),
            ),
          ],
        ),
      ),
    );
  }
}

class PuzzleSizeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzle Boyutu Seç'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Her satırda 3 kutucuk olacak
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
            ),
            itemBuilder: (context, index) {
              int size = index + 2; // 2x2'den başlayarak 10x10'a kadar
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PuzzleGameScreen(rows: size, columns: size),
                    ),
                  );
                },
                child: Text('$size x $size'),
              );
            },
            itemCount: 9, // 2x2'den 10x10'a kadar toplam 9 seçenek
          ),
        ),
      ),
    );
  }
}

class PuzzleGameScreen extends StatefulWidget {
  final int rows;
  final int columns;

  PuzzleGameScreen({required this.rows, required this.columns});

  @override
  _PuzzleGameScreenState createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  late List<List<int>> dividedIndices;

  bool puzzleCompleted = false;

  @override
  void initState() {
    super.initState();
    dividedIndices = splitImageIndices(widget.rows, widget.columns);
  }

  List<int> generateShuffledIndices(int size) {
    List<int> indices = List.generate(size, (index) => index);
    indices.shuffle();
    return indices;
  }

  List<List<int>> splitImageIndices(int rows, int columns) {
    List<int> shuffledIndices = generateShuffledIndices(rows * columns);
    List<List<int>> dividedIndices = [];
    int index = 0;
    for (int i = 0; i < rows; i++) {
      List<int> rowIndices = [];
      for (int j = 0; j < columns; j++) {
        rowIndices.add(shuffledIndices[index]);
        index++;
      }
      dividedIndices.add(rowIndices);
    }
    return dividedIndices;
  }

  void _onTileMoved(
      int sourceRow, int sourceColumn, int targetRow, int targetColumn) {
    if (!puzzleCompleted) {
      setState(() {
        int temp = dividedIndices[sourceRow][sourceColumn];
        dividedIndices[sourceRow][sourceColumn] =
            dividedIndices[targetRow][targetColumn];
        dividedIndices[targetRow][targetColumn] = temp;

        if (isPuzzleSolved()) {
          puzzleCompleted = true;
          showCongratulations();
        }
      });
    }
  }

  bool isPuzzleSolved() {
    List<int> flattenedIndices = dividedIndices.expand((row) => row).toList();
    for (int i = 0; i < flattenedIndices.length; i++) {
      if (flattenedIndices[i] != i) {
        return false;
      }
    }
    return true;
  }

  void showCongratulations() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tebrikler, Puzzle çözüldü!'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tekrar Çözmek İster Misiniz?',
          onPressed: () {
            setState(() {
              puzzleCompleted = false;

              dividedIndices = splitImageIndices(widget.rows, widget.columns);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzle Game'),
      ),
      body: Center(
        child: PuzzleBoard(
            dividedIndices: dividedIndices, onTileMoved: _onTileMoved),
      ),
    );
  }
}

class PuzzleBoard extends StatelessWidget {
  final List<List<int>> dividedIndices;
  final Function(int, int, int, int) onTileMoved;

  PuzzleBoard({required this.dividedIndices, required this.onTileMoved});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dividedIndices[0].length,
        ),
        itemBuilder: (context, index) {
          int row = index ~/ dividedIndices[0].length;
          int column = index % dividedIndices[0].length;
          int value = dividedIndices[row][column];
          return PuzzleTile(
            index: value,
            row: row,
            column: column,
            onTileMoved: onTileMoved,
          );
        },
        itemCount: dividedIndices.length * dividedIndices[0].length,
      ),
    );
  }
}

class PuzzleTile extends StatefulWidget {
  final int index;
  final int row;
  final int column;
  final Function(int, int, int, int) onTileMoved;

  PuzzleTile(
      {required this.index,
      required this.row,
      required this.column,
      required this.onTileMoved});

  @override
  _PuzzleTileState createState() => _PuzzleTileState();
}

class _PuzzleTileState extends State<PuzzleTile> {
  late Offset position = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      position = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    int targetRow =
        max(0, min(widget.row + (position.dy / 100).round(), widget.row - 1));
    int targetColumn = max(
        0, min(widget.column + (position.dx / 100).round(), widget.column - 1));
    widget.onTileMoved(widget.row, widget.column, targetRow, targetColumn);
    setState(() {
      position = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Transform.translate(
          offset: position,
          child: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
            child: Center(
              child: Text(
                '${widget.index}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
