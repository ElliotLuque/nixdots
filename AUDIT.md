# Auditoría técnica de nixdots y del sistema en ejecución

> **Informe histórico, no una validación del estado actual.** Describe la inspección fechada abajo y contiene referencias y números de línea anteriores a la migración de Caelestia a Veyl. Se han omitido los apartados de funcionalidades experimentales descartadas antes de incorporar este informe al repositorio. Revalidar los hallazgos antes de aplicar sus recomendaciones.

**Fecha:** 6 de noviembre de 2026.\
**Repositorio:** `/home/elliot/dotfiles/nixdots`.\
**Equipo inspeccionado en ejecución:** `nixos-pc`, usuario `elliot`.\
**Hosts declarados y evaluados:** `nixos-pc` y `nixos-laptop`, ambos `x86_64-linux`.\
**Base Git:** `aa456f69b72c5a82af10166e93f9a7dcbc137231`, con cambios previos preparados y sin preparar.

> Se audita el árbol de trabajo existente, no solamente el último commit. No se ha activado ninguna configuración, actualizado el lock, reiniciado servicios, instalado o retirado paquetes de perfiles, conectado una VPN ni ejecutado inferencia. Las construcciones de Nix sí han utilizado cachés y creado artefactos en `/nix/store`. El único archivo del repositorio creado por esta auditoría es este informe. No se reproducen credenciales ni contenidos de archivos secretos.

## 1. Resumen ejecutivo

La arquitectura es razonablemente pequeña y coherente con dos estaciones personales. La separación entre registro de módulos, selección de capacidades, identidad y particularidades de hardware funciona: **ambos sistemas evalúan y sus `system.build.toplevel` se construyen correctamente**. No hay evidencia que justifique sustituir flake-parts/import-tree, introducir un framework propio o dividir más los módulos.

La construcción satisfactoria no equivale a una instalación completamente verificada:

- **`nix flake check` falla realmente** en `herdr-theme`: la configuración genera `command = "lazygit"`, pero el check exige un comando terminado en `/bin/lazygit; exit`. No es un fallo de evaluación de Nix ni una valoración estética.
- **Home Manager está sano en este arranque.** `home-manager-elliot.service` está `active`, `Result=success`, `ExecMainStatus=0`. No se encontró una colisión actual que explique un servicio fallido.
- Hay dos riesgos de seguridad de impacto alto, condicionados por el modelo de amenazas: **acceso físico sin autenticación suficiente** —autologin y ausencia de bloqueo antes de suspender— y **privilegios equivalentes a root mediante Docker** para el mismo usuario que ejecuta clientes y extensiones de IA. Son políticas explícitas, no errores de sintaxis ni compromisos demostrados.
- Hay defectos o riesgos operativos verificables: Hyprlock instalado sin su servicio PAM; Firefox dentro del cgroup de Caelestia; Hunk imperativo antiguo que prevalece en el PATH observado; comprobaciones de ext4 desactivadas; diagnósticos del gestor systemd descartados; activaciones que dependen de que JSON mutable sea válido.
- La configuración NVIDIA del PC **no debe diagnosticarse con recetas antiguas**: el driver abierto 615.71.09 usa `UseKernelSuspendNotifiers=1`. La ausencia de las unidades tradicionales de suspensión no demuestra un fallo. La aceleración VA-API sí está integrada en `hardware.graphics.extraPackages`.
- No se observaron presión de memoria, falta inmediata de espacio, unidades fallidas ni un fallo global de la sesión gráfica. Tampoco se hizo un benchmark: el consumo de una sesión con aplicaciones abiertas no es una medición de reposo.

**Prioridad recomendada:** resolver autenticación física y límites de privilegios según la política deseada; recuperar un `flake check` fiable; corregir PAM, ciclo de vida de aplicaciones y observabilidad; después limpiar configuraciones obsoletas y optimizar comprobaciones.

### Registro resumido de hallazgos

| ID | Severidad | Hallazgo | Estado de la evidencia |
|---|---|---|---|
| F01 | Alta | Autologin y bloqueo antes de suspender desactivado | Declarado, evaluado y contrastado con upstream; suspend/resume no probado |
| F02 | Alta | Usuario de herramientas/IA con acceso root mediante Docker | Configuración y permisos del socket verificados; no se ejecutó una escalada |
| F03 | Media | `herdr-theme` hace fallar el check completo | Reproducido, salida 1 |
| F04 | Media | Hyprlock carece de configuración PAM de NixOS | Evaluación y `/etc/pam.d` verificados; desbloqueo no probado |
| F05 | Media | Aplicaciones gráficas comparten el cgroup de Caelestia | Firefox y política de terminación verificados; no se reinició el servicio |
| F06 | Media | Hunk imperativo antiguo prevalece sobre el declarativo | Resolución de ejecutables y versiones verificadas |
| F07 | Media | SSH escucha en todas las interfaces con autenticación por contraseña | Evaluación y escucha verificadas; alcance desde Internet desconocido |
| F08 | Media | Comprobación de ext4 omitida por política de arranque | Parámetros y raíz ext4 verificados; no se demuestra corrupción |
| F09 | Media | Diagnósticos del gestor systemd descartados | `emerg` / `null` comprobados en ejecución |
| F10 | Media | JSON mutable puede abortar la activación de Home Manager | Reproducido en memoria; archivos actuales válidos |
| F11 | Baja | Variables Java no llegan al entorno de Caelestia | Ausencia verificada; impacto final por aplicación no probado |
| F12 | Baja | Archivo de opciones de IntelliJ apunta a un selector antiguo | Selector del producto contrastado |
| F13 | Baja | Condición de retirada del pin local de Bun ya superada | Versiones verificadas; retirada del workaround no ensayada |

**Criterio de severidad:** alta implica acceso sensible o privilegios elevados bajo un escenario concreto; media implica pérdida de disponibilidad, fiabilidad, protección o diagnóstico; baja implica deriva o mantenimiento sin interrupción actual demostrada. No se declara ningún compromiso ni vulnerabilidad crítica explotada.

## 2. Método, alcance y trazabilidad

Se combinaron cuatro clases de evidencia:

1. **Estática:** módulos, hosts, documentación, scripts, parches y pruebas del árbol de trabajo.
2. **Evaluada:** valores resultantes de NixOS/Home Manager, derivaciones, archivos generados, DAG de activación y grafo del lock.
3. **En ejecución:** unidades, journal, archivos PAM, enlaces de Home Manager, PATH, permisos, sockets, cgroups, parámetros del driver, memoria y arranque del PC.
4. **Contraste upstream:** implementación fijada por el lock y documentación oficial relevante. Las conclusiones específicas de versiones se apoyan en el código fijado, no solamente en una guía web actual.

Se inspeccionaron los **54 archivos Nix versionados —4.177 líneas—**, además de documentación, scripts, pruebas y fuentes upstream pertinentes. El registro evaluado contiene **25 módulos NixOS y 30 Home Manager**. Las búsquedas de secretos se realizaron sin mostrar valores.

### Integridad del trabajo previo

El repositorio ya tenía modificaciones en `flake.nix`, `flake.lock`, hosts, documentación y módulos de IA/red. Se conservaron sin editar, preparar ni revertir. Una huella de nombres y contenidos de archivos versionados, ordenados y separados por bytes NUL, se mantuvo igual durante las comprobaciones y al cierre:

```text
04da5f970ff461400d7ea7f3b644734c147e6e7401b52d72fb90eb86dbc5aaa1
```

La huella excluye este informe. No es el hash de un commit ni del índice: identifica el contenido versionado del árbol de trabajo auditado. No cubre todos los archivos ignorados ni metadatos del sistema.

### Diferencia entre configuración construida y configuración activa

La configuración activa continúa siendo:

```text
/nix/store/j5vcvb8jm7zd5qzf4a74gp2ssp6hjvdz-nixos-system-nixos-pc-26.11.20261011.7fd4004
```

Los resultados construidos del árbol auditado, **sin activarlos**, son:

```text
PC:     /nix/store/35khssrap8i90nwcpsz9yahfrd16aqny-nixos-system-nixos-pc-26.11.20261011.7fd4004
Laptop: /nix/store/y5ryk7m5i2xg531b9abvz8jq6ldf0gyi-nixos-system-nixos-laptop-26.11.20261011.7fd4004
```

Por tanto, una observación del PC activo no certifica que todos los cambios pendientes estén ya aplicados, ni una construcción del portátil certifica su hardware.

## 3. Mapa real de arquitectura

### 3.1 Composición y responsabilidades

