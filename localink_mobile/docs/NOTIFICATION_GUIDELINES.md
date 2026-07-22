# Notification Guidelines: Vocal for Sanatan
Version 1.0.0 • Notification Design, Triggers & Templates

This document details the visual templates, trigger rules, and push/in-app notification guidelines for the Vocal for Sanatan application.

---

## 1. Notification Visual Structure

Every push notification must follow a clean, unified format:
*   **Icon:** App icon (Orange/White emblem) or category symbol (e.g. food, support).
*   **Title:** Concise, action-oriented heading (under 40 characters).
*   **Body:** Informative summary of the event (under 120 characters).
*   **Action Actions:** Tapable buttons embedded in the system tray banner (e.g. *Reply*, *View Directions*, *Approve*).

---

## 2. Standard Notification Templates

Here are the system notification events, templates, priorities, and action pathways:

| Event Trigger | Notification Title | Notification Body | Priority | Tap Action Route |
| :--- | :--- | :--- | :--- | :--- |
| **Store Approved** | 🌟 Store Approved! | *Congratulations! Rajesh's Hardware is now live and verified in Varanasi.* | High | `/business-dashboard` |
| **Store Rejected** | ⚠️ Correction Required | *Your listing requires address verification before publishing. Tap to correct.* | High | `/register-business` (edit mode) |
| **New Store Nearby** | 📍 New Nearby! | *A new pharmacy, Gupta Medicos, has registered 300m away from you.* | Medium | `/business-detail/:id` |
| **Review Received** | 💬 New Review | *Aditi left a 5-star review: "Excellent service!" Tap to reply.* | Medium | `/business-detail/:id#reviews` |
| **Temp Closure Alert**| 🕒 Store Closed | *Gupta Medicos is closed temporarily until Monday. Tap for details.* | Low | `/business-detail/:id` |
| **Complaint Updated** | ⚖️ Complaint Update | *Your ticket (#1024) has been reviewed. Tap to view moderator feedback.* | High | `/support-feedback` |
| **Admin Telemetry Alert**| 📈 Heatmap Peak | *Varanasi Zone 3 is showing high search volumes. Tap to view active heatmap.* | High | `/admin-heatmap` |

---

## 3. Delivery Channels

### A. System Tray Push Notifications
*   **Use Cases:** Time-sensitive alerts (approval, rejection, direct replies).
*   **Behavior:** Emits haptic sound alerts. Displays up to 2 action button links (e.g. *Accept* / *Reject* for admin, *View* for owner).

### B. In-App Notification Center
*   **Use Cases:** Non-blocking discoveries (new nearby shops, general product feedback invitations, system updates).
*   **Behavior:** Appears inside a sliding panel on the Home screen. Unread items display a pulsing orange badge count. Swipe-to-dismiss clears individual notifications.

---

## 4. Quiet Hours & Notification Control
*   **Do Not Disturb (Quiet Hours):** To prevent user exhaustion, no marketing or discovery push notifications are delivered between **9:00 PM and 8:00 AM**.
*   **Notification Preferences:** Users can toggle notification categories (e.g., *Community Discoveries*, *Business Status Updates*, *Reviews & Chats*, *AI Suggestions*) from the settings page.
