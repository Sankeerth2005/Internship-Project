namespace localink_be.Models.Enums
{
    /// <summary>
    /// Server-side business discovery sort modes.
    /// Coordinates rank results by distance and never hide farther businesses.
    /// Only <see cref="Nearest"/> ranks primarily by distance (after search relevance when querying).
    /// Other modes rank by their criterion, using distance as a tiebreaker.
    /// </summary>
    public enum BusinessSortMode
    {
        Nearest = 0,
        NameAsc = 1,
        NameDesc = 2,
        TopRated = 3,
        MostReviewed = 4,
        Newest = 5,
        MostPopular = 6
    }
}
