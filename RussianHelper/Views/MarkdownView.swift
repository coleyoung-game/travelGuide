import SwiftUI

// MARK: - MarkdownView
//
// Renders a subset of Markdown commonly produced by LLMs:
//   • Fenced code blocks  ```lang … ```
//   • Inline code         `code`
//   • Bold                **text**  or  __text__
//   • Italic              *text*  or  _text_
//   • Strikethrough       ~~text~~
//   • Headers             # / ## / ###
//   • Bullet lists        • / - / * at start of line
//   • Numbered lists      1. 2. …
//   • Horizontal rule     ---
//   • Plain text fallback

struct MarkdownView: View {
    let text: String
    var textColor: Color = .white.opacity(0.92)
    var codeBackground: Color = Color(red: 0.13, green: 0.13, blue: 0.16)
    var codeForeground: Color = Color(red: 0.85, green: 0.85, blue: 0.95)
    var accentColor: Color = Color(red: 0.514, green: 0.647, blue: 0.996)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(blocks(from: text)) { block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Block Renderer

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block.kind {

        case .codeBlock(let lang):
            VStack(alignment: .leading, spacing: 0) {
                if !lang.isEmpty {
                    Text(lang)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(block.content)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(codeForeground)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .padding(.top, lang.isEmpty ? 10 : 0)
                        .textSelection(.enabled)
                }
            }
            .background(codeBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )

        case .header(let level):
            inlineText(block.content)
                .font(headerFont(level))
                .foregroundStyle(textColor)
                .padding(.top, level == 1 ? 8 : 4)

        case .bullet:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                    .foregroundStyle(accentColor)
                    .font(.body)
                inlineText(block.content)
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .numbered(let n):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(n).")
                    .foregroundStyle(accentColor)
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 20, alignment: .trailing)
                inlineText(block.content)
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .rule:
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.vertical, 6)

        case .paragraph:
            inlineText(block.content)
                .foregroundStyle(textColor)
                .lineSpacing(3)
                .textSelection(.enabled)
        }
    }

    // MARK: - Inline Formatter

    private func inlineText(_ raw: String) -> Text {
        // Build an AttributedString with inline formatting
        if let attributed = try? AttributedString(
            markdown: raw,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return Text(attributed)
        }
        // Fallback: plain text
        return Text(raw)
    }

    // MARK: - Header Font

    private func headerFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2.weight(.bold)
        case 2: return .title3.weight(.semibold)
        default: return .headline
        }
    }
}

// MARK: - Block Parsing

private enum MDBlockKind: Equatable {
    case codeBlock(String)     // associated lang string
    case header(Int)           // level 1–3
    case bullet
    case numbered(Int)
    case rule
    case paragraph
}

private struct MDBlock: Identifiable {
    let id = UUID()
    let kind: MDBlockKind
    let content: String
}

private func blocks(from text: String) -> [MDBlock] {
    var result: [MDBlock] = []
    let lines = text.components(separatedBy: "\n")
    var i = 0

    while i < lines.count {
        let line = lines[i]

        // ── Fenced code block ─────────────────────────────────────────
        if line.hasPrefix("```") {
            let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            while i < lines.count && !lines[i].hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            // remove trailing blank lines inside the block
            while codeLines.last?.isEmpty == true { codeLines.removeLast() }
            result.append(MDBlock(kind: .codeBlock(lang), content: codeLines.joined(separator: "\n")))
            i += 1 // skip closing ```
            continue
        }

        // ── Horizontal rule ───────────────────────────────────────────
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            result.append(MDBlock(kind: .rule, content: ""))
            i += 1
            continue
        }

        // ── Headers ───────────────────────────────────────────────────
        if line.hasPrefix("### ") {
            result.append(MDBlock(kind: .header(3), content: String(line.dropFirst(4))))
            i += 1; continue
        }
        if line.hasPrefix("## ") {
            result.append(MDBlock(kind: .header(2), content: String(line.dropFirst(3))))
            i += 1; continue
        }
        if line.hasPrefix("# ") {
            result.append(MDBlock(kind: .header(1), content: String(line.dropFirst(2))))
            i += 1; continue
        }

        // ── Bullet ────────────────────────────────────────────────────
        if line.hasPrefix("• ") || line.hasPrefix("- ") || line.hasPrefix("* ") {
            let content = String(line.dropFirst(2))
            result.append(MDBlock(kind: .bullet, content: content))
            i += 1; continue
        }

        // ── Numbered list ─────────────────────────────────────────────
        if let match = line.firstMatch(of: /^(\d+)\.\s(.+)/) {
            let num = Int(match.output.1) ?? 1
            result.append(MDBlock(kind: .numbered(num), content: String(match.output.2)))
            i += 1; continue
        }

        // ── Empty line → skip ─────────────────────────────────────────
        if trimmed.isEmpty {
            i += 1; continue
        }

        // ── Paragraph (possibly multi-line) ──────────────────────────
        // Collect consecutive non-special lines into one paragraph
        var paraLines: [String] = [line]
        i += 1
        while i < lines.count {
            let next = lines[i]
            let nextTrimmed = next.trimmingCharacters(in: .whitespaces)
            // Stop collecting on blank line or special prefix
            if nextTrimmed.isEmpty { break }
            if next.hasPrefix("```") || next.hasPrefix("#") ||
               next.hasPrefix("• ") || next.hasPrefix("- ") ||
               next.hasPrefix("* ") || nextTrimmed == "---" { break }
            if next.firstMatch(of: /^\d+\.\s/) != nil { break }
            paraLines.append(next)
            i += 1
        }
        result.append(MDBlock(kind: .paragraph, content: paraLines.joined(separator: "\n")))
    }

    return result
}

// MARK: - Preview

#Preview {
    ScrollView {
        MarkdownView(text: """
        # 러시아어 여행 가이드

        ## 기본 인사말

        안녕하세요는 **Здравствуйте** (Zdravstvuyte)입니다.

        ### 유용한 표현들

        - 감사합니다: **Спасибо** (Spasibo)
        - 도와주세요: *Помогите* (Pomogite)
        - 얼마예요?: Сколько стоит?

        ---

        ## 코드 예제

        ```swift
        let greeting = "Здравствуйте"
        print(greeting)
        ```

        인라인 코드: `let x = 42` 처럼 사용합니다.

        1. 첫 번째 단계
        2. 두 번째 단계
        3. 세 번째 단계
        """)
        .padding(20)
    }
    .background(Color(red: 0.106, green: 0.106, blue: 0.122))
    .preferredColorScheme(.dark)
}
