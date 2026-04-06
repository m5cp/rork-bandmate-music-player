import SwiftUI

struct InstrumentPickerView: View {
    @Binding var selectedInstrument: Instrument
    let onSelect: (Instrument) -> Void
    @State private var expandedCategory: InstrumentCategory? = nil
    @State private var hapticTrigger: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    currentInstrumentHeader
                    categoryGrid
                    if let category = expandedCategory {
                        instrumentList(for: category)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Instruments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.selection, trigger: hapticTrigger)
        }
    }

    private var currentInstrumentHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(selectedInstrument.category.color.gradient)
                    .frame(width: 52, height: 52)
                Image(systemName: selectedInstrument.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Now Playing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(selectedInstrument.rawValue)
                    .font(.title3.bold())
                Text(selectedInstrument.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(InstrumentCategory.allCases) { category in
                let isExpanded = expandedCategory == category
                let count = Instrument.instruments(for: category).count
                let hasSelected = selectedInstrument.category == category

                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        expandedCategory = isExpanded ? nil : category
                    }
                    hapticTrigger += 1
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(isExpanded ? 0.25 : 0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: category.iconName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(category.color)
                                .symbolEffect(.bounce, value: isExpanded)
                        }

                        VStack(spacing: 2) {
                            Text(category.rawValue)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text("\(count) instruments")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isExpanded ? category.color.opacity(0.1) : Color(.secondarySystemGroupedBackground),
                        in: .rect(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isExpanded ? category.color.opacity(0.4) : .clear, lineWidth: 2)
                    )
                    .overlay(alignment: .topTrailing) {
                        if hasSelected {
                            Circle()
                                .fill(category.color)
                                .frame(width: 10, height: 10)
                                .padding(10)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(category.rawValue), \(count) instruments")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            }
        }
        .padding(.horizontal)
    }

    private func instrumentList(for category: InstrumentCategory) -> some View {
        let instruments = Instrument.instruments(for: category)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(category.color)
                    .font(.headline)
                Text(category.rawValue)
                    .font(.headline.bold())
            }
            .padding(.horizontal)

            LazyVStack(spacing: 0) {
                ForEach(Array(instruments.enumerated()), id: \.element.id) { index, instrument in
                    let isSelected = selectedInstrument == instrument

                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedInstrument = instrument
                            onSelect(instrument)
                        }
                        hapticTrigger += 1
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? category.color.gradient : AnyGradient(Gradient(colors: [Color(.quaternarySystemFill)])))
                                    .frame(width: 42, height: 42)
                                Image(systemName: instrument.iconName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(isSelected ? .white : category.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(instrument.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(instrument.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(category.color)
                                    .symbolEffect(.bounce, value: isSelected)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? category.color.opacity(0.08) : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(instrument.rawValue)
                    .accessibilityValue(isSelected ? "Selected" : "")
                    .accessibilityHint(instrument.shortDescription)

                    if index < instruments.count - 1 {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct InstrumentChipBar: View {
    let selectedInstrument: Instrument
    let onTap: () -> Void
    @State private var haptic: Int = 0

    var body: some View {
        Button {
            onTap()
            haptic += 1
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedInstrument.category.color.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: selectedInstrument.iconName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Instrument")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(selectedInstrument.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("Change")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selectedInstrument.category.color)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: haptic)
        .accessibilityLabel("Selected instrument: \(selectedInstrument.rawValue)")
        .accessibilityHint("Double tap to change instrument")
    }
}
