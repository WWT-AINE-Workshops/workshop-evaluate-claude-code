namespace Northwind.Dispatch.Api.Models;

/// <summary>The shape every dispatch endpoint returns. Field names are part of the API contract (docs/api.md).</summary>
public record DispatchDto(
    int Id,
    string Reference,
    string Status,
    string Origin,
    string Destination,
    string? DriverName,
    DateTime CreatedAt,
    DateTime? Eta);
