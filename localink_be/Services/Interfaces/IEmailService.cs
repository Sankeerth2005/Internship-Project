public interface IEmailService
{
    Task SendOtpEmailAsync(string toEmail, string otp);
    Task SendWelcomeEmailAsync(string toEmail, string name);
    Task SendNewBusinessNotificationToAdminAsync(
        string adminEmail,
        string businessName,
        string category,
        string description,
        string address,
        string phone,
        string email
    );

    Task SendBusinessStatusUpdateToUserAsync(
        string userEmail,
        string ownerName,
        string businessName,
        string category,
        string status,
        string? rejectionReason
    );

    Task SendBusinessRegistrationEmailToOwnerAsync(
        string ownerEmail,
        string ownerName,
        string businessName,
        string category
    );
}