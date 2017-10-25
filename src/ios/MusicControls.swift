//import Cordova
//import Foundation
import MediaPlayer

var musicControlsSettings: MusicControlsInfo?

class MusicControlsInfo: NSObject {
    var artist = ""
    var track = ""
    var album = ""
    var ticker = ""
    var cover = ""
    var duration: Int = 0
    var elapsed: Int = 0
    var isPlaying = false
    var hasPrev = false
    var hasNext = false
    var hasSkipForward = false
    var hasSkipBackward = false
    var skipForwardInterval: Int = 0
    var skipBackwardInterval: Int = 0
    var dismissable = false
    
    init(dictionary: [AnyHashable: Any]) {
        super.init()
        artist = dictionary["artist"] as! String
        track = dictionary["track"] as! String
        album = dictionary["album"] as! String
        ticker = dictionary["ticker"] as! String
        cover = dictionary["cover"] as! String
        duration = dictionary["duration"] as! Int
        elapsed = dictionary["elapsed"] as! Int
        isPlaying = (dictionary["isPlaying"] as! Int != 0)
        hasPrev = (dictionary["hasPrev"] as! Int != 0)
        hasNext = (dictionary["hasNext"] as! Int != 0)
        hasSkipForward = (dictionary["hasSkipForward"] as! Int != 0)
        hasSkipBackward = (dictionary["hasSkipBackward"] as! Int != 0)
        skipForwardInterval = dictionary["skipForwardInterval"] as! Int
        skipBackwardInterval = dictionary["skipBackwardInterval"] as! Int
        dismissable = (dictionary["dismissable"] as! Int != 0)
    }
}

@objc(MusicControls) class MusicControls : CDVPlugin {
    
    var latestEventCallbackId = ""
    
    func create(_ command: CDVInvokedUrlCommand) {
        var musicControlsInfoDict = command.arguments[0]
        var musicControlsInfo = musicControlsInfoDict as? MusicControlsInfo
        
        musicControlsSettings = musicControlsInfo
        
        if NSClassFromString("MPNowPlayingInfoCenter") != nil {
            return
        }
        
        self.commandDelegate!.run(inBackground: {() -> Void in
            var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo
            var updatedNowPlayingInfo = nowPlayingInfo
            
            var mediaItemArtwork: MPMediaItemArtwork? = self.createCoverArtwork(musicControlsInfo!.cover)
            var duration = musicControlsInfo?.duration
            var elapsed = musicControlsInfo?.elapsed
            var playbackRate = (musicControlsInfo?.isPlaying)! ? 1 : 0
            
            if mediaItemArtwork != nil {
                updatedNowPlayingInfo![MPMediaItemPropertyArtwork] = mediaItemArtwork
            }
            
            updatedNowPlayingInfo![MPMediaItemPropertyArtist] = musicControlsInfo?.artist
            updatedNowPlayingInfo![MPMediaItemPropertyTitle] = musicControlsInfo?.track
            updatedNowPlayingInfo![MPMediaItemPropertyAlbumTitle] = musicControlsInfo?.album
            updatedNowPlayingInfo![MPMediaItemPropertyPlaybackDuration] = duration
            updatedNowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
            updatedNowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
            
            nowPlayingInfoCenter.nowPlayingInfo = updatedNowPlayingInfo
        })
    }
    
    func createCoverArtwork(_ coverUri: String) -> MPMediaItemArtwork? {
        var coverImage: UIImage? = nil
        if coverUri == nil {
            return nil
        }
        if coverUri.isEmpty {
            return nil
        }
        if coverUri.hasPrefix("http://") || coverUri.hasPrefix("https://") {
            let coverImageUrl = URL(string: coverUri)
            do {
                let coverImageData = try Data(contentsOf: coverImageUrl!)
                coverImage = UIImage(data: coverImageData)
            } catch {
                print(error)
            }
        }
        else if coverUri.hasPrefix("file://") {
            let fullCoverImagePath: String = coverUri.replacingOccurrences(of: "file://", with: "")
            if FileManager.default.fileExists(atPath: fullCoverImagePath) {
                coverImage = UIImage(contentsOfFile: fullCoverImagePath)
            }
        }
        else if !coverUri.isEqual("") {
            let baseCoverImagePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let fullCoverImagePath = "\(baseCoverImagePath)\(coverUri)"
            if FileManager.default.fileExists(atPath: fullCoverImagePath) {
                coverImage = UIImage(named: fullCoverImagePath)
            }
        }
        else {
            coverImage = UIImage(named: "none")
        }
        
        /*let artwork = MPMediaItemArtwork.init(boundsSize: coverImage!.size, requestHandler: { (size) -> UIImage in
            return coverImage!
        })
        return isCoverImageValid(coverImage!) ? artwork : nil as MPMediaItemArtwork?*/
        
        return isCoverImageValid(coverImage!) ? MPMediaItemArtwork(image: coverImage!) : nil as MPMediaItemArtwork?
    }
    
    func isCoverImageValid(_ coverImage: UIImage) -> Bool {
        return coverImage != nil && (coverImage.ciImage! != nil || coverImage.cgImage! != nil)
    }
    
