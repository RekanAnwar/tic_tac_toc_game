import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_ai.dart';

class GamePageAI extends ConsumerStatefulWidget {
  const GamePageAI({super.key});

  @override
  _TicTacToePageState createState() => _TicTacToePageState();
}

class _TicTacToePageState extends ConsumerState<GamePageAI> {
  final GameAI _game = GameAI();
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
          _showWinDialog('Victory! You are the winner!');
        } else if (_winner == 'O') {
          _aiWins++;
          _showWinDialog('Game Over - AI is victorious!');
        } else if (_winner == 'Tie') {
          _showWinDialog('Draw! The game is tied.');
        }

        if (_winner == '' && _currentPlayer == 'X') {
          _currentPlayer = 'O';
          final List<int> move = _game.bestMove('O', diffcult);
          _game.makeMove(move[0], move[1], 'O');
          _winner = _game.checkWinner();
          if (_winner == 'O') {
            _aiWins++;
            _showWinDialog('Defeat! The AI has won this round.');
          } else if (_winner == 'Tie') {
            _showWinDialog('Draw! The game is tied.');
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
          title: const Text('Game Over'),
          content: Text(message, textAlign: TextAlign.center),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Play Again'),
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
          GameAI.boardSize, (_) => List.filled(GameAI.boardSize, ''));
      _currentPlayer = 'X';
      _winner = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe AI'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    'Select Level',
                    style: TextStyle(fontSize: 24),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton(
                      value: diffcult,
                      hint: const Text('level'),
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      items: [
                        const DropdownMenuItem(
                            value: 10,
                            child: Text(
                              'Hard',
                              style: TextStyle(fontSize: 20),
                            )),
                        const DropdownMenuItem(
                            value: 7,
                            child: Text(
                              'Medium',
                              style: TextStyle(fontSize: 20),
                            )),
                        const DropdownMenuItem(
                          value: 3,
                          child: Text(
                            'Easy',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          diffcult = value!;
                          setState(() {});
                          // _resetGame();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildBoard(),
          const SizedBox(height: 20),
          Text(
            'Player Score: $_playerWins',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          Text(
            'AI Score: $_aiWins',
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
          crossAxisCount: GameAI.boardSize,
        ),
        itemCount: GameAI.boardSize * GameAI.boardSize,
        itemBuilder: (context, index) {
          final int row = index ~/ GameAI.boardSize;
          final int col = index % GameAI.boardSize;
          return GestureDetector(
            onTap: () => _makeMove(row, col),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
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
