import SwiftUI

/// Kleiner Markdown-Renderer für Chat-Antworten: Überschriften,
/// Aufzählungen, nummerierte Listen, Code und Tabellen. Absichtlich
/// schlank — er deckt genau das ab, was Tandem selbst schreibt.
struct RichText: View {
    var markdown: String
    var accent: Color = AccentChoice.mint.color

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
                    // Trennzeile | --- | --- | überspringen.
                    if !cells.allSatisfy({ $0.allSatisfy { $0 == "-" || $0 == ":" } }) {
                        rows.append(cells)
                    }
                    index += 1
                }
                if !rows.isEmpty { result.append(.table(rows)) }
                continue
            }
            if line.hasPrefix("- ") || line.hasPrefix("• ") || line.hasPrefix("* ") {
                result.append(.bullet(inline(String(line.dropFirst(2)))))
                index += 1
                continue
            }
            if let dot = line.firstIndex(of: "."),
               line[line.startIndex..<dot].allSatisfy({ $0.isNumber }),
               line.index(after: dot) < line.endIndex,
               line[line.index(after: dot)] == " " {
                let number = String(line[line.startIndex..<dot])
                let text = String(line[line.index(dot, offsetBy: 2)...])
                result.append(.numbered(number, inline(text)))
                index += 1
                continue
            }
            result.append(.paragraph(inline(line)))
            index += 1
        }
        return result
    }

    private func inline(_ text: String) -> String { text }

    @ViewBuilder
    private func view(for block: Block) -> some View {
        switch block {
        case .heading(let text, let level):
            Text(attributed(text))
                .font(.system(size: level == 1 ? 19 : (level == 2 ? 16 : 14),
                              weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, level == 1 ? 2 : 6)
        case .paragraph(let text):
            Text(attributed(text))
                .font(.system(size: 14.5, design: .rounded))
                .foregroundStyle(.primary.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 7) {
                Circle().fill(accent).frame(width: 5, height: 5).padding(.top, 7)
                Text(attributed(text))
                    .font(.system(size: 14.5, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .numbered(let number, let text):
            HStack(alignment: .top, spacing: 8) {
                Text(number)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .frame(minWidth: 14, alignment: .trailing)
                    .padding(.top, 2)
                Text(attributed(text))
                    .font(.system(size: 14.5, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .code(let code):
            Text(code)
                .font(.system(size: 12.5, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                }
        case .table(let rows):
            RichTable(rows: rows, accent: accent)
        case .divider:
            Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
        }
    }

    private func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

/// Tabelle als echtes Raster mit Glaszeilen — Markdown-Tabellen kann
/// Foundation nicht rendern, und im Agenten-Chat sind sie zu nützlich,
/// um sie wegzulassen.
struct RichTable: View {
    var rows: [[String]]
    var accent: Color

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    ForEach(rows[index].indices, id: \.self) { cellIndex in
                        let cell = rows[index][cellIndex]
                        Text(cell)
                            .font(.system(size: 12, weight: index == 0 ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(index == 0 ? accent : .primary.opacity(0.88))
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if cellIndex < rows[index].count - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background(index == 0 ? accent.opacity(0.10) : Color.white.opacity(index % 2 == 0 ? 0.02 : 0))
                if index < rows.count - 1 {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.7)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        }
    }
}
