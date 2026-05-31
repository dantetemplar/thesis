# Thesis (Typst)

Bachelor thesis source in [Typst](https://typst.app/).

The document template (layout, title page conventions, typography) belongs to **Innopolis University**.

## Prerequisites

- [Typst](https://github.com/typst/typst/releases) on your `PATH` (`typst --version`).
- [uv](https://docs.astral.sh/uv/) for `overlay-title-signatures.py` (`uv --version`).
- **Times New Roman** installed system-wide (body text and title export from LibreOffice).
- **Git LFS** if you clone PDFs tracked by LFS (`git lfs install` once per machine).

## Getting started

To edit the template, edit `thesis.typ`, to edit content, edit `sections/` and `figures/`. To watch for changes and rebuild `thesis.pdf` automatically:

```bash
typst watch thesis.typ
```

To one-time compile the thesis, run:

```bash
typst compile thesis.typ
```

To add signatures on title, see [Signatures](#signatures) section.


## Title page (`title.pdf`)

Prepare your title page by yourself and export it to `title.pdf`, it will be embedded in the main document. For example, I have used provided [Title Page 2026.docx](Title%20Page%202026.docx).

The annotation uses the same pattern: edit [Annotation Title Page 2026.docx](Annotation%20Title%20Page%202026.docx) or provide your own, export to `annotation-title.pdf`, then compile `annotation.typ`.

## Signatures

Signatures are not in Typst. Add `my-signature.png` and `consultant-signature.png` to the repo root (gitignored), compile, then stamp page 1:

```bash
typst compile thesis.typ && typst compile annotation.typ
uv run overlay-title-signatures.py   # → thesis (signature).pdf, annotation (signature).pdf
```

Run the overlay again after each compile. One file: `uv run overlay-title-signatures.py thesis` or `annotation`. Edit coordinates in `overlay-title-signatures.py`.

## IDE: Tinymist

For editing in **VS Code** or **Cursor**, install the **[Tinymist](https://github.com/Myriad-Dreamin/tinymist)** extension. It provides syntax highlighting, jump-to-definition, preview, and can run the compiler using the same root as your project.

Open `thesis.typ` in the IDE and run **Typst: Pin the Main File to the Currently Open Document** (Ctrl+Shift+P).

## Repository layout

| Path | Role |
|------|------|
| `thesis.typ` | Main entry |
| `thesis.pdf` | Compiled thesis |
| `thesis (signature).pdf` | Compiled thesis with signatures |
| `Title Page 2026.docx` | Thesis title page source (edit here) |
| `title.pdf` | Exported thesis title page |
| `annotation.typ` | Annotation entry |
| `annotation.pdf` | Compiled annotation |
| `annotation (signature).pdf` | Compiled annotation with signatures |
| `Annotation Title Page 2026.docx` | Annotation title page source |
| `annotation-title.pdf` | Exported annotation title page |
| `template.typ` | Global styles, headers, bibliography |
| `overlay-title-signatures.py` | Post-process: stamp signatures on page 1 |
| `sections/` | Body text: see tree below |
| `figures/` | Raster/SVG assets referenced from chapters |
| `ref.bib`, `ieee.csl` | Bibliography |

`sections/` tree:

```text
sections/
├── abstract.typ
├── bibliography.typ
├── contents.typ
├── chapters/
│   ├── 1.typ
│   ├── 2.typ
│   ├── 3.typ
│   ├── 4.typ
│   └── 5.typ
└── annotation/            # included from annotation.typ
    ├── contents.typ
    ├── foreword.typ
    ├── main-part.typ
    ├── conclusion.typ
    └── references.typ
```
