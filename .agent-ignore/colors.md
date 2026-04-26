AGENT IGNORE THIS FILE

## Windows Terminal

```json
"profiles":
{
  "defaults":
  {
    "bellStyle": "none",
    "colorScheme": "paper2",
    "cursorShape": "filledBox",
    "font":
    {
      "face": "JetBrainsMonoNL Nerd Font Mono",
      // "face": "Cascadia Mono",
      "size": 13
    }
  },

  (...)

}
```

```json
"schemes": [
  {
    "name": "paper1",
    "cursorColor": "#000000",
    "selectionBackground": "#9FC5E8",
    "background": "#F2EEDE",
    "foreground": "#000000",
    "black": "#000000",
    "blue": "#2F5F8F",
    "brightBlack": "#303030",
    "brightBlue": "#3F6F9F",
    "brightCyan": "#3F7F78",
    "brightGreen": "#4F6F3A",
    "brightPurple": "#6A4F8A",
    "brightRed": "#9F3A30",
    "brightWhite": "#FFFFFF",
    "brightYellow": "#FFD400",
    "cyan": "#2F6F6A",
    "green": "#3F5F2A",
    "purple": "#5A3F78",
    "red": "#7F1D1D",
    "white": "#F2EEDE",
    "yellow": "#7A3F00"
  },
  {
    "name": "paper2",
    "cursorColor": "#000000",
    "selectionBackground": "#9FC5E8",
    "background": "#F2EEDE",
    "foreground": "#000000",
    "black": "#000000",
    "blue": "#1E6FCC",
    "brightBlack": "#555555",
    "brightBlue": "#1E6FCC",
    "brightCyan": "#158C86",
    "brightGreen": "#216609",
    "brightPurple": "#5C21A5",
    "brightRed": "#CC3E28",
    "brightWhite": "#AAAAAA",
    "brightYellow": "#FFD400",
    "cyan": "#158C86",
    "green": "#216609",
    "purple": "#5C21A5",
    "red": "#CC3E28",
    "white": "#AAAAAA",
    "yellow": "#B58900"
  },
],
```

## Color Palette

- Use the repo-wide high-contrast Paper light palette for editor, terminal, and Arch/Sway desktop theming.
- Core colors:
  - paper background: `#f2eede`
  - foreground text: `#000000`
  - muted surface: `#e8e1cc`
  - stronger surface: `#c8c3b3`
  - active surface: `#b8ad94`
  - selection blue: `#b7c9dc`
  - primary blue: `#2f5f8f`
  - bright blue: `#3f6f9f`
  - green: `#3f5f2a`
  - warning: `#7a3f00`
  - error: `#7f1d1d`
  - urgent red: `#9f3a30`
  - search yellow: `#ffd400`
- Use `#f2eede` for main backgrounds and lock screens.
- Use `#000000` for primary readable text.
- Use `#e8e1cc`, `#c8c3b3`, and `#b8ad94` for progressively stronger neutral UI surfaces such as bars, inactive frames, current-line markers, borders, and subtle panels.
- Use `#b7c9dc` for selections and active-but-not-urgent UI surfaces.
- Use `#2f5f8f` and `#3f6f9f` for blue accents, comments, matches, focused elements, and other readable non-error emphasis.
- Use `#3f5f2a` for green success/info accents.
- Use `#ffd400` for search highlights.
- Use `#7a3f00` for warnings.
- Use `#7f1d1d` and `#9f3a30` only for errors, urgent states, destructive states, and delete/diff-delete emphasis.
- Keep large UI surfaces calmer than code text.
- Use stronger colors for selections, current-location cues, diagnostics, diffs, and urgent states.
- Do not reintroduce dark/light alternate theme blocks unless explicitly requested.
