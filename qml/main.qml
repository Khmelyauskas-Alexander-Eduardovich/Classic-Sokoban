import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.0
import "levels.js" as Logic

ApplicationWindow {
    id: window
    visible: true
    width: 480
    height: 800
    title: qsTr("Sokoban Bravada")
    color: "#7cfc00"
    // Свой суррогат для единиц измерения
    readonly property int gu: (typeof units !== 'undefined') ? units.gu(1) : 8

    // Теперь вместо units.gu(5) пишем просто 5 * gu
    property int currentLevelIdx: 0
    property int maxUnlockedLevel: 0
    readonly property int totalLevels: 15

    // --- Менеджер базы данных ---
    QtObject {
        id: dbManager
        property var db: null
        function initDb() {
            try {
                db = LocalStorage.openDatabaseSync("SokobanBravada", "1.0", "Save Progress", 100000);
                db.transaction(function(tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)');
                });
            } catch (e) { console.log("SQL Error: " + e) }
        }

        function saveProgress() {
            if (!db) return;
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["lastIdx", String(window.currentLevelIdx)]);
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["savedMap", JSON.stringify(engine.map)]);
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["maxIdx", String(window.maxUnlockedLevel)]);
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["playerX", String(engine.px)]);
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["playerY", String(engine.py)]);
            });
        }

        function loadProgress() {
            if (!db) return;
            db.transaction(function(tx) {
                var rs = tx.executeSql('SELECT key, value FROM settings');
                var mapData = null; var pX = -1; var pY = -1;
                for (var i = 0; i < rs.rows.length; i++) {
                    var item = rs.rows.item(i);
                    if (item.key === "lastIdx") window.currentLevelIdx = parseInt(item.value);
                    if (item.key === "savedMap") mapData = JSON.parse(item.value);
                    if (item.key === "playerX") pX = parseInt(item.value);
                    if (item.key === "playerY") pY = parseInt(item.value);
                    if (item.key === "maxIdx") window.maxUnlockedLevel = parseInt(item.value);
                }
                if (mapData && pX !== -1) {
                    engine.map = mapData; engine.px = pX; engine.py = pY;
                    engine.isRestored = true;
                }
            });
        }
    }

    // --- Движок игры ---
    QtObject {
        id: engine
        property var map: []; property var history: []
        property int px: 0; property int py: 0; property int mapW: 0
        property bool isRestored: false; property bool swipeMode: false
        property bool levelJustLoaded: false

        function loadLevel(idx, forceReset = false) {
            if (idx >= Logic.levels.length) idx = 0;
            winLabel.visible = false;
            levelJustLoaded = true;
            window.currentLevelIdx = idx;
            if (idx > window.maxUnlockedLevel) window.maxUnlockedLevel = idx;

            if (!isRestored || forceReset) {
                var data = Logic.levels[idx];
                map = JSON.parse(JSON.stringify(data.map));
            }

            mapW = 0;
            for (var i = 0; i < map.length; i++) {
                if (map[i].length > mapW) mapW = map[i].length;
                var pPos = map[i].indexOf("@") === -1 ? map[i].indexOf("+") : map[i].indexOf("@");
                if (pPos !== -1) { px = pPos; py = i; }
            }

            isRestored = false; history = [];
            refresh();
            levelJustLoaded = false;
        }

        function refresh() {
            gameModel.clear();
            if (!map || map.length === 0) return;

            for (var y = 0; y < map.length; y++) {
                var rowStr = map[y];
                for (var x = 0; x < mapW; x++) {
                    var cellType = (x < rowStr.length) ? rowStr.charAt(x) : " ";
                    gameModel.append({"type": cellType});
                }
            }

            if (levelJustLoaded) {
                flick.contentX = (flick.contentWidth > flick.width) ? (flick.contentWidth - flick.width) / 2 : 0;
                flick.contentY = (flick.contentHeight > flick.height) ? (flick.contentHeight - flick.height) / 2 : 0;
            }

            winLabel.visible = !levelJustLoaded && isWin();
            if (winLabel.visible) autoNextTimer.start();
        }

        function isWin() {
            if (map.length === 0) return false;
            for (var i = 0; i < map.length; i++) if (map[i].indexOf("$") !== -1) return false;
            return true;
        }

        function step(dx, dy) {
            if (winLabel.visible) return;
            var res = Logic.tryMove(map, px, py, dx, dy);
            if (res && res.success) {
                history.push({ "m": JSON.parse(JSON.stringify(map)), "x": px, "y": py });
                map = res.newMap; px = res.newX; py = res.newY;
                refresh(); dbManager.saveProgress();
            }
        }

        function back() {
            if (history.length > 0 && !winLabel.visible) {
                var prev = history.pop();
                map = prev.m; px = prev.x; py = prev.y;
                refresh(); dbManager.saveProgress();
            }
        }
    }

    Timer { id: autoNextTimer; interval: 1500; onTriggered: engine.loadLevel(window.currentLevelIdx + 1, true) }
    ListModel { id: gameModel }

    Column {
        anchors.fill: parent; anchors.margins: 10; spacing: 15

        Text {
            text: qsTr("Level") + " " + (window.currentLevelIdx + 1)
            font.pixelSize: 24; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 15
            Button { text: qsTr("Back"); onClicked: engine.back() }
            Button {
                text: qsTr("Reset") // Тут двоеточие, это свойство
                onClicked: { // А это сигнал, код пишем в фигурных скобках
                    engine.loadLevel(window.currentLevelIdx, true);
                    flick.contentX = 0;
                    flick.contentY = 0;
                    //gameContainer.scale = 1.0;
                }
            }
            Button {
                text: qsTr("SELECT")
                visible: window.maxUnlockedLevel > 0
                onClicked: levelPicker.open()
            }
        }

        Item {
            id: flickViewport
            width: parent.width; height: 420; clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: gameContainer.width * gameContainer.scale
                contentHeight: gameContainer.height * gameContainer.scale

                // Магия для UT: заставляем его быть максимально отзывчивым
                boundsBehavior: Flickable.StopAtBounds
                pressDelay: 0
                interactive: true

                Item {
                    id: gameContainer
                    width: Math.max(40, engine.mapW * 40)
                    height: Math.max(40, (engine.map ? engine.map.length : 0) * 40)


                    // ФИКС ЦЕНТРИРОВАНИЯ:
                        // Мы центрируем только если контент МЕНЬШЕ видимой области.
                        // В остальных случаях отдаем управление Flickable (x=0, y=0)
                        x: (flick.contentWidth < flick.width) ? (flick.width - flick.contentWidth) / 2 : 0
                        y: (flick.contentHeight < flick.height) ? (flick.height - flick.contentHeight) / 2 : 0

                        transformOrigin: Item.TopLeft

                    GridView {
                        id: gameGrid; anchors.fill: parent; cellWidth: 40; cellHeight: 40
                        model: gameModel; interactive: false

                        delegate: Item {
                            width: 40; height: 40
                            Image { anchors.fill: parent; source: "floor.svg"; opacity: 0.1 }
                            Image {
                                anchors.fill: parent; smooth: false
                                source: {
                                    if (model.type === "#") return "wall.svg";
                                    if (model.type === "@") return "player.svg";
                                    if (model.type === "$") return "box.svg";
                                    if (model.type === ".") return "goal.svg";
                                    if (model.type === "*") return "box_on_goal.svg";
                                    if (model.type === "+") return "player.svg";
                                    return "";
                                }
                            }
                        }
                    }
                }
            }

            // Зум через колесо мышки для твоей Винды (не мешает скроллу на UT)
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onPressed: mouse.accepted = false
                onWheel: {
                    if (wheel.angleDelta.y > 0)
                        gameContainer.scale = Math.min(3.0, gameContainer.scale + 0.1)
                    else
                        gameContainer.scale = Math.max(0.5, gameContainer.scale - 0.1)
                }
            }
        }

        // --- Блок управления (Кнопки и Swipe) ---
        Item {
            id: controlRoot; width: 300; height: 220; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                id: touchpad; anchors.fill: parent; color: "white"; radius: 20; border.color: "black"; border.width: 2
                opacity: engine.swipeMode ? 0.2 : 0; visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
                MouseArea {
                    anchors.fill: parent; enabled: engine.swipeMode
                    property real startX: 0; property real startY: 0
                    onPressed: { startX = mouse.x; startY = mouse.y }
                    onPositionChanged: {
                        var dx = mouse.x - startX; var dy = mouse.y - startY
                        if (Math.abs(dx) > 40) { engine.step(dx > 0 ? 1 : -1, 0); startX = mouse.x; startY = mouse.y }
                        else if (Math.abs(dy) > 40) { engine.step(0, dy > 0 ? 1 : -1); startX = mouse.x; startY = mouse.y }
                    }
                    onDoubleClicked: engine.swipeMode = false
                }
                Text { anchors.centerIn: parent; text: qsTr("SWIPE MODE\nDouble tap to exit"); opacity: 0.5; horizontalAlignment: Text.AlignHCenter }
            }

            Grid {
                columns: 3; anchors.centerIn: parent; spacing: 10
                opacity: engine.swipeMode ? 0 : 1; visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
                Item { width: 70; height: 70 }
                Button { text: "↑"; width: 70; height: 70; onClicked: engine.step(0, -1); onPressAndHold: engine.swipeMode = true }
                Item { width: 70; height: 70 }
                Button { text: "←"; width: 70; height: 70; onClicked: engine.step(-1, 0); onPressAndHold: engine.swipeMode = true }
                Button { text: "↓"; width: 70; height: 70; onClicked: engine.step(0, 1); onPressAndHold: engine.swipeMode = true }
                Button { text: "→"; width: 70; height: 70; onClicked: engine.step(1, 0); onPressAndHold: engine.swipeMode = true }
            }
        }
    }

    Popup {
        id: levelPicker; x: (parent.width - width) / 2; y: (parent.height - height) / 2
        width: parent.width * 0.85; height: parent.height * 0.6; modal: true; focus: true
        background: Rectangle { color: "#f9f9f9"; radius: 20; border.width: 3 }
        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 15
            Text { text: qsTr("Select Level"); font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            GridView {
                width: parent.width; height: parent.height - 120; cellWidth: 70; cellHeight: 70; clip: true
                model: window.totalLevels
                delegate: Button {
                    width: 60; height: 60; text: (index + 1).toString(); enabled: index <= window.maxUnlockedLevel
                    onClicked: { engine.loadLevel(index); levelPicker.close() }
                }
            }
            Text {
                text: qsTr("New levels will be appeared in the Second Part of Sokoban\nStay tunned!")
                horizontalAlignment: Text.AlignHCenter
                color: "red"
            }
        }
    }

    Text { id: winLabel; text: qsTr("WIN!"); visible: false; anchors.centerIn: parent; font.pixelSize: 60; z: 10; color: "orange"; font.bold: true }

    Component.onCompleted: {
        dbManager.initDb();
        dbManager.loadProgress();
        engine.loadLevel(window.currentLevelIdx);
    }
}
