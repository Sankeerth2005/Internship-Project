using localink_be.Options;
using localink_be.Services;
using localink_be.Services.Implementations;
using Xunit;

namespace localink_be.ReferralTests;

public class ReferralTagCalculatorTests
{
    private static ReferralOptions Opts() => new() { Bronze = 10, Silver = 100, Gold = 1000 };

    [Theory]
    [InlineData(0, "none")]
    [InlineData(9, "none")]
    [InlineData(10, "bronze")]
    [InlineData(99, "bronze")]
    [InlineData(100, "silver")]
    [InlineData(999, "silver")]
    [InlineData(1000, "gold")]
    [InlineData(5000, "gold")]
    public void Tier_boundaries(int count, string expectedTier)
    {
        Assert.Equal(expectedTier, ReferralTagCalculator.FromCount(count, Opts()).Tier);
    }

    [Fact]
    public void Progress_at_zero_targets_bronze()
    {
        var r = ReferralTagCalculator.FromCount(0, Opts());
        Assert.Equal(0, r.ProgressCurrent);
        Assert.Equal(10, r.ProgressTarget);
        Assert.Equal(10, r.RemainingToNext);
    }

    [Fact]
    public void Progress_at_15_targets_silver()
    {
        var r = ReferralTagCalculator.FromCount(15, Opts());
        Assert.Equal("bronze", r.Tier);
        Assert.Equal(100, r.ProgressTarget);
        Assert.Equal(85, r.RemainingToNext);
    }

    [Fact]
    public void MilestoneNewlyAchieved_detects_crossings()
    {
        var o = Opts();
        Assert.Equal("bronze", ReferralTagCalculator.MilestoneNewlyAchieved(9, 10, o));
        Assert.Equal("silver", ReferralTagCalculator.MilestoneNewlyAchieved(99, 100, o));
        Assert.Equal("gold", ReferralTagCalculator.MilestoneNewlyAchieved(999, 1000, o));
        Assert.Null(ReferralTagCalculator.MilestoneNewlyAchieved(10, 11, o));
    }
}

public class CanonicalEmailTests
{
    [Theory]
    [InlineData("User@Example.com", "user@example.com")]
    [InlineData("user+ref@gmail.com", "user@gmail.com")]
    [InlineData("u.s.e.r+tag@googlemail.com", "user@gmail.com")]
    [InlineData("a.b+x@outlook.com", "a.b@outlook.com")]
    public void CanonicalEmail_normalizes_aliases(string input, string expected)
    {
        Assert.Equal(expected, ReferralService.CanonicalEmail(input));
    }
}