```text
flake.nix
  ├─ flake-parts + flakeModules.modules
  └─ import-tree [ modules/ hosts/ ]
       ├─ registra módulos reutilizables
       ├─ declara paquetes, checks y formatter
       └─ declara nixosConfigurations: nixos-pc, nixos-laptop

NixOS base
  ├─ system: Nix, herramientas mínimas, nh/limpieza, zona horaria
  └─ locale

NixOS workstation
  ├─ base + integración Home Manager
  ├─ desktop: gráficos, audio, Bluetooth, greetd, Hyprland
  ├─ development: Docker + nix-ld
  ├─ NetworkManager + cliente SSH
  └─ home-manager.sharedModules → HM workstation

elliot-workstation
  ├─ elliot: identidad, Fish, wheel, identidad HM, checkout de nh
  └─ grupos de escritorio/Docker + initial_session de greetd

HM workstation
  ├─ CLI/Fish
  ├─ desktop: Hyprland, Caelestia, aplicaciones, XDG, temas y scripts
  ├─ development: editor, IDE, JDK y herramientas
  └─ ai-clients: clientes, extensiones, skills e integraciones TUI
```

**Fuentes:** `flake.nix:120–130`, `modules/flake.nix:1–7`, `modules/roles/base.nix`, `modules/roles/workstation.nix:1–24`, `modules/users/elliot.nix:6–49`, `modules/desktop/session.nix:1–78`.

Los archivos descubiertos son módulos **de flake-parts**, no módulos NixOS aplicados automáticamente. Registrar una capacidad no la habilita; la seleccionan los imports. Los helpers y configuraciones de hardware con prefijo `_` quedan fuera del descubrimiento y se consumen explícitamente. Es una convención importante que la documentación y los checks ya cubren; no un cargador opaco inventado por el repositorio.

### 3.2 Matriz de hosts

| Área | `nixos-pc` | `nixos-laptop` |
|---|---|---|
| Plataforma / estado | `x86_64-linux`, NixOS y HM `24.11` | Igual |
| Raíz / intercambio | ext4, sin swap ni zram evaluados | ext4, una partición swap, sin zram |
| GPU | NVIDIA abierta, driver latest fijado por nixpkgs | NVIDIA propietaria + Intel PRIME offload |
| Energía | Governor `performance` | power-profiles-daemon; TLP y auto-cpufreq desactivados |
| NVIDIA PM | PM tradicional desactivada; notifier del kernel activo en runtime | PM y fine-grained activados; notifier evaluado desactivado |
| Pantallas | Dos salidas HDMI 3840×2160@60 declaradas | Monitores por defecto; `AQ_DRM_DEVICES` explícito |
| IA local | Ollama CUDA y `qwen3.8:27b-q4_k_m`; HM `local-llm` | Sin Ollama local seleccionado |
| Red explícita | LocalSend, servidor SSH, Mosh, campus VPN | LocalSend, servidor SSH, Mosh |
| VPN de usuario | Proton VPN | Proton VPN |
| Wi-Fi de campus | No seleccionado por estos imports | Opt-in comentado, no habilitado |

**Fuentes:** `hosts/nixos-pc/default.nix:6–95`, `hosts/nixos-laptop/default.nix:6–70`, `hosts/nixos-pc/_hardware-configuration.nix`, `hosts/nixos-laptop/_hardware-configuration.nix`, `modules/hardware/power-laptop.nix`, `modules/hardware/nvidia-prime.nix:1–21`.

Los hosts construyen kernel **6.18.55** y NVIDIA **615.71.09**. `stateVersion = "24.11"` conserva contratos de datos/defaults; **no significa que se estén ejecutando paquetes NixOS 24.11** y no debe actualizarse para igualarlo al nombre de la distribución.

### 3.3 Propiedad de la sesión y de los archivos

- **NixOS** instala y configura el compositor y los portales del sistema.
- **Home Manager** genera la configuración Lua de Hyprland y las integraciones de usuario. `package = null` y `portalPackage = null` son deliberados y evitan una segunda instalación competidora (`modules/desktop/hyprland.nix:69–74`).
- **Caelestia/Quickshell** funciona como unidad de usuario asociada a `graphical-session.target`; sus aplicaciones lanzadas y su bloqueo integrado requieren distinguirse del compositor y de Hyprlock.
- **Stylix/living-code** producen configuración declarativa. La CLI de Caelestia tiene deshabilitada la reescritura de temas de otras aplicaciones para evitar dos propietarios (`modules/desktop/caelestia.nix:145–166`). Se audita esa propiedad, no la apariencia.
- **Pi y Paseo** conservan preferencias/estado mutables; activaciones puntuales reconcilian una parte. Pi `auth.json` y `settings.json` no son archivos declarativos de HM. Esta separación es razonable, aunque requiere endurecer sus reconciliadores [F10].
- **Herdr** conserva las integraciones TUI. Los parches de menús/worktrees tienen un propósito concreto y pruebas; no son capas arbitrarias.

## 4. Flakes, fuentes y reproducibilidad

### 4.1 Lo que está fijado y comprobado

- `flake.lock` usa formato **7**, **25 inputs raíz**, **68 nodos**, de los cuales **67** tienen fuente fijada. Todos esos nodos tienen `narHash`; los nodos VCS tienen revisión.
- El nixpkgs principal es **`7fd4004d0511991fff3a0524856a9be09e28c5f0`**. `nixos-unstable` en la URL no implica actualización espontánea mientras se utilice este lock sin actualizarlo.
- Hyprland y Caelestia incluyen revisiones explícitas en `flake.nix`; los plugins siguen el input de Hyprland. Esta alineación es valiosa ante cambios de API/ABI.
- Los paquetes locales usan fuentes fijadas, parches versionados y mecanismos de dependencias/hash de Nix.
- `useGlobalPkgs = true` comparte el package set de NixOS con Home Manager (`modules/core/home-manager.nix:5–8`).
- La única caché de sustitución evaluada es `https://cache.nixos.org/`, con una clave pública de confianza. No se observó una caché privada añadida con confianza privilegiada.

### 4.2 Varios nixpkgs no equivalen a paquetes duplicados en memoria

Hay seis revisiones completas distintas de nixpkgs en el grafo: el principal y fuentes asociadas a agent-skills, Hyprland, el nixvim comunitario anidado, Stylix y una rama Darwin de otra dependencia. También hay un nodo `nixpkgs-lib` y varios flake-parts, algunos con la misma revisión (`flake.lock:847–958`, `flake.lock:980–998`, `flake.lock:1209–1239`).

Eso añade superficie de mantenimiento/evaluación, pero **no demuestra seis copias del sistema ni seis libc usadas por la sesión**. La flake personal de nixvim sigue el nixpkgs raíz y pasa su package set a `makeNixvimWithModule`, aunque su input comunitario conserve otro nixpkgs en el lock. Los follows deben juzgarse por los paquetes efectivamente seleccionados y las restricciones upstream, no por contar nodos.

Una normalización de follows solo se justifica tras comparar derivaciones/closures y ejecutar los checks. No se propone forzar el nixpkgs de Hyprland al principal sin comprobar compatibilidad.

### 4.3 Fronteras deliberadamente mutables

La reproducción del sistema **no incluye por sí sola**:

- perfiles imperativos y PATH real [F06];
- secretos, cuentas, preferencias y sesiones de clientes;
- pesos de Ollama descargados por un servicio y etiquetas de modelos potencialmente mutables;
- configuración de NetworkManager y credenciales provisionadas fuera del store;
- servicios remotos, APIs y respuestas de proveedores de IA.

`services.ollama.loadModels` declara una etiqueta, no un hash del contenido dentro del lock. El módulo upstream ejecuta `ollama pull` al arrancar su loader y `syncModels` está desactivado. Un build correcto no demuestra que el modelo se haya descargado ni que sus pesos coincidan en dos fechas. Véase O04 para una mejora proporcionada, sin convertir datos grandes en inputs Nix por defecto.

## 5. Home Manager: diagnóstico específico

### 5.1 Estado actual de `home-manager-elliot.service`

| Propiedad observada | Resultado |
|---|---|
| Tipo / persistencia | `oneshot`, `RemainAfterExit=yes` |
| Usuario | `elliot` |
| Estado / resultado | `active`, `success`, salida 0 |
| Ejecución del arranque actual | 10:36:15–10:36:16 CET |
| Timeout | 5 minutos |
| Generación de activación del servicio activo | `/nix/store/6a16iwd4gr1lfjnrl92h06zib61gs11y-home-manager-generation` |
| Copias previas | `HOME_MANAGER_BACKUP_EXT=backup` |

