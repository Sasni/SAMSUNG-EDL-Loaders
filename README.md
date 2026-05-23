# Samsung Qualcomm EDL Firehose Loaders

[![Telegram](https://img.shields.io/badge/Telegram-@Alephgsm-26A5E4?style=flat&logo=telegram&logoColor=white)](https://t.me/Alephgsm)
[![Website](https://img.shields.io/badge/Website-alephgsm.com-blue?style=flat)](https://alephgsm.com)
[![GitHub](https://img.shields.io/badge/GitHub-Alephgsm-181717?style=flat&logo=github)](https://github.com/Alephgsm)

A curated collection of **Samsung Qualcomm Firehose / EDL loaders** for servicing Samsung devices in **Emergency Download Mode (EDL)**.

Maintained by **[Alephgsm](https://alephgsm.com)** — GSM Alphabet | Mobile Security Researchers.

---

## About

This repository contains firehose programmer binaries (`.elf`, `.mbn`), loader bit packages (`.tar`), and firmware bundles (`.zip`, `.tgz`, `.rar`, `.7z`) for Samsung devices powered by Qualcomm chipsets.

These loaders are used with EDL tools such as [SharpEDLClient](https://alephgsm.com/2024/11/21/sharpedlclient/) to:

- Flash firmware partitions in EDL mode
- Unbrick / debrick Qualcomm Samsung devices
- Read and write device storage via Firehose protocol
- Service devices when standard Download Mode is unavailable

> **Note:** Each device variant (model number) has its own folder. Regional variants like `SM-G973U` and `SM-G973W` are kept separate even if they belong to the same product line.

---

## Device Support

**90+ Samsung model numbers** are supported across Galaxy S, Note, A, M, Z (Fold/Flip), and Tab series.

See the full list: **[DEVICE_SUPPORT.md](DEVICE_SUPPORT.md)**

---

## Repository Structure

```
SAMSUNG-EDL-Loaders/
├── Samsung Galaxy A52 5G (SM-A526U)/
│   ├── firehose/              ← .elf / .mbn firehose programmers
│   ├── loader_bit/            ← *_LOADER_BIT*.tar packages
│   └── firmware_packages/     ← .zip / .tgz / .rar / .7z bundles
├── Samsung Galaxy S10 (SM-G973U)/
│   └── firehose/
├── Generic Samsung Firehose/  ← Snapdragon platform loaders (smd460, smd855, etc.)
├── scripts/                   ← Organization & maintenance tools
├── DEVICE_SUPPORT.md
└── README.md
```

### Folder Naming Convention

```
Samsung Galaxy {Device Name} (SM-{ModelNumber})
```

Examples:
- `Samsung Galaxy S10 (SM-G973U)`
- `Samsung Galaxy S10 Plus (SM-G975U)`
- `Samsung Galaxy A52 5G (SM-A526U)`
- `Samsung Galaxy Z Fold 3 (SM-F926B)`

### File Types

| Category | Extensions | Description |
|----------|-----------|-------------|
| **Firehose** | `.elf`, `.mbn` | Direct firehose programmer binaries |
| **Loader BIT** | `.tar` | Packaged loader archives by bit revision |
| **Firmware Packages** | `.zip`, `.tgz`, `.rar`, `.7z` | Version-specific loader/firmware bundles |

Binary version tags in filenames:
- `U5`, `U9`, `U10` — software update / binary version
- `BIT5`, `BIT6`, `LOADER_BIT-A` — loader bit revision
- `_B8` — binary variant

---

## How to Use

1. Put your Samsung device into **EDL Mode** (Qualcomm 9008).
2. Find your exact **model number** (e.g. `SM-A526U`) on the device label or via `adb shell getprop ro.product.model`.
3. Navigate to the matching folder in this repository.
4. Select the appropriate firehose loader from the `firehose/` subfolder (or try `loader_bit/` / `firmware_packages/` if needed).
5. Load the firehose programmer in your EDL client and proceed with flashing or servicing.

For automated loader detection and advanced EDL features, check out **SharpEDLClient**:

- [SharpEDLClient on alephgsm.com](https://alephgsm.com/2024/11/21/sharpedlclient/)

---

## Generic Firehose Loaders

The [`Generic Samsung Firehose/`](Generic%20Samsung%20Firehose/) folder contains Snapdragon platform-based firehose programmers that may work across multiple devices sharing the same chipset:

| File | Platform |
|------|----------|
| `prog_firehose_ddr_smd460.elf` | Snapdragon 460 |
| `prog_firehose_ddr_smd680.elf` | Snapdragon 680 |
| `prog_firehose_ddr_smd720g.elf` | Snapdragon 720G |
| `prog_firehose_ddr_smd778.elf` | Snapdragon 778G |
| `prog_firehose_ddr_smd855.elf` | Snapdragon 855 |

---

## Related Projects

| Project | Description |
|---------|-------------|
| [SharpEDLClient](https://alephgsm.com/2024/11/21/sharpedlclient/) | Qualcomm EDL Mode client (C# / VB.NET source) |
| [Freya](https://github.com/Alephgsm/Freya) | Samsung open-source flash tool |
| [SharpOdinClient](https://github.com/Alephgsm/SharpOdinClient) | Samsung Download Mode protocol library |
| [SAM-unbrick-debrick](https://github.com/Alephgsm/SAM-unbrick-debrick) | Samsung Qualcomm unbrick / debrick scripts |

---

## Connect With Us

| Channel | Link |
|---------|------|
| **Website** | [alephgsm.com](https://alephgsm.com) |
| **Telegram** | [@Alephgsm](https://t.me/Alephgsm) |
| **GitHub** | [github.com/Alephgsm](https://github.com/Alephgsm) |
| **Contact** | [@GsmCoder](https://t.me/GsmCoder) on Telegram |

---

## Contributing

Found a missing loader or newer binary version? Open an [Issue](https://github.com/Alephgsm/SAMSUNG-EDL-Loaders/issues) or contact us on Telegram.

To reorganize or add new loaders locally, use the maintenance script:

```powershell
.\scripts\organize-loaders.ps1
```

---

## Disclaimer

These loaders are provided for **research, education, and legitimate device servicing** purposes only. Use at your own risk. Alephgsm is not responsible for any damage caused by improper use of these files.

---

<p align="center">
  <b>Alephgsm</b> — GSM Alphabet | Mobile Security Researchers<br>
  <a href="https://alephgsm.com">alephgsm.com</a> · <a href="https://t.me/Alephgsm">@Alephgsm</a>
</p>
