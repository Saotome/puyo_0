// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';

import 'parameters.dart';
import 'draw.dart';
import 'point.dart';

List<List<int>> next_puyo = new List.generate(PLAYER_NUM, (n) => new List<int>());
List board = new List.generate(PLAYER_NUM, (p) => new List.generate(FIELD_WIDTH, (x) => new List.generate(FIELD_HEIGHT, (y) => PUYO_BLOCK)));
List current = new List.generate(PLAYER_NUM, (m) => new CurrentPuyo(3,2,0));

//AI debug
int max_chain_num = 0;
List<int> chain = new List.filled(20, 0);

//DOM
final CanvasRenderingContext2D ctx = (querySelector("#canvas") as CanvasElement).context2D;
final InputElement button_next = querySelector("#button_next");
final InputElement button_clear = querySelector("#button_clear");

void main() {
  document.onKeyUp.listen((e) => keyUpEvent(e));
  button_next.onClick.listen((e) => buttonNextClick());
  button_clear.onClick.listen((e) => buttonClearClick());
  querySelector('#output').text = 'Dart is running.';
  String str = conpensateTsumo(makeNextBuffer()).toString();
  initialize();
  querySelector('#output').text = board.toString();
  //debugPuyo();
  
  draw(ctx, board, current, next_puyo);
  //doEval();
}

void keyUpEvent(KeyboardEvent e) {
  switch(e.keyCode) {
    case KC_N:
      buttonNextClick();
      break;
    case KC_C:
      initialize();
      break;
    default:
      break;
  }
}

void buttonNextClick() {
  button_next.disabled = true;
  Stopwatch stopwatch = new Stopwatch()..start();
  if(isChain(copyList2D(board[0]))) {
    board[0] = checkChain(copyList2D(board[0]));
    board[0] = fall(copyList2D(board[0]));
  } else {
    max_chain_num = 0;
    current[PLAYER_ONE] = selectNextMove(board, next_puyo, PLAYER_ONE);
    
    putPuyo(PLAYER_ONE, board, current, next_puyo);
    updateNextPuyo(PLAYER_ONE);
    updateCurrentPuyo(PLAYER_ONE);
    board[0] = fall(copyList2D(board[0]));
  }
  
  querySelector('#output').text = "${current[PLAYER_ONE].point.toString()} 点 ${stopwatch.elapsedMilliseconds.toString()} ms $max_chain_num 連鎖";
  draw(ctx, board, current, next_puyo);
  button_next.disabled = false;
}

void doEval() {
  int chain_num = 0;
  for(int i = 0; i < 50; ) {
    while(isChain(copyList2D(board[0]))) {
      board[0] = checkChain(copyList2D(board[0]));
      board[0] = fall(copyList2D(board[0]));
      chain_num++;
    }
    if(chain_num > 0) {
      chain[chain_num]++;
      chain_num = 0;
      i++;
    }
    current[PLAYER_ONE] = selectNextMove(board, next_puyo, PLAYER_ONE);
    
    putPuyo(PLAYER_ONE, board, current, next_puyo);
    updateNextPuyo(PLAYER_ONE);
    updateCurrentPuyo(PLAYER_ONE);
    board[0] = fall(copyList2D(board[0]));
    if(gameIsOver(board[0])) {
      chain[0]++;
      initialize();
    }
  }
  querySelector('#output').text = chain.toString();
}

void buttonClearClick() {
  initialize();
  draw(ctx, board, current, next_puyo);
}

CurrentPuyo selectNextMove(List board, List next, int player) {
  return EvalMaxMove(copyList3D(board), player, next, 0, new CurrentPuyo(3,2,0));
}

