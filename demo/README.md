# demo/: the practice kits

Each folder here is a complete practice kit for the workshop: a fictional service with a history of merged, reverted, rejected, and open pull requests, six ready-made practice cases, and an answer key. The method, the exercises, and the tracker are the same in every kit. What differs is the stack you practise on and the walkthrough that guides you.

**Pick the kit closest to the code your team works on**, then follow its walkthrough. Everything in these folders is **fictional**: Northwind Freight, its people, its pull requests, and its results don't exist.

| Folder | Fictional service | Stack | Written for | Runs on | Walkthrough | Cases |
|---|---|---|---|---|---|---|
| [python-fastapi/](python-fastapi/) | `northwind-shipments-api` | Python, FastAPI, SQLite, pytest | Anyone, including people who have never used a terminal, git, or Python | macOS, Linux, Windows with WSL | [WALKTHROUGH.md](../WALKTHROUGH.md) | P-01 to P-06 |
| [dotnet-angular/](dotnet-angular/) | `northwind-dispatch-portal` | ASP.NET Core 10, EF Core, xUnit; Angular 19, RxJS, Jest | .NET and Angular engineers who already use Claude Code day to day | Windows, WSL, macOS, Linux; every run in its own Docker container | [WALKTHROUGH-dotnet.md](../WALKTHROUGH-dotnet.md) | D-01 to D-06 |

Each kit's own README says what each of its files is, and its `ANSWERS.md` is the answer key. Open an answer key only after you've done the exercise.

## Two warnings, for every kit

- **The services contain deliberate weaknesses.** They are teaching material, and the cases depend on them being exactly as they are. Never deploy a demo service, and don't fix the copies in these folders.
- **The foundation folder holds the answers.** Each walkthrough builds a full-history practice repository and an `eval-set` folder with the reference outputs. Claude only ever runs in a separate runs folder, with the eval-run settings file from [templates/](../templates/). The walkthroughs explain why.
