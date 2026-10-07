#!/usr/bin/env dotnet
// check-setup: checks this computer for the .NET and Angular practice kit, and says how to fix what's missing.
// It changes nothing, except that --live builds the run image if it is missing.
//
// Usage (the same in PowerShell, bash and zsh):
//   dotnet run --file <workshop repository>/templates/check-setup.cs
//   dotnet run --file <workshop repository>/templates/check-setup.cs -- --live
//
//   --live   also signs in from inside the run container: one tiny real call, a few cents. It builds the run image
//            first if it is missing (once; a few minutes).
using System.Diagnostics;
using System.Net.Http;
using System.Text.RegularExpressions;

const string TestedClaudeVersion = "2.1.285";
var live = args.Contains("--live");
var fixes = 0;
var warns = 0;
void Ok(string s) => Console.WriteLine($"  [ ok ]  {s}");
void Warn(string s) { warns++; Console.WriteLine($"  [warn]  {s}"); }
void Fix(string s, params string[] how) { fixes++; Console.WriteLine($"  [FIX ]  {s}"); foreach (var l in how) Console.WriteLine($"            {l}"); }
var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
var windows = OperatingSystem.IsWindows();
var wsl = OperatingSystem.IsLinux() && File.Exists("/proc/version") && File.ReadAllText("/proc/version").Contains("microsoft", StringComparison.OrdinalIgnoreCase);

Console.WriteLine("Checking this computer for the Claude Lab: Evaluate Claude Code on Your Own Work (.NET and Angular kit)");
Console.WriteLine();

Console.WriteLine("Your system");
Ok($"{(windows ? "Windows" : OperatingSystem.IsMacOS() ? "macOS" : wsl ? "Linux inside Windows (WSL)" : "Linux")} {Environment.OSVersion.Version} ({System.Runtime.InteropServices.RuntimeInformation.OSArchitecture})");
Ok($".NET SDK {(await Capture("dotnet", "--version")).Trim()} (it is running this check)");
var freeGb = new DriveInfo(Path.GetPathRoot(home)!).AvailableFreeSpace / 1e9;
if (freeGb >= 8) Ok($"{freeGb:0} GB free on the drive with your home folder");
else Warn($"{freeGb:0.0} GB free. The run image takes about 2 GB, and each run's clone about 400 MB while it runs. Free up 8 GB to be comfortable.");
try
{
    using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(8) };
    await http.GetAsync("https://code.claude.com");
    Ok("Internet access to code.claude.com");
}
catch (Exception) { Warn("Could not reach https://code.claude.com. Behind a company proxy or VPN? Ask your IT team how to allow it."); }
Console.WriteLine();

Console.WriteLine("Git (2.28 or later)");
var gitVersion = Regex.Match(await Capture("git", "--version"), @"\d+\.\d+(\.\d+)?").Value;
if (gitVersion.Length == 0)
    Fix("git is not installed", windows ? "Run:  winget install --id Git.Git -e     then open a NEW terminal" : OperatingSystem.IsMacOS() ? "Run:  xcode-select --install" : "Run:  sudo apt update && sudo apt install -y git");
else if (new Version(gitVersion) < new Version(2, 28)) Fix($"git {gitVersion} is too old", windows ? "Run:  winget upgrade --id Git.Git -e" : OperatingSystem.IsMacOS() ? "Run:  brew install git" : "Run:  sudo apt update && sudo apt install -y git");
else Ok($"git {gitVersion}");
if (windows && (await Capture("git", "config", "--global", "core.longpaths")).Trim() != "true")
    Warn("git's long-path support is off. The web app's node_modules nests deeply. Turn it on with:  git config --global core.longpaths true");
Console.WriteLine();

Console.WriteLine("Docker (runs every eval run in its own container)");
var dockerOs = (await Capture("docker", "info", "--format", "{{.OSType}}")).Trim();
if ((await Capture("docker", "--version")).Length == 0)
    Fix("Docker is not installed", windows || OperatingSystem.IsMacOS() ? "Install Docker Desktop from https://www.docker.com/products/docker-desktop/, start it, then run this check again." : "Install Docker Engine: https://docs.docker.com/engine/install/  (on WSL, Docker Desktop for Windows with WSL integration also works)");
else if (dockerOs.Length == 0 || dockerOs.Contains("error", StringComparison.OrdinalIgnoreCase))
    Fix("Docker is installed but not running", windows || OperatingSystem.IsMacOS() ? "Start Docker Desktop, wait until it says it is running, then run this check again." : "Start it with:  sudo systemctl start docker");
else if (dockerOs != "linux")
    Fix($"Docker is running {dockerOs} containers", "The run image is a Linux image. In Docker Desktop, choose 'Switch to Linux containers'.");
