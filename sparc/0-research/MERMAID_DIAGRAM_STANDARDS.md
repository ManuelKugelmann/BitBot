# Mermaid Diagram Standards

BitBot's standard color scheme and formatting for mermaid diagrams.

## Color Scheme

Simplified from FLOW_INNER_BITBOT:

```
Entry/CLI:       #4a9eff  (blue)     - User input, CLI, entry points
Decisions:       #ffa726  (orange)   - Prompts, checks, config, warnings
Success/Work:    #66bb6a  (green)    - Work mode, done, safe operations
Errors:          #ef5350  (red)      - Errors only
```

## Text Color Rules

- **Blue (#4a9eff)**: No color needed (dark enough)
- **Orange (#ffa726)**: ALWAYS add `color:#333` (dark text on bright background)
- **Green (#66bb6a)**: ALWAYS add `color:#333` (dark text on bright background)
- **Red (#ef5350)**: ALWAYS add `color:#333` (dark text on bright background)
- **Format**: `fill:#COLOR,stroke:#333,stroke-width:2px,color:#333`

## Width Guidelines

Keep diagrams narrow (~60 chars per line) for terminal viewing

## Node Ordering

**IMPORTANT**: In Mermaid, the order you define nodes/edges determines layout:
- **TB (top-bottom)**: Order defines columns (left to right)
- **LR (left-right)**: Order defines rows (top to bottom)

Define nodes in the order you want them to appear spatially to avoid crossing lines.

## Example

```mermaid
graph LR
    A[User Input] --> B[Decision]
    B --> C[Work Mode]
    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style B fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style C fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```

## See Also

- `sparc/3-architecture/diagrams/` - Example diagrams following these standards
