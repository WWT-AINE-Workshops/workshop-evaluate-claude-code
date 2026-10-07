#!/usr/bin/env dotnet
// run-case: runs one evaluation case N times. Each run gets its own single-branch clone of the case branch and
// its own Docker containers, which see that clone and nothing else on this computer: not the eval set, not the
// full-history repository, not your home folder. It prints one row per run for the tracker's Runs tab, and copies
// the rows to your clipboard.
//
// Usage (the same in PowerShell, bash and zsh; the run-case wrapper next to this file runs it):
//   run-case --eval-set ~/nwd-foundation/eval-set --case D-02
//
// The case's options come from <eval-set>/<case>/case.json, and the model and run count from
// <eval-set>/eval-run.json. Options:
//   --eval-set DIR        the eval set folder (required); outputs go to DIR/outputs
//   --case ID             the case to run (required): its folder holds case.json and request.md
//   --runs N              number of runs, in parallel (default: eval-run.json's "runs", or 3)
//   --start N             number of the first run (default 1); use --start 2 --runs 2 after a run by hand
//   --runs-dir DIR        where the run clones are made (default ~/eval-runs); outside the eval set and repository
//   --model NAME          the model for every run (default: eval-run.json's "model"); recorded on each row
//   --settings FILE       Claude settings for the runs (default DIR/eval-run-settings.json)
//   --run-by ROLE         fills the "Run by (role)" column
//   --team-setup          also load the MCP servers (.mcp.json) and hooks the repository commits, to measure the
//                         team's shared setup against the baseline; the rows say so. Run it on a copy of the eval set
//   --credential-file F   a file holding a claude setup-token (default ~/.config/ccw5g/claude-oauth-token), used
//                         when no credential is set in this terminal
//   --claude-version V    the Claude Code version the run image pins (default: the version this kit was tested with)
//   --timeout MINUTES     stop a run that takes longer (default 30)
//   --keep                keep the run clones (they are removed by default, also after a failure or Ctrl+C)
//
// case.json keys: case, repo (path relative to the eval set, or a clone URL), branch (a local branch of repo),
// request, allow (the --allowedTools rules), and optionally:
//   setup           runs before Claude, with network, e.g. restore and npm ci
//   test            runs after Claude, with no network; leave it out for a review case
//   testNetwork     true lets the test reach the network (it has none by default)
//   referenceRepo, referenceRef, referenceFiles   files copied in from the merged ref before the test
//   checkBefore     also run the test before copying them in
//   extraBranches   more local branches to copy into each run's clone, such as open pull requests for a review case
//   env             variables for setup, Claude and the test, such as a connection string; no secrets
//   services        containers each run gets its own copy of, such as a database, reachable by name:
//                   {"db": {"image": "...", "env": {...}, "ready": "a command, run inside it, that succeeds once
//                   it is ready", "platform": "linux/amd64"}}. The test reaches them, but still not the internet
//   setupEnv        names of environment variables, such as a package feed token, passed only to the setup container
//   setupFiles      files mounted read-only, only into the setup container, such as {"nuget.config":
//                   "/home/runner/.nuget/NuGet/NuGet.Config"}; paths relative to the eval set
// Claude's container never sees setupEnv or setupFiles. eval-run.json keys: model, runs, and "browser": true for a
// run image with headless Chromium (for Karma tests).
//
// The credential reaches Claude's container through the environment, never on a command line. It is taken, in the
// order Claude Code itself uses, from Bedrock or Foundry variables, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_API_KEY, or
// CLAUDE_CODE_OAUTH_TOKEN in this terminal, then from the credential file; run-case prints which one it uses. AWS
// variables are passed only for Bedrock. Code a run executes can read the credential, and Claude's container can
// reach the network, so use one you can revoke after the workshop. Any output file that contains it is replaced
// with a notice.
using System.Diagnostics;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

const string TestedClaudeVersion = "2.1.285";
const string Header = "Case ID\tRun number\tDate\tRun by (role)\tClaude Code version\tModel\tSkill or plugin used\tHow isolated\tVerdict\tWhat we noticed\tOutput location\tCost (USD)\tDuration (minutes)";
// Passed to Claude's container when set. AWS variables only go with CLAUDE_CODE_USE_BEDROCK, so a terminal's own AWS
// session never reaches a run. The ones marked secret are scanned for.
string[] passThrough = ["CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_FOUNDRY", "ANTHROPIC_FOUNDRY_API_KEY", "ANTHROPIC_FOUNDRY_RESOURCE",
    "ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL"];
string[] bedrock = ["CLAUDE_CODE_USE_BEDROCK", "AWS_REGION", "AWS_DEFAULT_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
    "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK"];
string[] secretNames = ["CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK", "ANTHROPIC_FOUNDRY_API_KEY"];

// Ctrl+C stops the runs and their containers, then removes the clones, instead of leaving them behind.
Console.CancelKeyPress += (_, e) =>
{
    e.Cancel = true;
    if (!G.Stop.IsCancellationRequested) Console.Error.WriteLine("\nStopping: ending the runs and removing their clones...");
    G.Stop.Cancel();
};

try
{
    return await Main(args);
}
catch (Fail e)
{
    Console.Error.WriteLine(G.Stop.IsCancellationRequested ? "run-case: stopped." : $"run-case: {e.Message}");
    return 1;
}

