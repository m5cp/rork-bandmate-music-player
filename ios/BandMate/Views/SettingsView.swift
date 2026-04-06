import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("preferredInstrument") private var preferredInstrument: String = Instrument.trumpet.rawValue
    @AppStorage("practiceReminderEnabled") private var practiceReminderEnabled: Bool = false
    @AppStorage("practiceReminderHour") private var practiceReminderHour: Int = 17
    @AppStorage("practiceReminderMinute") private var practiceReminderMinute: Int = 0
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("skillLevel") private var skillLevelRaw: String = SkillLevel.beginner.rawValue

    @State private var showPrivacyPolicy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showInstrumentPicker: Bool = false
    @State private var selectedInstrument: Instrument = .trumpet

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                instrumentSection
                skillLevelSection
                practiceReminderSection
                aboutSection
                legalSection
            }
            .navigationTitle("Settings")
            .onAppear {
                selectedInstrument = Instrument(rawValue: preferredInstrument) ?? .trumpet
            }
            .sheet(isPresented: $showInstrumentPicker) {
                InstrumentPickerView(
                    selectedInstrument: $selectedInstrument,
                    onSelect: { instrument in
                        preferredInstrument = instrument.rawValue
                    }
                )
                .presentationDetents([.large])
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearanceModeRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            HStack(spacing: 12) {
                ForEach(AppearanceMode.allCases) { mode in
                    let isSelected = appearanceModeRaw == mode.rawValue
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            appearanceModeRaw = mode.rawValue
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mode.iconName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    isSelected ? Color.blue.gradient : AnyGradient(Gradient(colors: [Color(.quaternarySystemFill)])),
                                    in: Circle()
                                )

                            Text(mode.rawValue)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(isSelected ? .blue : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mode.rawValue)
                    .accessibilityValue(isSelected ? "Selected" : "")
                }
            }
            .listRowBackground(Color.clear)
        } header: {
            Text("Appearance")
        }
    }

    private var instrumentSection: some View {
        Section {
            Button {
                showInstrumentPicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedInstrument.category.color.gradient)
                            .frame(width: 36, height: 36)
                        Image(systemName: selectedInstrument.iconName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Default Instrument")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(selectedInstrument.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedInstrument.category.color)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Playback")
        }
    }

    private var skillLevelSection: some View {
        Section {
            ForEach(SkillLevel.allCases) { level in
                let isSelected = skillLevelRaw == level.rawValue
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        skillLevelRaw = level.rawValue
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: level.iconName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.yellow)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(level.rawValue)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(level.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Skill Level")
        } footer: {
            Text("AI practice feedback is tailored to your skill level.")
        }
    }

    private var practiceReminderSection: some View {
        Section {
            Toggle("Daily Practice Reminder", isOn: $practiceReminderEnabled)
                .onChange(of: practiceReminderEnabled) { _, enabled in
                    if enabled {
                        requestNotificationPermission()
                    } else {
                        cancelReminder()
                    }
                }

            if practiceReminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: {
                            Calendar.current.date(from: DateComponents(hour: practiceReminderHour, minute: practiceReminderMinute)) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            practiceReminderHour = components.hour ?? 17
                            practiceReminderMinute = components.minute ?? 0
                            scheduleReminder()
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Practice")
        } footer: {
            if practiceReminderEnabled {
                Text("You'll get a friendly reminder to practice every day.")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .fontWeight(.medium)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
            }

            HStack {
                Text("App")
                    .fontWeight(.medium)
                Spacer()
                Text("KITB – Sheet Music Player")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.medium))
            }
        } header: {
            Text("About")
        } footer: {
            Text("For educational use only. Accuracy may vary depending on image quality and music complexity.")
                .font(.caption)
        }
    }

    private var legalSection: some View {
        Section {
            Button("Privacy Policy") { showPrivacyPolicy = true }
            Button("Terms of Use") { showTerms = true }
            NavigationLink("Apple EULA") {
                LegalTextView(
                    title: "Apple EULA",
                    text: "This application is licensed to you under the terms of the Apple Licensed Application End User License Agreement (\"Standard EULA\"), the terms of which are available at:\n\nhttps://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n\nBy using this application, you agree to these terms."
                )
            }
        } header: {
            Text("Legal")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                LegalTextView(
                    title: "Privacy Policy",
                    text: "KITB – Sheet Music Player\n\nLast updated: April 2026\n\nYour privacy matters to us. This app processes sheet music images to detect musical notation. Images are sent to our secure servers for analysis and are not stored permanently.\n\nData We Collect:\n• Sheet music images (temporarily, for analysis only)\n• Song data you save (stored locally and synced to your account)\n• App preferences\n\nData We Don't Collect:\n• Personal identification information\n• Location data\n• Contact information\n\nWe do not sell, share, or distribute your data to third parties.\n\nFor questions, contact: support@kitb.app"
                )
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showPrivacyPolicy = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                LegalTextView(
                    title: "Terms of Use",
                    text: "KITB – Sheet Music Player\n\nTerms of Use\nLast updated: April 2026\n\nBy using this app, you agree to the following:\n\n1. Educational Use: This app is designed for educational purposes to help students learn and practice music.\n\n2. Accuracy: Music recognition accuracy may vary. Always verify results against your original sheet music.\n\n3. Copyright: You are responsible for ensuring you have the right to scan and use any sheet music. Do not scan copyrighted material without permission.\n\n4. Acceptable Use: Use this app only for lawful purposes.\n\n5. Disclaimer: This app is provided \"as is\" without warranties of any kind.\n\n6. Limitation of Liability: We are not liable for any damages arising from use of this app.\n\nFor questions, contact: support@kitb.app"
                )
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showTerms = false }
                    }
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in
                if granted {
                    scheduleReminder()
                } else {
                    practiceReminderEnabled = false
                }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["practiceReminder"])

        let encouragements = [
            "Time to practice! Your future self will thank you. 🎵",
            "Ready to make some music? Let's go! 🎶",
            "A little practice goes a long way. Open KITB! 🎼",
            "Your instrument misses you. Time to play! 🎹",
            "Practice makes progress! Let's play today. 🎺"
        ]

        let content = UNMutableNotificationContent()
        content.title = "Practice Time!"
        content.body = encouragements.randomElement() ?? encouragements[0]
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = practiceReminderHour
        dateComponents.minute = practiceReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "practiceReminder", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["practiceReminder"])
    }
}

struct LegalTextView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
