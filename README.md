## Requirements

- Windows
- AutoHotkey **v2.0 or later** (v1 is not supported)

## Download and setup

1. On this GitHub repository, click **Code → Download ZIP**.
2. Extract the entire ZIP before running any files.
3. Keep the repository folder structure intact. In particular, **`Lib` and `Anime Adventures` must be in the same parent folder**.

```text
Pantheon/
├── Lib/
│   └── ...
└── Anime Adventures/
    ├── Dungeons/
    │   ├── Dungeons.ahk
    │   ├── GUI/
    │   └── ...
    └── Progressive/
        ├── Progressive.ahk
        ├── GUI/
        └── ...
```

Keep the files inside each macro folder, including its `GUI` folder. Do not move an individual `.ahk` file out of its folder.

## Run a macro

1. Open Roblox and join Anime Adventures.
2. Open the folder for the macro you want to use.
3. Double-click the **`.ahk` file with the same name as the macro**:

   | Macro | File to run |
   | --- | --- |
   | Dungeons | `Anime Adventures/Dungeons/Dungeons.ahk` |
   | Progressive | `Anime Adventures/Progressive/Progressive.ahk` |

4. Configure your units and the available settings in the macro window.
5. Press **F1** to set up/resize the Roblox window, then **F2** to start.

## Default controls

| Key | Action |
| --- | --- |
| F1 | Set up/resize the Roblox window |
| F2 | Start the macro |
| F3 | Stop the macro |
| F4 | Pause/resume the macro |

These are the default controls for Dungeons and Progressive. Saved custom key bindings may differ.

## Troubleshooting

- **The script will not open:** Make sure AutoHotkey v2 is installed and `.ahk` files open with it.
- **Missing include, image, or file errors:** Extract the whole repository again and check the folder structure above. `Lib` must sit alongside `Anime Adventures`, and each macro must keep its supporting files.
