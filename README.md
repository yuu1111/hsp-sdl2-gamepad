# gamepad - SDL2 GameController Wrapper for HSP

HSP用のSDL2ベースゲームパッドラッパーDLL。

## 必要なファイル

- `gamepad.dll` - 本ライブラリ
- `SDL2.dll` - SDL2ランタイム（同じフォルダに配置）

## ビルド

```powershell
cd lib/gamepad
zig build -Doptimize=ReleaseFast
cp zig-out/bin/gamepad.dll ../../bin/debug/
```

## API

### 初期化・終了

| 関数 | 説明 | 戻り値 |
|------|------|--------|
| `GPINIT()` | 初期化 | 接続コントローラー数（失敗時-1） |
| `GPEND()` | 終了処理 | なし |

### コントローラー状態

| 関数 | 説明 | 戻り値 |
|------|------|--------|
| `GPGETJOYNUM()` | 接続コントローラー数を取得 | コントローラー数 |
| `GPISCONNECTED(index)` | 指定コントローラーが接続中か | 1=接続, 0=未接続 |
| `GPPOLL()` | 接続状態の変更をポーリング | 1=変更あり, 0=変更なし |

### 入力取得

| 関数 | 説明 | 戻り値 |
|------|------|--------|
| `GPGETJOYSTATE(state, index)` | ボタン・方向の16ビット状態を取得 | 0=成功, -1=失敗 |
| `GPBITCHECK(state, bit)` | 状態のビットをチェック | 1=ON, 0=OFF |
| `GPGETSTICK(lx, ly, rx, ry, index)` | アナログスティック値を取得（-32768〜32767） | 0=成功, -1=失敗 |
| `GPGETTRIGGER(left, right, index)` | トリガー値を取得（0〜32767） | 0=成功, -1=失敗 |

### 振動

| 関数 | 説明 | 戻り値 |
|------|------|--------|
| `GPRUMBLE(low, high, ms, index)` | 振動開始（0〜65535, 持続時間ms） | 0=成功, -1=失敗 |
| `GPRUMBLESTOP(index)` | 振動停止 | 0=成功, -1=失敗 |

### ビット定数（GPGETJOYSTATEで使用）

```hsp
// 方向（ビット0-3）
#define GP_DIR_RIGHT  0
#define GP_DIR_UP     1
#define GP_DIR_LEFT   2
#define GP_DIR_DOWN   3

// ボタン（ビット4-15）
#define GP_BTN_A      4
#define GP_BTN_B      5
#define GP_BTN_X      6
#define GP_BTN_Y      7
#define GP_BTN_LB     8
#define GP_BTN_RB     9
#define GP_BTN_BACK   10
#define GP_BTN_START  11
#define GP_BTN_L3     12
#define GP_BTN_R3     13
#define GP_BTN_LT     14
#define GP_BTN_RT     15
```

## 使用例

```hsp
#include "gamepad.as"

GPINIT
if stat < 0 : dialog "初期化失敗" : end

*main
    GPPOLL
    GPGETJOYSTATE state, 0

    if GPBITCHECK(state, GP_BTN_A) {
        mes "Aボタン押下"
    }

    await 16
    goto *main
```

## ライセンス

zlib License
