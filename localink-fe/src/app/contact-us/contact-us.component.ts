import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { ProfileComponent } from '.././pages/profile/profile.component'; 
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-contact-us',
  standalone: true,
  imports: [FormsModule, CommonModule, ProfileComponent],
  templateUrl: './contact-us.component.html',
  styleUrls: ['./contact-us.component.css']
})
export class ContactUsComponent {

  feedbackText = '';
  successMessage = '';
  userId: number | null = null;

  username: string = '';
  showProfile = false;

  constructor(private http: HttpClient, private userService: UserService) {
    this.loadUserFromToken();
    this.loadUserName();
  }

  loadUserFromToken() {
    const token = localStorage.getItem('token');
    if (!token) return;

    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      this.userId = payload.userId || payload.id || null;
    } catch {
      console.error('Invalid token');
    }
  }

 loadUserName() {
  this.userService.getUserProfile().subscribe({
    next: (res: any) => {
      this.username = res.fullName || res.username || 'User';
    },
    error: () => {
      this.username = 'User';
    }
  });
}
  toggleProfile() {
    this.showProfile = true;
  }

  closeProfile() {
    this.showProfile = false;
  }

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  submitFeedback() {
  if (!this.feedbackText.trim()) return;

  const token = localStorage.getItem('token');

  const payload = {
    feedback: this.feedbackText,
    userId: this.userId
  };

  this.http.post(
    'http://localhost:5138/api/v1/feedback',
    payload,
    {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  ).subscribe({
    next: () => {
      this.successMessage = 'Feedback submitted successfully!';
      this.feedbackText = '';

      // AUTO HIDE AFTER 4 SECONDS
      setTimeout(() => {
        this.successMessage = '';
      }, 4000);
    },
    error: (err) => console.error(err)
  });
}
}