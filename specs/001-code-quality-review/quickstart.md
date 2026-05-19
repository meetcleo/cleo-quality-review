# Quickstart: Code Quality Review Gem

## Installation

Add to your Gemfile:

```ruby
gem 'cleo_quality_review'
```

Or install directly:

```bash
gem install cleo_quality_review
```

## Basic Usage

### Check Changed Files

```bash
check_quality
```

Analyzes files changed from `origin/main` using all available checks (reek, flog, fasterer).

### Check Specific Files

```bash
check_quality lib/my_class.rb app/models/*.rb
```

### Output Formats

**Human-readable** (requires LLM configuration):
```bash
export OPENAI_API_KEY=your-key
check_quality --format human
```

**For AI agents**:
```bash
check_quality --format agent
```

**For GitHub Actions**:
```bash
check_quality --format github
```

### Filter Checks

Run only specific checks:
```bash
check_quality --only reek lib/
```

Exclude checks:
```bash
check_quality --exclude flog,fasterer lib/
```

## Configuration

Create `.cleo_quality_review.yaml` in your project root:

```yaml
AllTools:
  Include:
    - "**/*.rb"
    - "**/*.rake"
  Exclude:
    - "tmp/**/*"
    - "vendor/**/*"
    - "db/schema.rb"
```

## GitHub Actions Integration

```yaml
- name: Quality Review
  run: |
    gem install cleo_quality_review
    check_quality --format github
```

## Available Checks

| Check | Description |
|-------|-------------|
| reek | Code smell detection |
| flog | Complexity analysis |
| fasterer | Performance suggestions |

## Next Steps

- See [CLI Contract](contracts/cli.md) for full option reference
- See [Agent Output Contract](contracts/agent-output.md) for JSON schema
