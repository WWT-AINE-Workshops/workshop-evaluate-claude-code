namespace Northwind.Dispatch.Api.Models;

public enum DispatchStatus
{
    Pending,
    Assigned,
    InTransit,
    Delivered,
    Cancelled,
}

public class Dispatch
{
    public int Id { get; set; }

    /// <summary>The reference customers and drivers quote, such as NWD-1001.</summary>
    public string Reference { get; set; } = "";

    public int CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public string Origin { get; set; } = "";
    public string Destination { get; set; } = "";
    public DispatchStatus Status { get; set; } = DispatchStatus.Pending;

    /// <summary>Null until a dispatcher assigns a driver. Pending dispatches have none.</summary>
    public int? DriverId { get; set; }
    public Driver? Driver { get; set; }

    /// <summary>UTC. Stored as DateTime because SQLite cannot order by DateTimeOffset.</summary>
    public DateTime CreatedAt { get; set; }
    public DateTime? Eta { get; set; }
}

public class Driver
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Address { get; set; } = "";
}
