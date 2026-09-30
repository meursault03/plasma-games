pragma ComponentBehavior: Bound
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: Qt.resolvedUrl("../images/games.svg")
    toolTipMainText: "Plasma Games"
    toolTipSubText: "Snake, Minesweeper, tic-tac-toe, 2048 and Lights Out"
    onExpandedChanged: { if (!root.expanded) { games.interactive = false; games.pause(); } }

    GameController {
        id: games
        best: Math.max(0, Plasmoid.configuration.snakeBest)
        onBestChangedByGame: score => { Plasmoid.configuration.snakeBest = score; }
    }
    compactRepresentation: PanelIcon {
        onActivated: root.expanded = !root.expanded
    }
    fullRepresentation: FullRepresentation {
        controller: games
        expanded: root.expanded
        onInteractiveChangedByView: active => { games.interactive = active; }
    }
}
