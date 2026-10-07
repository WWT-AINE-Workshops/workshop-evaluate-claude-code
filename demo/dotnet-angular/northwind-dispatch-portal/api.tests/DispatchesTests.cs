using System.Net;
using System.Net.Http.Json;
using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Tests;

public class DispatchesTests(DispatchApiFactory api) : IClassFixture<DispatchApiFactory>
{
    [Fact]
    public async Task Health_IsAnonymous()
    {
        var response = await api.CreateClient().GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Get_ReturnsDispatchWithDriverName()
    {
        var dispatch = await api.ClientAs("dispatcher").GetFromJsonAsync<DispatchDto>("/api/dispatches/1");

        Assert.NotNull(dispatch);
        Assert.Equal("NWD-1001", dispatch.Reference);
        Assert.Equal("InTransit", dispatch.Status);
        Assert.Equal("Dana Ruiz", dispatch.DriverName);
    }

    [Fact]
    public async Task Get_UnknownId_Returns404()
    {
        var response = await api.ClientAs("dispatcher").GetAsync("/api/dispatches/999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Get_AsCustomer_Returns403()
    {
        var response = await api.ClientAs("customer").GetAsync("/api/dispatches/1");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Get_WithoutSignIn_Returns401()
    {
        var response = await api.CreateClient().GetAsync("/api/dispatches/1");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task List_AsDispatcher_ReturnsEverySeededDispatch()
    {
        var dispatches = await api.ClientAs("dispatcher").GetFromJsonAsync<List<DispatchDto>>("/api/dispatches");

        Assert.NotNull(dispatches);
        Assert.Equal(4, dispatches.Count);
    }

    [Fact]
    public async Task Search_MatchesReferenceOrDestination()
    {
        var client = api.ClientAs("dispatcher");

        var byReference = await client.GetFromJsonAsync<List<DispatchDto>>("/api/dispatches/search?q=1003");
        var byDestination = await client.GetFromJsonAsync<List<DispatchDto>>("/api/dispatches/search?q=boul");

        Assert.Equal(["NWD-1003"], byReference!.Select(d => d.Reference));
        Assert.Equal(["NWD-1002"], byDestination!.Select(d => d.Reference));
    }

    [Fact]
    public async Task Search_ShortQuery_ReturnsNothing()
    {
        var results = await api.ClientAs("dispatcher").GetFromJsonAsync<List<DispatchDto>>("/api/dispatches/search?q=N");

        Assert.Empty(results!);
    }
}
