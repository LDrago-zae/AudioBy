import SwiftUI

public struct VoicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var ttsService = TTSEngineService.shared
    @Bindable var playerService = AudioPlayerService.shared
    @State private var showingPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Rate & Pitch Controls Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Speech Narration Settings")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textDark)

                            VStack(spacing: 12) {
                                // Speech Rate Slider
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Reading Speed")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.textMuted)
                                        Spacer()
                                        Text(String(format: "%.2fx", ttsService.speechRate * 2.0))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.brandGreen)
                                    }

                                    Slider(value: $ttsService.speechRate, in: 0.3...0.7)
                                        .tint(Theme.brandGreen)
                                }

                                Divider().background(Theme.cardBorder)

                                // Speech Pitch Slider
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Voice Pitch")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.textMuted)
                                        Spacer()
                                        Text(String(format: "%.1fx", ttsService.speechPitch))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.brandCyan)
                                    }

                                    Slider(value: $ttsService.speechPitch, in: 0.75...1.25)
                                        .tint(Theme.brandCyan)
                                }
                            }
                            .padding(14)
                            .background(Theme.surfaceSubtle)
                            .cornerRadius(14)
                        }
                        .padding(16)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Studio voices (Premium)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Spacer()
                                if !EntitlementService.shared.isPremium {
                                    Text("PLUS+")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)

                            Text("Neural narration via ElevenLabs. Included with Premium.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(ElevenLabsService.shared.voices) { voice in
                                    let isSelected = playerService.useStudioVoice && ElevenLabsService.shared.selectedVoiceId == voice.id
                                    Button {
                                        if EntitlementService.shared.isPremium {
                                            ElevenLabsService.shared.selectedVoiceId = voice.id
                                            playerService.useStudioVoice = true
                                            playerService.narrationMode = .nativeTTS
                                        } else {
                                            showingPaywall = true
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(voice.name)
                                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                                    .foregroundColor(isSelected ? Theme.brandGreen : Theme.textDark)
                                                Text(voice.style)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.brandGreen)
                                            }
                                        }
                                        .padding(14)
                                        .background(isSelected ? Theme.brandGreen.opacity(0.10) : Theme.surfaceWhite)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Theme.brandGreen.opacity(0.35) : Theme.cardBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .opacity(EntitlementService.shared.isPremium ? 1 : 0.55)
                        }

                        // Available Native Voices List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Narrator Voices (\(ttsService.availableVoices.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(ttsService.availableVoices) { voice in
                                    let isSelected = ttsService.selectedVoiceId == voice.id
                                    Button {
                                        ttsService.selectVoice(id: voice.id)
                                        playerService.useStudioVoice = false
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(voice.flag)
                                                .font(.system(size: 24))

                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 6) {
                                                    Text(voice.name)
                                                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                                        .foregroundColor(isSelected ? Theme.brandGreen : Theme.textDark)

                                                    Text(voice.gender)
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Theme.textMuted)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Theme.surfaceSubtle)
                                                        .clipShape(Capsule())
                                                }

                                                Text("\(voice.regionName) • \(voice.qualityDescription)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Theme.textMuted)
                                            }

                                            Spacer()

                                            // Voice Preview Sample Button
                                            Button {
                                                ttsService.previewVoice(voice)
                                            } label: {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.brandGreen)
                                                    .frame(width: 32, height: 32)
                                                    .background(Theme.brandGreen.opacity(0.12))
                                                    .clipShape(Circle())
                                            }

                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.brandGreen)
                                                    .font(.system(size: 18))
                                            }
                                        }
                                        .padding(14)
                                        .background(isSelected ? Theme.brandGreen.opacity(0.10) : Theme.surfaceWhite)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isSelected ? Theme.brandGreen.opacity(0.35) : Theme.cardBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Narrator Voices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.brandGreen)
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}
