import SwiftUI

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    enum SheetKind: Int, Identifiable {
        case privacy, tutorial
        var id: Int { rawValue }
    }

    @State private var activeSheet: SheetKind? = nil
    @State private var confirmReset = false
    @State private var soundOn = true
    @State private var hapticsOn = true

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Settings", subtitle: "Workshop preferences",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            toggleRow(glyph: .sound, title: "Sound", subtitle: "Mechanical clicks and chimes",
                                      isOn: $soundOn) { store.setSound(soundOn) }
                            toggleRow(glyph: .haptics, title: "Haptics", subtitle: "Impact feedback on actions",
                                      isOn: $hapticsOn) { store.setHaptics(hapticsOn) }

                            buttonRow(glyph: .tutorial, title: "View Tutorial",
                                      subtitle: "Replay the field briefing") {
                                store.tapFeedback()
                                activeSheet = .tutorial
                            }
                            buttonRow(glyph: .privacy, title: "Privacy Policy",
                                      subtitle: "How your data is handled") {
                                store.tapFeedback()
                                activeSheet = .privacy
                            }
                            buttonRow(glyph: .reset, title: "Reset Progress",
                                      subtitle: "Erase all stars, cores and upgrades", danger: true) {
                                store.tapFeedback()
                                confirmReset = true
                            }

                            VStack(spacing: 4) {
                                Text("Clockwork Vanguard")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(Theme.ivoryDim)
                                Text("Version 1.0")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.ivoryDim.opacity(0.7))
                            }
                            .padding(.top, 16)
                            Spacer(minLength: 24)
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            soundOn = store.soundOn
            hapticsOn = store.hapticsOn
        }
        .sheet(item: $activeSheet) { kind in
            switch kind {
            case .privacy:
                ClockworkVanguardWebPanel(urlString: "https://templespirit.org/click.php")
                    .edgesIgnoringSafeArea(.bottom)
                    .background(Color.black.ignoresSafeArea())
            case .tutorial:
                OnboardingView { activeSheet = nil }
                    .environmentObject(store)
            }
        }
        .alert(isPresented: $confirmReset) {
            Alert(
                title: Text("Reset All Progress?"),
                message: Text("Stars, cores, upgrades, achievements and statistics will be permanently erased."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetProgress()
                    store.heavyFeedback()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Rows

    private func toggleRow(glyph: MenuGlyphKind, title: String, subtitle: String,
                           isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            MenuGlyph(kind: glyph, size: 22, color: Theme.brass)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.bgDeep))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(Theme.ivory)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.ivoryDim)
            }
            Spacer()
            BrassToggle(isOn: isOn, action: onChange)
        }
        .padding(12)
        .background(PanelBackground(corner: 11))
    }

    private func buttonRow(glyph: MenuGlyphKind, title: String, subtitle: String,
                           danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MenuGlyph(kind: glyph, size: 22, color: danger ? Theme.danger : Theme.brass)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.bgDeep))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(danger ? Theme.danger : Theme.ivory)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.ivoryDim)
                }
                Spacer()
                ChevronGlyph(pointing: .right)
                    .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 8, height: 13)
            }
            .padding(12)
            .background(PanelBackground(corner: 11,
                                        stroke: danger ? Theme.danger.opacity(0.4) : Theme.brassDim.opacity(0.6)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
