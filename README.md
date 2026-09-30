# Plasma Games

Five games in a KDE Plasma 6 panel widget: Snake, Minesweeper, tic-tac-toe,
2048, and Lights Out. Click the gamepad icon, choose a game, and play. The popup
uses a fixed dark theme and keeps the current round when you close it.

## Install

Install the widget from this directory:

```sh
kpackagetool6 --type Plasma/Applet --install ./package
```

Then add **Plasma Games** to a panel from Plasma's widget picker. To update an
existing installation, run:

```sh
kpackagetool6 --type Plasma/Applet --upgrade ./package
```

Plasma may keep the old QML loaded until the shell is restarted or the widget
is removed and added again.

## Controls

| Game | How to play |
| --- | --- |
| Snake | Arrow keys or WASD to turn; Space to pause. The snake wraps around the board. |
| Minesweeper | Click to reveal, right-click or press F on a focused square to flag. The first reveal and its neighbors are safe. |
| Tic-tac-toe | Choose a square with the mouse or keyboard. You play X against the computer. |
| 2048 | Arrow keys, WASD, or swipe to move tiles. Reach 2048 to win. |
| Lights Out | Click a light, or focus it and press Space or Enter. Turn every light off. |

**Back** returns to the game list and starts a new round next time. Snake pauses
when the popup closes or loses focus; use **Resume** when you return. Its best
score is saved per widget instance. The other games stay where you left them.

## Development

The widget uses QML and plain JavaScript. It has no runtime dependencies beyond
the standard Plasma 6, Qt Quick, and Kirigami modules. Node.js is only needed
for the game-rule tests.

```sh
node --test tests/games.test.cjs
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/*.qml
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/qml
```

The Qt tool paths above are used on Fedora and may differ on other systems.
