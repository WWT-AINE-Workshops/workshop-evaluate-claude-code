# The image every eval run uses: the .NET 10 SDK, Node 22, git, and one pinned Claude Code version.
# run-case builds it once, tagged with that version, and starts a fresh container from it for each step of each
# run. Only the run's own clone is mounted, so nothing a run starts can read the eval set or the answers.
# Build arguments: CLAUDE_VERSION (required); RUNNER_UID and RUNNER_GID, the user the runs use, which run-case
# sets to yours on Linux and WSL so the container can write to your clone; BROWSER=true adds a headless Chromium
# for Karma tests (eval-run.json "browser": true).
FROM mcr.microsoft.com/dotnet/sdk:10.0
ARG CLAUDE_VERSION
ARG RUNNER_UID=1000
ARG RUNNER_GID=1000
ARG BROWSER=false
ARG PLAYWRIGHT_VERSION=1.63.0
LABEL ccw5g.uid=$RUNNER_UID ccw5g.browser=$BROWSER
ENV DEBIAN_FRONTEND=noninteractive DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    NG_CLI_ANALYTICS=false NPM_CONFIG_UPDATE_NOTIFIER=false CI=1 PLAYWRIGHT_BROWSERS_PATH=/opt/browsers
RUN apt-get update && apt-get install -y --no-install-recommends git curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*
# The base image's own ubuntu user holds uid 1000; the runs need that uid (or yours) for themselves.
RUN userdel -r ubuntu 2>/dev/null; groupadd -o -g "$RUNNER_GID" runner && useradd -o -m -s /bin/bash -u "$RUNNER_UID" -g runner runner \
 && mkdir -p /work && chown runner:runner /work
# Karma needs a browser. Chrome's sandbox can't start inside a container, so CHROME_BIN points to a wrapper that
# turns it off; the container is the sandbox.
RUN if [ "$BROWSER" = true ]; then \
      npx -y "playwright@$PLAYWRIGHT_VERSION" install --with-deps chromium && rm -rf /var/lib/apt/lists/* /root/.npm \
      && chrome="$(find /opt/browsers -path '*chrome-linux*/chrome' -type f | head -1)" && test -n "$chrome" \
      && printf '#!/bin/sh\nexec "%s" --no-sandbox "$@"\n' "$chrome" > /usr/local/bin/chrome-for-tests \
      && chmod 755 /usr/local/bin/chrome-for-tests && chmod -R a+rX /opt/browsers; \
    fi
ENV CHROME_BIN=/usr/local/bin/chrome-for-tests
USER runner
WORKDIR /home/runner
RUN test -n "$CLAUDE_VERSION" && curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_VERSION" \
 && mkdir -p /home/runner/.nuget/packages /home/runner/.npm \
 && git config --global --add safe.directory /work
# The pinned version must stay the version every run reports: no updates inside a container.
ENV PATH=/home/runner/.local/bin:$PATH DISABLE_AUTOUPDATER=1
WORKDIR /work
