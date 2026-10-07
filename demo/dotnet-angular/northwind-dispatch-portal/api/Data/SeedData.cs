using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Data;

/// <summary>Fictional demo data. The tests rely on these exact rows.</summary>
public static class SeedData
{
    public static readonly DateTime Day = new(2026, 8, 3, 9, 0, 0, DateTimeKind.Utc);

    public static void Apply(DispatchDbContext db)
    {
        if (db.Dispatches.Any())
        {
            return;
        }

        var harbor = new Customer { Id = 1, Name = "Harbor Fresh Foods", Email = "orders@harborfresh.example", Address = "14 Quay Street, Portland" };
        var alpine = new Customer { Id = 2, Name = "Alpine Outfitters", Email = "logistics@alpine.example", Address = "220 Ridge Road, Denver" };
        var dana = new Driver { Id = 1, Name = "Dana Ruiz", Phone = "+1-555-0141" };
        var sam = new Driver { Id = 2, Name = "Sam Okafor", Phone = "+1-555-0177" };

        db.Customers.AddRange(harbor, alpine);
        db.Drivers.AddRange(dana, sam);
        db.Dispatches.AddRange(
            new Models.Dispatch { Id = 1, Reference = "NWD-1001", Customer = harbor, Origin = "Portland", Destination = "Seattle", Status = DispatchStatus.InTransit, Driver = dana, CreatedAt = Day, Eta = Day.AddHours(5) },
            new Models.Dispatch { Id = 2, Reference = "NWD-1002", Customer = alpine, Origin = "Denver", Destination = "Boulder", Status = DispatchStatus.Assigned, Driver = sam, CreatedAt = Day.AddHours(1), Eta = Day.AddHours(3) },
            new Models.Dispatch { Id = 3, Reference = "NWD-1003", Customer = harbor, Origin = "Portland", Destination = "Salem", Status = DispatchStatus.Pending, CreatedAt = Day.AddHours(2) },
            new Models.Dispatch { Id = 4, Reference = "NWD-1004", Customer = alpine, Origin = "Denver", Destination = "Northglenn", Status = DispatchStatus.Delivered, Driver = dana, CreatedAt = Day.AddHours(-20), Eta = Day.AddHours(-16) });
        db.SaveChanges();
    }
}
