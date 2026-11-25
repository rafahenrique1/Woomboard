import Foundation

/// Motor de sugestões offline do Woomboard.
/// Combina snippets pessoais, palavras aprendidas localmente por frequência e sugestões do UITextChecker.
public final class SuggestionEngine: Sendable {
    private let snippets: [TextSnippet]
    private let learnedWords: [String: Int]

    public init(
        snippets: [TextSnippet] = TextSnippet.defaults,
        learnedWords: [String: Int] = [:]
    ) {
        self.snippets = snippets
        self.learnedWords = learnedWords
    }

    public init(snippets: [String: String]) {
        self.snippets = snippets.map { TextSnippet(trigger: $0.key, expansion: $0.value) }
        self.learnedWords = [:]
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

    /// Retorna sugestões priorizando snippets exatos, prefixos de snippets, palavras aprendidas e UITextChecker.
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

            // 3. Palavras aprendidas localmente ordenadas por frequência
            let learnedMatches = learnedWords
                .filter { $0.key.lowercased().hasPrefix(lowered) && $0.key.lowercased() != lowered }
                .sorted { $0.value > $1.value }
                .prefix(2)
                .map(\.key)
            for match in learnedMatches {
                appendUnique(match, to: &results)
            }
        }

        // 4. Sugestões/correções vindas do UITextChecker do iOS
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
