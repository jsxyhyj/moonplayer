import QtQuick 2.7
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Dialogs 1.3
import QtQuick.Window 2.2
import MoonPlayer 1.0
import CustomWidgets 1.0

CustomWindow
{
    id: window
    visible: true
    minimumWidth: 800
    minimumHeight: 450
    autoHideBars: mpv.state == MpvObject.VIDEO_PLAYING || mpv.state == MpvObject.TV_PLAYING
    title: "MoonPlayer"
    
    Material.theme: Color.theme === "Dark" ? Material.Dark : Material.Light
    Material.accent: Material.Grey

    // Background color
    color: Color.windowBackground
    
    // Mpv
    MpvObject {
        id: mpv
        anchors.fill: parent
        visible: state !== MpvObject.STOPPED
        volume: volumeSlider.value

        onStopped: {
            if (!stoppedByUser)
                playlistModel.playNextItem();
        }

        onVideoSizeChanged: {
            if (window.visibility == Window.FullScreen)
                return;
            window.showNormal();
            if (videoSize.width != 0) {
                if (videoSize.width > Screen.desktopAvailableWidth)
                    window.width = Screen.desktopAvailableWidth;
                else
                    window.width = videoSize.width;
            }
            if (videoSize.height != 0) {
                if (videoSize.height > Screen.desktopAvailableHeight)
                    window.height = Screen.desktopAvailableHeight;
                else
                    window.height = videoSize.height;
            }
            window.x = (Screen.width - window.width) / 2;
            window.y = (Screen.height - window.height) / 2;
        }
        onStateChanged: {
            if (mpv.state === MpvObject.VIDEO_PLAYING || mpv.state === MpvObject.TV_PLAYING)
                explorer.close();
        }
    }
    
    // Select subtitles
    SelectionDialog {
        id: subtitleSelectionDialog
        title: qsTr("Select subtitles")
        items: mpv.subtitles
        onAccepted: mpv.setProperty("sid", currentIndex)
    }
    
    // Add subtitles
    FileDialog {
        id: addSubtitleDialog
        title: qsTr("Please choose a file")
        folder: shortcuts.home
        onAccepted: mpv.addSubtitle(addSubtitleDialog.fileUrl)
    }

    // Select audio tracks
    SelectionDialog {
        id: audioTrackSelectionDialog
        title: qsTr("Select audio tracks")
        items: mpv.audioTracks
        onAccepted: mpv.setProperty("aid", currentIndex)
    }
    
    // Select episode from playlist
    SelectionDialog {
        id: episodeSelectionDialog
        title: qsTr("Select episode")
        property var urls: []
        property bool download: false
        
        Connections {
            target: ykdl
            onAlbumParsed: {
                episodeSelectionDialog.items = titles;
                episodeSelectionDialog.urls = urls;
                episodeSelectionDialog.download = download;
                episodeSelectionDialog.open();
            }
        }
        onAccepted: playlistModel.addUrl(urls[currentIndex], download)
    }
    
    // Select streams
    SelectionDialog {
        id: streamSelectionDialog
        title: qsTr("Select streams")
        property bool isYkdl: true
        
        Connections {
            target: ykdl
            onStreamSelectionNeeded: {
                streamSelectionDialog.isYkdl = true;
                streamSelectionDialog.items = stream_types;
                streamSelectionDialog.open();
            }
        }
        
        Connections {
            target: youtube_dl
            onStreamSelectionNeeded: {
                streamSelectionDialog.isYkdl = false;
                streamSelectionDialog.items = stream_types;
                streamSelectionDialog.open();
            }
        }
        
        onAccepted: {
            if (isYkdl)
                ykdl.finishStreamSelection(currentIndex);
            else
                youtube_dl.finishStreamSelection(currentIndex);
        }
    }
    
    // Video options
    VideoOptionsDialog {
        id: videoOptionsDialog
        mpvObject: mpv
    }
    
    
    // Playlist
    Playlist {
        id: playlist
        x: window.width / 2 + 200
        y: window.height - 410
        onOpenFileRequested: fileDialog.open()
        onOpenUrlRequested: openUrlDialog.open()
    }
    
    // Volume
    Popup {
        id: volumePopup
        width: 40
        height: 120
        Slider {
            id: volumeSlider
            from: 0
            to: 100
            value: 100
            stepSize: 10
            snapMode: Slider.SnapAlways
            anchors.fill: parent
            orientation: Qt.Vertical
        }
    }
    
    // Settings
    Settings {
        id: settings
    }
    
    // Explorer
    Explorer {
        id: explorer
    }
    
    // Downloader
    Downloader {
        id: downloader
    }

    // Open url by Dialog
    OpenUrlDialog {
        id: openUrlDialog
    
        Connections {
            target: playlistModel
            onUrlDialogRequested: {
                window.raise();
                window.requestActivate();
            }
        }
    }

    // Open file by Dialog
    FileDialog {
        id: fileDialog
        title: qsTr("Please choose a file")
        folder: shortcuts.home
        selectMultiple: true
        onAccepted: playlistModel.addLocalFiles(fileDialog.fileUrls)
    }

    // Open file by drag
    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: playlistModel.addLocalFiles(drop.urls)
    }
    
    // Menu
    contextMenu: Menu {
        width: 150
        padding: 5
        Action { text: qsTr("Open files"); onTriggered: fileDialog.open() }
        Action { text: qsTr("Open URL"); onTriggered: openUrlDialog.open() }
        Action { text: qsTr("Explorer"); onTriggered: explorer.open() }
        MenuSeparator { padding: 0 }
        Menu {
            title: qsTr("Video")
            width: 150
            Action { text: qsTr("Options"); onTriggered: videoOptionsDialog.open() }
            MenuSeparator { padding: 0 }
            Action { text: qsTr("Default"); onTriggered: mpv.setProperty("video-aspect", 0) }
            Action { text: qsTr("4:3"); onTriggered: mpv.setProperty("video-aspect", 4 / 3) }
            Action { text: qsTr("16:9"); onTriggered: mpv.setProperty("video-aspect", 16 / 9) }
            Action { text: qsTr("16:10"); onTriggered: mpv.setProperty("video-aspect", 16 / 10) }
            Action { text: qsTr("1.85:1"); onTriggered: mpv.setProperty("video-aspect", 1.85) }
            Action { text: qsTr("2.35:1"); onTriggered: mpv.setProperty("video-aspect", 2.35) }
            delegate: MenuItem { height: 25 }
        }
        Menu {
            title: qsTr("Audio")
            width: 150
            Action { text: qsTr("Select"); onTriggered: audioTrackSelectionDialog.open() }
            delegate: MenuItem { height: 25 }
        }
        Menu {
            title: qsTr("Subtitle")
            width: 150
            Action { text: qsTr("Visible"); onTriggered: mpv.subVisible = !mpv.subVisible }
            Action { text: qsTr("Add"); onTriggered: addSubtitleDialog.open() }
            Action { text: qsTr("Select"); onTriggered: subtitleSelectionDialog.open() }
            delegate: MenuItem { height: 25 }
        }
        Menu {
            title: qsTr("Speed")
            width: 150
            Action { text: qsTr("Up"); onTriggered: if (mpv.speed < 2) mpv.speed += 0.25 }
            Action { text: qsTr("Down"); onTriggered: if (mpv.speed > 0.5) mpv.speed -= 0.25 }
            Action { text: qsTr("Reset"); onTriggered: mpv.speed = 1 }
            delegate: MenuItem { height: 25 }
        }
        Action { text: qsTr("Screenshot"); onTriggered: mpv.screenshot() }
        MenuSeparator { padding: 0 }
        Action { text: qsTr("Downloader"); onTriggered: downloader.open() }
        Action { text: qsTr("Settings"); onTriggered: settings.open() }
        Action { text: qsTr("Update plugins"); onTriggered: utils.updateParser() }
        Action { text: qsTr("Browser Ext."); onTriggered: Qt.openUrlExternally("https://coslyk.github.io/moonplayer/browser_ext.html") }
        Action { text: qsTr("Homepage"); onTriggered: Qt.openUrlExternally("https://coslyk.github.io/moonplayer/") }
        
        delegate: MenuItem { height: 25 }
    }
    
    // Toolbar
    toolbar: ToolBar {
        isPlaying: mpv.state == MpvObject.VIDEO_PLAYING || mpv.state == MpvObject.TV_PLAYING
        time: mpv.time
        duration: mpv.duration
        onPlayPauseButtonClicked: mpv.state == MpvObject.VIDEO_PLAYING ? mpv.pause() : mpv.play()
        onStopButtonClicked: mpv.stop()
        onSettingsButtonClicked: settings.open()
        onPlaylistButtonClicked: playlist.open()
        onExplorerButtonClicked: explorer.open()
        onSeekRequested: mpv.seek(time);
        onVolumeButtonClicked: {
            volumePopup.x = mpv.mapFromItem(volumeButton, 0, 0).x;
            volumePopup.y = mpv.mapFromItem(volumeButton, 0, 0).y - volumePopup.height;
            volumePopup.open();
        }
    }
    
    // Handle keyboard event
    Shortcut {
        sequence: "Left"
        onActivated: mpv.seek(mpv.time - 5);
    }
    
    Shortcut {
        sequence: "Right"
        onActivated: mpv.seek(mpv.time + 5);
    }
    
    Shortcut {
        sequence: "Up"
        onActivated: volumeSlider.value += 10;
    }
    
    Shortcut {
        sequence: "Down"
        onActivated: volumeSlider.value -= 10;
    }
    
    Shortcut {
        sequence: "Space"
        onActivated: mpv.state == MpvObject.VIDEO_PLAYING ? mpv.pause() : mpv.play()
    }

    Shortcut {
        sequence: "Return"
        onActivated: window.visibility == Window.FullScreen ? window.showNormal() : window.showFullScreen()
    }

    Shortcut {
        sequence: "Esc"
        onActivated: if (window.visibility == Window.FullScreen) showNormal();
    }

    Shortcut {
        sequence: "S"
        onActivated: mpv.screenshot()
    }

    Shortcut {
        sequence: "D"
        onActivated: mpv.subVisible = !mpv.subVisible;
    }
    
    Shortcut {
        sequence: "L"
        onActivated: playlist.open()
    }

    Shortcut {
        sequence: "R"
        onActivated: mpv.speed = 1
    }

    Shortcut {
        sequence: "U"
        onActivated: openUrlDialog.open()
    }

    Shortcut {
        sequence: "W"
        onActivated: explorer.open()
    }

    Shortcut {
        sequence: "Ctrl+Left"
        onActivated: if (mpv.speed > 0.5) mpv.speed -= 0.25;
    }

    Shortcut {
        sequence: "Ctrl+Right"
        onActivated: if (mpv.speed < 2) mpv.speed += 0.25;
    }
    
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: fileDialog.open()
    }
    
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: settings.open()
    }
}