    func watch2(_ command: CDVInvokedUrlCommand) {
        latestEventCallbackId = command.callbackId
        print("watch starts")
        print(latestEventCallbackId)
        print("watch ends")
        //registerMusicControlsEventListener()
    }
    
    func handleMusicControlsNotification(_ notification: Notification) {
        let receivedEvent = notification.object as? UIEvent
        /*if latestEventCallbackId() == nil {
         return
         }*/
        
        if receivedEvent?.type == .remoteControl {
            var action: String
            action = "marco"
            /*switch receivedEvent?.subtype {
             case UIEventSubtype.remoteControlTogglePlayPause:
             action = "music-controls-toggle-play-pause"
             case UIEventSubtype.remoteControlPlay:
             action = "music-controls-play"
             case .remoteControlPause:
             action = "music-controls-pause"
             case .remoteControlPreviousTrack:
             action = "music-controls-previous"
             case .remoteControlNextTrack:
             action = "music-controls-next"
             case .remoteControlStop:
             action = "music-controls-destroy"
             default:
             break
             }*/
            let jsonAction = "{\"message\":\"\(action)\"}"
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
            //commandDelegate.send(pluginResult, callbackId: latestEventCallbackId())
            commandDelegate.send(pluginResult, callbackId: latestEventCallbackId)
        }
    }
    
    //func play(_ event: MPRemoteCommandEvent) {
    func play() {
        let action = "music-controls-play"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    //func pause(_ event: MPRemoteCommandEvent) {
    func pause() {
        let action = "music-controls-pause"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    func nextTrack() {
        let action = "music-controls-next"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    func prevTrack() {
        let action = "music-controls-previous"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    func skipForwardEvent() {
        let action = "music-controls-skip-forward"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    func skipBackwardEvent() {
        let action = "music-controls-skip-backward"
        let jsonAction = "{\"message\":\"\(action)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonAction)
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
    }
    
    //func registerMusicControlsEventListener() {
    func watch(_ command: CDVInvokedUrlCommand) {
        latestEventCallbackId = command.callbackId
        //UIApplication.shared.beginReceivingRemoteControlEvents()
        
        if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0 {
            
            let commandCenter = MPRemoteCommandCenter.shared()
            //var commandCenter = MPRemoteCommandCenter.shared()
            if #available(iOS 9.1, *) {
            commandCenter.changePlaybackPositionCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(self.changedThumbSlider))
            }
            
            commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.play()
                return .success
            })
            
            commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.pause()
                return .success
            })
            
            commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.nextTrack()
                return .success
            })
            
            commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.prevTrack()
                return .success
            })
            
            commandCenter.skipForwardCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.skipForwardEvent()
                return .success
            })
            
            commandCenter.skipBackwardCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.skipBackwardEvent()
                return .success
            })
        }
    }
    
    func registerMusicControlsEventListener2() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMusicControlsNotification), name: NSNotification.Name(rawValue: "musicControlsEventNotification"), object: nil)
        if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0 {
            //only available in iOS 9.1 and up.
            let commandCenter = MPRemoteCommandCenter.shared()
            //commandCenter.changePlaybackPositionCommand.isEnabled = true
            //commandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(self.changedThumbSliderOnLockScreen))
            /*if musicControlsSettings!.hasNext {
             let nextTrackCommand: MPRemoteCommand? = commandCenter.nextTrackCommand
             nextTrackCommand?.isEnabled = true
             nextTrackCommand?.addTarget(self, action: #selector(self.nextTrackEvent))
             }
             if musicControlsSettings.hasPrev {
             let prevTrackCommand: MPRemoteCommand? = commandCenter.previousTrackCommand
             prevTrackCommand?.isEnabled = true
             prevTrackCommand?.addTarget(self, action: #selector(self.prevTrackEvent))
             }
             if musicControlsSettings.hasSkipForward {
             let skipForwardIntervalCommand: MPSkipIntervalCommand? = commandCenter.skipForwardCommand
             skipForwardIntervalCommand?.preferredIntervals = [musicControlsSettings.skipForwardInterval] as? [NSNumber]
             skipForwardIntervalCommand?.isEnabled = true
             skipForwardIntervalCommand?.addTarget(self, action: #selector(self.skipForwardEvent))
             }
             if musicControlsSettings.hasSkipBackward {
             let skipBackwardIntervalCommand: MPSkipIntervalCommand? = commandCenter.skipBackwardCommand
             skipBackwardIntervalCommand?.preferredIntervals = [musicControlsSettings.skipBackwardInterval] as? [NSNumber]
             skipBackwardIntervalCommand?.isEnabled = true
             skipBackwardIntervalCommand?.addTarget(self, action: #selector(self.skipBackwardEvent))
             }*/
        }
    }
    
    func changedThumbSlider(onLockScreen event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        let seekTo = "{\"message\":\"music-controls-seek-to\",\"position\":\"\(event.positionTime)\"}"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: seekTo)
        //pluginResult.associatedObject = ["position": event.positionTime]
        
        pluginResult?.associatedObject = ["position": event.positionTime]
        //pluginResult!.associatedObject = ["position": event.positionTime]
        
        self.commandDelegate!.send(pluginResult, callbackId: latestEventCallbackId)
        return .success
    }
    
}
