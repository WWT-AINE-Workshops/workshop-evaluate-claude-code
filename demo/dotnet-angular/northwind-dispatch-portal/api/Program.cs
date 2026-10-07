using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Northwind.Dispatch.Api.Auth;
using Northwind.Dispatch.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Production runs on SQL Server behind the gateway; this demo keeps everything in one SQLite file.
builder.Services.AddDbContext<DispatchDbContext>(o =>
    o.UseSqlite(builder.Configuration.GetConnectionString("Dispatch") ?? "Data Source=dispatch.db"));

builder.Services.AddAuthentication(GatewayAuthHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, GatewayAuthHandler>(GatewayAuthHandler.SchemeName, null);
builder.Services.AddAuthorizationBuilder()
    .AddPolicy(Policies.Dispatcher, p => p.RequireRole("dispatcher", "admin"))
    .AddPolicy(Policies.Admin, p => p.RequireRole("admin"));

builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<DispatchDbContext>();
    db.Database.EnsureCreated();
    SeedData.Apply(db);
}

app.UseAuthentication();
app.UseAuthorization();
app.MapGet("/health", () => Results.Ok(new { status = "ok" })).AllowAnonymous();
app.MapControllers();

app.Run();

/// <summary>Visible to the tests' WebApplicationFactory.</summary>
public partial class Program;
