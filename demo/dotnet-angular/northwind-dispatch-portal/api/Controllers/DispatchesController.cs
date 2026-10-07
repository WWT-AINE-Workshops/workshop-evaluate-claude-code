using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Northwind.Dispatch.Api.Auth;
using Northwind.Dispatch.Api.Data;
using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Controllers;

[ApiController]
[Route("api/dispatches")]
[Authorize]
public class DispatchesController(DispatchDbContext db) : ControllerBase
{
    public static readonly string[] SortValues = ["created", "eta", "reference"];

    /// <summary>Lists dispatches, optionally filtered by status, for the dispatch board.</summary>
    [HttpGet]
    [Authorize(Policy = Policies.Dispatcher)]
    public async Task<ActionResult<IEnumerable<DispatchDto>>> List([FromQuery] string? status, [FromQuery] string sort = "created")
    {
        if (!SortValues.Contains(sort))
        {
            return ValidationProblem(new ValidationProblemDetails(new Dictionary<string, string[]>
            {
                ["sort"] = [$"Unknown sort '{sort}'. Allowed values: {string.Join(", ", SortValues)}."],
            }));
        }

        var query = db.Dispatches.AsNoTracking();
        if (!string.IsNullOrEmpty(status))
        {
            if (!Enum.TryParse<DispatchStatus>(status, ignoreCase: true, out var parsed))
            {
                return ValidationProblem(new ValidationProblemDetails(new Dictionary<string, string[]>
                {
                    ["status"] = [$"Unknown status '{status}'."],
                }));
            }
            query = query.Where(d => d.Status == parsed);
        }

        query = sort switch
        {
            "eta" => query.OrderBy(d => d.Eta == null).ThenBy(d => d.Eta),
            "reference" => query.OrderBy(d => d.Reference),
            _ => query.OrderBy(d => d.CreatedAt),
        };

        return await query
            .Select(d => new DispatchDto(d.Id, d.Reference, d.Status.ToString(), d.Origin, d.Destination,
                d.Driver == null ? null : d.Driver.Name, d.CreatedAt, d.Eta))
            .ToListAsync();
    }

    /// <summary>Looks up one dispatch, with the assigned driver's name.</summary>
    [HttpGet("{id:int}")]
    [Authorize(Policy = Policies.Dispatcher)]
    public async Task<ActionResult<DispatchDto>> Get(int id)
    {
        var dispatch = await db.Dispatches.AsNoTracking().Include(d => d.Driver).FirstOrDefaultAsync(d => d.Id == id);
        if (dispatch is null)
        {
            return NotFound();
        }

        return new DispatchDto(dispatch.Id, dispatch.Reference, dispatch.Status.ToString(), dispatch.Origin,
            dispatch.Destination, dispatch.Driver!.Name, dispatch.CreatedAt, dispatch.Eta);
    }

    /// <summary>Typeahead search by reference or destination, for the portal's search box.</summary>
    [HttpGet("search")]
    [Authorize(Policy = Policies.Dispatcher)]
    public async Task<ActionResult<IEnumerable<DispatchDto>>> Search([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q) || q.Trim().Length < 2)
        {
            return Ok(Array.Empty<DispatchDto>());
        }

        var pattern = $"%{q.Trim()}%";
        return await db.Dispatches.AsNoTracking()
            .Where(d => EF.Functions.Like(d.Reference, pattern) || EF.Functions.Like(d.Destination, pattern))
            .OrderBy(d => d.Reference)
            .Take(10)
            .Select(d => new DispatchDto(d.Id, d.Reference, d.Status.ToString(), d.Origin, d.Destination,
                d.Driver == null ? null : d.Driver.Name, d.CreatedAt, d.Eta))
            .ToListAsync();
    }

    /// <summary>Cancels a dispatch that has not been delivered.</summary>
    [HttpPost("{id:int}/cancel")]
    public async Task<IActionResult> Cancel(int id)
    {
        var dispatch = await db.Dispatches.FindAsync(id);
        if (dispatch is null)
        {
            return NotFound();
        }
        if (dispatch.Status == DispatchStatus.Delivered)
        {
            return Conflict(new ProblemDetails { Title = "A delivered dispatch cannot be cancelled." });
        }

        dispatch.Status = DispatchStatus.Cancelled;
        await db.SaveChangesAsync();
        return NoContent();
    }
}
