# CI/CD Guide for TypeScript Type Generation

Strategies for keeping TypeScript types in sync with your backend in CI/CD pipelines.

## The Problem

When using nb_ts for TypeScript type generation, types can become stale if:
- Backend prop definitions change
- New serializers are added
- Inertia pages are modified

**Without CI checks**, you might deploy with:
- ✅ Backend expecting certain props
- ❌ Frontend using outdated TypeScript types
- 💥 Runtime errors in production

## The Solution

Add CI/CD checks to ensure types are always up to date.

---

## Strategy 1: Fail CI on Stale Types (Recommended)

**Best for:** Teams that want strict type safety.

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.16'
          otp-version: '26'

      - name: Install dependencies
        run: mix deps.get

      - name: Compile
        run: mix compile --warnings-as-errors

      - name: Generate TypeScript types
        run: mix nb_ts.gen.types

      - name: Check types are up to date
        run: |
          if [ -n "$(git status --porcelain assets/js/types/)" ]; then
            echo "❌ TypeScript types are out of date!"
            echo ""
            echo "Generated types differ from committed types."
            echo "Run 'mix nb_ts.gen.types' and commit the changes."
            echo ""
            git diff assets/js/types/
            exit 1
          fi
          echo "✅ TypeScript types are up to date"

      - name: Run tests
        run: mix test
```

**How it works:**
1. Generates fresh TypeScript types
2. Checks if generated types differ from committed types
3. Fails CI if types are stale
4. Shows diff to help developer fix the issue

**Developer workflow:**
```bash
# Make backend changes
vim lib/my_app_web/controllers/user_controller.ex

# Regenerate types
mix nb_ts.gen.types

# Commit both backend and types together
git add lib/ assets/js/types/
git commit -m "Add user role prop"
```

---

## Strategy 2: Auto-Generate and Commit Types

**Best for:** Teams that want automated type updates.

### GitHub Actions with Auto-Commit

```yaml
# .github/workflows/generate-types.yml
name: Generate TypeScript Types

on:
  push:
    branches: [main, develop]
    paths:
      - 'lib/**/*.ex'  # Only run when Elixir files change

jobs:
  generate-types:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.16'
          otp-version: '26'

      - name: Install dependencies
        run: mix deps.get

      - name: Generate TypeScript types
        run: mix nb_ts.gen.types

      - name: Commit changes if any
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"

          if [ -n "$(git status --porcelain assets/js/types/)" ]; then
            git add assets/js/types/
            git commit -m "chore: regenerate TypeScript types [skip ci]"
            git push
            echo "✅ TypeScript types updated and committed"
          else
            echo "✅ TypeScript types already up to date"
          fi
```

**How it works:**
1. Triggers when Elixir files change
2. Generates fresh types
3. Auto-commits if types changed
4. Uses `[skip ci]` to avoid infinite loop

**⚠️ Trade-offs:**
- ✅ No manual type regeneration needed
- ❌ Creates extra commits
- ❌ Can cause merge conflicts
- ❌ Types committed after PR is merged (not before)

---

## Strategy 3: Pre-Commit Hooks (Local)

**Best for:** Preventing stale types from being committed.

### Using Husky (Node.js)

```json
// package.json
{
  "scripts": {
    "types": "cd .. && mix nb_ts.gen.types"
  },
  "husky": {
    "hooks": {
      "pre-commit": "npm run types && git add assets/js/types/"
    }
  }
}
```

### Using Elixir Hooks

```bash
# .git/hooks/pre-commit
#!/bin/sh

echo "🔄 Regenerating TypeScript types..."
mix nb_ts.gen.types

# Check if types changed
if [ -n "$(git diff --cached --name-only | grep 'assets/js/types/')" ]; then
  echo "📝 TypeScript types updated, adding to commit..."
  git add assets/js/types/
fi

echo "✅ Pre-commit hook complete"
```

**How it works:**
1. Runs before every commit
2. Regenerates types
3. Adds changed types to the commit

**⚠️ Trade-offs:**
- ✅ Types always in sync
- ❌ Slows down commits (~1-2s)
- ❌ Requires setup on every developer's machine

---

## Strategy 4: GitLab CI

```yaml
# .gitlab-ci.yml
check-types:
  stage: test
  image: elixir:1.16
  before_script:
    - mix local.hex --force
    - mix local.rebar --force
    - mix deps.get
  script:
    - mix compile
    - mix nb_ts.gen.types
    - |
      if [ -n "$(git status --porcelain assets/js/types/)" ]; then
        echo "❌ TypeScript types are out of date!"
        echo "Run 'mix nb_ts.gen.types' and commit changes."
        git diff assets/js/types/
        exit 1
      fi
    - echo "✅ TypeScript types are up to date"
```

---

## Strategy 5: Make Task (Manual)

**Best for:** Small teams or personal projects.

### Makefile

```makefile
# Makefile
.PHONY: types check-types

types:
	@echo "🔄 Generating TypeScript types..."
	@mix nb_ts.gen.types
	@echo "✅ Types generated"

