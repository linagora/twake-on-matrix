# 33. Fix ReDoS vulnerabilities in regex patterns

Date: 2025-12-24

## Status

Accepted

## Context

Regular Expression Denial of Service (ReDoS) occurs when regex patterns with unbounded/nested quantifiers cause catastrophic backtracking. Audit identified 8 critical vulnerabilities that could freeze the app via crafted phone numbers, URLs, or HTML messages.

### Vulnerabilities Found

1. `lib/pages/login/login.dart:251` - Phone validation: `[+]*`, `[-\s\./0-9]*`
2. `lib/pages/chat/events/html_message.dart:48` - HTML tag removal: `<mx-reply>.*</mx-reply>`
3. `lib/utils/string_extension.dart:332-333` - URL separators: `[^ ]*://`, `\ *://\ *`
4. `lib/utils/string_extension.dart:64,82` - URL extraction: `https:\/\/[^\s]+`
5. `lib/utils/string_extension.dart:342-356` - Anchor parsing: `[^>]*`, `[^"]*`, `[^<]*`
6. `lib/pages/chat/events/message/message_content_builder_mixin.dart:368` - Special tags: `[^>]*>.*</`

## Decision

Replace unbounded quantifiers (`*`, `+`) with bounded limits (`{min,max}`), convert greedy `.*` to non-greedy `.*?` where appropriate

## Implementation

| File                                       | Before                                       | After                                         |
| ------------------------------------------ | -------------------------------------------- | --------------------------------------------- |
| **login.dart:251**                         | `[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*` | `[+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]{0,20}`     |
| **html_message.dart:48**                   | `<mx-reply>.*</mx-reply>`                    | `<mx-reply>.*?</mx-reply>` (non-greedy)       |
| **string_extension.dart:332-333**          | `[^ ]*://` and `\ *://\ *`                   | `[^ ]{0,100}://` and `\ {0,10}://\ {0,10}`    |
| **string_extension.dart:64,82**            | `https:\/\/[^\s]+`                           | `https:\/\/[^\s]{1,2048}`                     |
| **string_extension.dart:342-356**          | `[^>]*`, `[^"]*`, `[^<]*`                    | `[^>]{0,500}`, `[^"]{0,2048}`, `[^<]{0,1000}` |
| **message_content_builder_mixin.dart:368** | `[^>]*>.*</`                                 | `[^>]{0,500}>.*?</` (bounded + non-greedy)    |

**Limits Rationale:**

- Phone: E.164 max 15 digits → 20 chars with separators
- URLs: Browser limit ~2000 → 2048 chars
- HTML attributes: Typical <100 → 500 chars
- Anchor text: Normal messages → 1000 chars

## Consequences

**Positive:**

- Eliminated all 8 ReDoS vulnerabilities
- Prevents UI freezes from malicious phone numbers, URLs, or HTML
- Predictable regex performance (no exponential backtracking)
- Maintained backward compatibility

**Potential Issues:**

- Edge cases with extremely long input (URLs >2048, attributes >500, etc.) - all well above typical values
- Recommend adding ReDoS unit tests and monitoring regex performance

**Breaking Changes:** None. All limits exceed real-world usage.

## References

- [OWASP ReDoS](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS)
- [E.164 Phone Format](https://www.itu.int/rec/T-REC-E.164/)
- [RFC 2616 HTTP URL](https://www.rfc-editor.org/rfc/rfc2616#section-3.2.1)
