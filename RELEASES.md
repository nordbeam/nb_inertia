# NbInertia Release & Deployment Guide

Complete guide for deploying NbInertia applications with Server-Side Rendering (SSR) in production.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Configuration Details](#configuration-details)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Testing Releases Locally](#testing-releases-locally)
- [Migration Guide](#migration-guide)
- [Best Practices](#best-practices)

## Overview

NbInertia is designed to work seamlessly in Mix releases with minimal configuration:

1. **Clean Module Integration**: Provides `Inertia.SSR` as a compatibility shim delegating to `NbInertia.SSR` with DenoRider-based SSR
2. **Automatic Path Resolution**: SSR script paths resolved at runtime using `:code.priv_dir/1`
3. **Zero-Config Default**: No manual path configuration needed - automatically inferred from endpoint module
4. **Production Ready**: Optimized for Docker, Fly.io, Gigalixir, and traditional VPS deployments

### Module Redefining Warning (Expected Behavior)

You may see this warning during compilation:

```
warning: redefining module Inertia.SSR (current version loaded from _build/dev/lib/inertia/ebin/Elixir.Inertia.SSR.beam)
```

**This is expected and safe.** nb_inertia intentionally overrides `Inertia.SSR` from the base inertia library to provide DenoRider-based SSR instead of NodeJS-based SSR. The warning can be safely ignored - it's Elixir informing you that we're replacing the module, which is exactly what we want.

In releases, only one version of the module will be included (nb_inertia's version), so there's no runtime conflict.

## Quick Start

### 1. Configure NbInertia

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,
  ssr: [
    enabled: true,
    raise_on_failure: config_env() != :prod,
    dev_server_url: "http://localhost:5173"  # Optional: Vite dev server
  ]
```

**Important:**
- `endpoint` is required for automatic path resolution
- `raise_on_failure: false` in production allows graceful fallback to client-side rendering
- SSR errors in development/test will raise for easier debugging

### 2. Add SSR to Supervision Tree

Ensure `NbInertia.SSR` is in your application's supervision tree:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    # ... other children
    MyAppWeb.Endpoint,
    NbInertia.SSR  # Add this for SSR support
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

**Note:** This should be added automatically by `mix nb_inertia.install --ssr`.

### 3. Build Assets

Build your client and SSR bundles:

```bash
cd assets
npm run build        # or: bun run build
npm run build:ssr    # or: bun run build:ssr
cd ..
```

This creates:
- `priv/static/assets/app.js` - Client bundle
- `priv/static/ssr.js` - SSR bundle (for DenoRider)

**Vite Configuration Example:**

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        app: './js/app.jsx',
      },
    },
    outDir: '../priv/static/assets',
  },
})

// vite.ssr.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    ssr: true,
    rollupOptions: {
      input: './js/ssr.jsx',
    },
    outDir: '../priv/static',
  },
})
```

### 4. Build Release

```bash
MIX_ENV=prod mix release
```

The SSR bundle is automatically included in your release's priv directory.

### 5. Run Release

```bash
# Start in foreground
_build/prod/rel/my_app/bin/my_app start

# Or with console for debugging
_build/prod/rel/my_app/bin/my_app console

# Or as daemon
_build/prod/rel/my_app/bin/my_app daemon
```

## Configuration Details

### SSR Configuration Options

```elixir
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,  # Required for automatic path resolution
  ssr: [
    enabled: true,                                    # Enable SSR
    raise_on_failure: config_env() != :prod,         # Raise on SSR errors (default: true)
    script_path: nil,                                 # Optional: Override default path
    dev_server_url: "http://localhost:5173"          # Optional: Dev server URL
  ]
```

### Automatic Path Resolution

By default, `script_path` is automatically resolved to:

```
<your_app_priv_dir>/static/ssr.js
```

This works because:
1. nb_inertia reads your `:endpoint` config (e.g., `MyAppWeb.Endpoint`)
2. It infers your app name from the endpoint module (e.g., `MyAppWeb.Endpoint` → `:my_app`)
3. It uses `:code.priv_dir(:my_app)` to get the correct priv directory at runtime
4. In development: `/Users/you/my_app/priv/static/ssr.js`
5. In releases: `/app/lib/my_app-0.1.0/priv/static/ssr.js`

### Manual Path Configuration (Not Recommended)

If you need to override the automatic path resolution:

```elixir
config :nb_inertia,
  ssr: [
    enabled: true,
    script_path: "/custom/path/to/ssr.js"
  ]
```

**Warning**: Manual paths will not work correctly in releases unless you use runtime configuration.

## Troubleshooting

### Issue: SSR Not Working in Release

**Symptoms**: Pages render without SSR, or you see errors about missing SSR script.

**Solutions**:

1. **Verify the SSR bundle exists**:

   ```bash
   # Find your release directory
   ls _build/prod/rel/my_app/lib/my_app-*/priv/static/ssr.js
   ```

2. **Check SSR initialization logs**:

   Look for log messages when your app starts:

   ```
   [info] SSR: Using production bundle at /app/lib/my_app-0.1.0/priv/static/ssr.js
   ```

   If you see an error or warning, it means SSR couldn't find the script.

3. **Verify endpoint configuration**:

   Make sure you have configured `:endpoint` in your nb_inertia config:

   ```elixir
   config :nb_inertia,
     endpoint: MyAppWeb.Endpoint
   ```

4. **Check supervision tree**:

   Ensure `NbInertia.SSR` is in your application's supervision tree:

   ```elixir
   # lib/my_app/application.ex
   def start(_type, _args) do
     children = [
       # ... other children
       NbInertia.SSR
     ]
   end
   ```

   This should be added automatically by the `mix nb_inertia.install --ssr` command.

5. **Rebuild assets and release**:

   ```bash
   cd assets && npm run build:ssr
   cd .. && MIX_ENV=prod mix release --overwrite
   ```

### Issue: "Redefining module Inertia.SSR" Warning

**Symptoms**: You see a warning during compilation about redefining `Inertia.SSR`.

**Solution**: This is expected and safe behavior. nb_inertia intentionally overrides `Inertia.SSR` from the base inertia library to provide DenoRider-based SSR. The warning can be safely ignored. See the "Module Redefining Warning" section above for more details.

### Issue: Wrong Path in Logs

**Symptoms**: You see a path like `/Users/you/my_app/priv/static/ssr.js` in production logs.

**Solution**: This indicates you may have configured `script_path` with a compile-time path in your config.exs. Remove the explicit `script_path` configuration and let nb_inertia auto-detect it:

```elixir
# Before (problematic)
config :nb_inertia,
  ssr: [
    enabled: true,
    script_path: Path.join([__DIR__, "..", "priv", "static", "ssr.js"])  # ❌ Compile-time path
  ]

# After (correct)
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,  # Required for path inference
  ssr: [
    enabled: true  # ✅ Path is auto-detected at runtime
  ]
```

## Advanced Configuration

### Using a Different App Name

If your app structure is non-standard (e.g., umbrella app), you may need to explicitly configure the script path using runtime configuration:

```elixir
# config/runtime.exs
config :nb_inertia,
  ssr: [
    enabled: true,
    script_path: Path.join(:code.priv_dir(:my_custom_app), "static/ssr.js")
  ]
```

### SSR in Docker

When deploying with Docker, ensure:

1. Your Dockerfile builds the SSR bundle:

   ```dockerfile
   RUN cd assets && npm run build && npm run build:ssr
   ```

2. The priv directory is copied to the release:

   ```dockerfile
   COPY priv priv
   ```

3. The release includes the priv directory (default behavior):

   ```elixir
   # mix.exs - no special configuration needed
   def project do
     [
       # ...
       releases: [
         my_app: [
           # priv is included by default
         ]
       ]
     ]
   end
   ```

## Testing Releases Locally

Before deploying, test your release locally:

```bash
# Build release
MIX_ENV=prod mix release --overwrite

# Run release
_build/prod/rel/my_app/bin/my_app start

# Or run in foreground with console
_build/prod/rel/my_app/bin/my_app console
```

Then visit your app and:
1. Check that pages render correctly
2. View page source - you should see server-rendered HTML
3. Check logs for SSR initialization messages

## Migration Guide

If you're upgrading from an older version of nb_inertia:

### Remove Manual Script Path Configuration

**Before**:
```elixir
config :nb_inertia,
  ssr: [
    enabled: true,
    script_path: Path.join([__DIR__, "..", "priv", "static", "ssr.js"])
  ]
```

**After**:
```elixir
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,  # Add endpoint config
  ssr: [
    enabled: true  # Remove script_path - it's auto-detected
  ]
```

### No Manual Changes Needed

The compatibility shim `Inertia.SSR` is provided by nb_inertia and delegates to `NbInertia.SSR` automatically. You don't need to create or remove any files.

## Best Practices

1. **Always configure the endpoint**: This is required for automatic path resolution
2. **Use environment-based raise_on_failure**: Raise errors in dev/test, gracefully degrade in prod
3. **Test releases locally**: Don't wait for production to discover release issues
4. **Check logs**: SSR logs important information about initialization
5. **Keep SSR bundle small**: Use code splitting and tree shaking in your bundler config

## Further Reading

- [NbInertia.SSR Module Documentation](https://hexdocs.pm/nb_inertia/NbInertia.SSR.html)
- [Mix Release Documentation](https://hexdocs.pm/mix/Mix.Tasks.Release.html)
- [Elixir Releases Guide](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html)
