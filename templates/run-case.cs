#!/usr/bin/env dotnet
// run-case: runs one evaluation case N times. Each run gets its own single-branch clone of the case branch and
// its own Docker containers, which see that clone and nothing else on this computer: not the eval set, not the
// full-history repository, not your home folder. It prints one row per run for the tracker's Runs tab.
//
// Usage (the same in PowerShell, bash and zsh; the run-case wrapper next to this file runs it):
//   run-case --eval-set ~/nwd-foundation/eval-set --case D-01
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
//   --credential-file F   a file holding a claude setup-token (default ~/.config/ccw5g/claude-oauth-token), used
//                         when CLAUDE_CODE_OAUTH_TOKEN, ANTHROPIC_API_KEY and the cloud-provider variables are unset
//   --claude-version V    the Claude Code version the run image pins (default: the version this kit was tested with)
//   --timeout MINUTES     stop a run that takes longer (default 30)
//   --keep                keep the run clones (they are removed by default)
//
// case.json keys: case, repo (path relative to the eval set, or a clone URL), branch, request, allow (the
// --allowedTools rules), and optionally setup (runs before Claude, with network, e.g. restore and npm ci), test
// (runs after Claude; leave it out for a review case), referenceRepo, referenceRef, referenceFiles (copied in from
// the merged ref before the test), checkBefore (also run the test before copying them in), extraBranches (more
// branches to copy into each run's clone, such as open pull requests for a review case), setupEnv (names of
// environment variables, such as a package feed token, passed only to the setup container), and setupFiles (a map
// of files to mount read-only, only into the setup container, such as {"nuget.config":
// "/home/runner/.nuget/NuGet/NuGet.Config"}; paths relative to the eval set). Claude's container never sees setupEnv
// or setupFiles.
//
// The credential reaches Claude's container through the environment, never on a command line. It is taken, in this
// order Claude Code itself uses, from a cloud provider's variables, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_API_KEY, or
// CLAUDE_CODE_OAUTH_TOKEN in this terminal, then from the credential file; run-case prints which one it uses. Code a run executes can read the credential,
// and the container can reach the network, so use one you can revoke after the workshop. Any output file that
// contains it is replaced with a notice.
using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

const string TestedClaudeVersion = "2.1.285";
const string Header = "Case ID\tRun number\tDate\tRun by (role)\tClaude Code version\tModel\tSkill or plugin used\tHow isolated\tVerdict\tWhat we noticed\tOutput location\tCost (USD)\tDuration (minutes)";
// Credentials and provider settings passed to the Claude container when set. The ones marked secret are scanned for.
string[] passThrough = ["CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_BEDROCK", "AWS_REGION", "AWS_DEFAULT_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
    "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK", "CLAUDE_CODE_USE_VERTEX", "CLOUD_ML_REGION",
    "ANTHROPIC_VERTEX_PROJECT_ID", "CLAUDE_CODE_USE_FOUNDRY", "ANTHROPIC_FOUNDRY_API_KEY", "ANTHROPIC_FOUNDRY_RESOURCE",
    "ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL"];
string[] secretNames = ["CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK", "ANTHROPIC_FOUNDRY_API_KEY"];