else
{
    var dockerVersion = (await Capture("docker", "info", "--format", "{{.ServerVersion}}")).Trim();
    Ok($"Docker {dockerVersion}, running Linux containers");
    if (int.TryParse(dockerVersion.Split('.')[0], out var major) && major < 25)
        Warn($"Docker {dockerVersion} runs the practice kit, but cases with \"services\" (such as a database) need Docker 25 or later.");
    var memGb = double.TryParse((await Capture("docker", "info", "--format", "{{.MemTotal}}")).Trim(), out var mem) ? mem / 1e9 : 0;
    if (memGb >= 6) Ok($"Docker can use {memGb:0} GB of memory");
    else Warn($"Docker can use {memGb:0.0} GB of memory. Three parallel runs build .NET and run Jest: give it 6 GB or more (Docker Desktop > Settings > Resources).");
    var image = $"ccw5g-eval-run:{TestedClaudeVersion}";
    var builtFor = (await Capture("docker", "image", "inspect", "--format", "{{index .Config.Labels \"ccw5g.uid\"}}", image)).Trim();
    var myUid = OperatingSystem.IsLinux() ? (await Capture("id", "-u")).Trim() : "1000";
    var exists = (await Capture("docker", "image", "inspect", "--format", "{{.Id}}", image)).Trim().StartsWith("sha256:");
    if (builtFor == myUid) Ok($"The run image {image} is built");
    else if (exists) Ok($"The run image {image} is from an earlier version of the kit: run-case rebuilds it on first use (a few minutes)");
    else Ok($"The run image {image} is not built yet: run-case builds it on first use (a few minutes), or run this check with --live");
}
Console.WriteLine();