check-types:
	@echo "🔍 Checking TypeScript types..."
	@mix nb_ts.gen.types
	@if [ -n "$$(git status --porcelain assets/js/types/)" ]; then \
		echo "❌ Types are out of date!"; \
		git diff assets/js/types/; \
		exit 1; \
	fi
	@echo "✅ Types are up to date"

dev:
	@make types
	@mix phx.server

ci:
	@mix deps.get
	@mix compile
	@make check-types
	@mix test
```

**Usage:**
```bash
make types        # Generate types
make check-types  # Verify types are current
make dev          # Generate types and start server
make ci           # Run full CI checks
```

---

## Best Practices

### 1. Commit Types with Backend Changes

Always commit both together:

```bash
git add lib/my_app_web/controllers/
git add assets/js/types/
git commit -m "Add user profile endpoint with TypeScript types"
```

### 2. Document Type Generation in README

Add to your project's README:

```markdown
## TypeScript Types

TypeScript types are auto-generated from backend code.

### Generating Types

```bash
mix nb_ts.gen.types
```

### CI/CD

Our CI pipeline checks that types are up to date. If CI fails:

1. Run `mix nb_ts.gen.types`
2. Commit the changes: `git add assets/js/types/ && git commit -m "Update TS types"`
3. Push again
```

### 3. Add Types Directory to .gitignore (Optional)

**If using auto-generation CI:**

```gitignore
# .gitignore
assets/js/types/
```

Then types are generated fresh in CI and production builds.

**⚠️ Trade-off:**
- ✅ No merge conflicts on types
- ❌ Local development without types until first generation
- ❌ Types not reviewed in PRs

**Recommended:** Commit types for easier local development.

### 4. Verify Types in Code Review

Add to your PR template:

```markdown
## Checklist

- [ ] TypeScript types are up to date (`mix nb_ts.gen.types`)
- [ ] Types match the backend prop definitions
- [ ] No TypeScript errors in frontend
```

### 5. Monitor Type Generation Time

If type generation becomes slow (>5s), consider:

```elixir
# config/dev.exs
config :nb_ts,
  auto_generate: false  # Disable auto-generation in development
```

Then generate manually:
```bash
mix nb_ts.gen.types
```

---

## Troubleshooting CI

### CI Fails: "TypeScript types out of date"

**Cause:** You committed backend changes without regenerating types.

**Fix:**
```bash
mix nb_ts.gen.types
git add assets/js/types/
git commit --amend --no-edit
git push --force-with-lease
```

### CI Fails: "mix nb_ts.gen.types not found"

**Cause:** nb_ts not installed.

**Fix:** Add to `mix.exs`:
```elixir
{:nb_ts, github: "nordbeam/nb_ts", only: [:dev, :test], runtime: false}
```

### Types Generate Differently in CI vs Local

**Cause:** Different Elixir/OTP versions or dependencies.

**Fix:** Use same versions in CI as locally:

```yaml
# .github/workflows/ci.yml
- uses: erlef/setup-beam@v1
  with:
    elixir-version: '1.16.0'  # Match your .tool-versions
    otp-version: '26.2'       # Match your .tool-versions
```

### Auto-Commit Creates Merge Conflicts

**Cause:** Types changing frequently on different branches.

**Fix:** Use Strategy 1 (fail CI) instead of Strategy 2 (auto-commit).

---

## Recommended Setup

For most teams, we recommend:

**✅ Strategy 1: Fail CI on Stale Types**
- Catches issues early
- Types reviewed in PRs
- No extra commits
- Clear error messages

**✅ Plus: Make task for easy regeneration**
```makefile
types:
	mix nb_ts.gen.types
```

**✅ Plus: Document in README**
```markdown
## TypeScript Types

Run `make types` or `mix nb_ts.gen.types` after changing backend props.
```

This gives you:
- ✅ Type safety enforced
- ✅ Easy developer workflow
- ✅ Clear CI feedback
- ✅ Types versioned in git

---

## Example PR Workflow

1. **Developer** makes backend changes:
   ```bash
   # Add new prop to controller
   vim lib/my_app_web/controllers/user_controller.ex

   # Regenerate types
   mix nb_ts.gen.types

   # Update frontend to use new prop
   vim assets/js/pages/Users/Index.tsx

   # Commit everything together
   git add lib/ assets/
   git commit -m "Add user role field"
   git push
   ```

2. **CI** runs and verifies:
   - ✅ Types are up to date
   - ✅ Backend compiles
   - ✅ Frontend type checks
   - ✅ Tests pass

3. **Reviewer** sees in PR:
   - Backend prop change
   - Generated TypeScript types
   - Frontend using new types
   - All in one coherent PR

4. **Merge** - Everything stays in sync!

---

## Resources

- **nb_ts Documentation:** https://hexdocs.pm/nb_ts
- **nb_inertia Documentation:** https://hexdocs.pm/nb_inertia
- **GitHub Actions:** https://docs.github.com/actions
- **GitLab CI:** https://docs.gitlab.com/ee/ci/

For more help, see [DEBUGGING.md](DEBUGGING.md#typescript-issues).
