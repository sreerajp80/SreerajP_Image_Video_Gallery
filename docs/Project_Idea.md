# SreerajP Image Video Gallery

## 1. Overview
An offline-first Android media gallery application designed for viewing, organizing, editing, converting, and managing local images and videos. The application prioritizes high performance, complete user privacy, modern design aesthetics, broad media format support, and non-destructive media operations.

---

## 2. Core Features & Capabilities

### 2.1 Media Viewing & Browsing
- **Chronological Timeline**: Display all device images and videos organized chronologically with sticky date headers (Today, Yesterday, Month, Year).
- **"On This Day" / Flashback Memories Engine**: Automatic banner and carousel at the top of the timeline highlighting photos and videos captured on today's date in past years (1 year ago, 2 years ago, 5 years ago).
- **Dynamic Grid Layout**: Pinch-to-zoom gestures allowing seamless switching between grid densities (1 to 5 columns).
- **Fast Scroll Indexer**: Quick navigation scrubber with date indicator for large media libraries.
- **Media Type Indicators**: Visual badges distinguishing videos (duration badge), GIFs, animated formats, RAW photos, and high-resolution images.
- **Extract Embedded Images from PDFs**: Browse PDF files and extract high-resolution photos or illustrations directly into the gallery.
- **Comprehensive Image Format Support**:
  - **Standard**: JPEG (`.jpg`, `.jpeg`), PNG (`.png`), WEBP (`.webp`), BMP (`.bmp`), WBMP (`.wbmp`), ICO (`.ico`).
  - **Next-Gen & High-Efficiency**: HEIC / HEIF (`.heic`, `.heif`), AVIF (`.avif`).
  - **Vector**: SVG (`.svg`).
  - **Camera RAW & Digital Negatives**: DNG (`.dng`) along with thumbnail and embedded preview extraction for popular RAW formats (`.cr2`, `.nef`, `.arw`).
  - **Animated Media**: Animated GIF (`.gif`), Animated WEBP, and Animated AVIF with playback controls.

### 2.2 Fullscreen Viewer & Video Player
- **Interactive Image Viewer**: High-definition image display supporting smooth pinch-to-zoom, pan, double-tap to zoom, rotation preview, and swipe-to-dismiss.
- **Offline Video Player**:
  - **Container & Codec Support**: MP4 (`.mp4`, `.m4v`), MKV (`.mkv`), WebM (`.webm`), 3GP (`.3gp`), MOV (`.mov`), AVI (`.avi`), TS (`.ts`) decoding H.264, H.265/HEVC, VP8, VP9, AV1 with AAC, MP3, Opus, and FLAC audio.
  - **Advanced Playback Controls**: Play/pause, seek bar, timestamp display, frame-stepping, playback speed adjustment (0.25x to 2x), volume/brightness swipe gestures, and repeat/loop modes.
  - **HDR & Slow-Motion**: Hardware-accelerated HDR10 rendering and smooth high-frame-rate / slow-motion playback (60fps, 120fps, 240fps).
- **Media Information Drawer**: Quick swipe-up drawer displaying essential media details (date, resolution, file size, storage path, codec, bitrate, color space).

### 2.3 Media Intelligence, OCR & Scanner
- **In-Image QR & Barcode Scanner**:
  - Scan and detect QR codes, barcodes, and Wi-Fi codes directly from any image or video frame in the gallery.
  - One-tap actions: copy text, connect to Wi-Fi, view contact vCards, or open detected URLs in the browser.
- **Offline OCR (Optical Character Recognition)**:
  - Extract selectable text from photos (screenshots, receipts, signboards, book pages, code snippets) with copy, search, and share actions.
- **Media Notes & Markdown Attachments**:
  - Attach custom formatted notes, reminders, or markdown descriptions to any photo or video.

### 2.4 Media Metadata & EXIF Management
- **EXIF Inspector**: Detailed view of camera metadata including camera model, lens, exposure time, ISO, aperture, focal length, color space, and GPS coordinates.
- **Metadata Editing**: Local editing of media creation date, time, and custom user descriptions.
- **Privacy EXIF Stripper**: One-tap removal of sensitive EXIF metadata (location/GPS and device information) before sharing or exporting media.

