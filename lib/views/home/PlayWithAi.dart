import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_ai.dart';

class TicTacToePage extends ConsumerStatefulWidget {
  @override
  _TicTacToePageState createState() => _TicTacToePageState();
}

class _TicTacToePageState extends ConsumerState<TicTacToePage> {
  final TicTacToe _game = TicTacToe();
  int diffcult = 3;
  String _currentPlayer = 'X';
  String _winner = '';
  int _playerWins = 0;
  int _aiWins = 0;

  void _makeMove(int row, int col) {
    if (_game.makeMove(row, col, _currentPlayer)) {
      setState(() {
        _winner = _game.checkWinner();
        if (_winner == 'X') {
          _playerWins++;
          _showWinDialog('بەخێربێیت! تۆ بردی!');
        } else if (_winner == 'O') {
          _aiWins++;
          _showWinDialog('AI برد! کارە بختت دەگایەوە!');
        } else if (_winner == 'Tie') {
          _showWinDialog('یەکسانە!');
        }

        if (_winner == '' && _currentPlayer == 'X') {
          _currentPlayer = 'O';
          List<int> move = _game.bestMove('O', diffcult);
          _game.makeMove(move[0], move[1], 'O');
          _winner = _game.checkWinner();
          if (_winner == 'O') {
            _aiWins++;
            _showWinDialog('تۆ نەتتوانی یارییەکە ببەیتەوە');
          } else if (_winner == 'Tie') {
            _showWinDialog('یەکسانە!');
          }
          _currentPlayer = 'X';
        }
      });
    }
  }

  void _showWinDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'یاری کۆتایی هات',
            textAlign: TextAlign.right,
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: <Widget>[
            ElevatedButton(
              child: const Text(
                'دووبارە یاری بکە',
                textAlign: TextAlign.right,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      _game.board = List.generate(
          TicTacToe.boardSize, (_) => List.filled(TicTacToe.boardSize, ''));
      _currentPlayer = 'X';
      _winner = '';
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'تێک تاک تۆک',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: _resetGame,
            )
          ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton(
                      value: diffcult,
                      autofocus: true,
                      hint: const Text('level'),
                      menuMaxHeight: 400,
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      items: [
                        DropdownMenuItem(
                            value: 10,
                            child: const Text(
                              'گران',
                              style: TextStyle(fontSize: 20),
                            )),
                        const DropdownMenuItem(
                            value: 7,
                            child: Text(
                              'ناوەند',
                              style: TextStyle(fontSize: 20),
                            )),
                        const DropdownMenuItem(
                            value: 3,
                            child: Text(
                              'ئاسان',
                              style: TextStyle(fontSize: 20),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          diffcult = value!;
                          setState(() {
                            
                          });
                          // _resetGame();
                        });
                      }),
                  const Text(
                    'هەڵبژاردنی ئاست',
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ],
          ),
          _buildBoard(),
          const SizedBox(height: 20),
          Text(
            'ئەنجامەکانی یاریزانی: $_playerWins',
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          Text(
            'ئەنجامەکانی AI: $_aiWins',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: TicTacToe.boardSize,
        ),
        itemCount: TicTacToe.boardSize * TicTacToe.boardSize,
        itemBuilder: (context, index) {
          int row = index ~/ TicTacToe.boardSize;
          int col = index % TicTacToe.boardSize;
          return GestureDetector(
            onTap: () => _makeMove(row, col),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 1),
                color: _game.board[row][col] == 'X'
                    ? Colors.lightBlue[100]
                    : (_game.board[row][col] == 'O'
                        ? Colors.lightGreen[100]
                        : Colors.white),
              ),
              child: Center(
                child: Text(
                  _game.board[row][col],
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class df {
  static int difficailt = 3;
}