La unidad de sistema se ejecuta antes de `systemd-user-sessions.service`. Que siga `active (exited)` es el comportamiento previsto de esta unidad, no que una activación siga bloqueada.

Se clasificaron **29 entradas del journal de este arranque y 486 desde el 20 de octubre**: cero coincidencias con los patrones de colisión/fallo de activación utilizados. Es evidencia limitada al journal disponible y a esos patrones, no una garantía sobre cualquier error histórico.

### 5.2 Archivos, enlaces y colisiones

La comparación de `home.file` evaluado con el home actual encontró **107 definiciones**: 103 destinos enlazados a archivos de Home Manager —98 sin `force` y cinco con `force`—, dos directorios recursivos y dos destinos todavía ausentes. No se detectó una colisión potencial en el nivel superior analizado. Los directorios recursivos son `~/.config/Kvantum` y `~/.config/autostart`; se inspeccionaron también sus enlaces visibles.

- `~/.config/mimeapps.list` es un enlace gestionado. Su `.backup` existente **no constituye una colisión actual**.
- Hay un enlace `Base16Kvantum.backup` de una generación anterior; los archivos activos de Kvantum apuntan a archivos gestionados. No se ha probado que ese backup impida una activación.
- Pi `settings.json` es mutable; `models.json` es declarativo donde se selecciona `local-llm`. Paseo mantiene su JSON mutable con modo `0600`. El `auth.json` de Pi inspeccionado por metadatos también tiene modo `0600`.

La implementación fijada de Home Manager rechaza un archivo ajeno que debe respaldar si el destino `.backup` ya existe, salvo las excepciones/configuración de backup correspondientes. Es una **condición futura de fallo conocida**, no una causa demostrada del estado actual.

**Recomendación:** no borrar backups ni aplicar `force = true` indiscriminadamente. Ante un fallo real, identificar primero el destino exacto en el journal, determinar quién es su propietario y conservar el contenido antes de migrarlo. Forzar archivos que contienen preferencias o credenciales sería una regresión de propiedad.

### 5.3 DAG y mutaciones

Los reconciliadores de Pi, Paseo y Caelestia están después de `writeBoundary`; no todos dependen de `linkGeneration`. Estar después del límite de escritura autoriza la mutación, pero no garantiza que se hayan enlazado todos los archivos nuevos. Si una reconciliación necesita esos enlaces, debe expresar esa dependencia concreta, no confiar en un orden incidental.

Se demuestra un problema más directo en [F10]: excepciones de parseo/tipo de JSON mutable pueden abortar la activación. Los JSON reales estaban válidos, por lo que **no se atribuye a esto un fallo presente del servicio**.

## 6. Hallazgos detallados

### F01 — Alta: autenticación física insuficiente al iniciar y suspender

**Archivos:** `modules/users/elliot.nix:20–34`, `modules/desktop/caelestia.nix:168–181`; selección en ambos hosts.