### 2.5 Comprehensive Built-in Image Operations & Editor (Non-destructive)
- **Transformations & Geometry**:
  - **Crop**: Freeform selection and preset aspect ratios (1:1, 4:3, 16:9, 9:16, 3:2, 2:3, golden ratio, custom).
  - **Rotate & Straighten**: 90-degree step rotation, fine-angle straightening slider (-45° to +45°), and horizontal/vertical flipping.
  - **Perspective Correction**: Vertical and horizontal perspective skew adjustment for document and architecture correction.
- **Lighting, Tone & Color Tuning**:
  - **Exposure & Brightness**: Exposure compensation, brightness, and contrast controls.
  - **Dynamic Range**: Highlights, shadows, whites, and blacks recovery.
  - **Color Temperature & Vibrance**: Temperature (warmth/coolness), tint (magenta/green), saturation, and vibrance.
  - **Detail & Texture**: Sharpness enhancement, clarity, vignette (intensity and feathering), fade, and grain effect.
- **Curves & Levels**:
  - Master RGB curve and individual Red, Green, and Blue channel tone curve adjustments with live preview.
- **Artistic Filters & Presets**:
  - Grayscale and high-contrast Black & White.
  - Sepia, vintage, vivid, warm, cool, dramatic, and duo-tone presets.
  - Custom color matrix adjustments.
- **Markup, Annotations & Redaction**:
  - **Freehand Doodle**: Multi-color brush with adjustable stroke width and opacity.
  - **Geometric Shapes**: Rectangles, ellipses/circles, arrows, and lines for callouts.
  - **Text Annotations**: Customizable text overlay with font styling, background badge, alignment, and color.
  - **Privacy Redaction**: Pixelate, Gaussian blur, and solid blackout brush to obscure sensitive data, faces, or documents.
- **Watermarking**:
  - **Text Watermark**: Customizable text, font, size, opacity, rotation, and anchor positioning (corners, center, repeat tile).
  - **Timestamp Watermark**: Automatic date/time stamp overlay with formatting options.
  - **Image / Logo Watermark**: Custom image logo overlay with scale and opacity controls.
- **Privacy EXIF Scrubber**: One-tap stripping of sensitive EXIF metadata (location/GPS, camera serials, device info) before sharing or saving.
- **Non-destructive Versioning & Atomic Saving**: Original files remain untouched; edits are saved as new files or versioned copies via safe temporary staging files.

### 2.6 Format Conversion, Video Tools & Optimization
- **Image Format Conversion**: Convert single or multiple images across formats:
  - JPEG / JPG (with adjustable quality compression slider)
  - PNG (lossless compression)
  - WEBP (lossy and lossless modes)
  - BMP (uncompressed bitmap export)
- **PDF Document Export**: Convert one or multiple selected photos into a single PDF document with custom page layouts.
- **Image Compression & Resizing**:
  - Quality compression slider with real-time estimated file size preview.
  - Dimension scaling (by percentage or target pixel width/height).
- **Video Utilities**:
  - **Video to GIF**: Convert a selected video segment into an optimized animated GIF with custom framerate and resolution.
  - **Video Frame Grabber**: Extract high-resolution still frames from any video at exact timestamps as JPEG or PNG.
  - **Lossless Video Trimming**: Fast stream-copy trimming to create shorter clips without re-encoding quality loss.

### 2.7 Media Format Capability Matrix (Viewing, Editing & Conversion)

| Media Category | Formats & Extensions | Viewing & Playback | In-Place Editing | Supported Conversions & Exports |
| :--- | :--- | :--- | :--- | :--- |
| **Standard Raster Images** | JPEG (`.jpg`, `.jpeg`), PNG (`.png`), WEBP (`.webp`), BMP (`.bmp`), WBMP (`.wbmp`), ICO (`.ico`) | **Full**: Hardware-accelerated decode, pinch-to-zoom, pan, fast thumbnailing | **Full Editor**: Crop, straighten, perspective, color tuning, curves, markup, redaction, watermarks | Convert to JPEG, PNG, WEBP, BMP, or multi-page PDF document; compress / resize |
| **Next-Gen & High-Efficiency** | HEIC / HEIF (`.heic`, `.heif`), AVIF (`.avif`) | **Full**: Fullscreen decode and thumbnail caching | **Convert First**: Converts to standard bitmap/PNG for editing to ensure zero data loss | Export / convert to JPEG, PNG, WEBP, or PDF |
| **Vector Graphics** | SVG (`.svg`) | **Scalable**: Lossless vector rendering with infinite pinch-to-zoom | **View-Only**: Vector paths are preserved without destructive pixel manipulation | Rasterize and export to PNG or PDF |
| **Camera RAW & Digital Negatives** | DNG (`.dng`), Canon (`.cr2`), Nikon (`.nef`), Sony (`.arw`) | **Preview**: Extract and render high-resolution embedded preview and thumbnail | **View-Only**: Original sensor RAW data preserved intact without destructive overwrite | Develop / export preview to JPEG or PNG |
| **Animated Media** | Animated GIF (`.gif`), Animated WEBP, Animated AVIF | **Interactive**: Play, pause, step forward/backward, playback speed control | **Frame Extraction**: Extract single frames or convert sequence | Convert between GIF/WEBP; extract still frames to JPEG/PNG |
| **Video Containers & Codecs** | MP4, MKV, WebM, 3GP, MOV, AVI, TS (H.264, H.265/HEVC, VP8, VP9, AV1) | **Full Player**: Hardware playback, HDR10, seek bar, gesture controls, slow-mo (60-240fps) | **Lossless Trimming**: Fast stream-copy trimming without re-encoding loss | Video to animated GIF; video frame grabber to JPEG/PNG |

