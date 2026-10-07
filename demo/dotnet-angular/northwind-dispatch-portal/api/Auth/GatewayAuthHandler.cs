using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Northwind.Dispatch.Api.Auth;

/// <summary>
/// The SSO gateway in front of the portal signs users in and forwards who they are in two headers,
/// X-Northwind-User and X-Northwind-Role (customer, dispatcher or admin). The API trusts those headers
/// because only the gateway can reach it. The tests send the same headers.
/// </summary>
public class GatewayAuthHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger, UrlEncoder encoder)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Gateway";
    public const string UserHeader = "X-Northwind-User";
    public const string RoleHeader = "X-Northwind-Role";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var user = Request.Headers[UserHeader].ToString();
        var role = Request.Headers[RoleHeader].ToString();
        if (string.IsNullOrEmpty(user) || string.IsNullOrEmpty(role))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var identity = new ClaimsIdentity([new Claim(ClaimTypes.Name, user), new Claim(ClaimTypes.Role, role)], SchemeName);
        return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName)));
    }
}

public static class Policies
{
    /// <summary>Dispatchers and admins: the office staff who plan and change dispatches.</summary>
    public const string Dispatcher = "Dispatcher";

    /// <summary>Admins only: bulk data, reports and anything that spans customers.</summary>
    public const string Admin = "Admin";
}
