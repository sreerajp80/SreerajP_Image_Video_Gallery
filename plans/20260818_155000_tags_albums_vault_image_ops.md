# Tags, Custom Albums, Secure Vault, and Comprehensive Image Operations Plan

**Status:** Completed

## 1. Overview
Update `docs/Project_Idea.md` to incorporate detailed specifications for:
1. Flexible tagging system for both photos and videos.
2. User-created custom albums (virtual albums) alongside folder-based albums.
3. Secure private vault with local encryption (PIN/biometrics) for private media.
4. Maximum image operations for all operable image formats (transforms, color tuning, curves, markup/redaction, watermarking, batch processing).

## 2. Files to Change
- `docs/Project_Idea.md`

## 3. The Issue
`docs/Project_Idea.md` needs deeper coverage and explicit requirements for:
- Tagging support across all photos and videos with search/filtering capabilities.
- User-created custom albums with cover selection and ordering.
- A secure private vault with hardware-backed encryption, authentication, and leak-prevention mechanisms.
- Comprehensive image editing and enhancement operations for operable image formats.

## 4. Proposed Fix
Update `docs/Project_Idea.md` with:
- **2.4 Comprehensive Image Operations & Editor**: Expand with transformations (crop, fine straighten, flip, perspective), lighting/color tuning (exposure, highlights, shadows, warmth, saturation, curves), artistic filters, annotations/markup/doodle, sensitive area blurring/pixelation/redaction, watermarks, metadata scrubbing, and format conversion/compression.
- **2.7 Tagging & Organization**: Detail custom tag management for both photos and videos, multi-tag assignments, color badges, and multi-tag filtering/search.
- **2.8 Album Management**: Detail both physical device albums and user-created virtual albums (create, rename, delete, reorder, custom cover selection).
- **2.9 Secure Private Vault**: Detail offline AES-256 encrypted hidden vault, PIN/Biometric lock, zero public caching, screen capture prevention (`FLAG_SECURE`), and safe import/export.
- Update Capability Matrix and Architecture/Security sections to reflect vault encryption and expanded operation capabilities.

## 5. Verification
- Verify that `docs/Project_Idea.md` is well-structured, follows simple English, and strictly complies with all project rules (offline-only, safe non-destructive, relative paths only).