### 2.8 Search, Tagging & Smart Duplicate Cleaning
- **Custom Tag Management**: Create, rename, color-code, and delete custom tags locally.
- **Universal Tagging**: Attach multiple tags to individual or batch-selected photos and videos.
- **Full-Text SQLite (FTS5) Search Engine**:
  - Instant multi-criteria search across filenames, custom tags, album names, user markdown notes, EXIF camera models, and locations.
  - Multi-tag queries supporting both `AND` (match all tags) and `OR` (match any tag) filter conditions.
- **Visual Duplicate & Similar Photo Finder (Perceptual Hashing)**:
  - Use SHA-256 content hashing for exact duplicate detection and perceptual hashing (`pHash` / `dHash`) for visually similar photos (burst shots, similar angles).
  - Dedicated cleanup dashboard with side-by-side comparison tool and "Keep Best Photo / Delete Rest" assistant.
- **Tag Badges**: Visual tag chips shown in media information sheets for fast recognition.

### 2.9 Album Management & Organization
- **User-Created Custom Albums (Virtual Albums)**:
  - Create, rename, and delete custom albums without modifying the physical storage folder structure.
  - Add or remove photos and videos to one or multiple custom albums.
  - Custom album cover selection and custom media item ordering.
- **Device Physical Folders**: Automatic grouping by device storage directories (Camera, Screenshots, Downloads, WhatsApp, etc.).
- **Smart Auto-Albums**: Pre-configured dynamic collections:
  - Favorites (starred media)
  - Videos only
  - Animated & GIFs
  - Panoramas & High-Resolution
  - RAW captures
  - Recently Added / Recently Modified
- **Smart Filters**: Quick filter by media format, date range, file size, presence of tags, and presence of location data.

### 2.10 Secure Private Vault (Secret Media)
- **Private Encrypted Storage**: Dedicated secret vault for sensitive photos and videos.
- **Biometric & PIN Lock**: Protected by Android Biometric Prompt (Fingerprint / Face Unlock) or fallback PIN / Passcode.
- **True Hardware-Backed AES-256-GCM Encryption**: Uses the Android Keystore for cryptographic master key generation and AES-256-GCM encryption for all vault files. Vault files are isolated completely from Android MediaStore indexing.
- **Anti-Forensic Secure Shredding (Zero-Fill Overwrite)**: When moving media into the vault or permanently deleting sensitive media, file bytes are overwritten with zeroes/random data before unlinking to prevent file recovery.
- **FLAG_SECURE Native Window Protection**: Prevents screenshots, screen recordings, and blurs app previews in Android's recent apps switcher.
- **Anti-Leak & Privacy Safeguards**:
  - Zero thumbnail caching in public cache directories.
  - Auto-lock on app minimize, backgrounding, or configurable inactivity timeout.
- **Vault File Operations**:
  - Import media from gallery with option for safe deletion/shredding of public original.
  - Full in-vault image viewing and video playback with zero temporary file leaks.
  - Export / restore selected media back to public gallery storage.

### 2.11 Batch Operations, Portability & Offline Sync
- **Multi-Select Batch Actions**:
  - Batch format conversion and compression.
  - Batch watermark application.
  - Batch PDF creation from selected images.
  - Batch tagging and tag removal.
  - Batch assignment to custom albums.
  - Batch move to Secure Private Vault.
  - Batch export / safe deletion with confirmation.