Console.WriteLine("A credential for the runs (one you can revoke after the workshop)");
// In Claude Code's own order of precedence, as run-case uses them.
string[] providers = ["CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_FOUNDRY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY", "CLAUDE_CODE_OAUTH_TOKEN"];
var tokenFile = Path.Combine(home, ".config", "ccw5g", "claude-oauth-token");
var fromEnv = providers.FirstOrDefault(n => Environment.GetEnvironmentVariable(n) is { Length: > 0 });
var useBedrock = Environment.GetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK") is { Length: > 0 };
if (Environment.GetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX") is { Length: > 0 })
    Fix("CLAUDE_CODE_USE_VERTEX is set, but Google Cloud sign-in doesn't reach the run containers",
        "Unset it in this terminal, and use a setup-token, an API key, Bedrock, or Foundry with an API key.");
else if (fromEnv is not null) Ok($"{fromEnv} is set in this terminal, so run-case passes it to the containers");
else if (File.Exists(tokenFile) && new FileInfo(tokenFile).Length > 0)
{
    Ok($"A setup-token is saved in {tokenFile}");
    if (!windows && (File.GetUnixFileMode(tokenFile) & (UnixFileMode.GroupRead | UnixFileMode.OtherRead | UnixFileMode.GroupWrite | UnixFileMode.OtherWrite)) != 0)
        Fix("Other users on this computer can read the token file", $"Run:  chmod 600 {tokenFile}");
}
else
    Fix("No credential for the runs yet",
        "Run:  claude setup-token     sign in, and copy the token it prints. Then save it (nothing appears as you paste):",
        windows ? "  New-Item -ItemType Directory -Force $HOME\\.config\\ccw5g | Out-Null; $t = Read-Host -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($t)) | Set-Content -NoNewline $HOME\\.config\\ccw5g\\claude-oauth-token; Remove-Variable t"
                : "  mkdir -p ~/.config/ccw5g && chmod 700 ~/.config/ccw5g && read -rs T && printf '%s' \"$T\" > ~/.config/ccw5g/claude-oauth-token && unset T && chmod 600 ~/.config/ccw5g/claude-oauth-token",
        "Or set ANTHROPIC_API_KEY, or your organization's Bedrock or Foundry variables, in this terminal.");
if (!useBedrock && new[] { "AWS_ACCESS_KEY_ID", "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK" }.Any(n => Environment.GetEnvironmentVariable(n) is { Length: > 0 }))
    Ok("AWS credentials are set in this terminal; run-case keeps them out of the runs (it passes them only for Bedrock)");
var hostClaude = Regex.Match(await Capture("claude", "--version"), @"\d+\.\d+\.\d+").Value;
Ok(hostClaude.Length > 0 ? $"Claude Code {hostClaude} on this computer (the runs use {TestedClaudeVersion} inside the container)" : $"No Claude Code on this computer: not needed for the runs, which use {TestedClaudeVersion} inside the container");

if (live && fixes == 0)
{
    Console.WriteLine();
    Console.WriteLine("Signing in from inside the run container (one tiny real call, a few cents)");
    var script = Path.Combine(Path.GetDirectoryName(Location())!, "eval-run.Dockerfile");
    var image = $"ccw5g-eval-run:{TestedClaudeVersion}";
    // The same build as run-case's: on Linux and WSL the image's user takes your uid.
    var uid = OperatingSystem.IsLinux() ? (await Capture("id", "-u")).Trim() : "1000";
    var gid = OperatingSystem.IsLinux() ? (await Capture("id", "-g")).Trim() : "1000";
    if ((await Capture("docker", "image", "inspect", "--format", "{{index .Config.Labels \"ccw5g.uid\"}}", image)).Trim() != uid)
    {
        Console.WriteLine($"  Building {image} (once; a few minutes)...");
        await Capture("docker", "build", "-q", "-t", image, "--build-arg", $"CLAUDE_VERSION={TestedClaudeVersion}", "--build-arg", $"RUNNER_UID={uid}",
            "--build-arg", $"RUNNER_GID={gid}", "-f", script, Path.GetDirectoryName(script)!);
    }
    var env = new Dictionary<string, string>();
    string[] bedrock = ["AWS_REGION", "AWS_DEFAULT_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_BEARER_TOKEN_BEDROCK"];
    foreach (var n in providers.Concat(["ANTHROPIC_BASE_URL", "ANTHROPIC_FOUNDRY_API_KEY", "ANTHROPIC_FOUNDRY_RESOURCE", "ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL"]).Concat(useBedrock ? bedrock : []))
        if (Environment.GetEnvironmentVariable(n) is { Length: > 0 } v) env[n] = v;
    if (fromEnv is null && File.Exists(tokenFile)) env["CLAUDE_CODE_OAUTH_TOKEN"] = File.ReadAllText(tokenFile).Trim();
    List<string> run = ["run", "--rm"];
    foreach (var k in env.Keys) { run.Add("-e"); run.Add(k); }
    run.AddRange([image, "claude", "-p", "Reply with the single word ok", "--output-format", "json", "--no-session-persistence"]);
    var outText = await Capture2("docker", env, [.. run]);
    if (outText.Contains("\"is_error\":false")) Ok("Claude Code signs in inside the run container");
    else
    {
        var shown = env.Values.Where(s => s.Length >= 8).Aggregate(outText, (t, s) => t.Replace(s, "[credential]"));
        Fix("Signing in inside the run container did not work",
            "Check the token or key is current (claude setup-token makes a new one), and that your plan includes Claude Code.",
            $"What it printed: {shown[..Math.Min(shown.Length, 300)].ReplaceLineEndings(" ")}");
    }
}
else if (!live)
{
    Console.WriteLine();
    Console.WriteLine("  (Not checked: that the runs can sign in. Run this check with --live to check, at a cost of a few cents.)");
}
Console.WriteLine();

Console.WriteLine("Your workshop folders");
var leftovers = new[] { "nwd-foundation", "eval-runs" }.Where(d => Directory.Exists(Path.Combine(home, d)) && Directory.EnumerateFileSystemEntries(Path.Combine(home, d)).Any()).ToArray();
if (leftovers.Length > 0) Warn($"{string.Join(" and ", leftovers.Select(d => "~/" + d))} already have files from an earlier try. To start fresh, see 'Clean up' in WALKTHROUGH-dotnet.md.");
else Ok("No leftover practice folders from an earlier try");
Console.WriteLine();

if (fixes == 0)
{
    Console.WriteLine($"All set. ({warns} note{(warns == 1 ? "" : "s")} above.)");
    Console.WriteLine("Next: continue with the walkthrough.");
    return 0;
}
Console.WriteLine($"{fixes} item{(fixes == 1 ? "" : "s")} to fix. Do them in order, open a NEW terminal window, and run this check again.");
return 1;

static Task<string> Capture(string file, params string[] argv) => CaptureEnv(file, null, argv);
static Task<string> Capture2(string file, Dictionary<string, string> env, string[] argv) => CaptureEnv(file, env, argv);

static async Task<string> CaptureEnv(string file, Dictionary<string, string>? env, string[] argv)
{
    try
    {
        var psi = new ProcessStartInfo(file) { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        foreach (var a in argv) psi.ArgumentList.Add(a);
        if (env is not null) foreach (var (k, v) in env) psi.Environment[k] = v;
        using var p = Process.Start(psi)!;
        var o = p.StandardOutput.ReadToEndAsync();
        var e = p.StandardError.ReadToEndAsync();
        await p.WaitForExitAsync();
        return await o + await e;
    }
    catch (Exception) { return ""; }
}

static string Location([System.Runtime.CompilerServices.CallerFilePath] string path = "") => path;