async Task<int> Main(string[] argv)
{
    var o = ParseArgs(argv);
    if (o.ContainsKey("help")) { Console.Error.WriteLine(Usage()); return 2; }
    var evalSet = Full(Need(o, "eval-set"));
    var caseId = Need(o, "case");
    if (!Directory.Exists(evalSet)) throw new Fail($"eval set folder not found: {evalSet}");
    var caseDir = Path.Combine(evalSet, caseId);
    var caseFile = Path.Combine(caseDir, "case.json");
    if (!File.Exists(caseFile)) throw new Fail($"{caseFile} not found. Each case folder needs a case.json (see --help).");
    var c = ReadJson(caseFile);
    var configFile = Path.Combine(evalSet, "eval-run.json");
    var config = File.Exists(configFile) ? ReadJson(configFile) : new JsonObject();

    var repoValue = Str(c, "repo") ?? throw new Fail($"{caseFile} has no \"repo\"");
    var isUrl = repoValue.Contains("://") || repoValue.StartsWith("git@");
    var repo = isUrl ? repoValue : Full(Path.Combine(evalSet, repoValue));
    var branch = Str(c, "branch") ?? throw new Fail($"{caseFile} has no \"branch\"");
    var request = Full(Path.Combine(caseDir, Str(c, "request") ?? "request.md"));
    var allow = Strings(c, "allow") ?? throw new Fail($"{caseFile} has no \"allow\" list");
    var setup = Str(c, "setup");
    var test = Str(c, "test");
    var testNetwork = c["testNetwork"]?.GetValue<bool>() ?? false;
    var refRef = Str(c, "referenceRef");
    var refFiles = Strings(c, "referenceFiles") ?? [];
    var refRepoValue = Str(c, "referenceRepo");
    var refRepo = refRepoValue is null ? (isUrl ? null : repo) : Full(Path.Combine(evalSet, refRepoValue));
    var checkBefore = c["checkBefore"]?.GetValue<bool>() ?? false;
    var extra = Strings(c, "extraBranches") ?? [];
    var caseEnv = Map(c["env"] as JsonObject, "env");
    var services = (c["services"] as JsonObject ?? new JsonObject()).Select(kv =>
    {
        var s = kv.Value as JsonObject ?? throw new Fail($"services.{kv.Key} in {caseFile} must be an object");
        if (!Regex.IsMatch(kv.Key, "^[a-z][a-z0-9-]*$")) throw new Fail($"service name {kv.Key}: use lowercase letters, digits and dashes");
        return new Service(kv.Key, Str(s, "image") ?? throw new Fail($"services.{kv.Key} has no \"image\""),
            Map(s["env"] as JsonObject, $"services.{kv.Key}.env"), Str(s, "ready"), Str(s, "platform"));
    }).ToArray();
    var setupEnvNames = Strings(c, "setupEnv") ?? [];
    var setupFiles = (c["setupFiles"] as JsonObject ?? new JsonObject()).Select(kv => (Host: Full(Path.Combine(evalSet, kv.Key)), Container: kv.Value!.GetValue<string>())).ToArray();
    var runs = Count(o.GetValueOrDefault("runs") ?? config["runs"]?.ToString(), "--runs", 3);
    var start = Count(o.GetValueOrDefault("start"), "--start", 1);
    var model = o.GetValueOrDefault("model") ?? Str(config, "model") ?? throw new Fail("no model: set \"model\" in eval-run.json, or pass --model");
    var browser = config["browser"]?.GetValue<bool>() ?? false;
    var runsDir = Full(o.GetValueOrDefault("runs-dir") ?? "~/eval-runs");
    var settings = Full(o.GetValueOrDefault("settings") ?? Path.Combine(evalSet, "eval-run-settings.json"));
    var runBy = o.GetValueOrDefault("run-by") ?? "";
    var keep = o.ContainsKey("keep");
    var teamSetup = o.ContainsKey("team-setup");
    var version = o.GetValueOrDefault("claude-version") ?? TestedClaudeVersion;
    var timeoutText = o.GetValueOrDefault("timeout") ?? "30";
    var timeout = double.TryParse(timeoutText, NumberStyles.Float, CultureInfo.InvariantCulture, out var mins) && mins > 0
        ? TimeSpan.FromMinutes(mins) : throw new Fail($"--timeout must be a number of minutes, not \"{timeoutText}\"");

    // Check the inputs before anything is created.
    if (!File.Exists(request)) throw new Fail($"request file not found: {request}");
    if (!File.Exists(settings)) throw new Fail($"settings file not found: {settings}\n  Copy templates/eval-run-settings.json from the workshop repository there, or pass --settings <file>.");
    if (refFiles.Length > 0 && (refRef is null || refRepo is null)) throw new Fail("referenceFiles needs referenceRef, and a local referenceRepo when repo is a URL");
    if (refFiles.Length > 0 && test is null) throw new Fail("referenceFiles needs test");
    if (checkBefore && refFiles.Length == 0) throw new Fail("checkBefore needs referenceFiles");
    if (Inside(runsDir, evalSet)) throw new Fail($"--runs-dir must be outside the eval set ({evalSet}), so no run can reach the answers");
    if (!isUrl)
    {
        if (!Directory.Exists(repo)) throw new Fail($"repository not found: {repo}");
        if (Inside(runsDir, repo)) throw new Fail($"--runs-dir must be outside the repository ({repo})");
        // A clone copies only local branches. A branch someone else pushed is only origin/<branch> in your clone.
        foreach (var b in extra.Prepend(branch))
            if (await Run("git", ["-C", repo, "rev-parse", "--verify", "--quiet", $"refs/heads/{b}"]) != 0)
                throw new Fail(await Run("git", ["-C", repo, "rev-parse", "--verify", "--quiet", $"refs/remotes/origin/{b}"]) == 0
                    ? $"{b} is only a remote branch (origin/{b}) in {repo}. Make it a local branch first:\n  git -C \"{repo}\" branch {b} origin/{b}"
                    : $"branch {b} not found in {repo}. Create it at the commit the case starts from:\n  git -C \"{repo}\" branch {b} <commit>");
    }
    if (refRepo is not null && refFiles.Length > 0)
    {
        if (!Directory.Exists(refRepo)) throw new Fail($"reference repository not found: {refRepo}");
        if (Inside(runsDir, refRepo)) throw new Fail($"--runs-dir must be outside the reference repository ({refRepo})");
        foreach (var f in refFiles)
            if (await Run("git", ["-C", refRepo, "cat-file", "-e", $"{refRef}:{f}"]) != 0) throw new Fail($"{f} not found at {refRef} in {refRepo}");
    }
    var outDir = Path.Combine(evalSet, "outputs");
    for (var i = start; i < start + runs; i++)
    {
        if (Path.Exists(Path.Combine(runsDir, $"{caseId}-run-{i}"))) throw new Fail($"{Path.Combine(runsDir, $"{caseId}-run-{i}")} already exists. Remove it first.");
        if (File.Exists(Path.Combine(outDir, $"{caseId}-run-{i}.json"))) throw new Fail($"{Path.Combine(outDir, $"{caseId}-run-{i}.json")} already exists. Move earlier outputs aside, or use --start with the next run number.");
    }
    var dockerVersion = (await Capture("docker", ["info", "--format", "{{.ServerVersion}}"])).Trim();
    if (!Regex.IsMatch(dockerVersion, @"^\d")) throw new Fail("Docker isn't running. Start Docker Desktop (or the Docker service), then run this again.");
    if (services.Length > 0 && int.Parse(dockerVersion.Split('.')[0], CultureInfo.InvariantCulture) < 25)
        throw new Fail($"services need Docker 25 or later (this is {dockerVersion}): each run's containers join two networks");

    // The credential: from the environment, or a setup-token file. Only Claude's container gets it.
    if (Environment.GetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX") is { Length: > 0 })
        throw new Fail("Google Cloud sign-in doesn't reach the run containers. Unset CLAUDE_CODE_USE_VERTEX and use a setup-token, an API key, Bedrock, or Foundry with an API key.");
    var useBedrock = Environment.GetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK") is { Length: > 0 };
    var env = new Dictionary<string, string>();
    foreach (var name in useBedrock ? passThrough.Concat(bedrock) : passThrough)
        if (Environment.GetEnvironmentVariable(name) is { Length: > 0 } v) env[name] = v;
    var credentialFile = Full(o.GetValueOrDefault("credential-file") ?? "~/.config/ccw5g/claude-oauth-token");
    string[] signIns = ["CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_FOUNDRY"];
    if (!signIns.Any(env.ContainsKey) && File.Exists(credentialFile))
        env["CLAUDE_CODE_OAUTH_TOKEN"] = File.ReadAllText(credentialFile).Trim();
    if (!signIns.Any(env.ContainsKey))
        throw new Fail($"no credential for the runs. Save a claude setup-token in {credentialFile}, or set ANTHROPIC_API_KEY, or your Bedrock or Foundry variables (see the walkthrough's setup).");
    // Claude Code's own precedence: a cloud provider, then ANTHROPIC_AUTH_TOKEN, ANTHROPIC_API_KEY, CLAUDE_CODE_OAUTH_TOKEN.
    var source = useBedrock ? "Amazon Bedrock (CLAUDE_CODE_USE_BEDROCK in this terminal)"
        : env.ContainsKey("CLAUDE_CODE_USE_FOUNDRY") ? "Microsoft Foundry (CLAUDE_CODE_USE_FOUNDRY in this terminal)"
        : env.ContainsKey("ANTHROPIC_AUTH_TOKEN") ? "ANTHROPIC_AUTH_TOKEN in this terminal"
        : env.ContainsKey("ANTHROPIC_API_KEY") ? "ANTHROPIC_API_KEY in this terminal"
        : Environment.GetEnvironmentVariable("CLAUDE_CODE_OAUTH_TOKEN") is { Length: > 0 } ? "CLAUDE_CODE_OAUTH_TOKEN in this terminal"
        : $"the setup-token in {credentialFile}";
    Console.Error.WriteLine($"Signing in with {source}.");
    if (!useBedrock && bedrock.Skip(1).Any(n => Environment.GetEnvironmentVariable(n) is { Length: > 0 }))
        Console.Error.WriteLine("The AWS variables in this terminal are not passed to the runs (only with CLAUDE_CODE_USE_BEDROCK).");

    // Package feed credentials for the setup container only.
    var setupEnv = new Dictionary<string, string>();
    foreach (var n in setupEnvNames)
    {
        if (Environment.GetEnvironmentVariable(n) is { Length: > 0 } v) setupEnv[n] = v;
        else throw new Fail($"case.json names {n} in setupEnv, but it is not set in this terminal");
    }
    foreach (var (hostFile, _) in setupFiles)
        if (!File.Exists(hostFile)) throw new Fail($"case.json names {hostFile} in setupFiles, but it does not exist");
    var secrets = secretNames.Where(env.ContainsKey).Select(n => env[n]).Concat(setupEnv.Values)
        .Concat(setupFiles.SelectMany(m => SecretsIn(m.Host))).Where(s => s.Length >= 8).Distinct().ToArray();

    // The image, built once per Claude Code version from the Dockerfile next to this script. On Linux and WSL its
    // user takes your uid, so the containers can write to the clones you own.
    var uid = OperatingSystem.IsLinux() ? (await Capture("id", ["-u"])).Trim() : "1000";
    var gid = OperatingSystem.IsLinux() ? (await Capture("id", ["-g"])).Trim() : "1000";
    G.Image = $"ccw5g-eval-run:{version}{(browser ? "-browser" : "")}";
    if ((await Capture("docker", ["image", "inspect", "--format", "{{index .Config.Labels \"ccw5g.uid\"}}", G.Image])).Trim() != uid)
    {
        var dockerfile = Path.Combine(ScriptDir(), "eval-run.Dockerfile");
        if (!File.Exists(dockerfile)) throw new Fail($"{dockerfile} not found");
        Console.Error.WriteLine($"Building the run image {G.Image} (once; a few minutes)...");
        if (await Run("docker", ["build", "-q", "-t", G.Image, "--build-arg", $"CLAUDE_VERSION={version}", "--build-arg", $"RUNNER_UID={uid}",
                "--build-arg", $"RUNNER_GID={gid}", "--build-arg", $"BROWSER={(browser ? "true" : "false")}", "-f", dockerfile, ScriptDir()], echo: true) != 0)
            throw new Fail("building the run image failed (see above)");
    }
    // The package caches, shared by every run of this user, so restores after the first take seconds.
    var nuget = $"ccw5g-nuget-{uid}";
    var npm = $"ccw5g-npm-{uid}";
    foreach (var vol in new[] { nuget, npm }) await Run("docker", ["volume", "create", vol]);

    Directory.CreateDirectory(outDir);
    Directory.CreateDirectory(runsDir);
    var prompt = File.ReadAllText(request);
    var date = DateTime.Now.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    var runSettings = settings;
    if (teamSetup)
    {
        // The same settings, but with the repository's hooks and .mcp.json servers allowed.
        var s = ReadJson(settings);
        s["disableAllHooks"] = false;
        s["enableAllProjectMcpServers"] = true;
        runSettings = Path.Combine(runsDir, $".ccw5g-team-settings-{Guid.NewGuid():N}.json");
        File.WriteAllText(runSettings, s.ToJsonString());
    }

    var setupGate = new SemaphoreSlim(1);
    string[] rows;
    try
    {
        // One clone per run: only the case branch, no tags, origin removed. Later commits (the fix) are not in it.
        for (var i = start; i < start + runs; i++)
        {
            var dir = Path.Combine(runsDir, $"{caseId}-run-{i}");
            // --no-local copies objects instead of hard-linking them, so the clone shares nothing with the repository.
            List<string> clone = ["clone", "--quiet", "--config", "core.autocrlf=false", "--single-branch", "--branch", branch, "--no-tags"];
            if (!isUrl) clone.Add("--no-local");
            if (await Run("git", [.. clone, repo, dir], echo: true) != 0)
                throw new Fail($"cloning {branch} from {repo} failed");
            foreach (var b in extra)
                if (await Run("git", ["-C", dir, "fetch", "--quiet", "--no-tags", "origin", $"refs/heads/{b}:refs/heads/{b}"], echo: true) != 0)
                    throw new Fail($"branch {b} not found in {repo}");
            await Run("git", ["-C", dir, "remote", "remove", "origin"]);
        }

        Console.Error.WriteLine($"Started {runs} run(s) of {caseId} with Claude Code {version} and model {model}, each in its own containers{(teamSetup ? ", with the repository's team setup" : "")}; waiting...");
        rows = await Task.WhenAll(Enumerable.Range(start, runs).Select(i => OneRun(i)));
    }
    finally
    {
        if (!keep)
        {
            // Files the containers wrote may belong to the container's user, so a container removes the clones.
            var dirs = Enumerable.Range(start, runs).Select(i => $"{caseId}-run-{i}").Where(d => Directory.Exists(Path.Combine(runsDir, d))).ToArray();
            if (dirs.Length > 0)
                await Docker([$"ccw5g-{Safe(caseId)}-clean-{Guid.NewGuid():N}"[..40], "-v", $"{runsDir}:/runs"], ["rm", "-rf", .. dirs.Select(d => $"/runs/{d}")],
                    null, null, null, TimeSpan.FromMinutes(10), stoppable: false);
            foreach (var d in dirs) if (Directory.Exists(Path.Combine(runsDir, d))) try { Directory.Delete(Path.Combine(runsDir, d), true); } catch (Exception) { }
        }
        if (runSettings != settings) File.Delete(runSettings);
    }

    var tsv = Path.Combine(outDir, $"{caseId}-runs.tsv");
    File.WriteAllText(tsv, Header + "\n" + string.Concat(rows.Select(r => r + "\n")));
    Console.WriteLine();
    Console.Write(File.ReadAllText(tsv));
    Console.WriteLine();
    Console.WriteLine($"Rows saved to {tsv}.");
    if (G.Stop.IsCancellationRequested) { Console.WriteLine("Stopped before the runs finished: these rows are incomplete."); return 130; }
    Console.WriteLine(await ToClipboard(string.Concat(rows.Select(r => r + "\n")))
        ? "The rows, without the header, are on your clipboard: click cell A of the first empty row in the Runs tab, and paste."
        : "Copy the rows below the header line into the first empty row of the Runs tab, starting in column A.");
    if (keep) Console.WriteLine($"Run clones kept in {runsDir}.");
    Console.WriteLine(test is null
        ? "Grade each run: read the reply (.md) against note.md, check Must include / Must not, then type the verdict in the Runs tab."
        : "Grade each run: read the .diff and .status, check Must include / Must not, then type the verdict in the Runs tab.");
    return 0;

    async Task<string> OneRun(int i)
    {
        var dir = Path.Combine(runsDir, $"{caseId}-run-{i}");
        var b = Path.Combine(outDir, $"{caseId}-run-{i}");
        var name = $"ccw5g-{Safe(caseId)}-run-{i}-{Guid.NewGuid().ToString("N")[..6]}";
        string note;
        var cost = ""; var minutes = ""; var modelUsed = model;
        string[] envArgs = [.. caseEnv.SelectMany(kv => new[] { "-e", $"{kv.Key}={kv.Value}" })];
        // Networks: with services, each run gets an internal network for them (no internet), and a second one with
        // internet for setup and Claude. Without services, the test gets no network at all.
        string[] online = [], testNet = testNetwork ? [] : ["--network", "none"];
        var created = new List<string>();
        try
        {
            string? serviceError = null;
            if (services.Length > 0)
            {
                var inner = name + "-svc"; var outer = name + "-net";
                await Run("docker", ["network", "create", "--internal", inner]); created.Add("network:" + inner);
                await Run("docker", ["network", "create", outer]); created.Add("network:" + outer);
                online = ["--network", outer, "--network", inner];
                testNet = testNetwork ? online : ["--network", inner];
                serviceError = await StartServices(name, inner, b + ".services.txt", created);
            }
            var setupOk = serviceError is null;
            if (serviceError is not null) note = serviceError;
            else if (setup is not null)
            {
                // One setup at a time: parallel restores into the shared package caches collide. The first fills the
                // caches; the others then take seconds. The Claude runs themselves are parallel.
                await setupGate.WaitAsync();
                try
                {
                    setupOk = await Docker([name + "-setup", "-v", $"{dir}:/work", "-v", $"{nuget}:/home/runner/.nuget/packages", "-v", $"{npm}:/home/runner/.npm",
                            .. online, .. envArgs, .. setupFiles.SelectMany(m => new[] { "-v", $"{m.Host}:{m.Container}:ro" }), .. setupEnv.Keys.SelectMany(k => new[] { "-e", k })],
                        ["bash", "-c", setup], b + ".setup.txt", b + ".setup.txt", setupEnv, timeout) == 0;
                }
                finally { setupGate.Release(); }
            }
            if (G.Stop.IsCancellationRequested) note = "Stopped with Ctrl+C before Claude ran";
            else if (serviceError is not null) note = serviceError;
            else if (!setupOk) note = $"Setup failed: see {Path.GetFileName(b)}.setup.txt";
            else note = await ClaudeAndTests();
        }
        finally
        {
            foreach (var r in Enumerable.Reverse(created))
                await Run("docker", r.StartsWith("network:") ? ["network", "rm", r[8..]] : ["rm", "-f", r], stoppable: false);
        }

        // Nothing that contains the credential is kept.
        var leaked = false;
        foreach (var f in Directory.GetFiles(outDir, $"{caseId}-run-{i}.*"))
        {
            var text = File.ReadAllText(f);
            if (secrets.Any(s => text.Contains(s)))
            {
                File.WriteAllText(f, "run-case removed this file: it contained the credential the run signed in with, or a package feed secret. Revoke it and create a new one.\n");
                leaked = true;
            }
        }
        if (leaked) note = "CREDENTIAL FOUND IN OUTPUT: file(s) removed; revoke the credential. " + note;
        var location = b.StartsWith(Home()) ? "~" + b[Home().Length..].Replace('\\', '/') : b;
        return string.Join("\t", caseId, i, date, runBy, version, modelUsed, teamSetup ? "Team setup from the repository" : "None", "Container per run", "", note, location, cost, minutes);

        async Task<string> ClaudeAndTests()
        {
            var exit = await Docker([name, "-v", $"{dir}:/work", "-v", $"{runSettings}:/eval/settings.json:ro", "-v", $"{nuget}:/home/runner/.nuget/packages:ro",
                    .. online, .. envArgs, .. env.Keys.SelectMany(k => new[] { "-e", k })],
                ["claude", "-p", prompt, "--settings", "/eval/settings.json", "--permission-mode", "acceptEdits",
                 "--setting-sources", "project,local", .. (teamSetup ? Array.Empty<string>() : ["--strict-mcp-config"]), "--no-session-persistence",
                 "--allowedTools", string.Join(",", allow), "--model", model, "--output-format", "json"],
                b + ".json", b + ".stderr", env, timeout);

            // What Claude changed, captured before the reference files are copied in. New files are included.
            var status = await Capture("git", ["-c", "safe.directory=*", "-C", dir, "status", "--short"]);
            File.WriteAllText(b + ".status", status);
            var added = status.Split('\n').Count(l => l.StartsWith("??"));
            await Run("git", ["-c", "safe.directory=*", "-C", dir, "add", "--all", "--intent-to-add"], stoppable: false);
            await Run("git", ["-c", "safe.directory=*", "-C", dir, "diff", "--no-color", "--no-ext-diff"], stdout: b + ".diff", stoppable: false);
            var changed = (await Capture("git", ["-c", "safe.directory=*", "-C", dir, "diff", "--name-only"])).Split('\n', StringSplitOptions.RemoveEmptyEntries).Length;
            var changes = $"{changed} file{(changed == 1 ? "" : "s")} changed; new files: {added}";

            // The reply to .md; cost, duration and model(s) from the JSON.
            JsonObject? data = null;
            try
            {
                var node = JsonNode.Parse(File.ReadAllText(b + ".json"));
                data = node is JsonArray arr ? arr.LastOrDefault(m => Str(m as JsonObject, "type") == "result") as JsonObject : node as JsonObject;
            }
            catch (Exception) { }
            File.WriteAllText(b + ".md", (Str(data, "result") ?? "") + "\n");
            if (data?["total_cost_usd"] is JsonNode cn) cost = cn.GetValue<double>().ToString("0.00", CultureInfo.InvariantCulture);
            if (data?["duration_ms"] is JsonNode dn) minutes = (dn.GetValue<double>() / 60000).ToString("0.0", CultureInfo.InvariantCulture);
            if (data?["modelUsage"] is JsonObject mu && mu.Count > 0) modelUsed = string.Join("+", mu.Select(kv => kv.Key));

            if (G.Stop.IsCancellationRequested) return $"Stopped with Ctrl+C; {changes}";
            if (exit != 0) return $"Run failed: exit {exit}; see {Path.GetFileName(b)}.stderr";
            if (test is null) return $"Review case: grade the reply (.md) against note.md; {changes}";
            var before = checkBefore ? $"Before overlay: {await RunTests(name + "-before", b + ".tests-before.txt")}" : null;
            foreach (var f in refFiles)
            {
                // Byte for byte, so binary files and line endings arrive exactly as merged.
                var target = Path.Combine(dir, f);
                Directory.CreateDirectory(Path.GetDirectoryName(target)!);
                await Run("git", ["-C", refRepo!, "show", $"{refRef}:{f}"], stdout: target, stoppable: false);
            }
            var after = await RunTests(name + "-test", b + ".tests.txt");
            return before is not null ? $"{before}; after overlay: {after}; {changes}"
                : refFiles.Length > 0 ? $"Reference tests: {after}; {changes}" : $"Tests: {after}; {changes}";
        }

        // RunTests: the case's test command in a fresh container with no credential and no internet; "pass", or
        // "fail (<counts>; see <log>)".
        async Task<string> RunTests(string container, string log)
        {
            var code = await Docker([container, "-v", $"{dir}:/work", "-v", $"{nuget}:/home/runner/.nuget/packages:ro", .. testNet, .. envArgs],
                ["bash", "-c", test!], log, log, null, timeout);
            if (code == 0) return "pass";
            if (G.Stop.IsCancellationRequested) return "stopped";
            var text = File.Exists(log) ? File.ReadAllText(log) : "";
            // dotnet test prints "Failed: 1, Passed: 7"; Jest "Tests: 1 failed, 7 passed, 8 total"; Karma "Executed 8 of 8 (1 FAILED)".
            var dotnet = Regex.Matches(text, @"Failed:\s+(\d+), Passed:\s+(\d+)");
            var jest = Regex.Matches(text, @"^Tests:.*$", RegexOptions.Multiline);
            var karma = Regex.Matches(text, @"Executed (\d+) of \d+.*?\((\d+) FAILED\)");
            var counts = dotnet.Count > 0 ? $"{dotnet[^1].Groups[1].Value} failed, {dotnet[^1].Groups[2].Value} passed"
                : jest.Count > 0 ? string.Join(", ", Regex.Matches(jest[^1].Value, @"\d+ (failed|passed)").Select(x => x.Value))
                : karma.Count > 0 ? $"{karma[^1].Groups[2].Value} failed, {int.Parse(karma[^1].Groups[1].Value) - int.Parse(karma[^1].Groups[2].Value)} passed"
                : "";
            return $"fail ({(counts.Length > 0 ? counts + "; " : "")}see {Path.GetFileName(log)})";
        }
    }

    // StartServices: starts each service on the run's internal network, under its own name, and waits until its
    // ready command succeeds. Returns null, or the note for the Runs tab.
    async Task<string?> StartServices(string run, string network, string log, List<string> created)
    {
        foreach (var s in services)
        {
            var container = $"{run}-{s.Name}";
            List<string> argv = ["run", "-d", "--name", container, "--network", network, "--network-alias", s.Name];
            if (s.Platform is not null) argv.AddRange(["--platform", s.Platform]);
            foreach (var (k, v) in s.Env) argv.AddRange(["-e", $"{k}={v}"]);
            if (await Run("docker", [.. argv, s.Image], stdout: log, stderr: log) != 0) return $"Service {s.Name} didn't start: see {Path.GetFileName(log)}";
            created.Add(container);
        }
        foreach (var s in services.Where(s => s.Ready is not null))
        {
            var container = $"{run}-{s.Name}";
            var deadline = DateTime.UtcNow.AddMinutes(3);
            while (await Run("docker", ["exec", container, "sh", "-c", s.Ready!]) != 0)
            {
                if (G.Stop.IsCancellationRequested) return "Stopped with Ctrl+C before Claude ran";
                if (DateTime.UtcNow > deadline)
                {
                    await Run("docker", ["logs", container], stdout: log, stderr: log, stoppable: false);
                    return $"Service {s.Name} wasn't ready after 3 minutes: see {Path.GetFileName(log)}";
                }
                await Task.Delay(2000);
            }
        }
        return null;
    }
}

// Docker: docker run --rm --name <name> <options> <image> <command>, with stdout and stderr to files.
static async Task<int> Docker(string[] options, string[] command, string? stdout, string? stderr, Dictionary<string, string>? env, TimeSpan timeout, bool stoppable = true)
{
    if (stoppable && G.Stop.IsCancellationRequested) return -1;
    string[] argv = ["run", "--rm", "--name", options[0], .. options[1..], G.Image, .. command];
    var code = await Run("docker", argv, stdout: stdout, stderr: stderr, env: env, timeout: timeout, stoppable: stoppable);
    // rm -f stops the container and waits until it is gone, so nothing keeps running after a timeout or Ctrl+C.
    if (code == -1) await Run("docker", ["rm", "-f", options[0]], stoppable: false);
    return code;
}

// Run: starts a process with an argument list (no shell, so nothing needs quoting), and returns its exit code,
// or -1 after the timeout or Ctrl+C. Output goes to files, to the console with echo, or is discarded.
static async Task<int> Run(string file, string[] argv, string? stdout = null, string? stderr = null,
    Dictionary<string, string>? env = null, TimeSpan? timeout = null, bool echo = false, bool stoppable = true, byte[]? input = null)
{
    var psi = new ProcessStartInfo(file) { RedirectStandardOutput = !echo, RedirectStandardError = !echo, RedirectStandardInput = true, UseShellExecute = false };
    foreach (var a in argv) psi.ArgumentList.Add(a);
    if (env is not null) foreach (var (k, v) in env) psi.Environment[k] = v;
    using var p = Process.Start(psi) ?? throw new Fail($"could not start {file}");
    if (input is not null) await p.StandardInput.BaseStream.WriteAsync(input);
    p.StandardInput.Close();
    Task copyOut = Task.CompletedTask, copyErr = Task.CompletedTask;
    FileStream? outFile = null, errFile = null;
    if (!echo)
    {
        outFile = stdout is null ? null : new FileStream(stdout, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
        errFile = stderr is null ? null : stderr == stdout ? outFile : new FileStream(stderr, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
        copyOut = outFile is null ? p.StandardOutput.BaseStream.CopyToAsync(Stream.Null) : CopyLocked(p.StandardOutput.BaseStream, outFile);
        copyErr = errFile is null ? p.StandardError.BaseStream.CopyToAsync(Stream.Null) : CopyLocked(p.StandardError.BaseStream, errFile);
    }
    using var cts = stoppable ? CancellationTokenSource.CreateLinkedTokenSource(G.Stop.Token) : new CancellationTokenSource();
    if (timeout is { } t) cts.CancelAfter(t);
    try { await p.WaitForExitAsync(cts.Token); }
    catch (OperationCanceledException) { try { p.Kill(true); } catch (Exception) { } await p.WaitForExitAsync(); await Task.WhenAll(copyOut, copyErr); outFile?.Dispose(); if (errFile != outFile) errFile?.Dispose(); return -1; }
    await Task.WhenAll(copyOut, copyErr);
    outFile?.Dispose();
    if (errFile != outFile) errFile?.Dispose();
    return p.ExitCode;
}

// CopyLocked: copies a stream to a file that two streams may share (stdout and stderr to one log).
static async Task CopyLocked(Stream from, FileStream to)
{
    var buffer = new byte[16384];
    int n;
    while ((n = await from.ReadAsync(buffer)) > 0)
        lock (to) { to.Write(buffer, 0, n); to.Flush(); }
}

static async Task<string> Capture(string file, string[] argv)
{
    var tmp = Path.GetTempFileName();
    try { await Run(file, argv, stdout: tmp, stoppable: false); return File.ReadAllText(tmp); }
    catch (Exception e) when (e is not Fail) { return ""; }
    finally { File.Delete(tmp); }
}

// ToClipboard: puts the rows on the clipboard with the system's own tool. Windows' clip reads the console code
// page, so text with non-ASCII characters is left for the participant to copy.
static async Task<bool> ToClipboard(string text)
{
    var wsl = OperatingSystem.IsLinux() && File.Exists("/proc/version") && File.ReadAllText("/proc/version").Contains("microsoft", StringComparison.OrdinalIgnoreCase);
    var windowsClip = OperatingSystem.IsWindows() || wsl;
    if (windowsClip && text.Any(ch => ch > 127)) return false;
    (string file, string[] argv)[] tools = OperatingSystem.IsMacOS() ? [("pbcopy", [])]
        : windowsClip ? [(OperatingSystem.IsWindows() ? "clip" : "clip.exe", [])]
        : [("wl-copy", []), ("xclip", ["-selection", "clipboard"])];
    var bytes = Encoding.UTF8.GetBytes(windowsClip ? text.Replace("\n", "\r\n") : text);
    foreach (var (file, argv) in tools)
        try { if (await Run(file, argv, input: bytes, timeout: TimeSpan.FromSeconds(10), stoppable: false) == 0) return true; }
        catch (Exception) { }
    return false;
}

// SecretsIn: the password and token values in a package feed file (nuget.config, .npmrc), for the leak scan.
// Values that only name an environment variable, such as %FEED_TOKEN% or ${NPM_TOKEN}, are skipped.
static IEnumerable<string> SecretsIn(string file)
{
    var text = File.ReadAllText(file);
    var xml = Regex.Matches(text, @"key=""[^""]*(?:password|token|secret|apikey)[^""]*""\s+value=""([^""]+)""", RegexOptions.IgnoreCase);
    var ini = Regex.Matches(text, @"(?:_authToken|_auth|_password|password|token|secret)\s*[=:]\s*""?([^""\s]+)", RegexOptions.IgnoreCase);
    return xml.Concat(ini).Select(m => m.Groups[1].Value).Where(v => !v.StartsWith('%') && !v.StartsWith('$'));
}

static Dictionary<string, string> ParseArgs(string[] argv)
{
    string[] flags = ["keep", "help", "team-setup"];
    string[] valued = ["eval-set", "case", "runs", "start", "runs-dir", "model", "settings", "run-by", "credential-file", "claude-version", "timeout"];
    var o = new Dictionary<string, string>();
    for (var i = 0; i < argv.Length; i++)
    {
        var a = argv[i];
        if (a is "-h" or "--help") { o["help"] = ""; continue; }
        var key = a.StartsWith("--") ? a[2..] : throw new Fail($"unexpected argument {a} (run with --help for usage)");
        if (flags.Contains(key)) o[key] = "";
        else if (valued.Contains(key)) o[key] = i + 1 < argv.Length ? argv[++i] : throw new Fail($"--{key} needs a value");
        else throw new Fail($"unknown option --{key} (run with --help for usage)");
    }
    return o;
}

static string Need(Dictionary<string, string> o, string key) =>
    o.TryGetValue(key, out var v) && v.Length > 0 ? v : throw new Fail($"--{key} is required (run with --help for usage)");

static int Count(string? text, string what, int fallback) =>
    text is null ? fallback
    : int.TryParse(text, NumberStyles.None, CultureInfo.InvariantCulture, out var n) && n > 0 ? n
    : throw new Fail($"{what} must be a whole number above 0, not \"{text}\"");

static JsonObject ReadJson(string file)
{
    try { return JsonNode.Parse(File.ReadAllText(file)) as JsonObject ?? throw new Fail($"{file} must hold a JSON object"); }
    catch (JsonException e) { throw new Fail($"{file} isn't valid JSON: {e.Message}"); }
}

static string? Str(JsonObject? o, string key) => o?[key] is JsonValue v && v.TryGetValue<string>(out var s) ? s : null;

static string[]? Strings(JsonObject o, string key) => o[key]?.AsArray().Select(n => n!.GetValue<string>()).ToArray();

static Dictionary<string, string> Map(JsonObject? o, string what) =>
    (o ?? new JsonObject()).ToDictionary(kv => Regex.IsMatch(kv.Key, "^[A-Za-z_][A-Za-z0-9_]*$") ? kv.Key : throw new Fail($"{what}: {kv.Key} isn't a valid variable name"),
        kv => kv.Value?.ToString() ?? "");

static string Safe(string s) => Regex.Replace(s, "[^A-Za-z0-9_.-]", "_");

static string Home() => Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

// Full: an absolute path with ~ expanded and symlinks resolved, also for paths that do not exist yet.
static string Full(string path)
{
    if (path == "~" || path.StartsWith("~/") || path.StartsWith("~\\")) path = Home() + path[1..];
    var full = Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    var existing = full;
    var rest = new Stack<string>();
    while (!Path.Exists(existing) && Path.GetDirectoryName(existing) is { } parent) { rest.Push(Path.GetFileName(existing)); existing = parent; }
    var resolved = new DirectoryInfo(existing).ResolveLinkTarget(true)?.FullName ?? existing;
    // macOS links /var and /tmp into /private.
    if (OperatingSystem.IsMacOS() && (resolved.StartsWith("/var/") || resolved == "/tmp" || resolved.StartsWith("/tmp/"))) resolved = "/private" + resolved;
    return rest.Aggregate(resolved, Path.Combine);
}

// Inside: true if child is parent or below it.
static bool Inside(string child, string parent)
{
    var cmp = OperatingSystem.IsWindows() || OperatingSystem.IsMacOS() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;
    return (child + Path.DirectorySeparatorChar).StartsWith(parent.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar, cmp);
}

static string ScriptDir([System.Runtime.CompilerServices.CallerFilePath] string path = "") => Path.GetDirectoryName(path)!;

static string Usage()
{
    var lines = File.ReadAllLines(Path.Combine(ScriptDir(), "run-case.cs")).Skip(1).TakeWhile(l => l.StartsWith("//"));
    return string.Join("\n", lines.Select(l => l.Length > 3 ? l[3..] : ""));
}

record Service(string Name, string Image, Dictionary<string, string> Env, string? Ready, string? Platform);

static class G
{
    public static readonly CancellationTokenSource Stop = new();
    public static string Image = "";
}

class Fail(string message) : Exception(message);
