# 🎨 ArtCraft (`art`)

Open-source creative apps built by the ArtCraft team with AI, written from scratch in Rust.

## Contents

- [Shared ArtCraft module behavior](#shared-artcraft-module-behavior)
- [CADCraft](#cadcraft-cadcraft)
- [Craft Anything](#craft-anything-craft-anything)
- [DeckCraft](#deckcraft-deckcraft)
- [DesignCraft](#designcraft-designcraft)
- [EffectCraft](#effectcraft-effectcraft)
- [FigCraft](#figcraft-figcraft)
- [FilmCraft](#filmcraft-filmcraft)
- [GridCraft](#gridcraft-gridcraft)
- [LightCraft](#lightcraft-lightcraft)
- [MaterialCraft](#materialcraft-materialcraft)
- [PdfCraft](#pdfcraft-pdfcraft)
- [PhotoCraft](#photocraft-photocraft)
- [SoundCraft](#soundcraft-soundcraft)
- [TextureCraft](#texturecraft-texturecraft)
- [VectorCraft](#vectorcraft-vectorcraft)
- [WordCraft](#wordcraft-wordcraft)

---

## Shared ArtCraft module behavior

The modules in this category install the apps listed at https://getartcraft.com/apps. The ArtCraft team develops
them with AI, and every app is pre-1.0: the vendor labels each one **Early alpha** or **In development**, as shown in
its section below. Expect missing features, breaking changes, and frequent releases.

### Installation Method

**GitHub latest release (.deb)**

Each module finds the `<module>-<version>-linux-x86_64.deb` asset in the latest release of the `storytold/<module>`
GitHub repository, verifies it against the SHA-256 digest that GitHub publishes, and installs it using APT. Only
`x86_64` (`amd64`) is supported.

Each package installs two commands into `/usr/bin`: the desktop app `<module>` and its command-line companion
`<module>-cli`. The package scripts only refresh the desktop, MIME, and icon caches; they add no APT repository or
system service.

### Desktop Integration

- The `.deb` installs the desktop entry (`/usr/share/applications/ai.storyteller.<module>.desktop`), icons, and MIME
  types; the modules do not create their own.

### Updates

`mp outdated` compares the installed version with the latest GitHub release tag, and `mp upgrade` installs the newer
`.deb`. The apps also include an in-app self-update feature. Prefer `mp upgrade`, so the version recorded in the
module registry stays in sync with the installed package.

The ArtCraft Launcher (`storytold/craft-launcher`) is intentionally not provided as a module, because it installs and
updates the apps itself, outside Mint Provisioner.

### Removal

`mp remove` removes the package. `mp purge` also deletes `<module>` under `~/.config`, `~/.local`, `~/.local/share`,
`~/.local/state`, and `~/.cache`, plus `~/.<module>`. The apps do not document their user-data locations, so other files
may remain after a purge.

---

## CADCraft (`cadcraft`)

CADCraft is a computer-aided design and drafting application for 2D drawings and 3D models.

**Maturity:** In development

### Commands

- `cadcraft`: launches CADCraft.
- `cadcraft-cli`: CADCraft command-line companion.

### Official Website

https://getartcraft.com/apps/cadcraft

---

## Craft Anything (`craft-anything`)

Craft Anything is a software explorer that inspects how existing programs work, including binary analysis and decompilation, as a starting point for building your own version.

**Maturity:** Early alpha

### Commands

- `craft-anything`: launches Craft Anything.
- `craft-anything-cli`: Craft Anything command-line companion.

### Official Website

https://getartcraft.com/apps/craft-anything

---

## DeckCraft (`deckcraft`)

DeckCraft is a presentation editor for building and delivering dynamic slide shows.

**Maturity:** In development

### Commands

- `deckcraft`: launches DeckCraft.
- `deckcraft-cli`: DeckCraft command-line companion.

### Official Website

https://getartcraft.com/apps/deckcraft

---

## DesignCraft (`designcraft`)

DesignCraft is a page layout and desktop publishing application.

**Maturity:** In development

### Commands

- `designcraft`: launches DesignCraft.
- `designcraft-cli`: DesignCraft command-line companion.

### Official Website

https://getartcraft.com/apps/designcraft

---

## EffectCraft (`effectcraft`)

EffectCraft is a motion graphics and visual effects compositor.

**Maturity:** In development

### Commands

- `effectcraft`: launches EffectCraft.
- `effectcraft-cli`: EffectCraft command-line companion.

### Official Website

https://getartcraft.com/apps/effectcraft

---

## FigCraft (`figcraft`)

FigCraft is an interface design and prototyping tool.

**Maturity:** Early alpha

### Commands

- `figcraft`: launches FigCraft.
- `figcraft-cli`: FigCraft command-line companion.

### Official Website

https://getartcraft.com/apps/figcraft

---

## FilmCraft (`filmcraft`)

FilmCraft is a non-linear video editor rebuilt from scratch in Rust.

**Maturity:** In development

### Commands

- `filmcraft`: launches FilmCraft.
- `filmcraft-cli`: FilmCraft command-line companion.

### Official Website

https://getartcraft.com/apps/filmcraft

---

## GridCraft (`gridcraft`)

GridCraft is a spreadsheet application for data entry and analysis.

**Maturity:** In development

### Commands

- `gridcraft`: launches GridCraft.
- `gridcraft-cli`: GridCraft command-line companion.

### Official Website

https://getartcraft.com/apps/gridcraft

---

## LightCraft (`lightcraft`)

LightCraft is a local photo library manager and raw photo developer.

**Maturity:** In development

### Commands

- `lightcraft`: launches LightCraft.
- `lightcraft-cli`: LightCraft command-line companion.

### Official Website

https://getartcraft.com/apps/lightcraft

---

## MaterialCraft (`materialcraft`)

MaterialCraft is a node-based designer for procedural PBR materials.

**Maturity:** In development

### Commands

- `materialcraft`: launches MaterialCraft.
- `materialcraft-cli`: MaterialCraft command-line companion.

### Official Website

https://getartcraft.com/apps/materialcraft

---

## PdfCraft (`pdfcraft`)

PdfCraft is a PDF workbench for reading, organizing, combining, splitting, and securing PDF files.

**Maturity:** Early alpha

### Commands

- `pdfcraft`: launches PdfCraft.
- `pdfcraft-cli`: PdfCraft command-line companion.

### Official Website

https://getartcraft.com/apps/pdfcraft

---

## PhotoCraft (`photocraft`)

PhotoCraft is a raster image editor with a layout and tools familiar to users of established image editors.

**Maturity:** Early alpha

### Commands

- `photocraft`: launches PhotoCraft.
- `photocraft-cli`: PhotoCraft command-line companion.

### Official Website

https://getartcraft.com/apps/photocraft

---

## SoundCraft (`soundcraft`)

SoundCraft is a digital audio workstation for recording, editing, and mixing audio and MIDI.

**Maturity:** In development

### Commands

- `soundcraft`: launches SoundCraft.
- `soundcraft-cli`: SoundCraft command-line companion.

### Official Website

https://getartcraft.com/apps/soundcraft

---

## TextureCraft (`texturecraft`)

TextureCraft is a 3D texture painting application.

**Maturity:** In development

### Commands

- `texturecraft`: launches TextureCraft.
- `texturecraft-cli`: TextureCraft command-line companion.

### Official Website

https://getartcraft.com/apps/texturecraft

---

## VectorCraft (`vectorcraft`)

VectorCraft is a vector illustration application.

**Maturity:** In development

### Commands

- `vectorcraft`: launches VectorCraft.
- `vectorcraft-cli`: VectorCraft command-line companion.

### Official Website

https://getartcraft.com/apps/vectorcraft

---

## WordCraft (`wordcraft`)

WordCraft is a word processor.

**Maturity:** In development

### Commands

- `wordcraft`: launches WordCraft.
- `wordcraft-cli`: WordCraft command-line companion.

### Official Website

https://getartcraft.com/apps/wordcraft
