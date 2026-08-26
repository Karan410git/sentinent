# Sacheta — Project Instructions

## Project

Sacheta is a Flutter mobile diary experience designed as a
mysterious, magical personal journal.

The experience should feel cinematic, tactile and atmospheric,
not like a conventional productivity app.

## Current priority

Polish the closed-diary experience first.

Current stable sequence:

Tap diary
→ diary reacts/floats
→ seal glow
→ gold dust
→ camera push
→ STOP

The diary opening animation is intentionally NOT implemented
until it is redesigned properly.

## Architecture

- Flutter application
- Study scene: `lib/screens/study_scene.dart`
- Closed diary widget: `lib/widgets/sacheta_closed.dart`
- Explorer desk: `lib/widgets/explorer_desk.dart`
- Candle ambience: `lib/widgets/candle_glow.dart`
- Animation-specific widgets/controllers should remain modular.
- Assets live under `assets/master/`.

## Design language

- Dark
- Warm
- Sepia/parchment
- Mystical
- Minimal
- Cinematic
- Physical/tactile
- Subtle rather than flashy

Avoid:
- bright white UI
- generic gradients
- excessive glow
- exaggerated animations
- modern dashboard aesthetics
- slideshow-like transitions

## Animation philosophy

Every animation must have a visual purpose.

Diary:
- subtle floating
- never "breathing" or glitching

Magic:
- gold dust is special and infrequent
- ambient dust must remain separate from magical gold dust

Camera:
- should feel like the viewer is leaning toward the diary,
  not simply zooming an image

Transitions:
- should feel physical
- avoid simple fade-out/fade-in replacements
- do not animate static images just for the sake of motion

## Asset rules

- Never modify an original/master asset destructively.
- Preserve transparent backgrounds where required.
- Do not bake the desk/background into diary assets when
  the desk is rendered separately.
- Never stretch an asset to fit a screen.
- Prefer `BoxFit.contain` when preserving artwork.
- Create mobile-specific assets when the original composition
  does not suit portrait screens.

Current relevant assets:

- `assets/master/sacheta_open_blank.png`
- `assets/master/sacheta_page_blank.png`

These are experimental assets and should not be treated as
the final opening design.

## Coding rules

Before changing code:

1. Inspect the existing implementation.
2. Identify which animation/controller/widget owns the behavior.
3. Make the smallest change necessary.
4. Do not rewrite unrelated code.
5. Preserve working animations.
6. Run `dart format`.
7. Run `flutter analyze`.
8. Test before recommending a commit.

Do not invent file names, controllers, APIs or architecture
without checking the repository first.

## Git workflow

After a stable visual milestone:

- test
- analyze
- review diff
- commit

Do not commit experimental animation changes unless explicitly
asked.

## Agent response style

Be concise.

For implementation tasks:
- explain what will change
- give exact file(s)
- provide complete replacement code when requested
- avoid unnecessary theory
- do not repeat project history already contained here

For debugging:
- identify the likely cause first
- inspect relevant code
- give the smallest reliable fix

Do not make multiple speculative changes at once.

## Important

The developer may reject an animation even if it technically works.

Prioritize perceived quality and consistency with the established
Sacheta visual language over merely making an animation functional.
## Working Method

When asked to implement a change:

1. Read `CLAUDE.md`.
2. Inspect the relevant existing files before editing.
3. Understand the current implementation and dependencies.
4. State the planned change briefly.
5. Implement only the requested change.
6. Do not introduce unrelated refactors.
7. Run formatting and static analysis.
8. Report exactly what changed and any remaining issue.

When the user says "next", continue from the current
project state rather than redesigning previous completed work.

When an animation is visually unsatisfying:
- do not keep stacking tweaks onto it;
- identify whether the underlying approach is wrong;
- propose a better approach before making another large change.

Never assume an asset's dimensions, transparency, positioning,
or contents. Inspect it when necessary.

Prefer existing project components and assets over creating
duplicates.

## Current Phase

Phase 1 — Closed Diary Experience

Goal:
Make the closed diary scene feel alive and cinematic before
implementing the diary-opening interaction.

Completed:
- desk scene
- candle ambience
- diary floating
- seal glow
- gold dust
- camera approach

Next:
- ambient dust
- candle-light refinement
- camera-push refinement
- depth/lighting refinement

Do NOT implement the diary-opening animation yet.