CurrentPuyo EvalMaxMove(List B_now, int player, List next, int depth, CurrentPuyo move) {
  if(depth > DEPTH_MAX) return EvalMove(B_now, B_now, player, next, move);
  List moves = MakeNextMove(B_now, player);
  CurrentPuyo max_move = new CurrentPuyo(PUYO_X_DEF, PUYO_Y_DEF, SUB_DEF);
  
  for(int i = 0; i < moves.length; i++) {
    List buf = copyList3D(B_now);
    List prev = copyList3D(B_now);
    buf[player][moves[i].x][moves[i].y] = next[player][depth * 2];
    buf[player][moves[i].x + SUB_POS[moves[i].dir]['x']][moves[i].y + SUB_POS[moves[i].dir]['y']] = next[player][depth * 2 + 1];
    buf[player] = fall(buf[player]);
    moves[i] = EvalMove(buf, prev, player, next, moves[i]);
    CurrentPuyo new_move;
    //枝刈り
    if(moves[i].point >= 0 || depth < DEPTH_MAX) {
      List<Puyo> diff;
      while(isChainBA(prev[player], buf[player])) {
        diff = getBoardDiff2D(prev[player], buf[player]);
        prev[player] = copyList2D(buf[player]);
        buf[player] = checkChainDiff(buf[player], diff);
        buf[player] = fall(buf[player]);
      }
      new_move = EvalMaxMove(buf, player, next, depth + 1, moves[i]);
    } else {
      new_move= moves[i];
      new_move.point = 0;
    }
    if((new_move.point + moves[i].point) >= max_move.point) {
      if(depth == 0) {
        max_move = moves[i];
        max_move.point += new_move.point;
      } else {
        max_move.point = moves[i].point + new_move.point;
      }
    }
  }
  return max_move;
}

CurrentPuyo EvalMove(List now, List prev, int player, List next, CurrentPuyo move) {
  move.point = 0;
  if(gameIsOver(now[player])) move.point -= 999999;
  
  move.point += pow(chain_bonus[countChainBA(prev[player], now[player])], 3)~/1000;
  move.point += evalJoint(now[player]);
  move.point -= (sumHeightDiff(now[player]) * 1);
  move.point += (BOARD_HEIGHT - maxHeightDiff(now[player])) * 1;
  move.point += countReadyChain(now[player]);
  //move.point += pow(chain_bonus[countReadyChain(player, now)], 3)~/2000;
  return move;
}

//仮想発火
int countReadyChain(List<List<int>> board2) {
  int chain = 0;
  List<int> puyo = [PUYO_RED, PUYO_BLUE, PUYO_YELLOW, PUYO_GREEN];
  for(int x = 3; x >= BOARD_X_MIN && board2[x][BOARD_Y_MIN + 1] == PUYO_BLANK; x--) {
    int y = getHeight(board2[x]);
        if(y > BOARD_Y_MIN) {
          for(int c = PUYO_RED; c <= PUYO_GREEN; c++) {
            List buf = copyList2D(board2);
            buf[x][y] = puyo[c];
            chain += pow(chain_bonus[countChainBA(board2, buf)], 3)~/2000;
            //int count = countChainBA(player, board, buf);
            //if(count > chain) chain = count;
          }
        }
  }
  for(int x = 4; x <= BOARD_X_MAX && board2[x][BOARD_Y_MIN + 1] == PUYO_BLANK; x++) {
    int y = getHeight(board2[x]);
        if(y > BOARD_Y_MIN) {
          for(int c = PUYO_RED; c <= PUYO_GREEN; c++) {
            List buf = copyList2D(board2);
            buf[x][y] = puyo[c];
            chain += pow(chain_bonus[countChainBA(board2, buf)], 3)~/2000;
            //int count = countChainBA(player, board, buf);
            //if(count > chain) chain = count;
          }
        }
  }
  return chain;
}

//連鎖数
int countChain(List<List<int>> board) {
  List buf = copyList2D(board);
  int chain = 0;
  while(isChain(buf)) {
    buf = checkChain(buf);
    buf = fall(buf);
    chain++;
  }
  if(chain > max_chain_num) max_chain_num = chain;
  return chain;
}

int countChainBA(List<List<int>> before, List<List<int>> after) {
  List now = copyList2D(after);
  List prev = copyList2D(before);
  int chain = 0;
  while(isChainBA(prev, now)) {
    List<Puyo> diff = getBoardDiff2D(prev, now);
    prev = copyList2D(now);
    now = checkChainDiff(now, diff);
    now = fall(now);
    chain++;
  }
  if(chain > max_chain_num) max_chain_num = chain;
  return chain;
}

