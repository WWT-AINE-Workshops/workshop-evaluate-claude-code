# The image every eval run uses: the .NET 10 SDK, Node 22, git, and one pinned Claude Code version.
# run-case builds it once, tagged with that version, and starts a fresh container from it for each step of each
# run. Only the run's own clone is mounted, so nothing a run starts can read the eval set or the answers.
FROM mcr.microsoft.com/dotnet/sdk:10.0
ARG CLAUDE_VERSION
ENV DEBIAN_FRONTEND=noninteractive DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    NG_CLI_ANALYTICS=false NPM_CONFIG_UPDATE_NOTIFIER=false CI=1
RUN apt-get update && apt-get install -y --no-install-recommends git curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner && mkdir -p /work && chown runner:runner /work
USER runner
WORKDIR /home/runner
RUN test -n "$CLAUDE_VERSION" && curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_VERSION" \
 && mkdir -p /home/runner/.nuget/packages /home/runner/.npm \
 && git config --global --add safe.directory /work
# The pinned version must stay the version every run reports: no updates inside a container.
ENV PATH=/home/runner/.local/bin:$PATH DISABLE_AUTOUPDATER=1
WORKDIR /work