try
{
    return await Main(args);
}
catch (Fail e)
{
    Console.Error.WriteLine($"run-case: {e.Message}");
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
    var c = JsonNode.Parse(File.ReadAllText(caseFile))!.AsObject();
    var config = File.Exists(Path.Combine(evalSet, "eval-run.json"))
        ? JsonNode.Parse(File.ReadAllText(Path.Combine(evalSet, "eval-run.json")))!.AsObject() : new JsonObject();

    var repoValue = Str(c, "repo") ?? throw new Fail($"{caseFile} has no \"repo\"");
    var isUrl = repoValue.Contains("://") || repoValue.StartsWith("git@");
    var repo = isUrl ? repoValue : Full(Path.Combine(evalSet, repoValue));
    var branch = Str(c, "branch") ?? throw new Fail($"{caseFile} has no \"branch\"");
    var request = Full(Path.Combine(caseDir, Str(c, "request") ?? "request.md"));
    var allow = c["allow"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? throw new Fail($"{caseFile} has no \"allow\" list");
    var setup = Str(c, "setup");
    var test = Str(c, "test");
    var refRef = Str(c, "referenceRef");
    var refFiles = c["referenceFiles"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? [];
    var refRepoValue = Str(c, "referenceRepo");
    var refRepo = refRepoValue is null ? (isUrl ? null : repo) : Full(Path.Combine(evalSet, refRepoValue));
    var checkBefore = c["checkBefore"]?.GetValue<bool>() ?? false;
    var extra = c["extraBranches"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? [];
    var setupEnvNames = c["setupEnv"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? [];
    var setupFiles = c["setupFiles"]?.AsObject().Select(kv => (Host: Full(Path.Combine(evalSet, kv.Key)), Container: kv.Value!.GetValue<string>())).ToArray() ?? [];
    var runs = int.Parse(o.GetValueOrDefault("runs") ?? config["runs"]?.ToString() ?? "3");
    var start = int.Parse(o.GetValueOrDefault("start") ?? "1");
    if (runs < 1 || start < 1) throw new Fail("--runs and --start must be positive numbers");
    var model = o.GetValueOrDefault("model") ?? Str(config, "model") ?? throw new Fail("no model: set \"model\" in eval-run.json, or pass --model");
    var runsDir = Full(o.GetValueOrDefault("runs-dir") ?? "~/eval-runs");
    var settings = Full(o.GetValueOrDefault("settings") ?? Path.Combine(evalSet, "eval-run-settings.json"));
    var runBy = o.GetValueOrDefault("run-by") ?? "";
    var keep = o.ContainsKey("keep");
    var version = o.GetValueOrDefault("claude-version") ?? TestedClaudeVersion;
    var timeout = TimeSpan.FromMinutes(double.Parse(o.GetValueOrDefault("timeout") ?? "30"));
    var image = $"ccw5g-eval-run:{version}";

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
    if (await Run("docker", ["info", "--format", "{{.ServerVersion}}"]) != 0) throw new Fail("Docker isn't running. Start Docker Desktop (or the Docker service), then run this again.");

    // The credential: from the environment, or a setup-token file. Only the container processes get it.
    var env = new Dictionary<string, string>();
    foreach (var name in passThrough)
        if (Environment.GetEnvironmentVariable(name) is { Length: > 0 } v) env[name] = v;
    var credentialFile = Full(o.GetValueOrDefault("credential-file") ?? "~/.config/ccw5g/claude-oauth-token");
    if (!env.ContainsKey("CLAUDE_CODE_OAUTH_TOKEN") && !env.ContainsKey("ANTHROPIC_API_KEY") && !env.ContainsKey("CLAUDE_CODE_USE_BEDROCK")
        && !env.ContainsKey("CLAUDE_CODE_USE_VERTEX") && !env.ContainsKey("CLAUDE_CODE_USE_FOUNDRY") && File.Exists(credentialFile))
        env["CLAUDE_CODE_OAUTH_TOKEN"] = File.ReadAllText(credentialFile).Trim();
    if (env.Count == 0 || !(env.ContainsKey("CLAUDE_CODE_OAUTH_TOKEN") || env.ContainsKey("ANTHROPIC_API_KEY") || env.ContainsKey("ANTHROPIC_AUTH_TOKEN")
        || env.ContainsKey("CLAUDE_CODE_USE_BEDROCK") || env.ContainsKey("CLAUDE_CODE_USE_VERTEX") || env.ContainsKey("CLAUDE_CODE_USE_FOUNDRY")))
        throw new Fail($"no credential for the runs. Save a claude setup-token in {credentialFile}, or set CLAUDE_CODE_OAUTH_TOKEN, ANTHROPIC_API_KEY, or your cloud provider's variables (see the walkthrough's setup).");
    // Claude Code's own precedence: a cloud provider, then ANTHROPIC_AUTH_TOKEN, ANTHROPIC_API_KEY, CLAUDE_CODE_OAUTH_TOKEN.
    var source = env.ContainsKey("CLAUDE_CODE_USE_BEDROCK") ? "Amazon Bedrock (CLAUDE_CODE_USE_BEDROCK in this terminal)"
        : env.ContainsKey("CLAUDE_CODE_USE_VERTEX") ? "Google Cloud (CLAUDE_CODE_USE_VERTEX in this terminal)"
        : env.ContainsKey("CLAUDE_CODE_USE_FOUNDRY") ? "Microsoft Foundry (CLAUDE_CODE_USE_FOUNDRY in this terminal)"
        : env.ContainsKey("ANTHROPIC_AUTH_TOKEN") ? "ANTHROPIC_AUTH_TOKEN in this terminal"
        : env.ContainsKey("ANTHROPIC_API_KEY") ? "ANTHROPIC_API_KEY in this terminal"
        : Environment.GetEnvironmentVariable("CLAUDE_CODE_OAUTH_TOKEN") is { Length: > 0 } ? "CLAUDE_CODE_OAUTH_TOKEN in this terminal"
        : $"the setup-token in {credentialFile}";
    Console.Error.WriteLine($"Signing in with {source}.");

    // Package feed credentials for the setup container only.
    var setupEnv = new Dictionary<string, string>();
    foreach (var n in setupEnvNames)
    {
        if (Environment.GetEnvironmentVariable(n) is { Length: > 0 } v) setupEnv[n] = v;
        else throw new Fail($"case.json names {n} in setupEnv, but it is not set in this terminal");
    }
    foreach (var (hostFile, _) in setupFiles)
        if (!File.Exists(hostFile)) throw new Fail($"case.json names {hostFile} in setupFiles, but it does not exist");
    var secrets = secretNames.Where(env.ContainsKey).Select(n => env[n]).Concat(setupEnv.Values).Where(s => s.Length >= 8).ToArray();

    // The image, built once per Claude Code version from the Dockerfile next to this script.
    if (await Run("docker", ["image", "inspect", image]) != 0)
    {
        var dockerfile = Path.Combine(ScriptDir(), "eval-run.Dockerfile");
        if (!File.Exists(dockerfile)) throw new Fail($"{dockerfile} not found");
        Console.Error.WriteLine($"Building the run image {image} (once; a few minutes)...");
        if (await Run("docker", ["build", "-q", "-t", image, "--build-arg", $"CLAUDE_VERSION={version}", "-f", dockerfile, ScriptDir()], echo: true) != 0)
            throw new Fail("building the run image failed (see above)");
    }
    foreach (var vol in new[] { "ccw5g-nuget", "ccw5g-npm" }) await Run("docker", ["volume", "create", vol]);

    Directory.CreateDirectory(outDir);
    Directory.CreateDirectory(runsDir);
    var prompt = File.ReadAllText(request);
    var date = DateTime.Now.ToString("yyyy-MM-dd");

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

    Console.Error.WriteLine($"Started {runs} run(s) of {caseId} with Claude Code {version} and model {model}, each in its own containers; waiting...");
    var setupGate = new SemaphoreSlim(1);
    var rows = await Task.WhenAll(Enumerable.Range(start, runs).Select(i => OneRun(i)));

    var tsv = Path.Combine(outDir, $"{caseId}-runs.tsv");
    File.WriteAllText(tsv, Header + "\n" + string.Concat(rows.Select(r => r + "\n")));
    Console.WriteLine();
    Console.Write(File.ReadAllText(tsv));
    Console.WriteLine();
    Console.WriteLine($"Rows saved to {tsv} (paste them into the Runs tab).");
    if (keep) Console.WriteLine($"Run clones kept in {runsDir}.");
    Console.WriteLine(test is null
        ? "Grade each run: read the reply (.md) against note.md, check Must include / Must not, then type the verdict in the Runs tab."
        : "Grade each run: read the .diff and .status, check Must include / Must not, then type the verdict in the Runs tab.");
    return 0;

    async Task<string> OneRun(int i)
    {
        var dir = Path.Combine(runsDir, $"{caseId}-run-{i}");
        var b = Path.Combine(outDir, $"{caseId}-run-{i}");
        var name = $"ccw5g-{Regex.Replace(caseId, "[^A-Za-z0-9_.-]", "_")}-run-{i}-{Guid.NewGuid().ToString("N")[..6]}";
        string note;
        var cost = ""; var minutes = ""; var modelUsed = model;
        var setupOk = true;
        if (setup is not null)
        {
            // One setup at a time: parallel restores into the shared package caches collide. The first fills the
            // caches; the others then take seconds. The Claude runs themselves are parallel.
            await setupGate.WaitAsync();
            try
            {
                setupOk = await Docker([name + "-setup", "-v", $"{dir}:/work", "-v", "ccw5g-nuget:/home/runner/.nuget/packages", "-v", "ccw5g-npm:/home/runner/.npm",
                        .. setupFiles.SelectMany(m => new[] { "-v", $"{m.Host}:{m.Container}:ro" }), .. setupEnv.Keys.SelectMany(k => new[] { "-e", k })],
                    ["bash", "-c", setup], b + ".setup.txt", b + ".setup.txt", setupEnv, timeout) == 0;
            }
            finally { setupGate.Release(); }
        }
        if (!setupOk)
        {
            note = $"Setup failed: see {Path.GetFileName(b)}.setup.txt";
        }
        else
        {
            var exit = await Docker([name, "-v", $"{dir}:/work", "-v", $"{settings}:/eval/settings.json:ro", "-v", "ccw5g-nuget:/home/runner/.nuget/packages:ro",
                    .. env.Keys.SelectMany(k => new[] { "-e", k })],
                ["claude", "-p", prompt, "--settings", "/eval/settings.json", "--permission-mode", "acceptEdits",
                 "--setting-sources", "project,local", "--strict-mcp-config", "--no-session-persistence",
                 "--allowedTools", string.Join(",", allow), "--model", model, "--output-format", "json"],
                b + ".json", b + ".stderr", env, timeout);

            // What Claude changed, captured before the reference files are copied in. New files are included.
            var status = await Capture("git", ["-c", "safe.directory=*", "-C", dir, "status", "--short"]);
            File.WriteAllText(b + ".status", status);
            var added = status.Split('\n').Count(l => l.StartsWith("??"));
            await Run("git", ["-c", "safe.directory=*", "-C", dir, "add", "--all", "--intent-to-add"]);
            File.WriteAllText(b + ".diff", await Capture("git", ["-c", "safe.directory=*", "-C", dir, "diff", "--no-color", "--no-ext-diff"]));
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
            if (data?["total_cost_usd"] is JsonNode cn) cost = cn.GetValue<double>().ToString("0.00");
            if (data?["duration_ms"] is JsonNode dn) minutes = (dn.GetValue<double>() / 60000).ToString("0.0");
            if (data?["modelUsage"] is JsonObject mu && mu.Count > 0) modelUsed = string.Join("+", mu.Select(kv => kv.Key));

            if (exit != 0) note = $"Run failed: exit {exit}; see {Path.GetFileName(b)}.stderr";
            else if (test is null) note = $"Review case: grade the reply (.md) against note.md; {changes}";
            else
            {
                var before = checkBefore ? $"Before overlay: {await RunTests(name + "-before", dir, b + ".tests-before.txt")}" : null;
                foreach (var f in refFiles)
                {
                    var target = Path.Combine(dir, f);
                    Directory.CreateDirectory(Path.GetDirectoryName(target)!);
                    File.WriteAllText(target, await Capture("git", ["-C", refRepo!, "show", $"{refRef}:{f}"]));
                }
                var after = await RunTests(name + "-test", dir, b + ".tests.txt");
                note = before is not null ? $"{before}; after overlay: {after}; {changes}"
                    : refFiles.Length > 0 ? $"Reference tests: {after}; {changes}" : $"Tests: {after}; {changes}";
            }
        }

        // Nothing that contains the credential is kept.
        var leaked = false;
        foreach (var f in Directory.GetFiles(outDir, $"{caseId}-run-{i}.*"))
        {
            var text = File.ReadAllText(f);
            if (secrets.Any(s => text.Contains(s)))
            {
                File.WriteAllText(f, "run-case removed this file: it contained the credential the run signed in with. Revoke that credential and create a new one.\n");
                leaked = true;
            }
        }
        if (leaked) note = "CREDENTIAL FOUND IN OUTPUT: file(s) removed; revoke the credential. " + note;

        if (!keep)
        {
            // Files the containers wrote may belong to the container's user, so a container removes the clone.
            await Docker([name + "-clean", "-v", $"{runsDir}:/runs"], ["rm", "-rf", $"/runs/{caseId}-run-{i}"], null, null, null, TimeSpan.FromMinutes(10));
            if (Directory.Exists(dir)) try { Directory.Delete(dir, true); } catch (Exception) { }
        }
        var location = b.StartsWith(Home()) ? "~" + b[Home().Length..].Replace('\\', '/') : b;
        return string.Join("\t", caseId, i, date, runBy, version, modelUsed, "None", "Container per run", "", note, location, cost, minutes);
    }

    // RunTests: runs the case's test command in a fresh container with no credential; "pass", or "fail (<counts>; see <log>)".
    async Task<string> RunTests(string name, string dir, string log)
    {
        var code = await Docker([name, "-v", $"{dir}:/work", "-v", "ccw5g-nuget:/home/runner/.nuget/packages:ro"], ["bash", "-c", test!], log, log, null, timeout);
        if (code == 0) return "pass";
        var text = File.Exists(log) ? File.ReadAllText(log) : "";
        // dotnet test prints "Failed: 1, Passed: 7"; Jest prints "Tests: 1 failed, 7 passed, 8 total".
        var dotnet = Regex.Matches(text, @"Failed:\s+(\d+), Passed:\s+(\d+)");
        var jest = Regex.Matches(text, @"^Tests:.*$", RegexOptions.Multiline);
        var counts = dotnet.Count > 0 ? $"{dotnet[^1].Groups[1].Value} failed, {dotnet[^1].Groups[2].Value} passed"
            : jest.Count > 0 ? string.Join(", ", Regex.Matches(jest[^1].Value, @"\d+ (failed|passed)").Select(x => x.Value))
            : "";
        return $"fail ({(counts.Length > 0 ? counts + "; " : "")}see {Path.GetFileName(log)})";
    }
}

// Docker: docker run --rm --name <name> <options> <image> <command>, with stdout and stderr to files.
async Task<int> Docker(string[] options, string[] command, string? stdout, string? stderr, Dictionary<string, string>? env, TimeSpan timeout)
{
    var image = $"ccw5g-eval-run:{(args.SkipWhile(a => a != "--claude-version").Skip(1).FirstOrDefault() ?? TestedClaudeVersion)}";
    string[] argv = ["run", "--rm", "--name", options[0], .. options[1..], image, .. command];
    var code = await Run("docker", argv, stdout: stdout, stderr: stderr, env: env, timeout: timeout);
    if (code == -1) await Run("docker", ["kill", options[0]]);
    return code;
}

// Run: starts a process with an argument list (no shell, so nothing needs quoting), and returns its exit code,
// or -1 after the timeout. Output goes to files, to the console with echo, or is discarded.
static async Task<int> Run(string file, string[] argv, string? stdout = null, string? stderr = null,
    Dictionary<string, string>? env = null, TimeSpan? timeout = null, bool echo = false)
{
    var psi = new ProcessStartInfo(file) { RedirectStandardOutput = !echo, RedirectStandardError = !echo, RedirectStandardInput = true, UseShellExecute = false };
    foreach (var a in argv) psi.ArgumentList.Add(a);
    if (env is not null) foreach (var (k, v) in env) psi.Environment[k] = v;
    using var p = Process.Start(psi) ?? throw new Fail($"could not start {file}");
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
    using var cts = new CancellationTokenSource(timeout ?? Timeout.InfiniteTimeSpan);
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
    try { await Run(file, argv, stdout: tmp); return File.ReadAllText(tmp); }
    finally { File.Delete(tmp); }
}

static Dictionary<string, string> ParseArgs(string[] argv)
{
    string[] flags = ["keep", "help"];
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

static string? Str(JsonObject? o, string key) => o?[key] is JsonValue v && v.TryGetValue<string>(out var s) ? s : null;

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

class Fail(string message) : Exception(message);
