import SwiftUI

// MARK: - Pixel color palette (Celeste-inspired)

enum PixelTheme {
    static let bg = Color(red: 0.10, green: 0.08, blue: 0.14)
    static let cardBg = Color(red: 0.14, green: 0.12, blue: 0.18)
    static let border = Color(red: 0.28, green: 0.25, blue: 0.32)
    static let borderLight = Color(red: 0.38, green: 0.35, blue: 0.42)
    static let accent = Color.orange
    static let accentDim = Color(red: 0.65, green: 0.35, blue: 0.10)
    static let text = Color(red: 0.92, green: 0.90, blue: 0.85)
    static let textDim = Color(red: 0.55, green: 0.52, blue: 0.48)
    static let success = Color(red: 0.35, green: 0.70, blue: 0.35)
}

// MARK: - Pixel Button

struct PixelButton: View {
    let label: String
    var color: Color = PixelTheme.accent
    var textColor: Color = PixelTheme.text
    var pixelSize: CGFloat = 2
    var fullWidth: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            PixelText(text: label, pixelSize: pixelSize, color: textColor)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isHovered ? color.opacity(0.9) : color)
                .overlay(pixelBorder(color: color.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Pixel Text Field

struct PixelTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(PixelTheme.textDim)
                    .padding(.leading, 8)
            }

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(PixelTheme.text)
                .padding(8)
        }
        .background(PixelTheme.bg)
        .overlay(pixelBorder(color: PixelTheme.border))
    }
}

// MARK: - Pixel Progress Bar (horizontal, retro)

struct PixelProgressBar: View {
    let progress: Double
    let timeString: String
    var height: CGFloat = 20

    var body: some View {
        VStack(spacing: 6) {
            PixelText(text: timeString, pixelSize: 2.5, color: PixelTheme.text)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(PixelTheme.bg)

                    // Fill
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [PixelTheme.accent, PixelTheme.accentDim],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress))
                }
                .overlay(pixelBorder(color: PixelTheme.border))
            }
            .frame(height: height)
        }
    }
}

// MARK: - Pixel Chip (duration selector)

struct PixelChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelText(
                text: label,
                pixelSize: 1.5,
                color: isSelected ? PixelTheme.text : PixelTheme.textDim
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? PixelTheme.accent : PixelTheme.bg)
            .overlay(pixelBorder(color: isSelected ? PixelTheme.accent.opacity(0.6) : PixelTheme.border))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pixel border (1px rectangular, no corner radius — retro)

func pixelBorder(color: Color) -> some View {
    Rectangle()
        .strokeBorder(color, lineWidth: 1)
}

// MARK: - Pixel card background

struct PixelCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(PixelTheme.cardBg)
            .overlay(pixelBorder(color: PixelTheme.border))
    }
}
