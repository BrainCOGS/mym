# mym — macOS Apple Silicon (arm64) Installation Guide

This branch contains modifications required to build and run mym on **macOS with Apple Silicon (M1/M2/M3/M4)** against a **MariaDB server**.

## What was changed from upstream and why

| Problem | Root cause | Fix |
|---|---|---|
| Linker undefined symbols (`mexCreateMexFunction` etc.) | MATLAB R2023b applies a C++ MEX export map to this C-style MEX file | Custom `mex_compilation/clang++_maca64_mym.xml` with `LINKEXPORTCPP=""` |
| `MACOSX_DEPLOYMENT_TARGET` mismatch | Homebrew MariaDB connector built for macOS 15+, MATLAB defaults to 11.0 | `MACOSX_DEPLOYMENT_TARGET=15.0` set in custom XML |
| "Malformed packet" on connect | Bundled MySQL 8.4 client is protocol-incompatible with MariaDB 10.6+ servers | Recompile against Homebrew `mariadb-connector-c` instead of bundled MySQL client |
| `my_bool` compile error | Type removed in MySQL 8.0+ | Changed to `bool` |
| `SSL_MODE_*` / `MYSQL_OPT_SSL_MODE` compile errors | MySQL-only constants absent from MariaDB connector headers | Replaced with `MYSQL_OPT_SSL_ENFORCE` (MariaDB equivalent) |
| Expired server SSL certificate | Server cert expired but SSL still needed | Added `MYSQL_OPT_SSL_VERIFY_SERVER_CERT=false` — uses SSL without verifying the cert |

---

## System Requirements

- macOS 15 (Sequoia) or later, Apple Silicon Mac (arm64)
- **Xcode** (full app from the App Store, not just Command Line Tools)
- **MATLAB R2023b**
- **Homebrew**

---

## Installation

### 1. Install Xcode

Install Xcode from the Mac App Store, then open it once to accept the license agreement. Alternatively accept via terminal:

```bash
sudo xcodebuild -license accept
```

### 2. Install Homebrew

If not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the instructions at the end of the Homebrew installer to add it to your PATH.

### 3. Install MariaDB Connector/C

```bash
brew install mariadb-connector-c
```

### 4. Clone this repository

```bash
git clone https://github.com/braincogs/mym.git
cd mym
```

### 5. Compile the MEX file

Open MATLAB R2023b, set the working directory to the repo root, then run:

```matlab
cd('/path/to/mym')
run mex_compilation/compile_mexmaca64.m
```

This will build `mym.mexmaca64` and copy it along with `libmariadb.3.dylib` into `distribution/mexmaca64/`.

### 6. Add to MATLAB path

Add the distribution folder to your MATLAB path. The `mym.m` help file in the repo root must **not** shadow the compiled MEX — either delete it or ensure `distribution/mexmaca64/` comes first on the path.

```matlab
addpath('/path/to/mym/distribution/mexmaca64')
savepath
```

To make this permanent across MATLAB sessions, add the `addpath` line to your MATLAB startup file at `~/Documents/MATLAB/startup.m`.

---

## Usage

### Connect (with SSL, skipping expired cert verification)

```matlab
mym('open', 'your-server.example.com', 'username', 'password', 'true')
```

### Connect (without SSL)

```matlab
mym('open', 'your-server.example.com', 'username', 'password')
```

### Run a query

```matlab
result = mym('SELECT * FROM my_table LIMIT 10')
```

### Close connection

```matlab
mym('close')
```

---

## Notes

- The `'true'` / `'false'` fifth argument to `mym('open', ...)` controls SSL enforcement. SSL certificate verification is always disabled (to handle expired server certs) — SSL encryption itself is still active when `'true'` is passed.
- This build requires the Princeton VPN (or equivalent network access) to reach internal database servers such as `datajoint00.pni.princeton.edu`.
- The compiled `mym.mexmaca64` and `libmariadb.3.dylib` in `distribution/mexmaca64/` are committed to this branch so recompilation is only needed if you modify `src/mym.cpp`.
