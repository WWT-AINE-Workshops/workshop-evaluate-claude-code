using Microsoft.EntityFrameworkCore;
using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Data;

public class DispatchDbContext(DbContextOptions<DispatchDbContext> options) : DbContext(options)
{
    public DbSet<Models.Dispatch> Dispatches => Set<Models.Dispatch>();
    public DbSet<Driver> Drivers => Set<Driver>();
    public DbSet<Customer> Customers => Set<Customer>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<Models.Dispatch>().HasIndex(d => d.Reference).IsUnique();
        model.Entity<Models.Dispatch>().Property(d => d.Status).HasConversion<string>();
    }
}
