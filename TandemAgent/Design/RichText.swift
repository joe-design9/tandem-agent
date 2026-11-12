import SwiftUI

/// Kleiner Markdown-Renderer für Chat-Antworten: Überschriften,
/// Aufzählungen, nummerierte Listen, Code und Tabellen. Ruhige Typografie
/// ohne Rahmen und ohne Farbe.
struct RichText: View {
    var markdown: String
    var accent: Color = Palette.textSecondary

    var body: some View {
        let items = blocks()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                view(for: items[index])
            }
        }
    }

    private enum Block {
        case heading(String, Int)
        case paragraph(String)
        case bullet(String)
        case numbered(String, String)
        case code(String)
        case table([[String]])
        case divider
    }

    private func blocks() -> [Block] {
        var result: [Block] = []
        let lines = markdown.components(separatedBy: .newlines)
        var index = 0

        while index < lines.count {
            let raw = lines[index]
            let line = raw.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                index += 1
                continue
            }
            if line == "---" {
                result.append(.divider)
                index += 1
                continue
            }
            if line.hasPrefix("```") {
                var code: [String] = []
                index += 1
                while index < lines.count, !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[index])
                    index += 1
                }
                index += 1
                result.append(.code(code.joined(separator: "\n")))
                continue
            }
            if line.hasPrefix("### ") {
                result.append(.heading(String(line.dropFirst(4)), 3))
                index += 1
                continue
            }
            if line.hasPrefix("## ") {
                result.append(.heading(String(line.dropFirst(3)), 2))
                index += 1
                continue
            }
            if line.hasPrefix("# ") {
                result.append(.heading(String(line.dropFirst(2)), 1))
                index += 1
                continue
            }
            if line.hasPrefix("|") {
                var rows: [[String]] = []
                while index < lines.count {
                    let tableLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard tableLine.hasPrefix("|") else { break }
                    let cells = tableLine
                        .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                        .components(separatedBy: "|")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    if !cells.allSatisfy({ $0.allSatisfy { $0 == "-" || $0 == ":" } }) {
                        rows.append(cells)
                    }
                    index += 1
                }
                if !rows.isEmpty { result.append(.table(rows)) }
                continue
            }
            if line.hasPrefix("- ") || line.hasPrefix("• ") || line.hasPrefix("* ") {
                result.append(.bullet(String(line.dropFirst(2))))
                index += 1
                continue
            }
            if let dot = line.firstIndex(of: "."),
               line[line.startIndex..<dot].allSatisfy({ $0.isNumber }),
               line.index(after: dot) < line.endIndex,
               line[line.index(after: dot)] == " " {
                let number = String(line[line.startIndex..<dot])
                let text = String(line[line.index(dot, offsetBy: 2)...])
                result.append(.numbered(number, text))
                index += 1
                continue
            }
            result.append(.paragraph(line))
            index += 1
        }
        return result
    }

    @ViewBuilder
    private func view(for block: Block) -> some View {
        switch block {
        case .heading(let text, let level):
            Text(attributed(text))
                .font(.system(size: level == 1 ? 18 : (level == 2 ? 16 : 15), weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .padding(.top, level == 1 ? 4 : 6)
        case .paragraph(let text):
            Text(attributed(text))
                .font(.system(size: 15))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textTertiary)
                Text(attributed(text))
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .numbered(let number, let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Palette.textTertiary)
                    .frame(minWidth: 16, alignment: .leading)
                    .padding(.top, 1)
                Text(attributed(text))
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .code(let code):
            Text(code)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(Palette.textPrimary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Palette.surfaceSunken)
                }
        case .table(let rows):
            RichTable(rows: rows, accent: accent)
        case .divider:
            Rectangle().fill(Palette.hairline).frame(height: 0.5)
        }
    }

    private func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

/// Tabelle als schlichtes Raster mit Haarlinien.
struct RichTable: View {
    var rows: [[String]]
    var accent: Color

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    ForEach(rows[index].indices, id: \.self) { cellIndex in
                        Text(rows[index][cellIndex])
                            .font(.system(size: 13, weight: index == 0 ? .medium : .regular))
                            .foregroundStyle(index == 0 ? Palette.textSecondary : Palette.textPrimary)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 6)
                    }
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background(index == 0 ? Palette.surfaceRaised : Color.clear)

                if index < rows.count - 1 {
                    Rectangle().fill(Palette.hairline).frame(height: 0.5)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
