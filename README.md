<p align="center"><b>📱🗑️ iDevice Apps</b></p>
<h1 align="center">iDevice Apps</h1>
<p align="center">Elimina apps de tu iPhone o iPad <b>en masa</b> desde tu Mac — sin jailbreak.<br>
<a href="https://github.com/remasterzerouvm/idevice-apps/releases/latest"><b>⬇️ Descargar la última versión</b></a> · <a href="#english">English</a></p>

<p align="center">
<img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14+">
<img src="https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-blue" alt="Universal">
<img src="https://img.shields.io/badge/SwiftUI-native-orange?logo=swift" alt="SwiftUI">
<img src="https://img.shields.io/badge/license-MIT-green" alt="MIT">
</p>

---

## 🇪🇸 Español

**iDevice Apps** es una pequeña app nativa para macOS (SwiftUI) que te permite ver todas las apps instaladas en tu iPhone o iPad y desinstalar muchas a la vez con unos cuantos clics. Usa las herramientas libres de [libimobiledevice](https://libimobiledevice.org). No necesitas jailbreak.

### ✨ Funciones

- 🔌 **Estado de emparejamiento**: indica si hay un dispositivo conectado, sin emparejar o emparejado (se actualiza solo).
- 📋 **Lista de apps** de usuario, del sistema o todas, con icono, versión y tamaño.
- ☑️ **Selección múltiple** con casillas y desinstalación masiva.
- 📊 **Gráfica de almacenamiento** usado / libre, mostrando cuánto espacio liberarías con la selección actual.
- 🌐 Interfaz en **español e inglés** (sigue el idioma de macOS).

### 🧰 Requisitos

- macOS 14 (Sonoma) o posterior — Apple Silicon o Intel (binario universal).
- [Homebrew](https://brew.sh) con los paquetes `libimobiledevice` e `ideviceinstaller`. **Si faltan, la app te ofrece instalarlos** (y Homebrew también) desde Terminal. Manualmente:
  ```sh
  brew install libimobiledevice ideviceinstaller
  ```
- Un cable USB y el iPhone/iPad desbloqueado.

### 📦 Instalación

1. Descarga `iDevice-Apps-v1.0.0-macOS.zip` desde [Releases](https://github.com/remasterzerouvm/idevice-apps/releases/latest).
2. Descomprímelo y arrastra **iDevice Apps.app** a tu carpeta **Aplicaciones**.
3. La app está firmada ad-hoc (no notarizada por Apple), así que la primera vez macOS mostrará un aviso. Para abrirla:
   - **Clic derecho** (o Control+clic) sobre la app → **Abrir** → **Abrir**, o
   - En macOS 15+: *Ajustes del Sistema → Privacidad y seguridad → "Abrir de todos modos"*, o
   - En Terminal:
     ```sh
     xattr -dr com.apple.quarantine "/Applications/iDevice Apps.app"
     ```

### 🚀 Uso

1. Conecta tu iPhone/iPad por USB, desbloquéalo y toca **Confiar** cuando te lo pida.
2. Abre **iDevice Apps** y espera a que el estado aparezca como emparejado.
3. Elige ver apps de usuario, del sistema o todas.
4. Marca las apps que quieras eliminar (la gráfica te muestra el espacio que liberarás).
5. Pulsa desinstalar y listo. ✅

### 🛠️ Compilar desde el código

Solo necesitas las Command Line Tools de Xcode (`xcode-select --install`):
```sh
./build.sh
```
Genera un `iDevice Apps.app` universal firmado ad-hoc y un `iDevice-Apps.zip`.

### ❓ Preguntas frecuentes

- **¿Necesito jailbreak?** No. Usa los mismos protocolos que Finder/iTunes.
- **¿Puedo recuperar una app borrada?** Sí, vuelve a descargarla desde la App Store. Ojo: **los datos de la app se eliminan** junto con ella.
- **¿Por qué algunas apps no tienen icono?** Los iconos se obtienen de la API pública de búsqueda de iTunes usando el bundle ID (esos IDs se envían a Apple) y se guardan en `~/Library/Caches/IDeviceApps`. Las apps instaladas por sideload no tienen icono.
- **¿El espacio liberado es exacto?** Son estimaciones que reporta el dispositivo; puede variar un poco.
- **No detecta mi dispositivo.** Revisa el cable, desbloquea el dispositivo, acepta "Confiar en esta computadora" y verifica que `idevice_id -l` lo muestre en Terminal.

### ⚠️ Aviso

Este software se ofrece "tal cual", sin garantías. Desinstalar apps borra sus datos locales; haz un respaldo si lo necesitas. No está afiliado ni respaldado por Apple. iPhone, iPad y macOS son marcas de Apple Inc.

### 💖 Donaciones

Si te resulta útil y quieres apoyar, puedes donar en **remaster@pm.me**.

---

<a id="english"></a>
## 🇬🇧 English

**iDevice Apps** is a small native macOS app (SwiftUI) to list the apps on your iPhone/iPad and **bulk-uninstall** them — no jailbreak needed. Powered by [libimobiledevice](https://libimobiledevice.org).

**Features:** pairing status indicator · list user/system/all apps with icon, version and size · checkbox multi-select & mass uninstall · used/free storage chart showing space to be freed · English & Spanish UI.

**Requirements:** macOS 14+ (Apple Silicon or Intel) · Homebrew with `libimobiledevice` and `ideviceinstaller` (the app offers to install them for you).

**Install:** download the zip from [Releases](https://github.com/remasterzerouvm/idevice-apps/releases/latest), unzip, move to Applications. The app is ad-hoc signed (not notarized): right-click → **Open** → **Open**, or run `xattr -dr com.apple.quarantine "/Applications/iDevice Apps.app"`.

**Usage:** connect via USB, unlock and tap **Trust**, select apps, uninstall.

**Build:** `./build.sh` (Xcode Command Line Tools only).

**Disclaimer:** provided as-is, no warranty. Uninstalling an app deletes its data. Not affiliated with Apple. App icons are fetched from the public iTunes Search API using bundle IDs.

## 📄 License

[MIT](LICENSE) © 2026 Emanuel Avalos
