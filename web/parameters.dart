library parameters;

const int PLAYER_ONE = 0;
const int PLAYER_TWO = 1;
const int PLAYER_NUM = 1;
const int BOARD_HEIGHT = 13;
const int BOARD_WIDTH  = 6;
const int FIELD_HEIGHT = 1 + BOARD_HEIGHT + 1;
const int FIELD_WIDTH  = 1 + BOARD_WIDTH + 1;
const int BOARD_X_MIN = 1;
const int BOARD_X_MAX = BOARD_WIDTH;
const int BOARD_Y_MIN = 1;
const int BOARD_Y_MAX = BOARD_HEIGHT;
const int PUYO_X_DEF = 3;
const int PUYO_Y_DEF = 2;

//puyo color
const int PUYO_BLOCK  = -1;
const int PUYO_RED    = 0;
const int PUYO_BLUE   = 1;
const int PUYO_YELLOW = 2;
const int PUYO_GREEN  = 3;
const int PUYO_WHITE  = 4;
const int PUYO_BLANK  = 5;

final SUB_POS = [{'x' : 0, 'y' : -1}, {'x' : 1, 'y' : 0}, {'x' : 0, 'y' : 1}, {'x' : -1, 'y' : 0}];
const int SUB_UPPER = 0;
const int SUB_RIGHT = 1;
const int SUB_DOWN  = 2;
const int SUB_LEFT  = 3;
const int SUB_DEF = SUB_UPPER;


class Puyo {
  int x;
  int y;
  int color;
  
  Puyo(int x, int y, int color) {
    this.x = x;
    this.y = y;
    this.color = color;
  }
}

//keymap
const int KC_C = 67;
const int KC_N = 78;

//AI
const int DEPTH_MAX = 1;