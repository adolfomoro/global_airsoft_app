# UI/UX Research Notes

Research date: 2026-04-26

These notes collect reusable UX decisions for beginner-friendly mobile screens in this app.

## Sources

- Baymard, inline form validation: https://baymard.com/blog/inline-form-validation
- Baymard, mobile form labels: https://baymard.com/blog/mobile-forms-avoid-inline-labels
- W3C WAI, WCAG 3.3.2 labels or instructions: https://www.w3.org/WAI/WCAG21/Understanding/labels-or-instructions
- W3C WAI, WCAG 3.3.1 error identification: https://www.w3.org/WAI/WCAG21/Understanding/error-identification.html
- GOV.UK Design System, error messages: https://design-system.service.gov.uk/components/error-message/
- Material Design, text fields: https://m1.material.io/components/text-fields.html
- Nielsen Norman Group, usability heuristics summary: https://www.nngroup.com/articles/ten-usability-heuristics/
- Nielsen Norman Group, tutorials and contextual tips: https://media.nngroup.com/media/reports/free/Tablet_Website_and_Application_UX.pdf

## Principles To Reuse

- Keep instructions visible and near the field. Do not rely on placeholder text alone for rules or context.
- Avoid premature validation. Let users type first, then validate on blur, on submit, or after a clear interaction.
- Remove server or field errors as soon as users start correcting the field.
- Prefer error prevention over error recovery: good defaults, clear examples, and constraints reduce frustration.
- Keep copy short, familiar, and action-oriented. Beginner users should not need product jargon to complete a task.
- Preserve user input after errors. Do not make users re-enter information.
- Make the next action obvious and reachable, especially on mobile when the keyboard is open.
- Use visual hierarchy to show what matters first, but avoid decorative elements that add weight without helping the task.

## Applied To Google Account Setup

- Converted the page from a plain form into a guided review flow.
- Added a Google connection status cue to reassure users why the screen appears.
- Grouped profile photo and username into clear visual sections.
- Added visible username rules and a positive ready state.
- Moved username feedback into a reusable field with debounced availability checks and suggestion chips.
- Kept validation calm: no premature inline errors before the first submit attempt.
- Show backend username errors directly on the username field and clear them as the user edits.
- Kept the primary action available while the keyboard is open.
