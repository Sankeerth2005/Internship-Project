import { Component, AfterViewInit } from '@angular/core';
import { Inject, PLATFORM_ID } from '@angular/core';

import {
  FormBuilder,
  Validators,
  ReactiveFormsModule,
  FormGroup,
  AbstractControl
} from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';

import { AuthService } from '../core/services/auth.service';
import { TokenService } from '../core/services/token.service';
import { ForgotPasswordComponent } from '../forgot-password/forgot-password.component';
import { LanguageSwitcherComponent } from '../components/language-switcher/language-switcher.component';
import { environment } from '../../environments/environment';

// IMPORTANT (global grecaptcha)
declare var grecaptcha: any;

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule, ForgotPasswordComponent, TranslateModule, LanguageSwitcherComponent],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements AfterViewInit {

  loginForm!: FormGroup;
  showPassword = false;
  submitted = false;
  isLoading = false;
  errorMessage = "";
  captchaToken: string | null = null;
  captchaError = false;
  captchaRendered = false; 

  currentView: 'login' | 'forgot' = 'login';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private tokenService: TokenService,
    private router: Router,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    this.initializeForm();

    this.loginForm.valueChanges.subscribe(() => {
      this.errorMessage = '';
    });
  }

  private initializeForm() {
    this.loginForm = this.fb.group({
      usernameOrEmail: [
        '',
        [Validators.required, Validators.email, Validators.maxLength(100)]
      ],
      password: [
        '',
        [
          Validators.required,
          Validators.minLength(8),
          Validators.maxLength(50),
          Validators.pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$/)
        ]
      ]
    });
  }

  get f(): { [key: string]: AbstractControl } {
    return this.loginForm.controls;
  }

  togglePassword() {
    this.showPassword = !this.showPassword;
  }

  isInvalid(field: string): boolean {
    const control = this.f[field];
    return !!(control && control.invalid && (control.touched || this.submitted));
  }

  getError(field: string): string {
    const control = this.f[field];
    if (!control || !control.errors) return '';

    if (control.errors['required']) return `${field === 'password' ? 'Password' : 'Email'} is required`;
    if (control.errors['email']) return 'Enter a valid email address';
    if (control.errors['minlength']) return 'Too short';
    if (control.errors['maxlength']) return 'Too long';
    if (control.errors['pattern']) return 'Password must be strong';

    return 'Invalid field';
  }

  login() {
    try {
      this.submitted = true;
      this.errorMessage = '';

      if (isPlatformBrowser(this.platformId)) {
        const firstInvalid = document.querySelector('.invalid') as HTMLElement;
        firstInvalid?.focus();
      }

      if (this.loginForm.invalid || this.isLoading) return;

     
      if (!this.captchaToken) {
        this.captchaError = true;
        return;
      }

      this.isLoading = true;

      const payload = {
        usernameOrEmail: this.loginForm.value.usernameOrEmail.trim().toLowerCase(),
        password: this.loginForm.value.password,
        captchaToken: this.captchaToken // 
      };

      this.authService.login(payload).subscribe({
        next: (res: any) => {
          try {
            const response = res.data;

            this.tokenService.setToken(response.token);
            this.tokenService.setUser(response.user?.name || response.name);
            
            const role = (response?.user?.userType || response?.userType || '').toLowerCase().trim();
            localStorage.setItem('userType', role);

            if (role === 'client') {
              this.router.navigate(['/client-dashboard']);
            } else if(role === 'user') {
              this.router.navigate(['/user-dashboard']);
            }
            else if(role === 'admin') {
              this.router.navigate(['/admin-dashboard']);
            }
            else{
              this.errorMessage = 'Unknown user role';
            }
          } catch (err) {
            this.errorMessage = 'Something went wrong after login';
          }
        },
        error: (err: any) => {
          this.handleError(err);

          // RESET CAPTCHA
          if (typeof grecaptcha !== 'undefined') {
            grecaptcha.reset();
            this.captchaToken = '';
          }
        },
        complete: () => {
          this.isLoading = false;
        }
      });

    } catch (error) {
      this.errorMessage = "Unexpected error occurred";
      this.isLoading = false;
    }
  }

  onCaptchaResolved(token: string) {
    this.captchaToken = token;
    this.captchaError = false;
  }

  handleError(err: any) {
    if (err.status === 401) {
      this.errorMessage = 'Invalid email or password';
    } else if (err.status === 0) {
      this.errorMessage = 'Network error. Try again';
    } else {
      this.errorMessage = 'Login failed. Try again';
    }

    this.isLoading = false;
    this.triggerErrorAnimation();
  }

  triggerErrorAnimation() {
    if (!isPlatformBrowser(this.platformId)) return;

    const card = document.getElementById('loginCard');
    if (!card) return;

    card.classList.add('shake');
    setTimeout(() => card.classList.remove('shake'), 400);
  }

  goToForgotPassword() {
    this.currentView = 'forgot';
  }

  backToLogin() {
    this.currentView = 'login';
    this.captchaToken = null;
    this.renderCaptcha();
  }

  renderCaptcha() {
    setTimeout(() => {
      if (typeof grecaptcha !== 'undefined') {
        try {
          grecaptcha.reset();
        } catch (e) {
          console.warn('reCAPTCHA reset failed', e);
        }
      }
    }, 300);
  }

  ngAfterViewInit() {
    if (!isPlatformBrowser(this.platformId)) return;

    // Single reCAPTCHA render via interval
    const interval = setInterval(() => {
      if (!this.captchaRendered && typeof grecaptcha !== 'undefined') {
        this.captchaRendered = true;

        grecaptcha.render('loginCaptcha', {
          sitekey: environment.recaptchaSiteKey,
          theme: 'dark',
          callback: (token: string) => {
            this.onCaptchaResolved(token);
          }
        });

        clearInterval(interval);
      }
    }, 500);

    // Cursor glow effect
    const glow = document.querySelector('.cursor-glow') as HTMLElement;

    document.addEventListener('mousemove', (e) => {
      if (glow) {
        glow.style.left = e.clientX + 'px';
        glow.style.top = e.clientY + 'px';
      }
    });

    // Canvas animation
    const canvas = document.querySelector('.lines-canvas') as HTMLCanvasElement;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const resize = () => {
      canvas.width = window.innerWidth / 2;
      canvas.height = window.innerHeight;
    };

    resize();
    window.addEventListener('resize', resize);

    const points = Array.from({ length: 40 }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4
    }));

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      points.forEach(p => {
        p.x += p.vx;
        p.y += p.vy;

        if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
        if (p.y < 0 || p.y > canvas.height) p.vy *= -1;

        points.forEach(p2 => {
          const dist = Math.hypot(p.x - p2.x, p.y - p2.y);

          if (dist < 130) {
            ctx.strokeStyle = `rgba(200,169,126,${1 - dist / 130})`;
            ctx.lineWidth = 1;

            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.stroke();
          }
        });
      });

      requestAnimationFrame(draw);
    };

    draw();
  }
}