- **Zero-Cloud Peer-to-Peer (P2P) Local Wi-Fi Sync**:
  - Fast direct photo/video and metadata transfer between two devices on the same local Wi-Fi network using local sockets and QR pairing.
- **Encrypted Full Backup & Restore**:
  - Backup all tags, virtual albums, metadata edits, user notes, and favorites into a single password-protected `.gallerybak` archive.

---

## 3. UI/UX Requirements
- **Design System**: Material 3 guidelines with support for dynamic color palette and smooth micro-animations.
- **Themes**: Full support for both Light and Dark themes (with True Black / AMOLED dark mode).
- **Edge-to-Edge Experience**: Modern Android edge-to-edge transparent system bars navigation.
- **Responsive Layout**: Adaptive layouts optimized for portrait, landscape, tablets, and foldable devices.
- **Bi-directional Multi-Script Inclusion (English & Malayalam)**:
  - Full multi-language support for English (`en`) and Malayalam (`ml`).
  - Text direction detection per field (`detectTextDirection`) applied through `AdaptiveDirectionality` so Malayalam and Latin text flow properly.
- **Performance & Smoothness**: 60/120 FPS scrolling, lazy-loaded thumbnails, and asynchronous memory caching for smooth scrolling across thousands of media items.

---

## 4. Technical Architecture & Stack

| Component | Choice | Purpose |
|-----------|--------|---------|
| **Framework** | Flutter 3.44.8 | Cross-platform UI toolkit |
| **Language** | Dart 3.12.2 | Type-safe programming language |
| **State Management** | Riverpod | Predictable, reactive, testable state management |
| **Navigation** | go_router | Declarative routing with deep-link support |
| **Local Database & Search** | sqflite / SQLite FTS5 | Fast local metadata indexing, tag associations, album memberships, favorites, and full-text search |
| **Secure Storage & Crypto** | Android Keystore / AES-256-GCM | Hardware-backed key management and local media encryption |
| **Authentication** | local_auth | Biometric and PIN authentication for the Secure Vault |
| **Media Intelligence & Scanner** | Offline OCR & Barcode Scanning | In-image text recognition and QR/barcode decoding |
| **Duplicate Detection** | SHA-256 & Perceptual Hashing (pHash) | Exact and visually similar duplicate media grouping |
| **Media Storage** | Android Scoped Storage / MediaStore APIs | Standard, granular media access without legacy broad storage permissions |
| **File Safety** | AtomicSaver (Atomic File Operations) | Staging edits to temp files before replacing target to prevent file corruption |
| **Memory Optimization** | system_info2 (RAM-Aware Policy) | Query device RAM dynamically to adapt thumbnail cache and video buffer allocations |
| **Background Processing** | Dart Isolates / Background Tasks | Offloading heavy image decoding, thumbnail generation, filters, and conversions off the main UI thread |

---

## 5. Security, Privacy & Reliability Guarantees
- **No Remote Network**: The app never contacts a remote server. No HTTP client, no cloud backend, no analytics, no telemetry, no update check. `android.permission.INTERNET` is declared for exactly one feature — the device-to-device transfer screen — because Android requires it for *any* socket, including one that only reaches another phone on the same Wi-Fi router. Every connection is refused unless the peer's address is private (`10/8`, `172.16/12`, `192.168/16`, `169.254/16`), the listener binds to the device's own Wi-Fi address rather than `0.0.0.0`, and it runs only while the transfer screen is open.
- **Safe & Non-Destructive**: Never overwrite or delete original media files without explicit user confirmation, atomic file staging safeguards (`AtomicSaver`), and secure shredding options.
- **Hardware-Backed Encrypted Vault Protection**: Private media isolated with AES-256-GCM encryption, biometric authentication, and `FLAG_SECURE` native window protection.
- **Anti-Forensic Media Shredding**: Overwrites media file bytes with zeroes/random data before deletion to prevent unallocated space recovery.
- **Zero Cache Leaks**: Vault media thumbnails and temporary frames are never stored in shared or unencrypted storage.
- **Graceful Error Handling**: Resilient decoders and parsers that handle corrupted media or unsupported formats gracefully with clear fallback icons and non-blocking notifications.
- **Local Data Storage**: All tags, albums, user notes, favorites, and metadata edits remain exclusively on the local device.