//総連結数評価
int evalJoint(List<List<int>> board) {
  int sum = 0;
  int join;
  for(int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
    for(int y = BOARD_Y_MIN + 1; y <= BOARD_Y_MAX; y++){
      if(board[x][y] != PUYO_BLANK) {
        join = countJoinNum(copyList2D(board), board[x][y], x, y);
        if(join < 4) {
          sum += join;
        } else {
          sum--;
        }
      }
    }
  }
  return sum;
}

int sumHeightDiff(List<List<int>> board) {
  int sum = 0;
  int height_now;
  int height_last = getHeight(board[BOARD_X_MIN]);
  for(int x = BOARD_X_MIN + 1; x <= BOARD_X_MAX; x++) {
    height_now = getHeight(board[x]);
    sum += (height_now - height_last).abs();
    height_last = height_now;
  }
  return sum;
}

int maxHeightDiff(List<List<int>> board) {
  int max = 0;
  int diff;
  int height_now;
  int height_last = getHeight(board[BOARD_X_MIN]);
  for(int x = BOARD_X_MIN + 1; x <= BOARD_X_MAX; x++) {
    height_now = getHeight(board[x]);
    diff = (height_now - height_last).abs();
    if(max < diff) max = diff;
    height_last = height_now;
  }
  return max;
}

int getHeight(List<int> board) {
  int height = board.lastIndexOf(PUYO_BLANK);
  if(height < 0) return 0;
  return height;
}

bool gameIsOver(List<List<int>> board) {
  return board[3][2] != PUYO_BLANK;
}

class CurrentPuyo {
  int x;
  int y;
  int dir;
  int point;
  
  CurrentPuyo(int x, int y, int dir) {
    this.x = x;
    this.y = y;
    this.dir = dir;
    this.point = 0;
  }
}

List<CurrentPuyo> MakeNextMove(List<List<List<int>>> board, int player) {
  List moves = new List();
  for (int x = PUYO_X_DEF; x >= BOARD_X_MIN; x--) {
    if(board[player][x][PUYO_Y_DEF] != PUYO_BLANK) {
      break;
    } else {
      for(int r = 0; r <= SUB_LEFT; r++) {
        if(board[player][x + SUB_POS[r]['x']][PUYO_Y_DEF + SUB_POS[r]['y']] == PUYO_BLANK) {
          moves.add(new CurrentPuyo(x, PUYO_Y_DEF, r));
        }
      }
    }
  }
  for(int x = 4; x <= BOARD_X_MAX; x++) {
    if(board[player][x][PUYO_Y_DEF] != PUYO_BLANK) {
      break;
    } else {
      for(int r = 0; r <= SUB_LEFT; r++) {
        if(board[player][x + SUB_POS[r]['x']][PUYO_Y_DEF + SUB_POS[r]['y']] == PUYO_BLANK) {
          moves.add(new CurrentPuyo(x, PUYO_Y_DEF, r));
        }
      }
    }
  }
  return moves;
}

void initialize() {
  board = initBoard();
  initNextPuyo();
  initCurrentPuyo();
}

List initBoard() {
  return new List.generate(PLAYER_NUM, (p) => 
          new List.generate(FIELD_WIDTH, (x) => 
            new List.generate(FIELD_HEIGHT, (y) => checkBlockPos(x, y))));
}

int checkBlockPos(int x, int y) {
  if(x == 0 || x == FIELD_WIDTH - 1 || y == 0 || y == FIELD_HEIGHT - 1) {
    return PUYO_BLOCK;
  } else {
    return PUYO_BLANK;
  }
}

void initNextPuyo() {
  List buf = conpensateTsumo(makeNextBuffer());
  for(int p = 0; p < PLAYER_NUM; p++) {
    next_puyo[p] = buf;
  }
}

void initCurrentPuyo() {
  for(int p = 0; p < PLAYER_NUM; p++) {
    current[p].x = PUYO_X_DEF;
    current[p].y = PUYO_Y_DEF;
    current[p].dir = SUB_DEF;
    current[p].point = 0;
  }
}

//配列コピー
List copyList1D(List list) {
  return new List.generate(list.length, (i) => list[i]);
}

List<List> copyList2D(List<List> list) {
  return new List.generate(list.length, (i) => copyList1D(list[i]));
}

