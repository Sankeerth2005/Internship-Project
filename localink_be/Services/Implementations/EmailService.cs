using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    // OTP EMAIL
    public async Task SendOtpEmailAsync(string toEmail, string otp)
    {
        var subject = "Password Reset OTP - Vocal For Sanatan";
        var body = GetOtpTemplate(otp);

        await SendEmailAsync(toEmail, subject, body);
    }

    // WELCOME EMAIL
    public async Task SendWelcomeEmailAsync(string toEmail, string name)
    {
        var subject = "Welcome to Vocal For Sanatan!";
        var body = GetWelcomeTemplate(name);

        await SendEmailAsync(toEmail, subject, body);
    }

    // COMMON EMAIL METHOD
    private async Task SendEmailAsync(string toEmail, string subject, string htmlBody)
    {
        try
        {
            var email = new MimeMessage();

            email.From.Add(new MailboxAddress(
                _config["Email:AppName"] ?? "Vocal For Sanatan",
                _config["Email:From"] ?? "noreply@localink.com"
            ));

            email.To.Add(MailboxAddress.Parse(toEmail));
            email.Subject = subject;

            email.Body = new BodyBuilder
            {
                HtmlBody = htmlBody
            }.ToMessageBody();

            using var smtp = new SmtpClient();

            var portStr = _config["Email:Port"];
            var port = int.TryParse(portStr, out var p) ? p : 587;
            await smtp.ConnectAsync(
                _config["Email:Host"] ?? "smtp.gmail.com",
                port,
                SecureSocketOptions.StartTls
            );

            await smtp.AuthenticateAsync(
                _config["Email:Username"],
                _config["Email:Password"]
            );

            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);

            _logger.LogInformation("Email sent to {Email}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Email failed for {Email}", toEmail);
            throw new Exception("Email service failed");
        }
    }

    private string GetWelcomeTemplate(string name)
{
    return $@"
    <div style='margin:0;padding:0;background:#f4f6f8;font-family:Segoe UI,Arial,sans-serif'>
        <table width='100%' cellpadding='0' cellspacing='0'>
            <tr>
                <td align='center'>
                    <table width='600' style='background:#ffffff;border-radius:10px;padding:30px'>
                        
                        <tr>
                            <td align='center'>
                                <h1 style='color:#2d89ef;margin-bottom:5px'>Welcome to Vocal For Sanatan 🚀</h1>
                                <p style='color:#555;font-size:16px'>Hi {name}, we're excited to have you onboard!</p>
                            </td>
                        </tr>

                        <tr>
                            <td style='padding:20px 0;color:#444;font-size:15px;text-align:center'>
                                Discover local businesses, connect with customers, and grow faster than ever.
                            </td>
                        </tr>

                        <tr>
                            <td align='center'>
                                <a href='#' style='background:#2d89ef;color:#fff;padding:12px 25px;
                                    border-radius:6px;text-decoration:none;font-weight:bold'>
                                    Explore Vocal For Sanatan
                                </a>
                            </td>
                        </tr>

                        <tr>
                            <td style='padding-top:30px;font-size:13px;color:#888;text-align:center'>
                                Need help? Contact our support anytime.
                            </td>
                        </tr>

                        <tr>
                            <td style='padding-top:10px;font-size:12px;color:#aaa;text-align:center'>
                                © {DateTime.Now.Year} Vocal For Sanatan. All rights reserved.
                            </td>
                        </tr>

                    </table>
                </td>
            </tr>
        </table>
    </div>";
}

    // TEMPLATE
    private string GetOtpTemplate(string otp)
{
    return $@"
    <div style='background:#f4f6f8;padding:20px;font-family:Segoe UI,Arial'>
        <table width='100%' align='center'>
            <tr>
                <td align='center'>
                    <table width='500' style='background:#fff;border-radius:10px;padding:30px;text-align:center'>

                        <h2 style='color:#333'>Password Reset Request 🔐</h2>

                        <p style='color:#555;font-size:14px'>
                            Use the OTP below to reset your password.
                        </p>

                        <div style='margin:25px 0;font-size:32px;font-weight:bold;
                            letter-spacing:5px;color:#2d89ef'>
                            {otp}
                        </div>

                        <p style='color:#888;font-size:13px'>
                            This OTP is valid for <b>5 minutes</b>.
                        </p>

                        <hr style='margin:25px 0'/>

                        <p style='color:#999;font-size:12px'>
                            If you didn’t request this, please ignore this email.
                        </p>

                        <p style='color:#aaa;font-size:11px'>
                            Vocal For Sanatan Security Team
                        </p>

                    </table>
                </td>
            </tr>
        </table>
    </div>";
}

    public async Task SendNewBusinessNotificationToAdminAsync(
        string adminEmail,
        string businessName,
        string category,
        string description,
        string address,
        string phone,
        string email)
    {
        var subject = "🚀 New Business Registration - Action Required";

        var body = $@"
<div style='background:#f4f6f8;padding:20px;font-family:Segoe UI,Arial'>
    <table width='600' align='center' style='background:#fff;padding:25px;border-radius:10px'>

        <h2 style='color:#2d89ef'>🚀 New Business Pending Approval</h2>

        <p style='color:#555'>
            A new business has been registered and requires your review.
        </p>

        <table width='100%' style='margin-top:20px;font-size:14px;color:#333'>
            <tr><td><b>Business Name:</b></td><td>{businessName}</td></tr>
            <tr><td><b>Category:</b></td><td>{category}</td></tr>
            <tr><td><b>Description:</b></td><td>{description}</td></tr>
            <tr><td><b>Address:</b></td><td>{address}</td></tr>
            <tr><td><b>Phone:</b></td><td>{phone}</td></tr>
            <tr><td><b>Email:</b></td><td>{email}</td></tr>
        </table>

        <div style='margin-top:20px;padding:10px;background:#fff3cd;border-radius:6px;color:#856404'>
            Status: <b>Pending Approval</b>
        </div>

        <p style='margin-top:20px'>
            Please review this request in the admin dashboard.
        </p>

        <small style='color:#aaa'>Vocal For Sanatan System</small>

    </table>
</div>";

        await SendEmailAsync(adminEmail, subject, body);
    }

    public async Task SendBusinessStatusUpdateToUserAsync(
        string userEmail,
        string ownerName,
        string businessName,
        string category,
        string status,
        string? rejectionReason)
    {
        string subject;
        string body;

        if (status == "Approved")
        {
            subject = "🎉 Your Business Has Been Approved!";

            body = $@"
<div style='background:#f4f6f8;padding:20px;font-family:Segoe UI'>
    <table width='600' align='center' style='background:#fff;padding:25px;border-radius:10px;text-align:center'>

        <h2 style='color:#28a745'>🎉 Approved!</h2>

        <p style='font-size:16px;color:#333'>
            Congratulations {ownerName}, your business is now live!
        </p>

        <div style='margin:20px 0;text-align:left;font-size:14px'>
            <p><b>Business:</b> {businessName}</p>
            <p><b>Category:</b> {category}</p>
            <p><b>Status:</b> Approved ✅</p>
        </div>

        <a href='#' style='background:#28a745;color:#fff;padding:12px 25px;
            border-radius:6px;text-decoration:none;font-weight:bold'>
            View Dashboard
        </a>

        <p style='margin-top:20px;color:#777;font-size:13px'>
            Start attracting customers today 🚀
        </p>

        <small style='color:#aaa'>Vocal For Sanatan Team</small>

    </table>
</div>";
        }
        else
        {
            subject = "❌ Business Registration Update";

            body = $@"
<div style='background:#f4f6f8;padding:20px;font-family:Segoe UI'>
    <table width='600' align='center' style='background:#fff;padding:25px;border-radius:10px'>

        <h2 style='color:#dc3545'>Update on Your Business Submission</h2>

        <p>Hello {ownerName},</p>

        <p style='color:#555'>
            Unfortunately, your business submission was not approved at this time.
        </p>

        <div style='margin:20px 0;font-size:14px'>
            <p><b>Business:</b> {businessName}</p>
            <p><b>Category:</b> {category}</p>
            <p><b>Status:</b> Rejected ❌</p>
        </div>

        <div style='background:#ffe6e6;padding:12px;border-radius:6px;color:#a94442'>
            <b>Reason:</b> {rejectionReason}
        </div>

        <p style='margin-top:20px'>
            You can update your details and resubmit anytime.
        </p>

        <small style='color:#aaa'>Vocal For Sanatan Team</small>

    </table>
</div>";
        }

        await SendEmailAsync(userEmail, subject, body);
    }

    public async Task SendBusinessRegistrationEmailToOwnerAsync(
        string ownerEmail,
        string ownerName,
        string businessName,
        string category)
    {
        var subject = "🏢 Business Registration Submitted - Pending Review";
        var body = $@"
<div style='background:#f4f6f8;padding:20px;font-family:Segoe UI,Arial'>
    <table width='600' align='center' style='background:#fff;padding:25px;border-radius:10px'>

        <h2 style='color:#2d89ef'>🏢 Submission Received!</h2>

        <p>Hello {ownerName},</p>

        <p style='color:#555'>
            Thank you for registering your business, <b>{businessName}</b>.
        </p>

        <p style='color:#555'>
            Your submission has been received and is currently in <b>Pending</b> status. Our administrators will review the details shortly and notify you via email once the status is updated.
        </p>

        <table width='100%' style='margin-top:20px;font-size:14px;color:#333;border-top:1px solid #eee;padding-top:15px'>
            <tr><td><b>Business Name:</b></td><td>{businessName}</td></tr>
            <tr><td><b>Category:</b></td><td>{category}</td></tr>
            <tr><td><b>Status:</b></td><td>Pending Approval ⏳</td></tr>
        </table>

        <p style='margin-top:25px;font-size:13px;color:#888'>
            If you need to make changes or have questions, please contact support.
        </p>

        <small style='color:#aaa'>Vocal For Sanatan Team</small>

    </table>
</div>";

        await SendEmailAsync(ownerEmail, subject, body);
    }
}