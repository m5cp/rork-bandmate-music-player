import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("preferredInstrument") private var preferredInstrument: String = Instrument.trumpet.rawValue
    @AppStorage("practiceReminderEnabled") private var practiceReminderEnabled: Bool = false
    @AppStorage("practiceReminderHour") private var practiceReminderHour: Int = 17
    @AppStorage("practiceReminderMinute") private var practiceReminderMinute: Int = 0
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("skillLevel") private var skillLevelRaw: String = SkillLevel.beginner.rawValue

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
                supportSection
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

    private var supportSection: some View {
        Section {
            SettingsNavigationRow(
                icon: "headphones.circle.fill",
                iconColor: .blue,
                title: "Contact Support",
                destination: ContactSupportView()
            )

            SettingsNavigationRow(
                icon: "accessibility",
                iconColor: .blue,
                title: "Accessibility",
                destination: AccessibilityView()
            )
        } header: {
            Text("Support")
        }
    }

    private var aboutSection: some View {
        Section {
            SettingsNavigationRow(
                icon: "info.circle.fill",
                iconColor: .purple,
                title: "About KITB",
                destination: AboutKITBView()
            )

            HStack {
                Label {
                    Text("Version")
                } icon: {
                    Image(systemName: "number.circle.fill")
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.medium))
            }
        } header: {
            Text("About")
        }
    }

    private var legalSection: some View {
        Section {
            SettingsNavigationRow(
                icon: "lock.shield.fill",
                iconColor: .blue,
                title: "Privacy Policy",
                destination: PrivacyPolicyView()
            )

            SettingsNavigationRow(
                icon: "doc.text.fill",
                iconColor: .indigo,
                title: "Terms of Use",
                destination: TermsOfUseView()
            )

            SettingsNavigationRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Disclaimers",
                destination: DisclaimerView()
            )

            SettingsNavigationRow(
                icon: "doc.plaintext.fill",
                iconColor: .gray,
                title: "Apple EULA",
                destination: AppleEULAView()
            )
        } header: {
            Text("Legal")
        } footer: {
            Text("KITB is a supplemental learning tool for educational use only. It does not replace instruction from a qualified music teacher.")
                .font(.caption)
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

struct SettingsNavigationRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
        }
        .accessibilityLabel(title)
    }
}

struct AppleEULAView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerBadge(icon: "apple.logo", color: .gray, title: "Apple EULA", date: "Standard License Agreement")

                PolicyCard(icon: "doc.text.fill", iconColor: .gray, title: "License Agreement") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This application is licensed to you under the terms of the Apple Licensed Application End User License Agreement (\"Standard EULA\").")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("The full terms are available at:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "safari.fill")
                                    .font(.subheadline.weight(.semibold))
                                Text("View Apple Standard EULA")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                            }
                            .padding(14)
                            .background(Color.blue.opacity(0.08), in: .rect(cornerRadius: 12))
                        }

                        Text("By using this application, you agree to these terms.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Apple EULA")
        .navigationBarTitleDisplayMode(.inline)
    }
}