List<List<List>> copyList3D(List<List<List>> list) {
  return new List.generate(list.length, (i) => copyList2D(list[i]));
}

//落下
List<List<int>> fall(List<List<int>> items) {
  return (items.map((x) => fallOneLine(x))).toList();
}

List<int> fallOneLine(List<int> items){
  for (int y = BOARD_Y_MIN + 1; y <= BOARD_Y_MAX; y++) {
    if (items[y] == PUYO_BLANK) {
      items.removeAt(y);
      items.insert(BOARD_Y_MIN, PUYO_BLANK);
    }
  }
  return items;
}

//ツモ
List<int> makeNextBuffer() {
  return shuffle(new List.generate(256, (i) => i%4));
}

//シャッフル
List<int> shuffle(List<int> items) {
  Random rand = new Random();
  for (num i = items.length - 1; i > 0; i--) {
    num j = rand.nextInt(i);
    num temp = items[i];
    items[i] = items[j];
    items[j] = temp;
  }
  return items;
}

//ツモ補正
List<int> conpensateTsumo(List<int> items) {
  List temp = items.take(6).toList().where((e) => e != 3).toList();
  List forth_color = items.take(6).toList().where((e) => e == 3).toList();
  if(temp.length == 6) {
    return items;
  }
  items.removeRange(0, 6);
  forth_color.forEach((e) => items.insert(new Random().nextInt(items.length), e));
  items.insertAll(0, temp);
  return conpensateTsumo(items);
}

List<Puyo> getBoardDiff2D(List b, List a) {
  List<Puyo> diff = new List<Puyo>();
  for(int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
    for(int y = BOARD_Y_MIN + 1; y <= BOARD_Y_MAX; y++) {
      if(b[x][y] != a[x][y]) {
        diff.add(new Puyo(x, y, a[x][y]));
      }
    }
  }
  return diff;
}

//連結確認
bool isChain(List<List<int>> items) {
  for (int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
    for (int y = BOARD_Y_MIN + 1; y <= BOARD_Y_MAX; y++) {
      if(items[x][y] != PUYO_BLANK) {
        if(countJoinNum(copyList2D(items), items[x][y], x, y) >= 4) {
          return true;
        }
      }
    }
  }
  return false;
}

bool isChainBA(List before, List after) {
  List diff = getBoardDiff2D(before, after);
  return isChainDiff(after, diff);
}

bool isChainDiff(List<List<int>> b_now, List<Puyo> diff) {
  for(int i = 0; i < diff.length; i++) {
    if(b_now[diff[i].x][diff[i].y] != PUYO_BLANK) {
      if(countJoinNum(copyList2D(b_now), b_now[diff[i].x][diff[i].y], diff[i].x, diff[i].y) >= 4) {
        return true;
      }
    }
  }
  return false;
}

List<List<int>> checkChain(List<List<int>> items) {
  for(int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
    for(int y = BOARD_Y_MIN + 1; y <= BOARD_Y_MAX; y++){
      if(items[x][y] != PUYO_BLANK) {
        if(countJoinNum(copyList2D(items), items[x][y], x, y) >= 4) {
          items = deletePuyo(copyList2D(items), items[x][y], x, y);
        }
      }
    }
  }
  return items;
}

List checkChainBA(List before, List after) {
  List<Puyo> diff = getBoardDiff2D(before, after);
  return checkChainDiff(after, diff);
}

List checkChainDiff(List b_now, List<Puyo> diff) {
  for(int i = 0; i < diff.length; i++) {
    if(b_now[diff[i].x][diff[i].y] != PUYO_BLANK) {
      if(countJoinNum(copyList2D(b_now), b_now[diff[i].x][diff[i].y], diff[i].x, diff[i].y) >= 4) {
        b_now = deletePuyo(copyList2D(b_now), b_now[diff[i].x][diff[i].y], diff[i].x, diff[i].y);
      }
    }
  }
  return b_now;
}

