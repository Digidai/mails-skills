# Contributing to mails-skills

Thanks for your interest in contributing! This project is simple by design, so contributing should be straightforward.

## How to Contribute

### Reporting Issues

- Open a [GitHub Issue](https://github.com/Digidai/mails-skills/issues)
- Include your platform (Claude Code, OpenClaw, etc.) and OS
- Paste any error messages from `install.sh`

### Adding a New Skill

If you want to add support for a new AI agent platform:

1. Create a new directory under `skills/your-platform/`
2. Follow the format of existing skills -- the API reference is the same, only the format changes
3. Update `install.sh` to support the new platform
4. Update `README.md` with the new platform in the "Supported Platforms" table
5. Submit a pull request

### Improving Existing Skills

- Make examples more copy-paste friendly
- Fix inaccuracies in API documentation
- Add missing usage patterns

### Guidelines

- Keep it simple. This is a skill file installer, not a framework.
- Test `install.sh` changes on both macOS and Linux if possible.
- Skill files should be self-contained -- an agent should understand everything from the single file.

## Development

```bash
git clone https://github.com/Digidai/mails-skills.git
cd mails-skills

# Test the installer locally
./install.sh

# Test non-interactive mode (hosted)
./install.sh --url https://api.mails0.com --token test123 --mailbox test@mails0.com
```

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
