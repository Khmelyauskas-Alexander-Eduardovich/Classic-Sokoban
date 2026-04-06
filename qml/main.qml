/* Khmelyauskas Alexander Eduardovich - 3 d'Abril de 2026
 * In Loving Memory of My cat - Tom
* JWB Bravada - Sokoban Classic / Sokoban I
* main.qml
*/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.0
import "levels.js" as Logic

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 480
    title: qsTr("Sokoban Bravada")
    color: "#7cfc00"

    readonly property bool isLandscape: width > height
    property int currentLevelIdx: 0
    property int maxUnlockedLevel: 0
    readonly property int totalLevels: 15

    // --- Менеджер БД ---
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

    // --- Движок ---
    QtObject {
        id: engine
        property var map: []; property var history: []
        property int px: 0; property int py: 0; property int mapW: 0
        property bool isRestored: false; property bool swipeMode: false

        function loadLevel(idx, forceReset = false) {
            if (forceReset || idx !== window.currentLevelIdx) gameModel.clear();
            if (idx >= Logic.levels.length) idx = 0;
            winLabel.visible = false;
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
        }

        function refresh() {
            var totalCells = map.length * mapW;
            if (gameModel.count === 0) {
                for (var i = 0; i < totalCells; i++) gameModel.append({"type": " "});
            }
            var idx = 0;
            for (var y = 0; y < map.length; y++) {
                var rowStr = map[y];
                for (var x = 0; x < mapW; x++) {
                    var cellType = (x < rowStr.length) ? rowStr.charAt(x) : " ";
                    gameModel.setProperty(idx, "type", cellType);
                    idx++;
                }
            }
            winLabel.visible = isWin();
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

        function centerMap() {
            gameContainer.scale = 1.0;
            gameContainer.x = (flickViewport.width - gameContainer.width) / 2;
            gameContainer.y = (flickViewport.height - gameContainer.height) / 2;
        }
    }

    Timer { id: autoNextTimer; interval: 1500; onTriggered: engine.loadLevel(window.currentLevelIdx + 1, true) }
    ListModel { id: gameModel }

    // Контейнер интерфейса
    Item {
        anchors.fill: parent
        anchors.margins: 10

        Text {
            id: levelText
            text: qsTr("Level") + " " + (window.currentLevelIdx + 1)
            font.pixelSize: 24; font.bold: true; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        }

        // --- ИГРОВОЕ ПОЛЕ (Flickable + Pinch) ---
        Item {
            id: flickViewport
            width: isLandscape ? parent.width * 0.6 : parent.width
            height: isLandscape ? parent.height - 130 : 420
            clip: true

            anchors {
                top: levelText.bottom
                topMargin: 10
                left: isLandscape ? parent.left : undefined
                horizontalCenter: isLandscape ? undefined : parent.horizontalCenter
            }

            Rectangle { anchors.fill: parent; color: "#66cc00"; radius: 10; opacity: 0.2; border.color: "black"; border.width: 1 }

            // Контейнер самой карты
            Item {
                id: gameContainer
                width: Math.max(1, engine.mapW) * 40
                height: Math.max(1, engine.map.length) * 40
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

            // Обработка перемещения и колеса мыши
            // Единая область для зума и перетаскивания
                        MouseArea {
                            id: interactionArea
                            anchors.fill: parent
                            hoverEnabled: true

                            // Для перетаскивания
                            property real lastX: 0
                            property real lastY: 0

                            /*onPressed: {
                                lastX = mouse.x
                                lastY = mouse.y
                            }

                            onPositionChanged: {
                                if (pressed) {
                                    var dx = mouse.x - lastX
                                    var dy = mouse.y - lastY

                                    // Двигаем контейнер
                                    gameContainer.x += dx
                                    gameContainer.y += dy

                                    lastX = mouse.x
                                    lastY = mouse.y

                                    // Ограничение, чтобы не утащить карту в бесконечность
                                    keepInBounds()
                                }
                            }*/
                            // Зум через колесо (или жесты прокрутки на тачпаде/экране)
                            onWheel: {
                                var scaleStep = 0.1
                                var oldScale = gameContainer.scale
                                var newScale = wheel.angleDelta.y > 0
                                    ? Math.min(5.0, oldScale + scaleStep)
                                    : Math.max(0.3, oldScale - scaleStep)

                                if (newScale !== oldScale) {
                                    // Зум в точку курсора/пальца
                                    gameContainer.x = wheel.x - (wheel.x - gameContainer.x) * (newScale / oldScale)
                                    gameContainer.y = wheel.y - (wheel.y - gameContainer.y) * (newScale / oldScale)
                                    gameContainer.scale = newScale

                                    console.warn((wheel.angleDelta.y > 0 ? "Zoom-in" : "Zoom-out") + " | Scale: " + newScale.toFixed(2))
                                }
                            }

                            function keepInBounds() {
                                var vW = gameContainer.width * gameContainer.scale
                                var vH = gameContainer.height * gameContainer.scale
                                var margin = 60 // Сколько пикселей карты должно остаться в поле зрения

                                if (gameContainer.x < -vW + margin) gameContainer.x = -vW + margin
                                if (gameContainer.x > parent.width - margin) gameContainer.x = parent.width - margin
                                if (gameContainer.y < -vH + margin) gameContainer.y = -vH + margin
                                if (gameContainer.y > parent.height - margin) gameContainer.y = parent.height - margin
                            }
                        }
                        // Обработка жестов (Щипок)
/*                        PinchArea {
                                        id: pinchArea
                                        anchors.fill: parent
                                        pinch.target: gameContainer
                                        pinch.minimumScale: 0.3
                                        pinch.maximumScale: 5.0

                                        // Сохраняем начальный масштаб для сравнения
                                        property real initialScale: 1.0

                                        onPinchStarted: {
                                            initialScale = gameContainer.scale
                                        }

                                        onPinchFinished: {
                                            var finalScale = gameContainer.scale
                                            var diff = finalScale / initialScale
                                            var direction = (finalScale > initialScale) ? "Zoom-in" : "Zoom-out"

                                            // Вывод в консоль: направление и коэффициент относительно начала жеста
                                            console.warn(direction + " finished. Scale factor: " + diff.toFixed(2) + " (Total scale: " + finalScale.toFixed(2) + ")")

                                            // --- ПРОВЕРКА ГРАНИЦ ---
                                            // Вычисляем текущие визуальные размеры карты
                                            var vW = gameContainer.width * finalScale
                                            var vH = gameContainer.height * finalScale

                                            // Если после щипка карта оказалась полностью за пределами видимости (с запасом 40px)
                                            // Возвращаем её в ближайшую допустимую точку
                                            if (gameContainer.x < -vW + 40) gameContainer.x = -vW + 40
                                            if (gameContainer.x > flickViewport.width - 40) gameContainer.x = flickViewport.width - 40

                                            if (gameContainer.y < -vH + 40) gameContainer.y = -vH + 40
                                            if (gameContainer.y > flickViewport.height - 40) gameContainer.y = flickViewport.height - 40
                                        }
                                    }*/
                        MultiPointTouchArea {
                            id: touchArea
                            anchors.fill: parent
                            minimumTouchPoints: 1
                            maximumTouchPoints: 2

                            // Включаем поддержку мыши для десктопа
                            mouseEnabled: true

                            property real lastX: 0
                            property real lastY: 0
                            property real lastDist: 0

                            // Единая функция для перемещения (флика)
                            function handleMove(pointX, pointY) {
                                var dx = pointX - lastX
                                var dy = pointY - lastY
                                gameContainer.x += dx
                                gameContainer.y += dy
                                lastX = pointX
                                lastY = pointY
                            }

                            onPressed: (touchPoints) => {
                                // Берем либо первый палец, либо мышку
                                var p = touchPoints[0]
                                lastX = p.x
                                lastY = p.y

                                if (touchPoints.length === 2) {
                                    lastDist = Math.sqrt(Math.pow(touchPoints[0].x - touchPoints[1].x, 2) +
                                                         Math.pow(touchPoints[0].y - touchPoints[1].y, 2))
                                }
                            }

                            onUpdated: (touchPoints) => {
                                if (touchPoints.length === 1) {
                                    // Флик работает и для мышки, и для одного пальца
                                    handleMove(touchPoints[0].x, touchPoints[0].y)
                                } else if (touchPoints.length === 2) {
                                    // Зум (только для тача)
                                    var currentDist = Math.sqrt(Math.pow(touchPoints[0].x - touchPoints[1].x, 2) +
                                                                Math.pow(touchPoints[0].y - touchPoints[1].y, 2))

                                    if (lastDist > 0) {
                                        var zoomDelta = currentDist / lastDist
                                        var newScale = Math.min(5.0, Math.max(0.3, gameContainer.scale * zoomDelta))

                                        var centerX = (touchPoints[0].x + touchPoints[1].x) / 2
                                        var centerY = (touchPoints[0].y + touchPoints[1].y) / 2

                                        gameContainer.x = centerX - (centerX - gameContainer.x) * (newScale / gameContainer.scale)
                                        gameContainer.y = centerY - (centerY - gameContainer.y) * (newScale / gameContainer.scale)
                                        gameContainer.scale = newScale
                                    }
                                    lastDist = currentDist
                                    // Обновляем координаты, чтобы после зума флик не прыгал
                                    lastX = touchPoints[0].x
                                    lastY = touchPoints[0].y
                                }
                            }

                            onReleased: {
                                lastDist = 0
                            }
                        }
        }

        // --- БЛОК УПРАВЛЕНИЯ (Кнопки / Свайп) ---
        Item {
            id: controlRoot
            width: isLandscape ? parent.width * 0.35 : 300
            height: isLandscape ? flickViewport.height : 220
            anchors {
                top: isLandscape ? levelText.bottom : flickViewport.bottom
                topMargin: 10
                right: isLandscape ? parent.right : undefined
                horizontalCenter: isLandscape ? undefined : parent.horizontalCenter
            }

            Rectangle {
                id: touchpad; anchors.fill: parent; color: "white"; radius: 20; border.color: "black"; border.width: 2
                opacity: engine.swipeMode ? 0.3 : 0; visible: opacity > 0; scale: engine.swipeMode ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 } }

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
                Text { anchors.centerIn: parent; text: qsTr("SWIPE MODE\nDouble tap to exit"); horizontalAlignment: Text.AlignHCenter; opacity: 0.6 }
            }

            Grid {
                id: dpadGrid; columns: 3; spacing: 10; anchors.centerIn: parent
                opacity: engine.swipeMode ? 0 : 1; visible: opacity > 0; scale: engine.swipeMode ? 0.5 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 } }

                Item { width: 65; height: 65 }
                Button { text: "↑"; width: 65; height: 65; onClicked: engine.step(0, -1); onPressAndHold: engine.swipeMode = true }
                Item { width: 65; height: 65 }
                Button { text: "←"; width: 65; height: 65; onClicked: engine.step(-1, 0); onPressAndHold: engine.swipeMode = true }
                Button { text: "↓"; width: 65; height: 65; onClicked: engine.step(0, 1); onPressAndHold: engine.swipeMode = true }
                Button { text: "→"; width: 65; height: 65; onClicked: engine.step(1, 0); onPressAndHold: engine.swipeMode = true }
            }
        }
        // Нижние системные кнопки
        Row {
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            spacing: 25; height: 70
            Button { text: qsTr("Back"); width: 110; height: 50; onClicked: engine.back() }
            Button { text: qsTr("Reset"); width: 110; height: 50; onClicked: engine.loadLevel(window.currentLevelIdx, true) }
            Button {
                text: qsTr("SELECT"); width: 110; height: 50
                visible: window.maxUnlockedLevel > 0; onClicked: levelPicker.open()
            }
        }
    }

    // Окно выбора уровней
    Popup {
        id: levelPicker; x: (parent.width - width) / 2; y: (parent.height - height) / 2
        width: Math.min(parent.width * 0.9, 420); height: parent.height * 0.8; modal: true; focus: true
        background: Rectangle { color: "#f9f9f9"; radius: 25 }
        clip: true
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.8; duration: 150 }
        }

        // Используем Item вместо Column, чтобы работали привязки (anchors)
        Item {
            anchors.fill: parent
            anchors.margins: 20

            Text {
                id: titleText
                text: qsTr("Select Level")
                font.pixelSize: 26; font.bold: true
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: warnLabel
                text: qsTr("More levels coming soon in Sokoban II\nStay tuned!")
                font.pixelSize: 16; color: "red"; horizontalAlignment: Text.AlignHCenter
                anchors.top: titleText.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }

            GridView {
                id: levelsGrid
                width: 280 // Или 350
                anchors.horizontalCenter: parent.horizontalCenter

                // Теперь эти привязки будут работать!
                anchors.top: warnLabel.bottom
                anchors.topMargin: 15
                anchors.bottom: parent.bottom

                clip: true
                interactive: true
                model: window.totalLevels
                cellWidth: 70; cellHeight: 70

                snapMode: GridView.NoSnap
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    width: 70; height: 70
                    Button {
                        width: 60; height: 60; anchors.centerIn: parent
                        text: (index + 1).toString()
                        enabled: index <= window.maxUnlockedLevel
                        onClicked: { engine.loadLevel(index); levelPicker.close() }
                    }
                }
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
