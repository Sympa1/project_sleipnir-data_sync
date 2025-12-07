namespace data_sync.API.Data;

using Microsoft.EntityFrameworkCore;
using data_sync.API.Models;

/// <summary>
/// ApplicationDbContext
/// --------------------
/// EF Core DbContext für das Projekt. Enthält die DbSet-Eigenschaften für
/// die Entities (SyncFile, SyncEvent) sowie die Fluent-API-Konfiguration
/// in <see cref="OnModelCreating(ModelBuilder)"/>.
///
/// Verantwortlichkeiten:
/// - Tabellendefinitionen über DbSet<T>
/// - Beziehungskonfiguration (z. B. 1:n SyncFile -> SyncEvent)
/// - Festlegen von Primärschlüsseln, Required-Constraints und Default-Werten
///
/// Hinweis: Die DI-Registrierung erfolgt in Program.cs mit AddDbContext<T>.
///</summary>
public class ApplicationDbContext : DbContext
{
    /// <summary>
    /// Konstruktor, erwartet DbContextOptions die von der DI bereitgestellt werden.
    /// </summary>
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    /// <summary>
    /// DbSet für SyncFile. Repräsentiert die Tabelle, in der Dateien/Metadaten gespeichert werden.
    /// </summary>
    public DbSet<SyncFile> SyncFiles { get; set; } = null!;

    /// <summary>
    /// DbSet für SyncEvent. Repräsentiert Änderungs-Logs / Events pro Datei.
    /// </summary>
    public DbSet<SyncEvent> SyncEvents { get; set; } = null!;

    /// <summary>
    /// Fluent-API-Konfiguration der Entitäten.
    /// - Definiert Keys
    /// - Setzt Required-Constraints
    /// - Konfiguriert Relation SyncFile 1:n SyncEvent
    /// - Setzt sinnvolle Default-Werte
    ///</summary>
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Konfiguration für SyncFile
        modelBuilder.Entity<SyncFile>(entity =>
        {
            // Primärschlüssel für SyncFile
            entity.HasKey(f => f.FileId);

            // Path darf nicht null sein (logische Pflichtangabe)
            entity.Property(f => f.Path).IsRequired();

            // Hash darf nicht null sein; Default ist leerer String damit DB-Zustand konsistent bleibt
            entity.Property(f => f.Hash).IsRequired().HasDefaultValue(string.Empty);

            // Beziehung: Ein SyncFile hat viele SyncEvents (1:n)
            // Die Navigationseigenschaft SyncEvents in SyncFile und File in SyncEvent werden damit verbunden.
            // OnDelete Cascade führt dazu, dass beim Löschen einer Datei deren Events mitgelöscht werden.
            entity.HasMany(f => f.SyncEvents)
                  .WithOne(e => e.File)
                  .HasForeignKey(e => e.FileId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Konfiguration für SyncEvent
        modelBuilder.Entity<SyncEvent>(entity =>
        {
            // Primärschlüssel für SyncEvent
            entity.HasKey(e => e.LogId);

            // Timestamp ist erforderlich; jedes Event sollte eine Zeitangabe haben
            entity.Property(e => e.Timestamp).IsRequired();

            // Details können optional gesetzt werden; Default ist leerer String (keine NULLs)
            entity.Property(e => e.Details).HasDefaultValue(string.Empty);
        });

        base.OnModelCreating(modelBuilder);
    }
}
