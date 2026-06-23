//
//  CallView.swift
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI
import AVFoundation

@available(iOS 26.0, *)
struct CallView: View {
    let contact: ContactConfig
    var preloadedBackground: UIImage? = nil
    var onEnd: () -> Void
    
    @Environment(\.localizationBundle) private var bundle
    
    @StateObject private var callManager = CallManager()
    @State private var isSpeaker  = false
    @State private var isMuted    = false
    @State private var isFaceTime = false
    @State private var fetchedImage: UIImage? = nil
    
    private var bgImage: UIImage? { preloadedBackground ?? fetchedImage }
    
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let safeTop = proxy.safeAreaInsets.top
            let safeBot = proxy.safeAreaInsets.bottom
            
            ZStack {
                // Background
                Group {
                    if let img = bgImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w, height: h)
                            .clipped()
                    } else {
                        Color(red: 0.12, green: 0.10, blue: 0.10)
                    }
                }
                .frame(width: w, height: h)
                
                // Contact info
                VStack(spacing: 3) {
                    callStatusText
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(contact.name)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                }
                .padding(.top, safeTop - 330)
                .frame(maxWidth: .infinity, alignment: .top)
                
                // Call controls
                VStack(alignment: .leading, spacing: 20) {
                    GlassEffectContainer(spacing: 14) {
                        VStack(spacing: 14) {
                            HStack(spacing: 0) {
                                callButton(
                                    icon: isSpeaker ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                                    label: String(localized: "Audio", bundle: bundle),
                                    active: isSpeaker,
                                    width: w / 3
                                ) {
                                    isSpeaker.toggle()
                                    try? AVAudioSession.sharedInstance()
                                        .overrideOutputAudioPort(isSpeaker ? .speaker : .none)
                                }
                                callButton(icon: "video.fill", label: String(localized: "FaceTime", bundle: bundle), active: isFaceTime, width: w / 3) {
                                    isFaceTime.toggle()
                                }
                                callButton(icon: "mic.slash.fill", label: String(localized: "Mute", bundle: bundle), active: isMuted, width: w / 3) {
                                    isMuted.toggle()
                                }
                            }
                            HStack(spacing: 0) {
                                callButton(icon: "ellipsis", label: String(localized: "More", bundle: bundle), width: w / 3) {}
                                Button {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    callManager.endCall()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "phone.down.fill")
                                            .font(.system(size: 26, weight: .medium))
                                            .foregroundStyle(.white)
                                            .frame(width: 84, height: 84)
                                            .background(
                                                Circle().fill(Color.red)
                                            )
                                        Text(String(localized: "End", bundle: bundle))
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.75))
                                    }
                                }
                                .frame(width: w / 3)
                                callButton(icon: "circle.grid.3x3.fill", label: String(localized: "Keypad", bundle: bundle), width: w / 3) {}
                            }
                        }
                    }
                }
                .frame(width: w)
                .position(x: w / 2, y: h - safeBot - 160)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .task {
            callManager.startCall()
            guard preloadedBackground == nil,
                  let urlStr = contact.imageURL,
                  let url = URL(string: urlStr) else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                fetchedImage = img
            }
        }
        .onChange(of: callManager.state) { _, state in
            if state == .ended {
                LastCallContext.save(
                    contactName: contact.name,
                    durationSeconds: callManager.elapsedSeconds
                )
                Task {
                    try? await Task.sleep(nanoseconds: 1_300_000_000)
                    onEnd()
                }
            }
        }
    }
    
    @ViewBuilder
    private var callStatusText: some View {
        switch callManager.state {
        case .ringing:   Text(String(localized: "Calling mobile...", bundle: bundle))
        case .connected: Text(callManager.timerString)
        case .ended:     Text(String(localized: "Call ended", bundle: bundle))
        }
    }
    
    @ViewBuilder
    private func callButton(icon: String, label: String, active: Bool = false, width: CGFloat, action: @escaping () -> Void) -> some View {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(active ? Color.black : .white)
                        .frame(width: 84, height: 84)
                        .glassEffect(.clear, in: .circle)
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(width: width)
        }
}

private struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Call Screen") {
    CallView(
        contact: ContactConfig(
            id: 1,
            name: "AARP",
            avatar: "https://ui-avatars.com/api/?name=AARP&background=E11B22&color=fff&bold=true",
            imageURL: "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=800&q=80",
            description: nil,
            websiteURL: nil
        ),
        onEnd: {}
    )
}
