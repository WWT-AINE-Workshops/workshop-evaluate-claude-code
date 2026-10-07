using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Northwind.Dispatch.Api.Auth;

namespace Northwind.Dispatch.Api.Tests;

/// <summary>
/// One API per test class, on its own in-memory SQLite database seeded with SeedData.
/// Use it with IClassFixture&lt;DispatchApiFactory&gt;, and sign in with ClientAs.
/// </summary>
public class DispatchApiFactory : WebApplicationFactory<Program>
{
    private readonly string _connectionString = $"Data Source=dispatch-{Guid.NewGuid():N};Mode=Memory;Cache=Shared";
    private readonly SqliteConnection _keepAlive;

    public DispatchApiFactory()
    {
        // An in-memory database lives only while a connection to it is open.
        _keepAlive = new SqliteConnection(_connectionString);
        _keepAlive.Open();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("ConnectionStrings:Dispatch", _connectionString);
    }

    /// <summary>A client signed in through the gateway headers, as a customer, dispatcher or admin.</summary>
    public HttpClient ClientAs(string role, string user = "test-user")
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Add(GatewayAuthHandler.UserHeader, user);
        client.DefaultRequestHeaders.Add(GatewayAuthHandler.RoleHeader, role);
        return client;
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing)
        {
            _keepAlive.Dispose();
        }
    }
}
