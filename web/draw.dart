library draw;

import 'dart:html';
import 'dart:math';
import 'parameters.dart';

const int FIELD_X = 50;
const int FIELD_Y = 50;
const int FIELD_MARGIN = 50;
const int PUYO_R      = 10;
const int PUYO_MARGIN = 2;
final List<String> puyo_color = ["red","blue","yellow","green","white","black"];

//描画
void draw(CanvasRenderingContext2D ctx,
          List<List<List<int>>> board, List current, List next) {
  drawBoard(ctx);
  drawPuyoAll(ctx, board);
  drawCurrentPuyo(ctx, current, next);
  drawNextPuyo(ctx, next);
}

void drawBoard(CanvasRenderingContext2D ctx) {
  for(int p = 0; p < PLAYER_NUM; p++) {
    ctx..beginPath()
      ..fillStyle = 'rgb(128,128,128)'
      ..fillRect(0,0,640,480)
      ..fillStyle = 'rgb(64,64,64)'
      ..fillRect(FIELD_X, FIELD_Y + (PUYO_R * 2 + PUYO_MARGIN),
          (PUYO_R * 2 + PUYO_MARGIN) * (BOARD_WIDTH + 1),
          (PUYO_R * 2 + PUYO_MARGIN) * BOARD_HEIGHT);
  }
}

void drawPuyoAll(CanvasRenderingContext2D ctx, List<List<List<int>>> items) {
  for(int p = 0; p < items.length; p++) {
    for(int x = BOARD_X_MIN; x <= BOARD_X_MAX; x++) {
      for(int y = BOARD_Y_MIN; y <= BOARD_Y_MAX; y++) {
        if((items[p][x][y] != PUYO_BLANK) &&
           (items[p][x][y] != PUYO_BLOCK)) {
          drawPuyo(ctx, items[p][x][y], p, x, y);
        }
      }
    }
  }
}

void drawCurrentPuyo(ctx, List current, List next) {
  for(int p = 0; p < PLAYER_NUM; p++) {
    if(current[p].y >= BOARD_Y_MIN) {
      drawPuyo(ctx, next[p][0], p, current[p].x, current[p].y);
    }
    if(current[p].y + SUB_POS[current[p].dir]['y'] >= BOARD_Y_MIN) {
      drawPuyo(ctx, next[p][1], p, current[p].x + SUB_POS[current[p].dir]['x'], current[p].y + SUB_POS[current[p].dir]['y']);
    }
  }
}

void drawNextPuyo(ctx, List next) {
  int p = 0;
  for(int n = 2; n < 6; n++) {
    ctx..beginPath()
       ..lineWidth = 2
       ..fillStyle = puyo_color[next[p][n]]
       ..strokeStyle = puyo_color[next[p][n]]
       ..arc(FIELD_X + (PUYO_R * 2 + PUYO_MARGIN) * (BOARD_WIDTH + (n ~/ 2)),
           FIELD_Y + (PUYO_R * 2 + PUYO_MARGIN) * (3 * (n ~/ 2) - n),
           PUYO_R, 0, 2*PI)
       ..fill()
       ..closePath()
       ..stroke();
  }
}

void drawPuyo(ctx, int color, int player, int x, int y) {
  ctx..beginPath()
     ..lineWidth = 2
     ..fillStyle = puyo_color[color]
     ..strokeStyle = puyo_color[color]
     ..arc(FIELD_X + (x + player * FIELD_WIDTH) * (PUYO_R*2 + PUYO_MARGIN) + player * FIELD_MARGIN,
           FIELD_Y + y * (PUYO_R*2 + PUYO_MARGIN), 
           PUYO_R, 0, 2*PI)
     ..fill()
     ..closePath()
     ..stroke();
}