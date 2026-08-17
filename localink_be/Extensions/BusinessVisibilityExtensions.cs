using localink_be.Models.Entities;

namespace localink_be.Extensions
{
    /// <summary>
    /// Consumer-facing visibility rules for businesses.
    /// Keep EF filters and discovery SQL in sync via this single definition.
    /// </summary>
    public static class BusinessVisibilityExtensions
    {
        /// <summary>
        /// SQL fragment (AND ...) excluding businesses with an active admin-approved temporary closure.
        /// Used by BusinessDiscoveryRepository raw SQL.
        /// </summary>
        public const string SqlAndNotActivelyTemporarilyClosed = """
              AND NOT (
                    b.temporary_closure_status = N'Approved'
                AND b.temporary_closure_reopen_date IS NOT NULL
                AND b.temporary_closure_reopen_date > SYSUTCDATETIME()
              )
            """;

        public static bool IsActivelyTemporarilyClosed(this Business business, DateTime? utcNow = null)
        {
            var now = utcNow ?? DateTime.UtcNow;
            return business.TemporaryClosureStatus == "Approved"
                && business.TemporaryClosureReopenDate.HasValue
                && business.TemporaryClosureReopenDate.Value > now;
        }

        /// <summary>
        /// EF filter: approved temporary closures that have not yet reached reopen time are hidden from consumers.
        /// </summary>
        public static IQueryable<Business> WhereVisibleToConsumers(this IQueryable<Business> query)
        {
            var now = DateTime.UtcNow;
            return query.Where(b =>
                !(b.TemporaryClosureStatus == "Approved"
                  && b.TemporaryClosureReopenDate.HasValue
                  && b.TemporaryClosureReopenDate.Value > now));
        }
    }
}