**Evidencia:** `initial_session` de greetd inicia Hyprland directamente como `elliot`. En ambos hosts, Caelestia evalúa `general.idle.lockBeforeSleep = false`; el bloqueo por inactividad está a 600 segundos. El [upstream fijado de Caelestia, `modules/IdleMonitors.qml:40–44`](https://github.com/caelestia-dots/shell/blob/6d3e6a96492b0e9c668464875ac34150113ede5f/modules/IdleMonitors.qml#L40-L44), solo marca la sesión como bloqueada en `onAboutToSleep` si esa opción es verdadera. El timeout de inactividad no sustituye una garantía de bloqueo antes de suspender.

**Impacto:** quien tenga acceso físico al arranque obtiene la sesión del usuario sin contraseña. Una suspensión solicitada antes del bloqueo no tiene protección previa garantizada por esta configuración. El impacto aumenta porque el usuario tiene credenciales de herramientas y acceso a Docker. Ambas raíces son ext4 y no declaran dispositivos LUKS de initrd; en el PC la raíz es un dispositivo de partición directo. No se auditó cifrado por fichero ni protección frente a arranque externo.

**Recomendación:** separar explícitamente la política de comodidad del PC y la de movilidad del portátil. Para una estación que debe proteger una sesión desatendida, exigir autenticación inicial y activar el bloqueo antes de dormir en **el locker realmente utilizado**. No añadir simultáneamente varios lockers ni asumir que habilitar Hyprlock resuelve Caelestia. Considerar cifrado de datos en reposo como proyecto separado, no como un cambio trivial de una opción.

**Validación pendiente:** con acceso de recuperación, verificar bloqueo manual, suspensión inmediata desde sesión desbloqueada, cierre de tapa, reanudación y desbloqueo. No se ejecutó ninguna de esas acciones.

**Coste/riesgo:** 30–90 min para políticas y pruebas, sin contar cifrado; riesgo medio de quedarse fuera de la sesión si PAM no funciona. **Confianza:** alta en la configuración; media en el comportamiento físico final, no ensayado. El autologin puede aceptarse deliberadamente en un PC bajo control físico, pero ese supuesto debe quedar documentado.

### F02 — Alta: clientes y extensiones se ejecutan con acceso root equivalente por Docker

**Archivos:** `modules/development/default.nix:3–6`, `modules/users/elliot.nix:23–28`, `modules/roles/workstation.nix:3–24`.

**Evidencia:** Docker rootful está habilitado, rootless deshabilitado y `elliot` pertenece a `docker`. El socket observado es `0660 root:docker`. Los clientes y extensiones de desarrollo/IA se ejecutan bajo el mismo usuario. No había contenedores en ejecución en la consulta realizada; eso no elimina el acceso al daemon.

**Impacto:** ejecutar código bajo ese UID permite pedir al daemon rootful operaciones con privilegios de host. El sandbox de los builders Nix **no** restringe automáticamente una extensión, un agente o un comando del usuario en su sesión. Docker documenta expresamente el carácter root-equivalente del grupo. No se ha demostrado código malicioso ni se ha ejecutado una prueba de escalada.

**Recomendación:** decidir si los agentes y las extensiones deben tener autoridad total sobre la máquina. Si no, valorar Docker rootless o un entorno/usuario de trabajo realmente aislado y sin el socket rootful. No basta con quitar el grupo del archivo si los procesos activos conservan grupos, ni con una preferencia de confirmación dentro de la herramienta.

**Coste/riesgo:** medio, aproximadamente 2–4 h de ensayo y migración; puede afectar red, puertos, GPU, imágenes, volúmenes y contextos existentes. No migrar ni eliminar datos sin inventario. **Confianza:** alta sobre la exposición; su aceptación depende de la política de confianza.

### F03 — Media: check de Herdr contradictorio con la configuración generada

**Archivos:** `modules/checks.nix:271–321`, especialmente línea 309; `modules/ai/herd/default.nix:76–84`.

**Reproducción ejecutada:**

```sh
nix build --no-link --no-write-lock-file .#checks.x86_64-linux.herdr-theme
# Salida 1: AssertionError
```

El TOML generado contiene `command = "lazygit"`; el check exige `.endswith('/bin/lazygit; exit')`. El comentario de la configuración todavía promete salir explícitamente del shell. El check completo también terminó con salida 1 por esta derivación.

**Impacto:** se pierde una señal verde fiable de validación. Un sistema puede construir mientras la suite falla; no deben confundirse ambos resultados. No se probó interactivamente si el popup necesita `exit` con la versión actual de Herdr.

**Recomendación:** decidir el comportamiento deseado del popup y alinear implementación, comentario y aserción. Si se exige una ruta absoluta y salida explícita, restaurar esa propiedad en la configuración; si la nueva implementación de Herdr hace innecesario el shell, ajustar la prueba con evidencia. No eliminar el check completo por llamarse `herdr-theme`: también comprueba comandos y atajos.

**Coste/riesgo:** 15–45 min más una prueba del popup; riesgo bajo. **Confianza:** alta, fallo reproducido.

### F04 — Media: Hyprlock instalado sin su servicio PAM

**Archivos:** `modules/desktop/hyprland/hyprlock.nix:3–11`, import en `modules/desktop/session.nix:51–60`.

**Evidencia:** Home Manager habilita Hyprlock, pero `programs.hyprlock.enable` de NixOS y `security.pam.services.hyprlock` no están habilitados/definidos. `/etc/pam.d/hyprlock` no existe; el servicio PAM `other` presente deniega autenticación. El módulo HM fijado avisa expresamente de que instalar el paquete sin PAM no permite desbloquear.

**Impacto:** si se invoca Hyprlock como alternativa o manualmente, no hay una ruta de autenticación PAM válida configurada para él. Puede producir un bloqueo operativo de la sesión. No se encontró una invocación declarada que demuestre que sea el locker principal; Caelestia usa un locker propio y archivos PAM empaquetados mediante `configDirectory`. No se extrapola este fallo a su autenticación.

**Recomendación:** o retirar Hyprlock si no tiene función real, o añadir en NixOS `security.pam.services.hyprlock = {};` —alternativamente el módulo NixOS de Hyprlock, coordinando propiedad del paquete— y probarlo con recuperación disponible. Un solo cambio pequeño, sin crear otra abstracción de lockers.

**Coste/riesgo:** 15–30 min; riesgo medio durante la prueba de bloqueo. **Confianza:** alta sobre la ausencia de PAM; no se intentó bloquear/desbloquear.

### F05 — Media: reiniciar Caelestia alcanzaría aplicaciones lanzadas desde su cgroup

**Archivos:** `modules/desktop/caelestia.nix:138–143`; servicio generado por el módulo upstream.

**Evidencia en ejecución:**

```text
caelestia.service: KillMode=control-group, TimeoutStopUSec=5s, SendSIGKILL=yes
Quickshell PID 1893: .../session.slice/caelestia.service
Firefox    PID 2241: .../session.slice/caelestia.service
```

El upstream `modules/launcher/services/Apps.qml` usa `Quickshell.execDetached` o `DesktopEntry.execute`. Desasociar el padre no crea otro cgroup: Firefox tiene como padre el gestor de usuario, pero sigue dentro de la unidad de Caelestia.

**Impacto:** detener/reiniciar esa unidad señala también a esas aplicaciones; después puede aplicar SIGKILL. Hay riesgo de cierre de aplicaciones y pérdida de trabajo no guardado cuando se intenta recargar solamente el shell. No se ejecutó un reinicio para demostrar pérdida de datos.

**Recomendación:** lanzar las aplicaciones en scopes/unidades propios bajo `app.slice`, conservando el entorno gráfico; por ejemplo, mediante un mecanismo de lanzamiento que use `systemd-run --user --scope --collect --slice=app.slice -- …`. Hace falta integrarlo en el launcher real, no solo crear un alias de terminal. No cambiar a `KillMode=process` sin analizar los procesos residuales y la limpieza: oculta el acoplamiento en lugar de dar a cada aplicación su ciclo de vida.

**Validación pendiente:** abrir una aplicación descartable, comprobar su cgroup y ensayar la recarga del shell en una sesión de prueba. **Coste/riesgo:** 1–3 h si hay que adaptar o parchear el launcher; riesgo medio. **Confianza:** alta sobre pertenencia y semántica de systemd; no se ejecutó la terminación.

### F06 — Media: el Hunk utilizado desde el PATH observado no es el declarativo

**Área:** estado de `~/.nix-profile`; paquete declarativo en `modules/ai/herd/hunk.nix:10–74`.

**Evidencia:**

```text
~/.nix-profile/bin/hunk                 → hunk 0.21.1
/etc/profiles/per-user/elliot/bin/hunk   → hunk 0.23.0
which -a hunk: primero el perfil imperativo
```

El perfil imperativo contiene también Ambxst, GCC, una entrada desktop y paquetes de Paseo procedentes de un worktree. No se concluye que todos causen conflictos; Hunk sí demuestra una diferencia de versión. El PATH es el observado desde el contexto del agente; otras sesiones deben comprobarse por separado. La configuración de Herdr y la extensión local usan la ruta absoluta del Hunk empaquetado, por lo que **no se afirma que ese atajo use 0.21.1**.

**Impacto:** comandos manuales, documentación y diagnóstico pueden ejecutar una versión distinta de la construida. El lock del repositorio no reproduce todo el entorno efectivo.

**Recomendación:** inventariar las entradas imperativas, decidir qué experimentos deben permanecer y retirar o migrar solo las entradas que estén sustituidas de forma deliberada. No purgar el perfil completo ni sus generaciones por automatismo. Verificar `type -a`/`which -a` en la sesión de usuario y rutas del launcher antes y después.

**Coste/riesgo:** 15–45 min; riesgo bajo-medio por dependencias de flujos experimentales. **Confianza:** alta sobre el contexto inspeccionado.

### F07 — Media: SSH expuesto a redes alcanzables con contraseña habilitada

**Archivos:** `modules/networking/ssh.nix:3–6`, selección en `hosts/nixos-pc/default.nix:19–21` y `hosts/nixos-laptop/default.nix:19–21`.

**Evidencia:** ambos hosts evalúan `PasswordAuthentication=true`, `KbdInteractiveAuthentication=true`, `PermitRootLogin="prohibit-password"`; firewall habilitado con TCP 22 permitido. En el PC, SSH escucha en `0.0.0.0:22` y `[::]:22`. No hay claves de acceso del usuario declaradas en sus opciones `authorizedKeys` —esto no prueba que no existan claves provisionadas fuera de Nix—.

**Impacto:** el servicio acepta intentos de autenticación por contraseña desde redes que puedan alcanzar el equipo. Es relevante en un portátil móvil. No se ha demostrado publicación en Internet, contraseñas débiles ni intentos exitosos. Root no tiene permitido entrar por contraseña con ese ajuste.

**Recomendación:** conservar el servidor si es necesario, pero decidir una política por host: claves verificadas y desactivación posterior de los métodos de contraseña, o escucha/firewall limitado a redes de confianza/VPN. Si se necesita MFA por PAM, no desactivar keyboard-interactive indiscriminadamente.

**Coste/riesgo:** 30–60 min más prueba de acceso; riesgo medio-alto de perder acceso remoto. Validar primero una segunda sesión por clave y acceso local. No se realizó ningún login ni cambio de firewall. **Confianza:** alta sobre la política; alcance exterior no verificado.

### F08 — Media: el arranque omite las comprobaciones de los sistemas ext4

**Archivos:** `modules/hardware/boot-workstation.nix:28–29`; raíces en `hosts/nixos-pc/_hardware-configuration.nix:16–19` y `hosts/nixos-laptop/_hardware-configuration.nix:16–19`.

**Evidencia:** `fsck.mode=skip` y `fsck.repair=no` se incluyen en ambos hosts. La línea de arranque actual del PC contiene ambos y su raíz es ext4. Un servicio fsck con resultado satisfactorio no demuestra que haya comprobado el disco cuando se le ha indicado omitirlo.

**Impacto:** se desactiva la comprobación en el punto normal de mantenimiento fuera de línea; el replay del journal de ext4 no sustituye todas las verificaciones de consistencia. No hay evidencia de corrupción existente.

**Recomendación:** recuperar el comportamiento automático normal salvo justificación documentada y una alternativa de mantenimiento. No proponer reparación incondicional con `yes`, ni ejecutar fsck sobre la raíz montada. Validar el siguiente arranque de mantenimiento y revisar su journal.

**Coste/riesgo:** cambio pequeño, 15–30 min más reinicio planificado; riesgo medio de un arranque más largo o de requerir intervención si existe un problema previo. **Confianza:** alta.

### F09 — Media: systemd descarta información esencial para diagnosticar fallos

**Archivos:** `modules/hardware/boot-workstation.nix:20–26`.

**Evidencia:** los parámetros incluyen `systemd.log_level=0`, `systemd.log_target=null` y un nivel equivalente para initrd. En ejecución:

```text
systemctl log-level  → emerg
systemctl log-target → null
```

**Impacto:** se pierden diagnósticos del **gestor systemd**. Esto complica investigar dependencias, fallos de activación y arranque. No significa que todo journald esté desactivado: se pudieron leer logs de servicios y aplicaciones. `quiet`, `loglevel` y `consoleLogLevel` tampoco equivalen por sí solos a borrar todo el journal.

**Recomendación:** mantener la consola silenciosa si es un requisito, pero conservar el logging del gestor hacia journal con nivel útil. Separar visibilidad de la consola, estado de arranque y registro persistente. Revisar también el filtrado de udev, sin cambiar todos los flags como un bloque indiferenciado.

**Coste/riesgo:** 15–30 min y un reinicio para los parámetros del kernel; riesgo bajo. **Confianza:** alta, verificado en runtime.

### F10 — Media: datos JSON mutables pueden hacer fallar una activación completa

**Archivos:** `modules/ai/pi.nix:124–136`, `modules/ai/_paseo-theme.py:16–24`, `modules/ai/paseo.nix:79–82`.

**Reproducción no invasiva:** se ejecutó el código con un `Path` simulado en memoria; ninguna prueba leyó credenciales ni escribió el home real.

| Entrada sintética | Resultado Pi | Resultado Paseo |
|---|---|---|
| JSON incompleto `{` | `JSONDecodeError` | `JSONDecodeError` |
| Array `[]` | `TypeError` | `AttributeError` |
| `null` o número | `TypeError` | No ensayado |
| Objeto con `plugins` como array | No aplicable | `AttributeError` |

Las excepciones no se manejan, de modo que el comando de activación sale con error. Pi además reescribe mediante `Path.write_text`, sin sustitución atómica, por lo que una interrupción o escritura concurrente puede dejar datos incompletos o perder cambios. Paseo sí usa archivo temporal, sustitución atómica y backup inicial `0600`; no debe presentarse como si careciera de esas protecciones. Ninguno resuelve por sí solo una carrera con otro escritor.

**Impacto:** una preferencia mutable inválida puede impedir completar una activación de HM que no depende funcionalmente de ese tema. **Los dos archivos reales eran objetos JSON válidos y el servicio actual tuvo éxito.**

**Recomendación:** validar objeto raíz y tipos anidados, tratar por separado ausencia y corrupción, no sustituir silenciosamente preferencias/credenciales por `{}`, y elegir una política explícita: avisar y omitir la reconciliación cosmética o fallar con un diagnóstico seguro si existe un motivo real. En Pi, usar escritura atómica preservando permisos; coordinar escritores si la aplicación permanece activa. Añadir pruebas de estas entradas y de fallos de escritura a los helpers, sin volcar el JSON en los errores.

**Coste/riesgo:** 1–3 h; riesgo bajo-medio de alterar preferencias si la migración se implementa mal. **Confianza:** alta sobre las excepciones; el daño por carrera/interrupción es potencial, no observado.

### F11 — Baja: el entorno Java del launcher no coincide con el de terminal

**Archivos:** `modules/development/default.nix:36–40`, `modules/desktop/hyprland.nix:131–134`, `modules/desktop/caelestia.nix:142`.

**Evidencia:** se define `JAVA_HOME` y `JDK_JAVA_OPTIONS` en `home.sessionVariables`, y Hyprland declara también `JDK_JAVA_OPTIONS`. Sin embargo, el gestor de usuario, Quickshell y Firefox inspeccionados no contienen ninguna de esas dos variables; el subproceso de auditoría sí. La unidad de Caelestia tiene `environment = []` y es una ruta de lanzamiento distinta a la terminal.

**Impacto:** no se puede asumir que un programa Java lanzado desde el shell gráfico reciba la selección de JDK/backend configurada para la terminal. Firefox solo demuestra herencia de entorno; su ausencia de variables Java no es un fallo de Firefox. Tampoco se demostró que IntelliJ deje de funcionar: puede usar su runtime empaquetado.

**Recomendación:** si la intención es aplicarlas a todas las aplicaciones gráficas, transportar únicamente las variables necesarias al gestor/unidad de usuario y verificar un proceso Java lanzado por la ruta real. Si son preferencias exclusivas de terminal, documentarlo y retirar la expectativa duplicada. No importar indiscriminadamente todo el entorno, que puede contener secretos.

**Coste/riesgo:** 30–60 min; riesgo bajo-medio porque forzar WLToolkit globalmente puede afectar aplicaciones incompatibles. **Confianza:** alta sobre la ausencia; media sobre el efecto funcional por aplicación.

### F12 — Baja: las VM options de IntelliJ apuntan a una versión antigua

**Archivo:** `modules/development/default.nix:41–47`.

**Evidencia:** se fuerza `JetBrains/IntelliJIdea2025.3/idea64.vmoptions`, pero el paquete evaluado es IntelliJ **2026.2.3**. Su `product-info.json` contiene `dataDirectoryName = "IntelliJIdea2026.2"` y `-Didea.paths.selector=IntelliJIdea2026.2`.

**Impacto:** con el selector normal del producto, el archivo gestionado no configura la versión instalada. No se verificó un override privado que redirigiese el directorio de configuración.

**Recomendación:** alinear el selector con el producto o usar un mecanismo de opciones soportado por su empaquetado que no quede desfasado con cada cambio de versión. Comprobar las opciones efectivas de una instancia antes de borrar archivos antiguos. Evitar fijar otro año sin una comprobación que detecte la próxima deriva.

**Coste/riesgo:** 15–30 min; riesgo bajo. **Confianza:** alta sobre la discrepancia.

### F13 — Baja: el pin local de Bun ha superado su condición documentada de retirada

**Archivo:** `modules/ai/herd/hunk.nix:14–56`.

**Evidencia:** el comentario pide retirar el override cuando nixpkgs alcance Bun ≥1.3.14; el pin local es **1.3.14** y nixpkgs ya proporciona **1.4.2**. Hunk es 0.23.0 y la variante local responde correctamente a `--version`.

**Impacto:** se mantiene un runtime antiguo y una descarga/hash específicos por plataforma sin una condición de retirada actualizada. Eso es deuda de mantenimiento, no prueba de una vulnerabilidad de Bun ni de un fallo actual de Hunk.

**Recomendación:** ensayar por separado (1) usar el Bun actual y (2) retirar el workaround que ejecuta JavaScript en lugar de un binario compilado. El segundo responde a un segfault distinto y no queda invalidado automáticamente por el número de versión. Probar diff, `--watch`, parada y notas de agente en un repositorio descartable; solo entonces simplificar y actualizar el comentario con evidencia.

**Coste/riesgo:** 30–90 min; riesgo bajo-medio de reintroducir bloqueo/segfault. **Confianza:** alta sobre las versiones; no verificada sobre la eliminación segura del workaround.

## 7. Hyprland, Caelestia y NVIDIA: conclusiones y falsos positivos descartados

### 7.1 Sesión gráfica

La sesión activa contiene Hyprland, Quickshell y aplicaciones Wayland. Las pruebas Lua validan generación y overrides con llamadas stub; **no prueban renderizado ni ABI en una sesión nueva**. Que Home Manager use configuración Lua es coherente con la revisión fijada; no se debe migrar a otra sintaxis siguiendo documentación de una revisión distinta.

La separación compositor/portal de NixOS y configuración HM es correcta. No se observó una segunda barra Ambxst en ejecución por el mero hecho de existir en un perfil; paquete instalado y proceso activo son cosas distintas. Sí hay un problema de propiedad de procesos al lanzar aplicaciones desde Caelestia [F05].

En el journal gráfico del arranque se contabilizaron 62 avisos de backend relacionados con inhibición —`Inhibiting other than idle not supported`— y tres avisos PAM sobre la ausencia de un `other` por defecto. No se los convierte en prueba de sesión rota o de imposibilidad de desbloquear Caelestia. Su contexto y las pruebas de bloqueo/suspensión pendientes importan más que la presencia de la palabra «error» o «PAM».

### 7.2 NVIDIA del PC: suspensión y aceleración

Configuración/evidencia contrastadas:

```text
Driver:                         615.71.09, módulos abiertos
PreserveVideoMemoryAllocations:  1
UseKernelSuspendNotifiers:      1
EnableS0ixPowerManagement:       0
DynamicPowerManagement:         3
nvidia_drm modeset:             Y
```

El nixpkgs fijado habilita por defecto el notifier del kernel para módulos abiertos y driver ≥595. NVIDIA documenta la conservación de VRAM con ese mecanismo. **No se recomienda habilitar ciegamente las unidades `nvidia-suspend/resume` como si faltasen obligatoriamente.** La configuración del portátil propietario utiliza otro camino y no puede validarse con los parámetros del PC.

La sospecha de una VA-API mal instalada también se descartó: `hardware.nvidia.videoAcceleration = true` en ambos hosts, el paquete aparece en `hardware.graphics.extraPackages`, y `/run/opengl-driver/lib/dri/nvidia_drv_video.so` existe. En el nixpkgs actual esa integración es automática. La entrada adicional en `environment.systemPackages` es potencialmente redundante, no prueba de ausencia de integración. **No se reprodujo decodificación de vídeo ni se midió uso de NVDEC.**

### 7.3 Workarounds que requieren una prueba, no una acusación

`modules/hardware/nvidia-desktop.nix:3–9` añade `nomodeset`, pese a habilitar KMS en la configuración común. El kernel avisa: `Booted with the nomodeset parameter. Only the system framebuffer will be available`. Sin embargo, `nvidia_drm` tiene modeset `Y` y la sesión funciona. El aviso merece revisar el motivo del workaround; **no demuestra que Hyprland esté usando solo framebuffer o software**.

También hay `no_hardware_cursors`, ajustes de flicker y políticas por host. Conservarlos o retirarlos debe depender de una comparación en una generación de prueba, con acceso de recuperación y revisión de logs. No se recomienda una «limpieza NVIDIA» masiva ni se atribuye una mejora de rendimiento no medida.

En el portátil, `AQ_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1` asume numeración de nodos (`hosts/nixos-laptop/default.nix:38–44`). No se dispone de su sysfs para confirmar el orden. Si varía entre arranques, usar enlaces udev estables y sin `:` dentro del nombre, identificados por PCI, y comprobar PRIME. **No sugerir directamente una ruta PCI `by-path` con dos puntos como si fuese una entrada simple:** el separador de la variable también es `:`. Es una mejora condicional, no un fallo actual demostrado.

## 8. Seguridad, red y secretos

### 8.1 Superficie declarada y observada

| Componente | Política evaluada / observación | Lectura de seguridad |
|---|---|---|
| Firewall, ambos hosts | Habilitado | No se encontró una desactivación general |
| SSH | TCP 22 permitido; escucha IPv4/IPv6 en el PC | Riesgo específico [F07] |
| LocalSend | TCP/UDP 53317 permitidos | Elección explícita del host; no se observó listener en la muestra TCP |
| Mosh | UDP 60000–61000 permitido | Rango esperado del módulo nativo; no implica 1.001 procesos escuchando |
| Reverse-path filtering | `loose` | Compatible con routing/VPN; no equivale a «firewall apagado» |
| Ollama | `127.0.0.1:11434` | No se publica su API directamente en todas las interfaces |
| Paseo | Listener observado en `127.0.0.1:24543` | No se demostró exposición remota del daemon |
| Nix daemon | `allowed-users=["*"]`, `trusted-users=["root"]`, sandbox habilitado | Usar el daemon no concede ser usuario de confianza |
| Docker | Rootful; socket accesible por `docker` | Riesgo específico [F02] |

Un listener no loopback de resolución local también aparece en 5355, pero no se concluye que atraviese el firewall solo por aparecer en `ss`. No se hicieron escaneos externos, pruebas de NAT ni captura de tráfico. La tabla de opciones evaluadas no sustituye una inspección completa y privilegiada de todas las reglas efectivas.

`allowUnfree = true` es una política de licencias amplia, no una vulnerabilidad por sí misma. Nix, el navegador, herramientas de desarrollo y extensiones son distintas fronteras de ejecución: ni fijar fuentes ni pasar checks hace que todo el código runtime esté aislado.

### 8.2 Secretos y Git

- Se analizaron **98 archivos de texto versionados** con patrones de asignaciones/tokens. Los candidatos revisados correspondían a pruebas sintéticas, configuración de Herdr o sustitución de variables para Wi-Fi; no se identificó una credencial real que deba publicarse aquí.
- Se analizaron **719 blobs históricos de texto** con patrones de alta especificidad de tokens y claves privadas: sin coincidencias. No es una auditoría criptográfica, una garantía sobre todos los secretos ni una revisión completa de backups/artefactos externos.
- `.env` está ignorado y **no aparece en el snapshot real de la flake Git** utilizado por Nix. No se ha demostrado una fuga al store por ese archivo. Cambiar a `path:` o copiar expresamente directorios sería otro mecanismo y requeriría otra comprobación.
- No se imprimieron valores de credenciales VPN o de autenticación. Los archivos específicos de autenticación se inspeccionaron por metadatos; la validación de los JSON mutables de preferencias solo devolvió si su raíz era un objeto válido.

### 8.3 VPN y provisión

`modules/networking/campus-vpn.nix` referencia `/etc/nixdots/upv-vpn.conf` como cadena de ruta runtime, no con `builtins.readFile`. El helper de provisión valida la identidad, usa creación restrictiva y reemplazo atómico. Codifica contraseña/PSK en hexadecimal para impedir inyección en la sintaxis de configuración: **hexadecimal no es cifrado**.

La unidad de strongSwan tiene condición de existencia del archivo, no se selecciona para inicio automático normal y los CHILD_SA usan `start_action = "none"`, evitando disparar autenticaciones/2FA durante builds y arranques. Los perfiles, redes y DNS corresponden a una integración universitaria específica; no se propone cambiar sus protocolos unilateralmente sin compatibilidad con el servicio.

La Wi-Fi de campus separa perfiles y secretos runtime; no está seleccionada en el portátil actual. Proton VPN es una unidad de usuario independiente. **No se comprobaron coexistencia Proton/IPsec, fugas DNS, kill switch, IPv6, reconnect ni alcance de rutas**. Requieren una sesión de red controlada y pruebas antes/durante/después de conectar, no inferencias a partir de nombres de opciones.

## 9. Recursos, rendimiento y estabilidad

### 9.1 Muestras del PC

| Métrica | Observación | Limitación |
|---|---|---|
| RAM | 62 GiB totales; al cierre aproximadamente 7,8 GiB usados y 54 GiB disponibles | Muestra de sesión; caché recuperable no es fuga |
| Swap | 0 en runtime; PC sin swap/zram declarados | No hubo presión que demostrase necesidad inmediata |
| Raíz / ESP | 56 % / 9 % usados; aproximadamente 144 GiB libres en raíz | Después de construcciones; no atribuir el crecimiento a un único paquete |
| Quickshell | Aproximadamente 1.018 MiB RSS; 0 % de un núcleo durante una ventana de 5 s | RSS incluye memoria compartida; una muestra no demuestra fuga ni rendimiento sostenido |
| GPU | RTX 4080 SUPER, 16.376 MiB; muestra con 2.593 MiB usados, 8 % de utilización y 59,30 W | Aplicaciones abiertas; no es un baseline idle ni consumo exclusivo de Caelestia |
| Ollama | Activo; aproximadamente 328 MiB según `MemoryCurrent` en una muestra | No se ejecutó ni midió inferencia |
| Arranque | 31,659 s total; 8,910 s userspace; 15,179 s firmware | Un arranque, no comparación A/B |

El resultado de `systemd-analyze blame` no debe sumarse como si todas las unidades fueran secuenciales ni convertir servicios disparados después en responsables de la ruta crítica. NetworkManager-wait-online aparece alrededor de cinco segundos, pero hay consumidores de red como el loader de modelos; no se justifica deshabilitarlo sin estudiar dependencias.

Al cierre, `systemctl --failed` y `systemctl --user --failed` mostraban cero unidades fallidas. Hay un fallo de probe `mt76x2u` con código `-110` en el journal del kernel; el dispositivo fue identificado como un receptor Xbox, no como evidencia de que la Wi-Fi del portátil falle. No se diagnosticó ni probó su uso, y no se propone alterar drivers por ese único mensaje.

### 9.2 Tamaño y optimizaciones justificadas

Las closures de los sistemas construidos son **31.941.872.560 bytes —29,75 GiB— para PC** y **30.165.263.240 bytes —28,09 GiB— para laptop**, según `nix path-info --closure-size`. Es tamaño NAR de la closure, no uso físico exclusivo de disco: comparten numerosas rutas del store. Tampoco incluyen automáticamente todos los pesos de modelos runtime.

Hay herramientas pesadas —CUDA, Qt, IDE, navegadores, SDK— acordes con la función de workstation. No hay evidencia para prometer grandes ahorros eliminando líneas duplicadas de `home.packages`: una ruta idéntica del store no ocupa dos veces disco ni RAM por estar en dos listas.

El governor `performance` del PC es una elección explícita. El portátil no tiene simultáneamente TLP, auto-cpufreq y power-profiles-daemon compitiendo. Cualquier ajuste energético requiere medir frecuencia, consumo y latencia sobre el equipo correspondiente; no se recomienda cambiar por una preferencia genérica.

## 10. Simplificaciones y oportunidades, sin rediseño innecesario

Estas actuaciones son secundarias frente a los hallazgos anteriores. No implican que la práctica actual sea inválida por ser poco habitual.

| ID | Propuesta y evidencia | Beneficio real esperado | Coste / riesgo |
|---|---|---|---|
| O01 | Consolidar las tres variantes Rust de checks en `modules/ai/herd/package.nix:39–78`, conservando los filtros `terminal_browser`, `row_gap`, `merge_delete` y sus fixtures | Menos derivaciones/compilaciones similares; ejecutar los filtros sobre un mismo árbol de build o una suite común | Medio / bajo-medio; comparar cobertura y aislamiento. No se midió el ahorro final |
| O02 | Revalidar `nomodeset`, cursor y otros workarounds NVIDIA por separado [§7] | Retirar solo incompatibilidades ya resueltas; aclarar motivos y condiciones de retirada | Medio / medio-alto por necesidad de una sesión/arranque de prueba |
| O03 | Comprobar orden DRM del portátil y usar enlaces estables solo si hace falta | Evitar que un cambio de enumeración altere la GPU preferida | Bajo-medio / medio; no hay fallo runtime del portátil demostrado |
| O04 | Registrar digest del modelo Ollama y política de actualización, junto a la etiqueta declarada en `hosts/nixos-pc/default.nix:28` | Reproducción de pesos y trazabilidad sin meter decenas de GB en la flake por defecto | Bajo / bajo; no activar `syncModels` si puede borrar modelos no declarados |
| O05 | Elegir un propietario de cada paquete: bat/btop/delta, fuentes/cursor y VA-API donde el módulo ya los instala | Listas más claras y menor deriva; **no** ahorro doble de una misma ruta | Bajo / bajo; verificar que el módulo permanezca habilitado antes de quitar entradas |
| O06 | Retirar `herdr-projects` de `flake.nix:71–74` si ya no tiene función | Menos fuente/input y superficie de actualización; no ahorro runtime demostrado | Bajo / bajo; búsqueda solo encuentra su declaración y lock; `nix why-depends` confirma que el sistema PC no depende de su fuente |
| O07 | Retirar o documentar el módulo Hyprpaper deshabilitado (`modules/desktop/hyprland/hyprpaper.nix:3–14`) y `HISTSIZE`/`SAVEHIST` de Fish (`modules/shell/fish.nix:189–190`) | Menos configuración inerte: esas variables no controlan el historial nativo de Fish | Bajo / bajo; comprobar si se exportaban deliberadamente para shells hijos |
| O08 | Corregir el enlace a `pi-statusline.md` en `docs/architecture.md:122`, cuyo destino local no existe | Documentación navegable; un fallo verificable y barato de corregir | Muy bajo / bajo |

No se propone crear opciones `enable` para cada archivo, un generador de hosts, una matriz de roles especulativa o un framework de scripts compartidos sin necesidad real. El registro de módulos y los fixtures headless existentes ya proporcionan una separación útil y verificable.

## 11. Comprobaciones ejecutadas y resultados

### 11.1 Evaluación y construcción

| Comprobación | Resultado | Qué demuestra / qué no |
|---|---|---|
| Parseo con `nix-instantiate --parse` de 54 archivos Nix | 54/54 correctos | Sintaxis; no semántica del hardware |
| `nix flake show --no-write-lock-file --all-systems .` | Correcto | Salidas declaradas; no activación |
| `nix flake check --no-build --no-write-lock-file .` | Correcto | Evaluación de hosts y checks; no ejecución de sus builders |
| `nix build --no-link --no-write-lock-file …nixos-pc…system.build.toplevel` | Salida 0 | Sistema construible en este entorno |
| Igual para `nixos-laptop` | Salida 0 | Sistema construible, no arrancado en el portátil |
| `nix flake check --no-write-lock-file` completo, con límite | Salida 1, fallo de `herdr-theme` | No existe una suite completa verde |

La advertencia `unknown flake output 'modules'` es esperable por el registro de flake-parts. No es el motivo del fallo de Herdr.

Las construcciones se limitaron normalmente con `--max-jobs 2 --cores 2`, `--no-link` y timeouts. La repetición final de ambos toplevels dio salida 0 usando resultados ya disponibles. No se ejecutó `switch`, `boot`, `test` de nixos-rebuild ni activación independiente de HM.

### 11.2 Checks individuales

| Check `checks.x86_64-linux.*` | Resultado confirmado |
|---|---|
| `architecture` | Correcto, salida 0 |
| `hyprland-overrides` | Correcto, salida 0 |
| `networking-and-access` | Correcto, salida 0 |
| `desktop-scripts` | Correcto, salida 0 |
| `diff-pager-themes` | Correcto, salida 0 |
| `herdr-worktree-tools` | Correcto, salida 0; log con 33 tests Python |
| `terminal-browser` | Correcto, salida 0 |
| `herdr-theme` | **Falla**, salida 1 [F03] |
| `herdr-terminal-browser-menu` | Evaluado; sin resultado construido válido al cierre |
| `herdr-sidebar-spacing` | Evaluado; sin resultado construido válido al cierre |
| `herdr-worktree-menu` | Evaluado; sin resultado construido válido al cierre |

**Balance de los checks conservados en este informe:** siete correctos, uno fallido y tres no completados/verificados. La ejecución completa inició trabajo de dependencias Rust, pero el fallo anterior impide afirmar que los tres checks Rust hayan pasado o que sus tests hayan fallado. No se presentan cancelaciones o errores de consultas exploratorias como defectos del repositorio.

Los checks CLI de Herdr/browser son principalmente smoke tests de empaquetado/versiones, no sesiones interactivas completas.

### 11.3 Pruebas de inspección y seguridad

- Estado y propiedades de unidades del sistema y de usuario; cero unidades fallidas al cierre.
- Journal de Home Manager, journal gráfico y mensajes seleccionados del kernel.
- Comparación de archivos HM, enlaces, backups y DAG de activación.
- Resolución/versión de Hunk declarativo e imperativo; inventario de perfil sin modificación.
- Escucha TCP, opciones de firewall/SSH/Nix y permisos del socket Docker.
- Entorno de usuario y procesos, **seleccionando nombres de variables conocidos**, no volcando el entorno completo.
- Cgroups de Quickshell y Firefox, parámetros NVIDIA, driver instalado y metadatos de IntelliJ.
- Validación de JSON real limitada al tipo/parseo, y errores sintéticos en memoria [F10].
- Búsqueda de secretos en árbol e historia sin divulgar valores; exclusión de `.env` en la fuente Git real.
- Espacio/memoria, muestra de CPU, métricas GPU y tiempos de arranque.

### 11.4 Reproducción mínima de las evidencias principales

Estos comandos no activan configuraciones. Las construcciones usan el store y pueden ser costosas; las consultas no necesitan imprimir secretos. Los PID concretos del informe pertenecen a esta sesión: para repetir la inspección hay que identificar los actuales.

```sh
# Estado de Home Manager, política de terminación y cgroups —F04/F05 y §5—.
systemctl show home-manager-elliot.service \
  -p ActiveState -p Result -p ExecMainStatus -p User -p Type
systemctl --user show caelestia.service \
  -p MainPID -p ControlGroup -p KillMode -p TimeoutStopUSec -p SendSIGKILL
ps -u "$USER" -o pid,ppid,comm,cgroup
test -e /etc/pam.d/hyprlock; printf 'PAM hyprlock: salida=%s\n' "$?"

# Deriva de ejecutable y observabilidad —F06/F09—.
which -a hunk
"$HOME/.nix-profile/bin/hunk" --version
/etc/profiles/per-user/elliot/bin/hunk --version
systemctl log-level
systemctl log-target

# Escucha y herencia de variables conocidas —F07/F11—.
ss -H -lnt
systemctl --user show-environment | grep -E '^(JAVA_HOME|JDK_JAVA_OPTIONS|EDITOR)='

# Ambos sistemas, sin aplicar el resultado.
nix build --no-link --no-write-lock-file --max-jobs 2 --cores 2 \
  .#nixosConfigurations.nixos-pc.config.system.build.toplevel \
  .#nixosConfigurations.nixos-laptop.config.system.build.toplevel
```

Para contrastar la política de ambos hosts sin inspeccionar archivos privados:

```sh
nix eval --json --no-write-lock-file .#nixosConfigurations --apply '
  builtins.mapAttrs (_: s:
    let c = s.config; h = c.home-manager.users.elliot;
    in {
      autologinUser = c.services.greetd.settings.initial_session.user;
      lockBeforeSleep = h.programs.caelestia.settings.general.idle.lockBeforeSleep;
      docker = c.virtualisation.docker.enable;
      rootless = c.virtualisation.docker.rootless.enable;
      groups = c.users.users.elliot.extraGroups;
      hyprlockPam = c.security.pam.services ? hyprlock;
      sshPassword = c.services.openssh.settings.PasswordAuthentication;
      sshKeyboardInteractive = c.services.openssh.settings.KbdInteractiveAuthentication;
      ideaVersion = s.pkgs.jetbrains.idea.version;
      bunVersion = s.pkgs.bun.version;
    })'
```

Los casos sintéticos de F10 usan el código de los archivos citados, sustituyendo `pathlib.Path` por un objeto en memoria con `read_text` y escritura real prohibida. No deben reproducirse corrompiendo el `settings.json` o `config.json` del usuario.

## 12. Límites y verificaciones pendientes

1. **Solo PC en ejecución.** No hay acceso runtime demostrado al portátil: GPU, buses PCI, nodos DRM, batería, tapa, Wi-Fi, suspensión y consumo requieren ese equipo.
2. **Sin activación.** No se certifica el resultado de aplicar el árbol sucio sobre el sistema actual. Una activación puede fallar por datos mutables aunque el toplevel construya.
3. **Sin bloqueo/desbloqueo o suspensión.** No se comprobó contraseña, PAM real, lock antes de dormir, VRAM tras resume o recuperación de aplicaciones.
4. **Sin reiniciar Caelestia.** La consecuencia de `KillMode` se deriva de pertenencia observada y semántica documentada, no de una prueba destructiva sobre aplicaciones abiertas.
5. **Sin conexiones de red activas de prueba.** No se validaron SSH remoto, Mosh, LocalSend, campus VPN, 2FA, Proton, rutas, DNS o exposición desde Internet.
6. **Sin inferencia/descarga de modelos.** No hay conclusión sobre calidad, latencia, tokens/s, compatibilidad de cada cliente o suficiencia de VRAM para el modelo seleccionado. La cuantización y el offload impiden deducirlo solo del nombre «27b».
7. **Sin benchmark gráfico o energético.** No se atribuyen fugas a una muestra de RSS ni se prometen mejoras de animaciones, cursores o potencia sin A/B.
8. **Suite incompleta.** Los tres checks Rust y las pruebas SDK/typecheck de Pi no tienen un resultado positivo de esta auditoría. No se hizo una reconstrucción independiente de todos los paquetes desde cero ni comparación bit a bit de ambos sistemas.
9. **Secretos y privilegios.** El análisis de patrones no cubre todos los formatos de secretos, repos externos, historial borrado, copias de seguridad ni memoria de procesos. No se hizo pentest, escalada Docker ni revisión completa de advisories/CVE de todas las dependencias.
10. **Visibilidad parcial.** Se evitaron elevaciones innecesarias. Algunos archivos de procesos —por ejemplo el entorno del compositor— no eran legibles con el usuario actual. No se infiere su contenido a partir de otros procesos.
11. **Logs extensos y cachés.** Algunas salidas de builds quedaron truncadas en la interfaz; los resultados finales se confirmaron con consultas de outputs y repeticiones acotadas. No se usó una salida truncada para inventar un éxito.

## 13. Hoja de ruta por impacto y esfuerzo

### P0 — Acordar políticas de acceso y evitar pérdida de trabajo

1. **F01:** definir qué hosts necesitan autenticación inicial y bloqueo antes de suspender. Corregir primero la ruta de autenticación/recuperación y después probar el ciclo completo.
2. **F02:** decidir si el usuario que ejecuta agentes puede administrar el host vía Docker. Si no, diseñar una migración rootless/aislada con inventario de datos, sin retirar privilegios a ciegas.
3. **F05:** hasta separar cgroups, no tratar un reinicio de Caelestia como una operación inocua sobre aplicaciones abiertas. Resolver el lanzamiento en scopes y ensayarlo con una aplicación descartable.

**Esfuerzo:** de medio día a un día de trabajo y pruebas, dependiendo de Docker/launcher. **Salida exigible:** política escrita y pruebas físicas/operativas, no solo un build verde.

### P1 — Recuperar señal de validación y capacidad de diagnóstico

1. **F03:** alinear Lazygit/configuración/check y lograr su check verde.
2. **F04:** decidir si Hyprlock se conserva; configurar PAM si se usa y probar desbloqueo con recuperación.
3. **F08/F09:** recuperar fsck normal y logging útil, mediante arranque de mantenimiento.
4. Completar los tres checks Rust, distinguiendo coste de construcción y fallos de tests. Si se consolidan [O01], mantener los mismos casos.

**Esfuerzo:** 2–4 h de cambios/pruebas, más compilaciones y un reinicio planificado. **Salida exigible:** `nix flake check` completo con todos sus resultados y logs conservados.

### P2 — Reducir deriva entre lo declarado y lo ejecutado

1. **F06:** revisar el Hunk imperativo y los experimentos que aún deben permanecer.
2. **F10:** endurecer reconciliadores mutables y añadir pruebas de JSON/tipos/escritura.
3. **F07:** revisar SSH por host, verificar claves y solo después endurecer autenticación o red.
4. **F11/F12:** verificar la ruta de lanzamiento Java y las opciones reales de IntelliJ.

**Esfuerzo:** medio día. **Salida exigible:** ejecutables resueltos esperados, activación ensayada con fixtures adversos y acceso SSH de recuperación conservado.

### P3 — Simplificación con beneficio comprobable

1. **F13/O02:** revalidar workarounds de Bun/NVIDIA de forma independiente.
2. **O03:** verificar GPU/energía en el portátil, no extrapolar el PC.
3. **O04–O09:** registrar digest de modelos, eliminar entradas sin función real, corregir documentación y aclarar cobertura SDK.
4. Revisar follows solo si se demuestra reducción de evaluación/construcción o mejora de mantenimiento sin comprometer las versiones alineadas del stack gráfico.

**Esfuerzo:** pequeños cambios independientes, algunos sujetos a hardware. **Salida exigible:** menos excepciones con motivo desconocido, sin un framework adicional ni promesas de ahorro no medidas.

## 14. Referencias oficiales y upstream contrastadas

- [Home Manager: Hyprlock, revisión fijada](https://github.com/nix-community/home-manager/blob/92a0ed1be12f1e20093faf8af63bae2c74ad521e/modules/programs/hyprlock.nix): requisito PAM de NixOS.
- [Home Manager: detección de colisiones, revisión fijada](https://github.com/nix-community/home-manager/blob/92a0ed1be12f1e20093faf8af63bae2c74ad521e/modules/files/check-link-targets.sh): archivos ajenos, backups y rechazo de sobrescritura.
- [Home Manager: integración NixOS, revisión fijada](https://github.com/nix-community/home-manager/blob/92a0ed1be12f1e20093faf8af63bae2c74ad521e/nixos/default.nix): unidad de activación de usuario.
- [Caelestia: IdleMonitors.qml, revisión fijada](https://github.com/caelestia-dots/shell/blob/6d3e6a96492b0e9c668464875ac34150113ede5f/modules/IdleMonitors.qml): condicionamiento de `onAboutToSleep`.
- [Caelestia: Apps.qml, revisión fijada](https://github.com/caelestia-dots/shell/blob/6d3e6a96492b0e9c668464875ac34150113ede5f/modules/launcher/services/Apps.qml) y `modules/lock/Pam.qml`: lanzamiento y PAM propios.
- [NixOS: módulo NVIDIA, revisión fijada](https://github.com/NixOS/nixpkgs/blob/7fd4004d0511991fff3a0524856a9be09e28c5f0/nixos/modules/hardware/video/nvidia.nix): notifier del kernel y activación de VA-API.
- [NVIDIA 615.71.09: gestión de energía](https://download.nvidia.com/XFree86/Linux-x86_64/615.71.09/README/powermanagement.html): módulos abiertos, conservación de memoria y suspensión.
- [systemd.kill](https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html): alcance de `KillMode=control-group` y terminación forzada.
- [systemd-fsck](https://www.freedesktop.org/software/systemd/man/latest/systemd-fsck@.service.html): `fsck.mode` y `fsck.repair`.
- [systemd, parámetros del gestor](https://www.freedesktop.org/software/systemd/man/latest/systemd.html): niveles y destinos de logging frente a salida de servicios.
- [Docker: grupo docker y privilegios](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user): autoridad root-equivalente del acceso al daemon rootful.
- [NixOS: módulo Ollama, revisión fijada](https://github.com/NixOS/nixpkgs/blob/7fd4004d0511991fff3a0524856a9be09e28c5f0/nixos/modules/services/misc/ollama.nix): listener, loader, `pull` y sincronización de modelos.

**Conclusión:** no hace falta reescribir la arquitectura. El mayor retorno está en cerrar unas pocas diferencias entre configuración, estado mutable, propiedad de procesos y política de acceso; después, en restaurar una suite completa y conservar evidencia de las pruebas que necesariamente deben hacerse sobre hardware y una sesión real.