int countJoinNum(List<List<int>> items, int color, int x, int y) {
  if(items[x][y] != color) return 0;
  items[x][y] = PUYO_BLANK;
  int join_num = 1;
  if(x >= BOARD_X_MIN + 1) join_num += countJoinNum(items, color, x - 1, y);
  if(y >= BOARD_Y_MIN + 2) join_num += countJoinNum(items, color, x, y - 1);
  if(x < items.length - 2) join_num += countJoinNum(items, color, x + 1, y);
  if(y < items[x].length - 2) join_num += countJoinNum(items, color, x, y + 1);
  return join_num;
}

List<List<int>> deletePuyo(List<List<int>> items, int color, int x, int y) {
  if(items[x][y] != color) return items;
  items[x][y] = PUYO_BLANK;
  if(x >= BOARD_X_MIN + 1) items = deletePuyo(items, color, x - 1, y);
  if(y >= BOARD_Y_MIN + 2) items = deletePuyo(items, color, x, y - 1);
  if(x < items.length - 2) items = deletePuyo(items, color, x + 1, y);
  if(y < items[x].length - 2) items = deletePuyo(items, color, x, y + 1);
  return items;
}

List<List<int>> checkChainDiffZ(List<List<int>> b_now, List<Puyo> diff) {
  List<Puyo> joinList;
  for(int i = 0; i < diff.length; i++) {
    if(b_now[diff[i].x][diff[i].y] != PUYO_BLANK) {
      joinList = getJoinList(copyList2D(b_now), b_now[diff[i].x][diff[i].y], diff[i].x, diff[i].y, new List());
      if(joinList.length >= 4) {
        b_now = vanishPuyo(b_now, joinList);
      }
    }
  }
  return b_now;
}

int countJoinNumZ(List<List<int>> board, int color, int x, int y) {
  return getJoinList(board, color, x, y, new List()).length;
}

List<Puyo> getJoinList(List<List<int>> board, int color, int x, int y, List<Puyo> join) {
  if(board[x][y] != color) return join;
  board[x][y] = PUYO_BLANK;
  join.add(new Puyo(x, y, PUYO_BLANK));
  if(x >= BOARD_X_MIN + 1) join = getJoinList(board, color, x - 1, y, join);
  if(y >= BOARD_Y_MIN + 2) join = getJoinList(board, color, x, y - 1, join);
  if(x < board.length - 2) join = getJoinList(board, color, x + 1, y, join);
  if(y < board[x].length - 2) join = getJoinList(board, color, x, y + 1, join);
  return join;
}

List<List<int>> vanishPuyo(List<List<int>> board, List<Puyo> vanish) {
  for(int i = 0; i < vanish.length; i++) {
    board[vanish[i].x][vanish[i].y] = PUYO_BLANK;
  }
  return board;
}

List<List<List<int>>> putPuyo(int player, List board, List current, List next) {
  board[player] = putPuyoPlayer(board[player], current[player], next[player]);
  return board;
}

List putPuyoPlayer(List board, CurrentPuyo current, List next) {
  if(!putCheck(board, current)) {
    return board;
  }
  
  board[current.x][current.y] = next[0];
  board[current.x + SUB_POS[current.dir]['x']][current.y + SUB_POS[current.dir]['y']] = next[1];
  next.removeRange(0, 2);
  return board;
}

void updateNextPuyo(int player) {
  if(next_puyo[player].length <= 6) {
    List buf = makeNextBuffer();
    for(int p = 0; p < PLAYER_NUM; p++) {
      next_puyo[p].insertAll(next_puyo[p].length, buf);
    }
  }
}

void updateCurrentPuyo(int player) {
  current[player].x = 3;
  current[player].y = 2;
  current[player].dir = SUB_UPPER;
}

List putNewPuyo(int player) {
  updateCurrentPuyo(player);
  updateNextPuyo(player);
  return putPuyo(player, board, current, next_puyo);
}

bool putCheck(List<List<int>> items, CurrentPuyo chkpuyo) {
  return (items[chkpuyo.x][chkpuyo.y] == PUYO_BLANK) && 
      items[chkpuyo.x + SUB_POS[chkpuyo.dir]['x']][chkpuyo.y + SUB_POS[chkpuyo.dir]['y']] == PUYO_BLANK; 
}

void debugPuyo() {
  for(int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
    for(int y = BOARD_Y_MIN; y <= BOARD_Y_MAX; y++) {
      board[0][x][y] = new Random().nextInt(4);
    }
  }
}
