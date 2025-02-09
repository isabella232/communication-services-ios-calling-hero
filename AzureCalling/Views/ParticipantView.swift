//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit
import AVFoundation
import AzureCommunicationCalling

class ParticipantView: UIView {
    private static let xibName: String = "ParticipantView"

    // MARK: Properties

    private var renderer: VideoStreamRenderer?
    private var rendererView: RendererView?
    private var videoStreamId: String?
    private var isScreenSharing: Bool = false

    // MARK: IBOutlets

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var placeholderImage: UIImageView!
    @IBOutlet weak var videoViewContainer: UIView!
    @IBOutlet weak var activeSpeakerView: ActiveSpeakerView!
    @IBOutlet weak var participantLabelView: ParticipantLabelView!

    // MARK: Constructors

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }

    // MARK: Operation methods

    func updateDisplayName(displayName: String) {
        participantLabelView.updateDisplayName(displayName: displayName)
    }

    func updateMuteIndicator(isMuted: Bool) {
        participantLabelView.updateMuteIndicator(isMuted: isMuted)
    }

    func updateActiveSpeaker(isSpeaking: Bool) {
        activeSpeakerView.isHidden = !isSpeaking
    }

    func updateVideoStream(localVideoStream: LocalVideoStream?) {
        if localVideoStream == nil {
            cleanUpVideoRendering()
            return
        }

        let newVideoSourceId = "LocalVideoStream:" + localVideoStream!.source.id
        if newVideoSourceId == videoStreamId {
            return
        }
        cleanUpVideoRendering()

        do {
            let newRenderer: VideoStreamRenderer = try VideoStreamRenderer(localVideoStream: localVideoStream!)
            try updateRendering(newRenderer: newRenderer)
            videoStreamId = newVideoSourceId
        } catch {
            print("Failed to render local video")
        }
    }

    func updateVideoStream(remoteVideoStream: RemoteVideoStream?, isScreenSharing: Bool = false) {
        self.isScreenSharing = isScreenSharing
        if remoteVideoStream == nil {
            cleanUpVideoRendering()
            return
        }

        let newVideoSourceId = "RemoteVideoStream:" + String(remoteVideoStream!.id)
        if newVideoSourceId == videoStreamId {
            return
        }
        cleanUpVideoRendering()

        do {
            let newRenderer: VideoStreamRenderer = try VideoStreamRenderer(remoteVideoStream: remoteVideoStream!)
            try updateRendering(newRenderer: newRenderer)
            videoStreamId = newVideoSourceId
        } catch {
            print("Failed to render remote video")
        }
    }

    func updateDisplayNameVisible(isDisplayNameVisible: Bool) {
        guard let view = participantLabelView else {
            return
        }
        view.isHidden = !isDisplayNameVisible
    }

    func dispose() {
        cleanUpVideoRendering()
    }

    // MARK: Private methods

    private func initSubviews() {
        let nib = UINib(nibName: ParticipantView.xibName, bundle: nil)
        nib.instantiate(withOwner: self, options: nil)

        contentView.frame = bounds
        addSubview(contentView)
    }

    private func updateRendering(newRenderer: VideoStreamRenderer) throws {
        let scalingMode = !isScreenSharing ? CreateViewOptions(scalingMode: .crop) : CreateViewOptions(scalingMode: .fit)
        let newRendererView: RendererView = try newRenderer.createView(withOptions: scalingMode)

        attachRendererView(rendererView: newRendererView)

        renderer = newRenderer
        rendererView = newRendererView
    }

    private func attachRendererView(rendererView: RendererView) {
        rendererView.translatesAutoresizingMaskIntoConstraints = false
        videoViewContainer.addSubview(rendererView)

        let constraints = [
            rendererView.topAnchor.constraint(equalTo: videoViewContainer.topAnchor),
            rendererView.bottomAnchor.constraint(equalTo: videoViewContainer.bottomAnchor),
            rendererView.leftAnchor.constraint(equalTo: videoViewContainer.leftAnchor),
            rendererView.rightAnchor.constraint(equalTo: videoViewContainer.rightAnchor)
        ]

        NSLayoutConstraint.activate(constraints)

    }

    private func cleanUpVideoRendering() {
        rendererView?.removeFromSuperview()
        rendererView?.dispose()
        renderer?.dispose()
        renderer = nil
        rendererView = nil
        videoStreamId = nil
    }
}
