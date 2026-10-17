---
trigger: always_on
---

# Centralized Design System and Shared Components Enforcement

## 1. Objective

Establish and enforce a centralized, consistent, reusable, and scalable architecture across the entire project. All shared design values and reusable components must have a single source of truth.

## 2. Centralized Design Tokens

Inspect the existing project structure and consolidate shared values into dedicated files or their existing equivalents:

- `app_colors` — All application colors and semantic color tokens.
- `app_dimensions` — All spacing, padding, margins, sizes, heights, widths, and other dimensional values.
- `app_icons` — All application icons and their semantic mappings.
- `app_strings` — All user-facing text and shared static strings.
- `app_typography` — Font families, sizes, weights, and text styles.
- `app_theme` — Application themes and global visual configuration.
- Appropriate constants, enums, formatters, and validation rules for non-visual application logic.

Adapt filenames and structure to the project's actual technology and conventions. Reuse existing centralized definitions instead of creating duplicates.

## 3. Centralized Architecture and Integration

Centralization must be implemented throughout the actual application, not merely through the creation of files.

- All shared components must consume the centralized design tokens.
- All screens must reuse shared components wherever appropriate.
- Centralized defaults must be consistent, with explicit overrides allowed when genuinely necessary.
- Changes to a shared token must propagate to every dependent component and screen.
- Provide a central export or access point for shared components when appropriate.
- Prevent duplicate definitions and direct values that bypass the established architecture.
- Avoid circular dependencies and preserve clear architectural boundaries.

## 4. Shared Components

Maintain a dedicated location for reusable components, including buttons, input fields, cards, dialogs, menus, dropdowns, notifications, loading indicators, empty states, error states, and other repeated UI elements discovered during the audit.

Components must expose appropriate configurable properties, such as size, color, variant, icon, icon position, loading state, and disabled state.

Use centralized defaults while allowing controlled customization without duplicating component implementations.

## 5. Language and Naming Standards

- Use English for filenames, class names, variables, functions, enums, and other code identifiers.
- Keep user-facing text in centralized localization resources.
- Support Arabic and English using the localization mechanism appropriate to the project.
- Do not hardcode translated text directly into screens or reusable components.
- Replace magic strings in business logic with appropriate enums, constants, or typed representations.
- Preserve correct Arabic right-to-left and English left-to-right behavior.

## 6. Full-Project Audit

Audit the entire project, including screens, widgets, components, controllers, services, models, repositories, utilities, tests, configuration, and documentation.

Identify duplicated values, inconsistent components, hardcoded strings, direct color or dimension values, duplicated formatting logic, and any other architectural inconsistencies.

Do not blindly centralize every literal. Distinguish legitimate local values from genuine violations and centralize only what benefits consistency, reuse, or maintainability.

## 7. Permanent Project Rules

Inspect the existing Google Antigravity project rules and update the appropriate rule files using the supported project rule mechanism.

Ensure these standards persist across future tasks:
- **Mandatory Search First**: Before introducing any new color, dimension, icon, user-facing string, typography style, or UI component, the agent MUST search existing definitions in:
  - `lib/core/constants/app_colors.dart`
  - `lib/core/constants/app_dimensions.dart`
  - `lib/core/constants/app_icons.dart`
  - `lib/core/constants/app_strings.dart`
  - `lib/core/constants/app_typography.dart`
  - `lib/core/widgets/widgets.dart`
- **Zero Raw Color Hexes**: Direct `Color(0x...)` instantiation in `lib/views/` is strictly prohibited. All colors must originate from `AppColors`.
- **Zero Hardcoded Strings**: All user-facing Arabic and English strings must reside in `AppStrings`.
- **Reusable Component Reuse**: Screens must consume shared components (`CustomButton`, `CustomTextField`, `CustomDialog`, `CustomDropdown`, `CustomModalSheet`, `OneUiCard`, `OneUiAppBar`, `EmptyStateWidget`, `AppFilterChip`, `AppLoadingIndicator`, `AppSnackBar`) rather than implementing ad-hoc inline variants.
- **Automated Verification**: All changes must pass `flutter analyze` and `flutter test` (including `test/design_system_enforcement_test.dart`).

Do not merely describe the rules in a response. Write them into the actual project configuration.

## 8. Automated Enforcement

Add or update appropriate automated checks, such as linters, static-analysis rules, tests, or validation scripts, to detect preventable violations.

Check for duplicated design tokens, unauthorized hardcoded UI strings, direct color and dimension values where prohibited, and duplicate shared component implementations.

Use checks compatible with the existing technology and avoid introducing unnecessary dependencies.

## 9. Implementation and Verification

First inspect the current architecture and produce a concise implementation plan. Then implement the changes across the relevant files.

Preserve existing functionality, approved visual design, and user-facing behavior unless a change is explicitly required.

Do not delete existing definitions until their usage and dependencies have been verified. Update all affected references and remove obsolete definitions only when safe.

Run the available formatter, static analysis, tests, and relevant build checks. Resolve regressions caused by the changes.

## 10. Completion Report

Provide a concise report covering:

- Files created or modified.
- Centralized values and shared components integrated.
- Violations identified and resolved.
- Permanent rules and automated checks added or updated.
- Verification commands and their actual results.
- Remaining violations, limitations, or unresolved issues.

Do not claim completion without evidence.

## Mandatory Acceptance Criteria

Creating centralized files alone is not sufficient. The actual application must use them.

The task is complete only when the centralized architecture has been integrated across the applicable project scope, existing duplication has been addressed, permanent rules have been written, and available verification checks have been executed.

Begin by inspecting the entire project and its existing rules. Implement the changes incrementally, verify each stage, and continue beyond planning until the applicable work is completed.