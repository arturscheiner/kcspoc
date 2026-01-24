> This architecture is mandatory. New code MUST follow these rules.
> Legacy code may be migrated incrementally.

# kcspoc MVC Architecture

Starting from v0.6.0, kcspoc follows a strict Model-View-Controller (MVC) architecture to ensure maintainability, testability, and clarity.

## 📐 Architecture Layers

### 🎮 Controller (`lib/control/`)
- **Intent**: Orchestrates the high-level flow of a command.
- **Rules**:
    - Parses CLI flags and arguments.
    - Calls Services to perform business logic.
    - Selects Views to display messages.
    - **Prohibited**: Direct `kubectl` calls, direct `echo`/`printf` (except for raw data output if required).

### ⚙️ Service (`lib/service/`)
- **Intent**: Contains "how" the business logic works.
- **Rules**:
    - Implements idempotency (e.g., "ensure X exists").
    - Coordinates multiple Model calls.
    - **Prohibited**: UI output, CLI argument parsing.

### 📦 Model (`lib/model/`)
- **Intent**: The single source of truth for external state (K8s, FS, Env).
- **Rules**:
    - Wraps system-level commands (e.g., `kubectl`, `sed`, `git`).
    - Abstracts filesystem operations.
    - **Prohibited**: Business logic decisions, UI output.

### 🎨 View (`lib/view/`)
- **Intent**: Defines the look and feel of the application.
- **Rules**:
    - Handles all formatting, colors, and iconography.
    - Provides consistent UI primitives (banners, sections, steps).
    - **Prohibited**: Business logic, state changes.

---

## 🌊 Flow Convention
All command execution MUST follow this directional flow:
**Controller** ⮕ **Service** ⮕ **Model** (⮕ View via Controller/Service)

## 🛠 Planned Automated Sourcing (Proposal)
To avoid manual `source` calls for every new component, `kcspoc.sh` will be updated to automatically source all `.sh` files under the MVC directories:

```bash
# Example sourcing pattern
for layer in control service model view; do
    for component in "$LIB_DIR/$layer"/*.sh; do
        [ -f "$component" ] && source "$component"
    done
done
```
