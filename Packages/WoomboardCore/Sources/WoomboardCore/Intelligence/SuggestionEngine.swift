import Foundation

/// Motor de sugestões offline do Woomboard.
/// Combina expansão de snippets pessoais com sugestões externas (ex.: UITextChecker no iOS).
public final class SuggestionEngine: Sendable {
    private let snippets: [TextSnippet]

    public init(snippets: [TextSnippet] = TextSnippet.defaults) {
        self.snippets = snippets
    }

    public init(snippets: [String: String]) {
        self.snippets = snippets.map { TextSnippet(trigger: $0.key, expansion: $0.value) }
    }

    /// Extrai a palavra atual em digitação antes do cursor.
    public func currentWord(forContextBeforeInput context: String?) -> String {
        guard let context, !context.isEmpty else { return "" }
        if let last = context.last, last.isWhitespace || last.isNewline {
            return ""
        }
        return context
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .last
            .map(String.init) ?? ""
    }

    /// Retorna sugestões priorizando snippets exatos, prefixos de snippets e sugestões do sistema.
    public func suggestions(
        forContextBeforeInput context: String?,
        systemCompletions: [String] = []
    ) -> [String] {
        let token = currentWord(forContextBeforeInput: context)
        guard !token.isEmpty else { return [] }

        let lowered = token.lowercased()
        var results: [String] = []

        // 1. Match exato de snippet
        for snippet in snippets where snippet.trigger.lowercased() == lowered {
            appendUnique(snippet.expansion, to: &results)
        }

        // 2. Match por prefixo de snippet (quando usuário digitou pelo menos 2 caracteres)
        if lowered.count >= 2 {
            for snippet in snippets where snippet.trigger.lowercased().hasPrefix(lowered) {
                appendUnique(snippet.expansion, to: &results)
            }
        }

        // 3. Sugestões/correções vindas do UITextChecker do iOS
        for completion in systemCompletions {
            appendUnique(completion, to: &results)
        }

        return Array(results.prefix(3))
    }

    private func appendUnique(_ value: String, to list: inout [String]) {
        guard !value.isEmpty, !list.contains(value) else { return }
        list.append(value)
    }
}
