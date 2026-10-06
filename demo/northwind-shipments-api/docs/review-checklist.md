# Review checklist

Reviewers check, in this order:

1. The change does what the pull request says, and nothing else.
2. Every new or changed endpoint checks who the caller is and what they may touch.
3. Inputs reach SQL, the shell, the file system, and outbound HTTP only through safe APIs.
4. New behavior has tests, including the failure path.
5. User-visible changes are in docs/api.md and CHANGELOG.md.
6. No secrets, credentials, or personal data in code, tests, logs, or fixtures.

Formatting and import order are enforced by ruff. Do not comment on them.
